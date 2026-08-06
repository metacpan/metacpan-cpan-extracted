#!/usr/bin/env perl
use v5.20;
use warnings;
use Text::Stencil;

my $csv = Text::Stencil->new(
    # CSV quotes a literal quote by doubling it (RFC 4180); json would escape
    # it as \" instead, which a standards-conforming parser rejects.
    row       => q{"{name:replace:":""}",{age:int},"{email:replace:":""}"},
    separator => "\n",
);

my @users = (
    { name => 'Alice',   age => 30, email => 'alice@example.com' },
    { name => 'Bob "B"', age => 25, email => 'bob@example.com' },
    { name => 'Charlie', age => 35, email => 'charlie@example.com' },
);

say '"Name","Age","Email"';
say $csv->render(\@users);
