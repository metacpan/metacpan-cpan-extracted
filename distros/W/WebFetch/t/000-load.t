#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::More;
use Try::Tiny;

# always test these modules can load
my @modules = qw(
    WebFetch
    WebFetch::Data::Store
    WebFetch::Data::Record
    WebFetch::Input::PerlStruct
    WebFetch::Input::SiteNews
    WebFetch::Output::Dump
);

# count tests
plan tests => int(@modules);

# test loading modules
foreach my $mod (@modules) {
    require_ok($mod);
}

require WebFetch;
diag( "Testing WebFetch " . WebFetch->version() . ", Perl $], $^X" );
