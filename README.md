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

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
