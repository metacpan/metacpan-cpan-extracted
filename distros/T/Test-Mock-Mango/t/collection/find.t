#!/usr/bin/env perl

use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

my $cursor = $mango->db('foo')->collection('bar')->find( {some => 'query'} );
isa_ok($cursor, 'Test::Mock::Mango::Cursor', '"find" returns cursor');

done_testing();
