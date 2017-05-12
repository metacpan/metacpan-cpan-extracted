#!/usr/bin/perl -w

use utf8;
use strict;

use lib './lib';
use URI;
use URI::file;

use XML::Pastor;
use XML::Pastor::Util	qw(slurp_file);
use Data::Dumper;

main();

sub main {
	binmode(STDOUT, ":utf8");
	test_pastor();
}

#------------------------------------------------------
sub test_uri {
	my @u;
	
	$u[0] = URI::file->new_abs('test/schema/country.xsd');
	$u[1] = URI->new('http://www.example.com/schemas/country_schema.xsd');
	$u[2] = URI->new('hello.xsd');
	$u[3] = $u[2]->abs($u[1]);
	$u[4] = $u[2]->abs($u[0]);
	
	for (my $i=0; $i<@u; $i++) {
		print "URI [$i] = " . $u[$i] . "\n";
	}
	
}


#------------------------------------------------------
sub test_pastor() {	
	my $country;	
	my $pastor = XML::Pastor->new();
	
	$pastor->generate(	mode =>'eval',
							schema=>['./test/source/country/schema/country_schema4_import.xsd'], 
							destination=>'./test/out/lib/', 
							class_prefix=>"XML::Pastor::Test",
							verbose => 9
					);

	
	print "\n\n******* FILE SYSTEM ****************************";
	$country = XML::Pastor::Test::country->from_xml(URI::file->new_abs('./test/source/country/xml/country.xml'));
	test_country($country);		
	$country->to_xml("./test/out/xml/country.xml");
	
	
	print "\n\n******* FILE HANDLE ****************************";
	my $fh = IO::File->new("./test/source/country/xml/country.xml", "r");	
	$country = XML::Pastor::Test::country->from_xml($fh);
	test_country($country);		

	print "\n\n******* STRING ****************************";
	my $str = slurp_file("./test/source/country/xml/country.xml");
	$country = XML::Pastor::Test::country->from_xml($str);
	test_country($country);		

	print "\n\n******* DUMP *****************************\n";
	my $d=Data::Dumper->new([$country]);
	$d->Sortkeys(1);
	print $d->Dump();
		
#	print "\n\n******* HTTP ***********************************";
#	$country = XML::Pastor::Test::country->from_xml('http://test.dev.vedora.org/ayhan/workspace/XML-Pastor/test/xml/country.xml');
#	test_country($country);					
}

#---------------------------------------------
sub test_country($) {
	my $country	= shift;
	
	print "\n====== COUNTRY ==========\n";
	print "code : " . $country->code . ", Name : " . $country->name .  "\n";

	my $city	= $country->city;
	if (defined($city)) {		
		print "\n-----LEAD CITY--------\n";
		print "code : " . $city->code . ", Name : " . $city->name .  "\n";
	}
	
	print "\n-----CITIES --------\n";
	my $cities	= $country->grab("city");	
	foreach my $city (@$cities) {
		print "code : " . $city->code . ", Name : " . $city->name .  "\n";			
	}	
}

1;
