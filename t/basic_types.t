#!/usr/bin/env perl

use lib 'lib';
use v5.20.0;
use Test::Most;
use Type::Attributes;
use Scalar::Util 'refaddr';
use PadWalker 'peek_my';

BEGIN {
    $ENV{DEBUG_TYPE_ATTRIBUTES} = 1;
}

sub show_ref {
    my $var     = shift;
    my $address = refaddr $var;
    my $pad     = peek_my(1);
    my $varname = 'Could not determine variable name';
  VAR: foreach my $var ( keys %$pad ) {
        if ( $address == refaddr $pad->{$var} ) {
            $varname = $var;
            last VAR;
        }
    }
    say STDERR sprintf "----> $varname. Decimal: $address Hexadecimal: 0x%x" =>
      $var;
}

subtest 'scalars' => sub {
    my $foo : Type(Int) = 3;
    ok $foo, 'We should be able to create a typed variable';
    is $foo, 3, '... and its value should be correct';
    ok $foo = -4, '... and we can assign new values';
    is $foo, -4, '... and they should work just fine';
    throws_ok { $foo = 'bar' }
    'Error::TypeTiny::Assertion',
      'Assigning a string to an integer should throw an exception';
    show_ref \$foo;

    my $bar : Type(NegativeInt);
    ok !defined $bar,
      'We should be able to create a typed scalar with no default value';
    ok $bar = -2, '... but we can assign a valid value to it';
    is $bar, -2, '... and it should return that value';
    throws_ok { $bar = 3 }
    'Error::TypeTiny::Assertion',
      '... but assigning a bad type to it should fail';
    show_ref \$bar;

    throws_ok { my $baz : Type(NoSuchType) }
    qr/Unknown type: NoSuchType/,
      'Trying to assign an unknown type should fail';
};

subtest 'arrays' => sub {
    my @foo : Type(Int) = qw(1 2 3);
    ok @foo, 'We should be able to create a typed array.';
    show_ref( \@foo );
    eq_or_diff \@foo, [ 1, 2, 3 ], '... and it should have the correct data';
    throws_ok { @foo = qw(2 bar 4) }
    'Error::TypeTiny::Assertion',
      '... and assinging bad values to the array should fail';

  TODO: {
        local $TODO = "Direct assignment bypasses Variable::Magic";
        throws_ok { $foo[1] = 'bar' }
        'Error::TypeTiny::Assertion',
          'Assigning an incorrect type to an array entry should fail';
    }

    throws_ok { push @foo => 'this' }
    'Error::TypeTiny::Assertion',
      'Pushing an invalid type onto a typed array should fail';
};

subtest 'hashes' => sub {
    pass 'We will come back to this after we figure out the array bug';
};

done_testing;
