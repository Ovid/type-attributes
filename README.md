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

Looks like there's a bug in [Variable::Magic](https://metacpan.org/pod/Variable%3A%3AMagic) with Perl 5.26 and above,
when using `$@->isa`. Bug filed: [https://rt.cpan.org/Ticket/Display.html?id=145680](https://rt.cpan.org/Ticket/Display.html?id=145680)

Test case, with everything stripped out that I can find.

```perl
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
```

Running that with 5.26 and above on my M1 Mac produces this:

```
$ perl testcase.pl
Done
Attempt to free unreferenced scalar: SV 0x14401a550 at t/core.t line 27.
```

Passing a true value to the script makes the error go away:

```
$ perl testcase.pl 1
Done
```

# AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
