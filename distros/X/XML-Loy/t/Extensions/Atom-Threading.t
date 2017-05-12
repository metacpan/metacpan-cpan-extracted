#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 29;
use Test::Warn;

use lib '../lib', '../../lib';

use_ok('XML::Loy::Atom');
use_ok('XML::Loy::Atom::Threading');

warning_is {
  XML::Loy::Atom::Threading->new;
} 'Only use XML::Loy::Atom::Threading as an extension to Atom', 'Only extension';

ok(my $atom = XML::Loy::Atom->new('feed'), 'New Atom Feed');
ok($atom->extension('XML::Loy::Atom::Threading'), 'Add extension');

ok($atom->author(name => 'Fry'), 'Add author');

is($atom->author->[0]->at('name')->text, 'Fry', 'Get Author');

ok(my $entry = $atom->entry(id => 'urn:1'), 'New entry');

ok($entry->in_reply_to('urn:entry:1' => {
  href => 'http://sojolicio.us/blog/1.html',
  type => 'application/xhtml+xml'
  }), 'Add entry');

is($entry->in_reply_to->[0]->attr('href'),
   'http://sojolicio.us/blog/1.html',
   'Get in_reply_to'
);

ok(!$entry->in_reply_to->[1], 'Only one entry');

ok($entry->in_reply_to('urn:entry:2' => {
  href => 'http://sojolicio.us/blog/2.atom',
  type => 'application/atom+xml'
  }), 'Add entry');

is($entry->in_reply_to->[0]->attr('href'),
   'http://sojolicio.us/blog/1.html',
   'Get in_reply_to'
);

is($entry->in_reply_to->[1]->attr('href'),
   'http://sojolicio.us/blog/2.atom',
   'Get in_reply_to'
);

ok($atom->in_reply_to('urn:feed:1' => {
  href => 'http://sojolicio.us/blog-replies.html',
  }), 'Add entry');

is($atom->in_reply_to->[0]->attr('href'),
   'http://sojolicio.us/blog-replies.html',
   'Get in_reply_to'
);

ok($entry->replies('http://sojolicio.us/entry/1/replies' => {
  count   => 5,
  updated => '2011-08-30T16:16:40Z'
}), 'Set replies');

is($entry->replies->attr('thr:count'), 5, 'Get replies');

ok($atom->replies('http://sojolicio.us/feed/replies' => {
  count   => 18
}), 'Set replies');

is($atom->replies->attr('thr:count'), 18, 'Get replies');

is($entry->replies->attr('thr:count'), 5, 'Get replies');


ok($entry->total(6), 'Set total okay');
is($entry->total, 6, 'Get total okay');
ok($entry->total(7), 'Set total okay');
is($entry->total, 7, 'Get total okay');
ok($atom->total(8), 'Set total okay');
is($atom->total, 8, 'Get total okay');
ok($entry->total(7), 'Set total okay');
is($entry->total, 7, 'Get total okay');
