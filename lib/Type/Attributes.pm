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

Looks like there's a bug in L<Variable::Magic> with Perl 5.26 and above,
when using C<< $@->isa >>. Bug filed: L<https://rt.cpan.org/Ticket/Display.html?id=145680>

Test case, with everything stripped out that I can find.

    #!/usr/bin/env perl

    use Variable::Magic qw(wizard cast);

    my $use_regex = shift @ARGV;

    sub Fake::Exception::throw { die bless {} => shift }

    my $wizard = wizard( set => sub { Fake::Exception->throw } );

    my $counter = 3;
    my @foo     = qw(1 2 3.2);
    cast $counter, $wizard;
    cast @foo,     $wizard;

    eval { Fake::Exception->throw };

    if ($use_regex) {
        $@ =~ qr/Fake::Exception/;
    }
    else {
        $@->isa('Fake::Exception');
    }

    eval { @foo = qw(2 bar 4) };
    $@->isa('Fake::Exception');
    print "Done\n";

Running that with 5.26 and above on my M1 Mac produces this:

    $ perl testcase.pl
    Done
    Attempt to free unreferenced scalar: SV 0x14401a550 at t/core.t line 27.

Passing a true value to the script makes the error go away:

    $ perl testcase.pl 1
    Done
