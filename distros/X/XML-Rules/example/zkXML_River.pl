use strict;
use warnings;
use XML::Simple;

my $xml_raw = <<XML_RAW;
<survey>
<animals srcurl="blah.whatever.blah" method="ftp">
    <fish name="barramundi" freshwater="yes" saltwater="yes">
      <river>Todd</river>
      <river>Katherine</river>
    </fish>
    <fish name="carp" freshwater="yes" saltwater="no">
      <river>Tilbuster Ponds</river>
      <river>Maribyrnong</river>
      <river>Patterson</river>
      <river>Paterson</river>
      <river>Glenelg</river>
      <river>Murray</river>
      <river>Bunyip</river>
      <river>Campaspe</river>
    </fish>
    <fish name="yellowfin" freshwater="yes" saltwater="no">
      <river>Eucumbene</river>
      <river>Mulla Mulla Creek</river>
      <river>Burrungubugge</river>
      <river>Goobarragandra</river>
      <river>Bombala</river>
      <river>Murray</river>
      <river>Emu Swamp Creek</river>
    </fish>
</animals>
</survey>
XML_RAW

my $data = XMLin($xml_raw, ForceArray => [qw(river fish)], KeyAttr => []);

foreach my $Animal (@{$data->{animals}{fish}}) {
	print <<"*END*";
[ Survey information for: $Animal->{name} ]:

Saltwater:$Animal->{saltwater}
Freshwater:$Animal->{freshwater}
Rivers covered in survey:

*END*
	for (@{$Animal->{river}}) {
		print $_, "\n";
	}
	print "\n";
}