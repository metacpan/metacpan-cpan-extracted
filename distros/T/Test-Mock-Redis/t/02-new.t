#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Mock::Redis ();


my $r = Test::Mock::Redis->new;

$r->set('foo', 'foobar');
is $r->get('foo'), 'foobar';

my $s = Test::Mock::Redis->new;

is $s->get('foo'), 'foobar', 'we got the same mock redis object back';

my $t = Test::Mock::Redis->new(server => 'something.else');

is $t->get('foo'), undef, 'mock redis object with new server is new';


done_testing();


