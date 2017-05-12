#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 19;

use XML::Atom::Syndication::Test::Util qw( get_feed );
use XML::Atom::Syndication::Feed;

my $feed = XML::Atom::Syndication::Feed->new;
ok(ref $feed eq 'XML::Atom::Syndication::Feed');

my $fv1 = XML::Atom::Syndication::Feed->new(Version =>1.0);
ok($fv1->ns eq 'http://www.w3.org/2005/Atom');

my $fv2 = XML::Atom::Syndication::Feed->new(Version =>0.3);
ok($fv2->ns eq 'http://purl.org/atom/ns#');

my $feed1 = get_feed('feed_icon.xml');
ok($feed1->icon eq 'http://example.com/favicon.ico');

my $feed2 = get_feed('feed_id.xml');
ok($feed2->id eq 'http://example.com/');

my $feed3 = get_feed('feed_logo.xml');
ok($feed3->logo eq 'http://example.com/logo.jpg');

my $feed4 = get_feed('x-feed_updated.xml');
ok($feed4->updated eq '2005-04-22T20:16:00Z');

my $feed5 = get_feed('feed_generator.xml');
my $g = $feed5->generator;
ok(ref $g eq 'XML::Atom::Syndication::Generator');
ok($g->agent eq 'Example generator');
ok($g->version eq '2.65');
ok($g->uri eq 'http://example.com/');

my $feed6 = get_feed('x-feed_entry_multiple.xml');
my @e = $feed6->entries;
ok(@e == 2);
ok(ref $e[0] eq 'XML::Atom::Syndication::Entry');

my $e1 = XML::Atom::Syndication::Entry->new;
$e1->title('Entry 3');
$feed6->add_entry($e1);
@e = $feed6->entries;
ok(@e == 3);
ok($e[-1]->title->body eq 'Entry 3');

my $e2 = XML::Atom::Syndication::Entry->new;
$e2->title('Entry 0');
$feed6->insert_entry($e2);
@e = $feed6->entries;
ok(@e == 4);
ok($e[0]->title->body eq 'Entry 0');

$e2->remove;
@e = $feed6->entries;
ok(@e == 3);
ok(! grep { $e[-1]->title->body eq 'Entry 0' } @e);

1;