#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

use lib '../lib', '../../lib';

use_ok('XML::Loy::Atom');
use_ok('XML::Loy::Atom::Threading');

use XML::Loy::Atom;

ok(my $entry = XML::Loy::Atom->new('entry'), 'Get object');

# Add threading extension
ok($entry->extension(-Atom::Threading), 'Add extension');

# Add Atom author and id
ok($entry->author(name => 'Zoidberg'), 'Add author');
ok($entry->id('http://sojolicio.us/blog/2'), 'Set id');

# Add threading information
ok($entry->in_reply_to('urn:entry:1' => {
  href => 'http://sojolicio.us/blog/1'
}), 'Set in-reply-to');

# Add replies information
ok($entry->replies('http://sojolicio.us/blog/1/replies' => {
  count => 7,
  updated => time
}), 'Add replies information');

# Get threading information
is($entry->in_reply_to->[0]->attr('href'),
'http://sojolicio.us/blog/1', 'Correct href');
