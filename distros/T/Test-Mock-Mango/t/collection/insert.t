#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mango;

use Test::Mock::Mango;

my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

subtest "Blocking syntax" => sub {	
	
	subtest "Single insert - autogen id" => sub {		
		my $oid = $mango->db('foo')->collection('bar')->insert({
			name => 'Ned Flanders',
			job	 => 'Neigdiddlyabour',
			dob  => '1942-01-01',
			hair => 'brown',
		});
		like   $oid, qr/^[0-9a-fA-F]{24}$/, "Single generated OID returnded as expected [$oid]";
		isa_ok $oid, 'Mango::BSON::ObjectID';
		is     scalar @{$Test::Mock::Mango::data->{collection}}, 6, 'Data inserted';
	};

	subtest "Single insert - known id" => sub {		
		my $oid = $mango->db('foo')->collection('bar')->insert({
			_id	 => 'ABC1234',
			name => 'Ned Flanders',
			job	 => 'Neigdiddlyabour',
			dob  => '1942-01-01',
			hair => 'brown',
		});
		is $oid, 'ABC1234', "Single known OID returnded as expected [ABC1234]";
		is scalar @{$Test::Mock::Mango::data->{collection}}, 7, 'Data inserted';
	};

	subtest "Multiple insert - mix ids" => sub {		
		my $oids = $mango->db('foo')->collection('bar')->insert([
			{
				_id	 => 'ABC9999',
				name => 'Ned Flanders',
				job	 => 'Neigdiddlyabour',
				dob  => '1942-01-01',
				hair => 'brown',
			},
			{				
				name => 'Todd Flanders',
				job	 => 'Annoyance',
				dob  => '1984-01-01',
				hair => 'brown',
			},
		]);
		is     ref $oids,  'ARRAY', 	   'Return array as expected';
		is     $oids->[0], 'ABC9999',    'First known OID returned as expected [ABC9999]';
		like   $oids->[1], qr/^[0-9a-fA-F]{24}$/, 'Second autogen OID returned as expected';
		isa_ok $oids->[1], 'Mango::BSON::ObjectID';
		is     scalar @{$Test::Mock::Mango::data->{collection}}, 9, 'Data inserted';
	};

	subtest "Error state" => sub {		
		$Test::Mock::Mango::error = 'oh noes';
		my $oid = $mango->db('foo')->collection('bar')->insert({
			_id	 => 'ABC1234',
			name => 'Ned Flanders',
			job	 => 'Neigdiddlyabour',
			dob  => '1942-01-01',
			hair => 'brown',
		});
		is $oid, undef, 'OID undef as expected';
		is scalar @{$Test::Mock::Mango::data->{collection}}, 9, 'No data inserted';
		is $Test::Mock::Mango::error, undef, 'Error reset';
	};
};

# ------------------------------------------------------------------------------

subtest "Non-blocking syntax" => sub {
	plan tests => 4;
	my $mango = Mango->new('mongodb://localhost:123456'); # FAKE!

	subtest "Single insert - autogen id" => sub {
		plan tests => 2;
		$mango->db('foo')->collection('bar')->insert({
			name => 'Ned Flanders',
			job	 => 'Neigdiddlyabour',
			dob  => '1942-01-01',
			hair => 'brown',
		}
		=> sub {
			my ($collection, $err, $oid) = @_;
			like $oid, qr/^[0-9a-fA-F]{24}$/, "Single generated OID returnded as expected [$oid]";
			is scalar @{$Test::Mock::Mango::data->{collection}}, 10, 'Data inserted';
		});		
	};

	subtest "Single insert - known id" => sub {
		plan tests => 2;
		$mango->db('foo')->collection('bar')->insert({
			_id	 => 'ABC1235',
			name => 'Ned Flanders',
			job	 => 'Neigdiddlyabour',
			dob  => '1942-01-01',
			hair => 'brown',
		}
		=> sub {
			my ($collection, $err, $oid) = @_;
			is $oid, 'ABC1235', "Single known OID returnded as expected [ABC1234]";
			is scalar @{$Test::Mock::Mango::data->{collection}}, 11, 'Data inserted';
		});		
	};

	subtest "Multiple insert - mix ids" => sub {
		plan tests => 4;
		my $oids = $mango->db('foo')->collection('bar')->insert([
			{
				_id	 => 'ABC9998',
				name => 'Ned Flanders',
				job	 => 'Neigdiddlyabour',
				dob  => '1942-01-01',
				hair => 'brown',
			},
			{				
				name => 'Todd Flanders',
				job	 => 'Annoyance',
				dob  => '1984-01-01',
				hair => 'brown',
			},
		]
		=> sub {
			my ($collection, $err, $oids) = @_;
			is   ref $oids,  'ARRAY', 	   'Return array as expected';
			is   $oids->[0], 'ABC9998',    'First known OID returned as expected [ABC9998]';
			like $oids->[1], qr/^[0-9a-fA-F]{24}$/, 'Second autogen OID returned as expected';
			is scalar @{$Test::Mock::Mango::data->{collection}}, 13, 'Data inserted';
		});		
	};

	subtest "Error state" => sub {
		plan tests => 4;
		$Test::Mock::Mango::error = 'oh noes';
		$mango->db('foo')->collection('bar')->insert({
			_id	 => 'ABC1235',
			name => 'Ned Flanders',
			job	 => 'Neigdiddlyabour',
			dob  => '1942-01-01',
			hair => 'brown',
		}
		=> sub {
			my ($collection, $err, $oid) = @_;
			is $oid, undef, 'OID undef as expected';
			is scalar @{$Test::Mock::Mango::data->{collection}}, 13, 'No data inserted';
			is $err, 'oh noes', 'Error returned';
			is $Test::Mock::Mango::error, undef, 'Error reset';
		});		
	};

};

done_testing();
