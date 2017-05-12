#!/usr/bin/env perl

use strict;
use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

subtest "Blocking syntax" => sub {
	
	my $doc = undef;

	subtest "basic call" => sub {
		$doc = $mango->db('foo')->collection('bar')->update({a=>1},{a=>2});
		is $doc->{a}, '2', 'updated doc';
		is $doc->{n},  1,  'number of docs updated set';		
	};

	subtest "error state" => sub {
		$Test::Mock::Mango::error = 'oh noes';
		$doc = $mango->db('foo')->collection('bar')->update({a=>1},{a=>2});
		is $doc, undef, 'returns undef as expected';
		is $Test::Mock::Mango::error, undef, 'error reset';
	};

	subtest "alter n" => sub {
		$Test::Mock::Mango::n = 0;
		$doc = $mango->db('foo')->collection('bar')->update({a=>1},{a=>2});
		is $doc->{n}, '0', 'n set as expected';	

		$Test::Mock::Mango::n = 7;
		$doc = $mango->db('foo')->collection('bar')->update({a=>1},{a=>2});
		is $doc->{n}, '7', 'n set as expected';	

		is $Test::Mock::Mango::n, undef, 'n has been reset';
	};
};


subtest "Non-blocking syntax" => sub {	

	subtest "basic call" => sub {
		$mango->db('foo')->collection('bar')->update(
			{foo=>'bar'},
			{foo=>'baz'}
			=> sub {
				my ($collection, $err, $doc) = @_;
				is $doc->{foo}, 'baz', 'updated doc';
				is $doc->{n},	1,	   'number of docs updated set';
				is $err, undef, 'no error returned';
			}
		);
	};

	subtest "error state" => sub {
		$Test::Mock::Mango::error = 'oh noes';
		$mango->db('foo')->collection('bar')->update(
			{foo=>'bar'},
			{foo=>'baz'}
			=> sub {
				my ($collection, $err, $doc) = @_;
				is $doc, undef, 'returns undef as expected';
				is $err, 'oh noes', 'returns error as expected';
				is $Test::Mock::Mango::error, undef, 'error reset';
			}
		);
	};
};

done_testing();
