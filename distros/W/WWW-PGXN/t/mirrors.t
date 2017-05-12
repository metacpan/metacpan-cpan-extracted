#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More tests => 16;
#use Test::More 'no_plan';
use WWW::PGXN;

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Fetch mirror data.
ok my @mirrors = $pgxn->mirrors, 'Fetch mirrors';
is @mirrors, 2, 'Should have two mirrors';
isa_ok $_, 'WWW::PGXN::Mirror' for @mirrors;

my $mirror = $mirrors[0];
can_ok $mirror, qw(
    new
    uri
    frequency
    location
    organization
    timezone
    email
    bandwidth
    src
    rsync
    notes
);

is $mirror->bandwidth,    '100Mbps',                 'Should have bandwidth';
is $mirror->email,        'web_pgxn@depesz.com',     'Should have email';
is $mirror->frequency,    'every 6 hours',           'Should have frequency';
is $mirror->location,     "N\xFCrnberg, Germany",    'Should have location';
is $mirror->notes,        'access via http only',    'Should have notes';
is $mirror->organization, 'depesz Software',         'Should have organization';
is $mirror->rsync,        '',                        'Should have no rsync';
is $mirror->src,          'rsync://my.pgxn.org/',    'Should have src';
is $mirror->timezone,     'CEST',                    'Should have timezone';
is $mirror->uri,          'http://pgxn.depesz.com/', 'Should have uri';

