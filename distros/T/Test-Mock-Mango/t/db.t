#!/usr/bin/env perl

use Test::More;
use Mango;
use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!


use_ok 'Test::Mock::Mango::DB';
new_ok 'Test::Mock::Mango::DB';
can_ok 'Test::Mock::Mango::DB', qw|collection|;

my $db;

$db = Test::Mock::Mango::DB->new('mydb');
is $db->{name}, 'mydb', 'name set ok (plain construct)';

$db = $mango->db('mydb2');
is $db->{name}, 'mydb2', 'name set ok (mango construct)';

my $collection = $mango->db('foo')->collection('bar');
isa_ok(
	$collection,
	'Test::Mock::Mango::Collection',
	'Test::Mock::Mango::DB creations collection'
);

done_testing();
