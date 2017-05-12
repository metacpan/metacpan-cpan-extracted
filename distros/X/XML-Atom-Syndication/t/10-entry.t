#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 8;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;
use XML::Atom::Syndication::Entry;
use File::Spec;

my $entry = XML::Atom::Syndication::Entry->new;
ok(ref $entry eq 'XML::Atom::Syndication::Entry');

my $ev1 = XML::Atom::Syndication::Entry->new(Version =>1.0);
ok($ev1->ns eq 'http://www.w3.org/2005/Atom');

my $ev2 = XML::Atom::Syndication::Entry->new(Version =>0.3);
ok($ev2->ns eq 'http://purl.org/atom/ns#');

my $file = File::Spec->catfile('x','x-entry_standalone.xml');
my $fh;
open $fh, $file or die "couldn't open $file";
my $e = XML::Atom::Syndication::Entry->new($fh)
    or die XML::Atom::Syndication::Entry->errstr;
close $fh;
ok(ref $e eq 'XML::Atom::Syndication::Entry');
ok($e->title->body eq 'Example Atom');

my @e;

my $feed1 = get_feed('x-entry_published.xml');
@e = $feed1->entries;
ok($e[0]->published eq '1999-09-02T03:10:00Z');

my $feed2 = get_feed('x-entry_updated.xml');
@e = $feed2->entries;
ok($e[0]->updated eq '2005-04-22T20:16:00Z');

my $feed3 = get_feed('x-entry_id.xml');
@e = $feed3->entries;
ok($e[0]->id eq 'http://example.com/');

1;