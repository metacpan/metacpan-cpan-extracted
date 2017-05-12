#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 10;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @contribs = (
    ['entry_contributor_name.xml','name','Example contributor'],
    ['entry_contributor_email.xml','email','me@example.com'],
    ['entry_contributor_uri.xml','uri','http://example.com/']
);

foreach my $c (@contribs) {
    my $feed = get_feed($c->[0]);
    my @e = $feed->entries;
    my $contributor = $e[0]->contributor;
    ok(ref $contributor eq 'XML::Atom::Syndication::Person');
    my $meth = $c->[1];
    ok($contributor->$meth eq $c->[2]);
}

my $feed = get_feed('entry_contributor_multiple.xml');
my @e = $feed->entries;
my @contribs2 = $e[0]->contributor;
ok(@contribs2 == 2);
ok(ref $contribs2[0] eq 'XML::Atom::Syndication::Person');
ok($contribs2[0]->name eq 'Contributor 1');
ok($contribs2[1]->name eq 'Contributor 2');

1;