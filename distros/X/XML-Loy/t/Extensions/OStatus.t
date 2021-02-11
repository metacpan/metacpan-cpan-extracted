#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib', '../lib', '../../lib';

use Test::More tests => 17;

use_ok('XML::Loy::Atom');

ok(my $atom = XML::Loy::Atom->new('entry'), 'New entry');

ok($atom->extension(-OStatus, -ActivityStreams), 'Add extension');

ok($atom->actor(name => 'Akron'), 'Add author');
ok($atom->verb_unfollow, 'Add verb');
is($atom->verb, 'http://ostatus.org/schema/1.0/unfollow', 'Get verb');
ok($atom->verb_unfavorite, 'Add verb');
is($atom->verb, 'http://ostatus.org/schema/1.0/unfavorite', 'Get verb');
ok($atom->verb_leave, 'Add verb');
is($atom->verb, 'http://ostatus.org/schema/1.0/leave', 'Get verb');

ok($atom->object(name => 'Peter'), 'Add object');

ok($atom->attention('http://sojolicious.example/user/peter'), 'Add new attention');
is($atom->link('ostatus:attention')->[0]->attr('href'), 'http://sojolicious.example/user/peter', 'Attention link');
is($atom->attention, 'http://sojolicious.example/user/peter', 'Attention link');

ok($atom->conversation('http://sojolicious.example/conv/34'), 'Add new conversation');
is($atom->link('ostatus:conversation')->[0]->attr('href'), 'http://sojolicious.example/conv/34', 'Conversation link');
is($atom->conversation, 'http://sojolicious.example/conv/34', 'Conversation link');

