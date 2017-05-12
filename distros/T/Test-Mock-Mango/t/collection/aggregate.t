#!/usr/bin/env perl

use Test::More tests => 2;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

subtest "Blocking syntax" => sub {
	
	my $docs = undef;

	subtest "basic call" => sub {
		$docs = $mango->db('foo')->collection('bar')->aggregate;
		is ref $docs, 'ARRAY', 'returns array ref';
	};

	subtest "error state" => sub {
		$Test::Mock::Mango::error = 'oh noes';
		$docs = $mango->db('foo')->collection('bar')->aggregate;
		is $docs, undef, 'returns undef as expected';
		is $Test::Mock::Mango::error, undef, 'error reset';
	};
};


subtest "non-blocking syntax" => sub {	

	subtest "basic call" => sub {
		$mango->db('foo')->collection('bar')->aggregate(sub {
			my ($cursor, $err, $docs) = @_;
			is ref $docs, 'ARRAY', 'returns array ref';
		});
	};

	subtest "error state" => sub {
		$Test::Mock::Mango::error = 'oh noes';
		$mango->db('foo')->collection('bar')->aggregate(sub {
			my ($cursor, $err, $docs) = @_;
			is $docs, undef, 'returns undef as expected';
			is $err, 'oh noes', 'returns error as expected';
			is $Test::Mock::Mango::error, undef, 'error reset';
		});
	};
};

done_testing();
