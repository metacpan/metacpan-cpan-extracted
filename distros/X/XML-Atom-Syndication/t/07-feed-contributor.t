#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 10;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my @contribs = (
    ['feed_contributor_name.xml','name','Example contributor'],
    ['feed_contributor_email.xml','email','me@example.com'],
    ['feed_contributor_uri.xml','uri','http://example.com/']
);

foreach my $c (@contribs) {
    my $feed = get_feed($c->[0]);
    my $contributor = $feed->contributor;
    ok(ref $contributor eq 'XML::Atom::Syndication::Person');
    my $meth = $c->[1];
    ok($contributor->$meth eq $c->[2]);
}

my $feed = get_feed('feed_contributor_multiple.xml');
my @contribs2 = $feed->contributor;
ok(@contribs2 == 2);
ok(ref $contribs2[0] eq 'XML::Atom::Syndication::Person');
ok($contribs2[0]->name eq 'Contributor 1');
ok($contribs2[1]->name eq 'Contributor 2');

1;