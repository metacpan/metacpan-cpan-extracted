#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;
use Test::More tests => 7;
#use Test::More 'no_plan';
use WWW::PGXN;
use File::Spec::Functions qw(catfile);

SEARCHER: {
    package PGXN::API::Searcher;
    $INC{'PGXN/API/Searcher.pm'} = __FILE__;
}

# Set up the WWW::PGXN object.
my $pgxn = new_ok 'WWW::PGXN', [ url => 'file:t/mirror' ];

##############################################################################
# Try to get a nonexistent tag.
ok !$pgxn->get_tag('nonexistent'),
    'Should get nothing when searching for a nonexistent tag';

# Fetch tag data.
ok my $tag = $pgxn->get_tag('key value'),
    'Find tag "key value"';
isa_ok $tag, 'WWW::PGXN::Tag', 'It';
can_ok $tag, qw(
    new
    name
    releases
);

is $tag->name, 'key value', 'Should have name';
is_deeply $tag->releases, {
    pair  => {
        stable  => [{version => '0.1.0', date => '2010-10-19T03:59:54Z'}],
        testing => [{version => '0.1.1', date => '2010-10-29T22:44:42Z'}],
    },
    pgTAP => { stable => [{version => '0.25.0', date => '2011-01-14T23:43:12Z'}] },
}, 'Should have release data';
