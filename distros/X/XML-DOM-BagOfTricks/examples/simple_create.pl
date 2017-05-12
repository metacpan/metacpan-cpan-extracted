#!/usr/bin/perl -w

use XML::DOM;


my %pubs = (
	    'Star of Belgravia'=> {
				   Tube => 'Knightsbridge',
				   Postcode => 'SW1X 8HT',
				   Food => 'True',
				   Brewery => 'Fullers',
				  },
	    'Cittie of Yorke' => {
				  Tube => 'Chancery Lane',
				  Postcode => 'WC1',
				 },
	    'Penderals Oak' => {
				Tube => 'Chancery Lane',
				Postcode => 'WC1',
				Food => 'True',
				Brewery => 'Weatherspoons',
			       },
	    'The Angel' => {
			    Tube => 'Old Street',
			    Postcode => 'EC1',
			   },
	   );

my $doc = XML::DOM::Document->new();
my $root = $doc->createElement('Pubs');

foreach my $pubname (sort keys %pubs) {
    my $pub = $doc->createElement('PublicHouse');
    $pub->setAttribute('Brewery',$pubs{$pubname}{Brewery}) if ($pubs{$pubname}{Brewery});
    $pub->setAttribute('Food',$pubs{$pubname}{Food}) if ($pubs{$pubname}{Food});
    $pub->setAttribute('Name',$pubname);

    my $pub_tube = $doc->createElement('TubeStation');
    $pub_tube->appendChild($doc->createTextNode($pubs{$pubname}{Tube}));
    $pub->appendChild($pub_tube);

    my $pub_postcode = $doc->createElement('Postcode');
    $pub_postcode->appendChild($doc->createTextNode($pubs{$pubname}{Postcode}));
    $pub->appendChild($pub_postcode);

    $root->appendChild($pub);
}

print $root->toString, "\n";

