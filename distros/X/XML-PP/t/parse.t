#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most;

BEGIN { use_ok('XML::PP') }

my $xml = <<'XML';
<?xml version="1.0"?>
<config>
	<memory_cache>
		<driver>Null</driver>
	</memory_cache>
	<disc_cache>
		<driver>Null</driver>
	</disc_cache>
	<SiteTitle>Sample VWF site</SiteTitle>
	<root_dir>/Users/njh/src/njh/vwf</root_dir>
</config>
XML

my $xml_pp = new_ok('XML::PP');

my $tree = $xml_pp->collapse_structure($xml_pp->parse(\$xml));
ok(defined($tree));
ok(ref($tree) eq 'HASH');

diag(Data::Dumper->new([$tree])->Dump()) if($ENV{'TEST_VERBOSE'});

my $expected = {
	config => {
		memory_cache => { driver => 'Null' } ,
		disc_cache => { driver => 'Null' },
		SiteTitle => 'Sample VWF site',
		root_dir => '/Users/njh/src/njh/vwf'
	}
};

is_deeply($tree, $expected, 'Parse and collapse work together');

done_testing();
