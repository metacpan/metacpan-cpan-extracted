#!/usr/bin/env perl

use strict;
use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

subtest "Blocking syntax" => sub {

	#$mango->db('foo')->collection('bar')->drop; # TODO
	ok(1);

	


};

subtest "Non-blocking syntax" => sub {

	$mango->db('foo')->collection('bar')->drop( sub {
		my ($collection, $err) = @_;
		ok 1, 'drop runs ok';
	});

	$Test::Mock::Mango::error = 'oh noes';
	$mango->db('foo')->collection('bar')->drop( sub {
		my ($collection, $err) = @_;
		
		is $Test::Mock::Mango::error, undef, 'error state reset';
		is $err, 'oh noes', 'error set as expected';		
	});

};

done_testing();
