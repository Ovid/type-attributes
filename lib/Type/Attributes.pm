use strict;
use warnings;

package Type::Attributes;
use v5.20.0;
use Variable::Magic qw(wizard cast);
use Attribute::Handlers;
use Type::Attributes::Types;
use Type::Params    qw(compile);
use Types::Standard qw(ArrayRef HashRef);
use Scalar::Util 'refaddr';
use Carp 'croak';

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

    _show_ref('$unknown', $referent, $package);
    _show_ref('%ACTIONS_FOR', \%ACTIONS_FOR);
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
    _show_ref('$scalar_wizard', $wizard);
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
    _show_ref('$array_wizard', $wizard);
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
    _show_ref('$hash_wizard', $wizard);
}

END {
    use DDP;
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
    say STDERR sprintf "====> %s in $package Decimal: $address Hexadecimal: 0x%x" => $name, $var;
}

1;
