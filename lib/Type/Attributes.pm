use strict;
use warnings;

package Type::Attributes;

# ABSTRACT: Types Variables in Perl

use v5.20.0;
use Variable::Magic qw(wizard cast);
use Attribute::Handlers;
use Type::Attributes::Types;
use Type::Params    qw(compile);
use Types::Standard qw(ArrayRef HashRef);
use Scalar::Util 'refaddr';
use Carp 'croak';

our $VERSION = '0.05';

sub import {
    my ($class) = @_;
    state $seen = {};
    if ( !$seen->{'Type'}++ ) {
        no warnings;
        eval qq{ sub UNIVERSAL::Type :ATTR { goto &Type::Attributes::Type} };
    }
}

my %ACTIONS_FOR;

sub Type : ATTR {
    my ( $package, $symbol, $referent, $attr, $data ) = @_;

    _show_ref( '$unknown', $referent, $package );
    _show_ref( '%ACTIONS_FOR', \%ACTIONS_FOR );
    if ( exists $ACTIONS_FOR{ refaddr $referent } ) {

        # should never happen
        my $address = refaddr $referent;
        croak("PANIC: type assigning already made for variable at $referent");
    }

    my $type     = _extract_type($data);
    my %dispatch = (
        SCALAR => \&_handle_scalar,
        ARRAY  => \&_handle_array,
        HASH   => \&_handle_hash,
    );
    my $handler = $dispatch{ ref $referent }
      or croak("Cannot assign types to $referent");
    $handler->( $type, $referent );
}

sub _extract_type {

    # currently this only allows simple types, such as :Type(Int).
    # We want something much more robust here. For example, we might want:
    # my @colors :Type(ArrayRef[Enum[qw/red blue green/]])
    my $data = shift;
    my $type = Type::Attributes::Types->can( $data->[0] )
      or croak("Unknown type: $data->[0]");
    return $type->();
}

sub _handle_scalar {
    my ( $type, $referent ) = @_;
    my $address = refaddr $referent;

    $ACTIONS_FOR{$address} = {
        set => sub {
            my $value = shift;
            state $check = compile($type);
            $check->($$value);
        },
    };
    my $wizard = wizard(
        set  => $ACTIONS_FOR{$address}{set},
        free => sub { delete $ACTIONS_FOR{$address} },
    );
    cast $$referent => $wizard;
    _show_ref( '$scalar_wizard', $wizard );
}

sub _handle_array {
    my ( $type, $referent ) = @_;
    my $address = refaddr $referent;

    $ACTIONS_FOR{$address} = {
        set => sub {
            my $value = shift;
            state $check = compile( ArrayRef [$type] );
            $check->($value);
        },
    };

# tried various keys such as "get len clear copy dup local fetch store exists delete"
# and none seemd to cover the case of $foo[$i] = $val.
    my $wizard = wizard(
        set  => $ACTIONS_FOR{$address}{set},
        free => sub { delete $ACTIONS_FOR{$address} },
    );
    cast @$referent => $wizard;
    _show_ref( '$array_wizard', $wizard );
}

sub _handle_hash {
    my ( $type, $referent ) = @_;
    my $address = refaddr $referent;

    $ACTIONS_FOR{$address} = {
        store => sub {
            my $value = shift;
            state $check = compile( HashRef [$type] );
            $check->($value);
        },
    };

    my $wizard = wizard(
        store => $ACTIONS_FOR{$address}{set},
        free  => sub { delete $ACTIONS_FOR{$address} },

    );
    cast %$referent => $wizard;
    _show_ref( '$hash_wizard', $wizard );
}

END {
    if ( $ENV{DEBUG_TYPE_ATTRIBUTES} ) {
        foreach my $address ( keys %ACTIONS_FOR ) {

            # XXX This should never happen, but it
            say STDERR sprintf "Unfreed variable: $address Hexadecimal: 0x%x",
              $address;
        }
    }
}

sub _show_ref {
    return unless $ENV{DEBUG_TYPE_ATTRIBUTES};
    my ( $name, $var, $package ) = @_;
    $package //= __PACKAGE__;
    my $address = refaddr $var;
    say STDERR sprintf
      "====> %s in $package Decimal: $address Hexadecimal: 0x%x" => $name,
      $var;
}

1;

__END__

=head1 SYNOPSIS

    my $count :Type(ZeroOrPositiveInt) = 3;
    $count = -2; # fatal

    my @array :Type(Int); # no default value required

    # invalid defaults are fatal
    my %hash  :Type(NonEmptySimpleStr) = []; # fatal

=head1 DESCRIPTION

Experimental module to attempt to use L<Variable::Magic>,
L<Attribute::Handlers>, and L<Type::Tiny> to make it transparent to create
typed variables in Perl.

=head1 DEVELOPMENT NOTES

At the present time, the C<t/error.t> script is this:

    #!/usr/bin/env perl

    use Test::More;
    use Type::Attributes;

    my $counter : Type(Int) = 3;
    eval { $counter = 'bar'; 1 };
    ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

    my @foo : Type(Num) = qw(1 2 3.2);
    eval { @foo = qw(2 bar 4); 1 };
    ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

    done_testing;

This minimal test case outputs something like:

    t/error.t ..
    ok 1 - Bad type
    ok 2 - Bad type
    1..2
    Attempt to free unreferenced scalar: SV 0x11e0cf7e0 during global destruction.
    ok
    All tests successful.
    Files=1, Tests=2,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.04 cusr  0.01 csys =  0.06 CPU)
    Result: PASS

The C<Attempt to free unreferenced scalar> is a compiler level error.

It shows up intermittently (though most of the time), so it's probably a
global destruction ordering issue. Removing either C<eval> makes the error go
away.

Further, swapping the order of the tests makes the error go away:

    my @foo : Type(Num) = qw(1 2 3.2);
    eval { @foo = qw(2 bar 4); 1 };
    ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

    my $counter : Type(Int) = 3;
    eval { $counter = 'bar'; 1 };
    ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

C<perl -v>:

    This is perl 5, version 26, subversion 3 (v5.26.3) built for darwin-2level
    (with 1 registered patch, see perl -V for more detail)

Also, the following C<TODO> test in F<t/basic_types.t> is annoying. I wonder
if this is related.

  TODO: {
        local $TODO = "Direct assignment bypasses Variable::Magic";
        throws_ok { $foo[1] = 'bar' }
        'Error::TypeTiny::Assertion',
          'Assigning an incorrect type to an array entry should fail';
    }

The above I<should> work because the docs for C<set> in L<Variable::Magic> say
the following:

    This magic is called each time the value of the variable changes. It is
    called for array subscripts and slices, but never for hashes.
