#!/usr/bin/perl -w
use strict;

use Test::More tests => 12;

use WWW::Scraper::ISBN::Record;

my $record = WWW::Scraper::ISBN::Record->new();
isa_ok($record,'WWW::Scraper::ISBN::Record');
my $record2 = $record->new();
isa_ok($record2,'WWW::Scraper::ISBN::Record');

my %defaults = (
    isbn        => undef,
    found       => 0,
    found_in    => undef,
    book        => undef,
    error       => '',
);

for my $method (qw( isbn found found_in book error )) {
    is($record->$method(),$defaults{$method},".. default test for $method");
    is($record->$method('value'),'value',".. value test for $method");
}
