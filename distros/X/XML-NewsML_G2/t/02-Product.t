#!/usr/bin/env perl

use Test::More;
use XML::NewsML_G2;

use warnings;
use strict;

ok(my $p1 = XML::NewsML_G2::Product->new(isbn => 123), 'create product 1');
ok(my $p2 = XML::NewsML_G2::Product->new(name => 'some book', isbn => 456), 'create product 2');
ok(my $p3 = XML::NewsML_G2::Product->new(isbn => 789), 'create product 3');

like($p1->name, qr/1/, 'first product gets 1');
is($p2->name, 'some book', 'name unmodified when set');
like($p3->name, qr/2/, 'third product gets 2');

is($p1->isbn, 123, 'isbn 1 ok');
is($p2->isbn, 456, 'isbn 2 ok');
is($p3->isbn, 789, 'isbn 3 ok');

done_testing;
