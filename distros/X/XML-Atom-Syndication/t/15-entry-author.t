#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 10;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @authors = (
    ['entry_author_name.xml','name','Example author'],
    ['entry_author_email.xml','email','me@example.com'],
    ['entry_author_uri.xml','uri','http://example.com/']
);

foreach my $a (@authors) {
    my $feed = get_feed($a->[0]);
    my @e = $feed->entries;
    my $author = $e[0]->author;
    ok(ref $author eq 'XML::Atom::Syndication::Person');
    my $meth = $a->[1];
    ok($author->$meth eq $a->[2]);
}

my $feed = get_feed('x-entry_author_multiple.xml');
my @e = $feed->entries;
my @authors2 = $e[0]->author;
ok(@authors2 == 2);
ok(ref $authors2[0] eq 'XML::Atom::Syndication::Person');
ok($authors2[0]->name eq 'Author 1');
ok($authors2[1]->name eq 'Author 2');

1;