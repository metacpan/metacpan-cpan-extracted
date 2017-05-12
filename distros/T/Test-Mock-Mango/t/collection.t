#!/usr/bin/env perl

use strict;
use Test::More;
use Mango;
use Test::Mock::Mango;

use_ok 'Test::Mock::Mango::Collection';

subtest 'Collection' => sub {

	my $collection = Test::Mock::Mango::Collection->new;

	can_ok $collection, (qw|
		aggregate create drop
		find find_one full_name insert
		update remove
	|);

};

my $collection;

my $mango = Mango->new;
$collection = $mango->db('foo')->collection('bar');
is 	   $collection->{name}, 'bar', 'collection name set ok';
isa_ok $collection->{db},   'Test::Mock::Mango::DB', 'parent is DB class';
is     $collection->{db}->{name}, 'foo', 'db name is set ok';


$collection = Test::Mock::Mango::Collection->new('baz');
is 	   $collection->{name}, 'baz', 'collection name set ok';
is     $collection->{db},   undef, 'no parent db';

done_testing();
