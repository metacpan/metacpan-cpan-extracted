#!/usr/bin/env perl

use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

subtest "Blocking syntax" => sub {
	my $doc;

	$doc = $mango->db('foo')->command('getLastError', w => 2);
	is $doc, undef, 'returns undef';

	$Test::Mock::Mango::error = 'oh noes';
	$doc = $mango->db('foo')->command('getLastError', w => 2);
	is $doc, undef, 'undef returned as expected';
	is $Test::Mock::Mango::error, undef, 'Error reset';
};


subtest "non-blocking syntax" => sub {
	$mango->db('foo')->command( ('getLastError', w => 2) => sub {
		my ($collection,$err,$doc) = @_;
		is $doc, undef, 'returns undef';		
	});

	$Test::Mock::Mango::error = 'oh noes';
	$mango->db('foo')->command( ('getLastError', w => 2) => sub {
		my ($collection,$err,$doc) = @_;
		
		is $err, 'oh noes', 'error set as expected';
		is $doc, undef, 	'undef returned as expected';
		is $Test::Mock::Mango::error, undef, 'Error reset';
	});
};


done_testing();
