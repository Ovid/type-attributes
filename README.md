# NAME

Type::Attributes - Types Variables in Perl

# VERSION

version 0.05

# SYNOPSIS

```perl
my $count :Type(ZeroOrPositiveInt) = 3;
$count = -2; # fatal

my @array :Type(Int); # no default value required

# invalid defaults are fatal
my %hash  :Type(NonEmptySimpleStr) = []; # fatal
```

# DESCRIPTION

Experimental module to attempt to use [Variable::Magic](https://metacpan.org/pod/Variable%3A%3AMagic),
[Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers), and [Type::Tiny](https://metacpan.org/pod/Type%3A%3ATiny) to make it transparent to create
typed variables in Perl.

# DEVELOPMENT NOTES

At the present time, I seem to be hitting the following obstacle:

```perl
    $ prove t/basic_types.t
    t/basic_types.t .. ====> $unknown in Test::Me Decimal: 5373860072 Hexadecimal: 0x1404e98e8
    ====> %ACTIONS_FOR in Type::Attributes Decimal: 5234169112 Hexadecimal: 0x137fb1518
    ====> $scalar_wizard in Type::Attributes Decimal: 5373808976 Hexadecimal: 0x1404dd150
    ----> $foo. Decimal: 5373860072 Hexadecimal: 0x1404e98e8
    ====> $unknown in Test::Me Decimal: 5373840144 Hexadecimal: 0x1404e4b10
    ====> %ACTIONS_FOR in Type::Attributes Decimal: 5234169112 Hexadecimal: 0x137fb1518
    ====> $scalar_wizard in Type::Attributes Decimal: 5373756680 Hexadecimal: 0x1404d0508
    ----> $bar. Decimal: 5373840144 Hexadecimal: 0x1404e4b10
    ====> $unknown in Test::Me Decimal: 5373839472 Hexadecimal: 0x1404e4870
    ====> %ACTIONS_FOR in Type::Attributes Decimal: 5234169112 Hexadecimal: 0x137fb1518
    t/basic_types.t .. 1/? ====> $unknown in Test::Me Decimal: 5373839112 Hexadecimal: 0x1404e4708
    ====> %ACTIONS_FOR in Type::Attributes Decimal: 5234169112 Hexadecimal: 0x137fb1518
    ====> $array_wizard in Type::Attributes Decimal: 5373763616 Hexadecimal: 0x1404d2020
    ----> @foo. Decimal: 5373839112 Hexadecimal: 0x1404e4708
    Unfreed variable: 5373839112 Hexadecimal: 0x1404e4708
    Attempt to free unreferenced scalar: SV 0x1404deed8 during global destruction.
    t/basic_types.t .. ok
    All tests successful.
    Files=1, Tests=3,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.05 cusr  0.01 csys =  0.07 CPU)
    Result: PASS
```

This line is from the Perl compiler:

```
    Attempt to free unreferenced scalar: SV 0x1404deed8 during global destruction.
```

It shows up intermittently (though most of the time), so it's probably a
global destruction ordering issue. Commenting out the `arrays` subtest makes
the issue go away.  If I reduce the `arrays` subtest to this (the
`throws_ok` is needed), the problem comes back:

```perl
subtest 'arrays' => sub {
    my @foo : Type(Int) = qw(1 2 3);
    pass;
    throws_ok { @foo = qw(2 bar 4) }
      'Error::TypeTiny::Assertion',
      '... and assigning bad values to the array should fail';
};
```

Comment out the `throws_ok` test to verify.

`perl -v`:

```perl
This is perl 5, version 26, subversion 3 (v5.26.3) built for darwin-2level
(with 1 registered patch, see perl -V for more detail)
```

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
