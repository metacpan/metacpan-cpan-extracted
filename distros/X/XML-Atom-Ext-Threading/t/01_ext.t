use strict;
use Test::More 'no_plan';

use XML::Atom::Entry;
use XML::Atom::Link;
use XML::Atom::Ext::Threading;

$XML::Atom::DefaultVersion = '1.0';

my $ns     = XML::Atom::Ext::Threading->element_ns;
my $prefix = $ns->{prefix};
my $uri    = $ns->{uri};

my $res = XML::Atom::Entry->new;

# "in-reply-to" extension element
my $reply = XML::Atom::Ext::Threading::InReplyTo->new;
isa_ok($reply, 'XML::Atom::Ext::Threading::InReplyTo');
$reply->ref('tag:example.org,2005:1');
is($reply->ref, 'tag:example.org,2005:1');
$reply->href('http://www.example.org/entries/1');
is($reply->href, 'http://www.example.org/entries/1');
$reply->type('application/xhtml+xml');
is($reply->type, 'application/xhtml+xml');

$res->in_reply_to($reply);
like($res->as_xml, qr/<thr:in-reply-to /);
like($res->as_xml, qr/ref="tag:example.org,2005:1"/);
like($res->as_xml, qr!href="http://www.example.org/entries/1"!);
like($res->as_xml, qr!type="application/xhtml\+xml"!);

my $orig = XML::Atom::Entry->new;

# "replies" link relation
my $link = XML::Atom::Link->new;
$link->rel('replies');
is($link->rel, 'replies');
$link->type('application/atom+xml');
$link->href('http://www.example.org/mycommentsfeed.xml');
$link->count(10);
is($link->count, 10);
$link->updated('2005-07-28T12:10:00Z');
is($link->updated, '2005-07-28T12:10:00Z');

$orig->add_link($link);
like($orig->as_xml, qr/rel="replies"/);
like($orig->as_xml, qr/thr:count="10"/);
like($orig->as_xml, qr/thr:updated="2005-07-28T12:10:00Z"/);

# "total" extension element
$orig->total(10);
is($orig->total, 10);
like($orig->as_xml, qr!<thr:total xmlns:thr="http://purl.org/syndication/thread/1.0">10</thr:total>!);
