#!/usr/bin/env perl
use v5.20;
use Text::Stencil;

my $csv = Text::Stencil->new(
    row       => '"{name:json}",{age:int},"{email:json}"',
    separator => "\n",
);

my @users = (
    { name => 'Alice',   age => 30, email => 'alice@example.com' },
    { name => 'Bob "B"', age => 25, email => 'bob@example.com' },
    { name => 'Charlie', age => 35, email => 'charlie@example.com' },
);

say '"Name","Age","Email"';
say $csv->render(\@users);
