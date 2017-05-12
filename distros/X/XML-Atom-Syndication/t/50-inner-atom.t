#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 15;

use File::Spec;
use XML::Atom::Syndication::Test::Util qw( get_feed );

my $test;

my $feed = get_feed('feed_title.xml');
ok($feed->can('inner_atom'));
$test = $feed->as_xml;
ok($test !~ m{CHANGED TITLE});
ok($test !~ m{ADDED SUBTITLE});
$feed->inner_atom(
             '<title>CHANGED TITLE</title><subtitle>ADDED SUBTITLE</subtitle>');
$test = $feed->as_xml;
ok($test =~ m{CHANGED TITLE});
ok($test =~ m{ADDED SUBTITLE});

my $entry = get_feed('entry_title.xml');
my @e     = $entry->entries;
ok($e[0]->can('inner_atom'));
$test = $entry->as_xml;
ok($test !~ m{CHANGED TITLE});
ok($test !~ m{ADDED SUMMARY});
$e[0]->inner_atom(
             '<title>CHANGED TITLE</title><summary>ADDED SUMMARY</summary>');
$test = $entry->as_xml;
ok($test =~ m{CHANGED TITLE});
ok($test =~ m{ADDED SUMMARY});

my $src = get_feed('entry_source_title.xml');
my @es  = $src->entries;
my $s   = $es[0]->source;
ok($s->can('inner_atom'));
$test = $src->as_xml;
ok($test !~ m{CHANGED TITLE});
ok($test !~ m{ADDED SUBTITLE});
$s->inner_atom(
             '<title>CHANGED TITLE</title><subtitle>ADDED SUBTITLE</subtitle>');
$test = $src->as_xml;
ok($test =~ m{CHANGED TITLE});
ok($test =~ m{ADDED SUBTITLE});

1;
