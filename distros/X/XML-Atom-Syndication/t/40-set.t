#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;
use lib 'lib';

use Test::More tests => 40;

use XML::Atom::Syndication::Feed;
use XML::Atom::Syndication::Link;
use XML::Atom::Syndication::Entry;
use XML::Atom::Syndication::Content;

my $feed = XML::Atom::Syndication::Feed->new;
ok(ref $feed eq 'XML::Atom::Syndication::Feed');

ok($feed->title('Example Atom'));
ok($feed->id('http://example.com/'));
ok($feed->updated('2005-04-22T20:16:00Z'));
my $self = XML::Atom::Syndication::Link->new;
ok($self->rel('self'));
ok($self->href('http://example.com/'));
ok($feed->link($self));
my $alt = XML::Atom::Syndication::Link->new;
ok($alt->rel('alternate'));
ok($alt->href('http://example.com/feed.atom'));
ok($feed->link($alt,1)); # add

my $e = XML::Atom::Syndication::Entry->new;
ok($e->title('Entry 1'));
ok($e->id('http://example.com/1'));
ok($e->updated('2005-04-22T20:16:00Z'));
my $alt2 = XML::Atom::Syndication::Link->new;
ok($alt2->rel('alternate'));
ok($alt2->href('http://example.com/1'));
ok($e->link($alt2,1)); # add
my $via = XML::Atom::Syndication::Link->new;
ok($via->rel('via'));
ok($via->href('http://foo.com/'));
ok($e->link($via,1));

ok($feed->insert_entry($e)); 
my $e2 = XML::Atom::Syndication::Entry->new;
ok($e2->title('Entry 2'));
my $c = XML::Atom::Syndication::Content->new;
ok($c->type('text'));
ok($c->body('Not what he & I "thought."'));
ok($e2->content($c));
ok($feed->add_entry($e2)); 

# check that everthing comes out the right way now.

ok($feed->title->body eq 'Example Atom');
ok($feed->id eq 'http://example.com/');
ok($feed->updated eq '2005-04-22T20:16:00Z');
my @links = $feed->link;
ok(@links == 2);
ok(grep { $_->rel eq 'self' } @links);
ok(grep { $_->rel eq 'alternate' } @links);
my @e = $feed->entries;
ok(@e == 2);
ok($e[0]->title->body eq 'Entry 1');
ok($e[0]->id eq 'http://example.com/1');
ok($e[0]->updated eq '2005-04-22T20:16:00Z');
my @elinks = $e[0]->link;
ok(@links == 2);
ok(grep { $_->rel eq 'via' } @elinks);
ok(grep { $_->rel eq 'alternate' } @elinks);

ok($e[1]->title->body eq 'Entry 2');
ok($e[1]->content->body eq 'Not what he & I "thought."');

# warn $feed->as_xml;

