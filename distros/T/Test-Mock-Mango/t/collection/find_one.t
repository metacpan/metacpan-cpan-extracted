#!/usr/bin/env perl

use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

subtest "Blocking syntax" => sub {
	my $doc;

	$doc = $mango->db('foo')->collection('bar')->find_one( {some => 'query'} );
	is_deeply(
		$doc,
		{
			_id		=> 'ABCDEFG-123456',
			name	=> 'Homer Simpson',
			job		=> 'Safety Inspector',
			dob		=> '1956-03-01',
			hair	=> 'none',
		},
		'"find_one" returns correct document in "blocking" syntax'
	);

	$Test::Mock::Mango::error = 'oh noes';
	$doc = $mango->db('foo')->collection('bar')->find_one( {some => 'query'} );
	is $doc, undef, 'undef returned as expected';
	is $Test::Mock::Mango::error, undef, 'Error reset';
};


subtest "non-blocking syntax" => sub {
	$mango->db('foo')->collection('bar')->find_one( {some => 'query'}, sub {
		my ($collection,$err,$doc) = @_;
		is_deeply(
			$doc,
			{
				_id		=> 'ABCDEFG-123456',
				name	=> 'Homer Simpson',
				job		=> 'Safety Inspector',
				dob		=> '1956-03-01',
				hair	=> 'none',
			},
			'"find_one" returns correct document in "non-blocking" syntax'
		);
	});

	$Test::Mock::Mango::error = 'oh noes';
	$mango->db('foo')->collection('bar')->find_one( {some => 'query'}, sub {
		my ($collection,$err,$doc) = @_;
		
		is $err, 'oh noes', 'error set as expected';
		is $doc, undef, 	'undef returned as expected';
		is $Test::Mock::Mango::error, undef, 'Error reset';
	});
};


subtest 'Empty collection returns undef' => sub {
	# Empty fake collection
	$Test::Mock::Mango::data->{collection} = [];

	my $doc = $mango->db('foo')->collection('bar')->find_one( {some => 'query'} );
	is($doc, undef, 'returns undef as expected');
};

done_testing();
