use strict;
use warnings;
use XML::Rules;

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

my $parser = XML::Rules->new(
	stripspaces => 7,
	rules => {
		_default => '',
		river => sub {'.river' => "$_[1]->{_content}\n"},
		fish => sub {
			print <<"*END*";
[ Survey information for: $_[1]->{name} ]:

Saltwater:$_[1]->{saltwater}
Freshwater:$_[1]->{freshwater}
Rivers covered in survey:

$_[1]->{river}
*END*
		},
	}
);
$parser->parse($xml_raw);
