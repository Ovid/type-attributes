#!/usr/bin/env perl

use Test::More;
use Type::Attributes;
use Types::Common qw(Int Num);

my $counter : Type(Int) = 3;
eval { $counter = 'bar'; 1 };
ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

my @foo : Type(Num) = qw(1 2 3.2);
eval { @foo = qw(2 bar 4); 1 };
ok $@->isa('Error::TypeTiny::Assertion'), 'Bad type';

done_testing;
