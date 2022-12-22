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

At the present time, the `t/error.t` script is this:

```perl
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
```

This minimal test case outputs something like:

```
t/error.t ..
ok 1 - Bad type
ok 2 - Bad type
1..2
Attempt to free unreferenced scalar: SV 0x11e0cf7e0 during global destruction.
ok
All tests successful.
Files=1, Tests=2,  0 wallclock secs ( 0.01 usr  0.00 sys +  0.04 cusr  0.01 csys =  0.06 CPU)
Result: PASS
```

The `Attempt to free unreferenced scalar` is a compiler level error.

It shows up intermittently (though most of the time), so it's probably a
global destruction ordering issue. Removing either `eval` makes the error go
away.

Further, swapping the order of the tests makes the error go away:

```perl
my @foo : Type(Num) = qw(1 2 3.2);
eval { @foo = qw(2 bar 4); 1 };
ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

my $counter : Type(Int) = 3;
eval { $counter = 'bar'; 1 };
ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';
```

`perl -v`:

```perl
This is perl 5, version 26, subversion 3 (v5.26.3) built for darwin-2level
(with 1 registered patch, see perl -V for more detail)
```

Also, the following `TODO` test in `t/basic_types.t` is annoying. I wonder
if this is related.

```
TODO: {
      local $TODO = "Direct assignment bypasses Variable::Magic";
      throws_ok { $foo[1] = 'bar' }
      'Error::TypeTiny::Assertion',
        'Assigning an incorrect type to an array entry should fail';
  }
```

The above _should_ work because the docs for `set` in [Variable::Magic](https://metacpan.org/pod/Variable%3A%3AMagic) say
the following:

```perl
This magic is called each time the value of the variable changes. It is
called for array subscripts and slices, but never for hashes.
```

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
