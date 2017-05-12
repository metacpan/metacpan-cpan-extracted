use Test;
use strict;
$^W = 1; # play nice with old perl

BEGIN { plan tests=> 5 }

use FileHandle;
require XML::Mini::Document;
use strict;

my $XMLString = 
qq|<?xml version="1.0"?>
 <people> <person>
   bob
  </person> <person> ralph </person> <person> cindy
  </person>
  <person> <name> <first>
	   Noam </first> <last>
	   Chomsky </last> </name> <hair color="brown" /> </person>
 </people>
|;


{
	my $miniXML =  XML::Mini::Document->new();

	my $numchildren = $miniXML->parse($XMLString);

	ok($numchildren, 2);

	my $name1 = $miniXML->getElement('person')->getValue() || ok(0);

	ok($name1, 'bob');

	my $name3 = $miniXML->getElement('person', 3)->getValue() || ok(0);

	ok($name3, 'cindy');


	my $name2 = $miniXML->getElementByPath('people/person', 1, 2)->getValue();

	ok($name2, 'ralph');

	my $people = $miniXML->getElement('people') || ok(0);

	my $noam = $people->getElementByPath('person/name/first',4)->getValue();

	ok($noam, 'Noam');

}

