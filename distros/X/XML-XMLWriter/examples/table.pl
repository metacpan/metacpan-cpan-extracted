#!/usr/bin/perl

use XML::XMLWriter;

my @data=(['Name', 'Adress', 'Email', 'Sex'],
	  ['Herbert', 'BeerAvenue 45', 'herbert@names.org', 'Male'],
	  ['Anelise', 'SchmidtStree 21', 'foo@bar.com', 'Female'],
	  ['XYZ', 'ZYX', 'ZY', 'XZ'],
	  ['etc...']);

#this produces warnings
my $doc = new XML::XMLWriter;

#transitional a bit more tolerant, so no warnings
#my $doc = new XML::XMLWriter(system => 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd',
#			     public => '-//W3C//DTD XHTML 1.0 Transitional//EN');

#we just use another encoding (doesn't matter since only ascii characters are used)
#my $doc = new XML::XMLWriter(system => 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd',
#			     public => '-//W3C//DTD XHTML 1.0 Transitional//EN',
#			     encoding => 'ISO-8859-15');

my $html = $doc->createRoot;
$html->head->title->_pcdata('A Table');
my $body = $html->body;
$body->h1->_pcdata('Here is a table!');
my $table = $body->table({align => 'center', cellspacing => 1, cellpadding => 2, border => 1});
for(my $i=0; $i<@data; $i++) {
  my $tr = $table->tr;
  foreach $_ (@{$data[$i]}) {
    $i==0 ? $tr->th->_pcdata($_) : $tr->td->_pcdata($_);
  }
}
$body->b->_pcdata("that's it!");
$doc->print();

