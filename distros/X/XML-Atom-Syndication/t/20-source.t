#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 5;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;
use XML::Atom::Syndication::Source;

my $source = XML::Atom::Syndication::Source->new;
ok(ref $source eq 'XML::Atom::Syndication::Source');

my $sv1 = XML::Atom::Syndication::Source->new(Version =>1.0);
ok($sv1->ns eq 'http://www.w3.org/2005/Atom');

my $sv2 = XML::Atom::Syndication::Source->new(Version =>0.3);
ok($sv2->ns eq 'http://purl.org/atom/ns#');

my @e;

my $feed2 = get_feed('x-entry_source_updated.xml');
@e = $feed2->entries;
ok($e[0]->source->updated eq '2005-04-22T20:16:00Z');

my $feed3 = get_feed('x-entry_source_id.xml');
@e = $feed3->entries;
ok($e[0]->source->id eq 'http://example.com/');

1;