#!/usr/bin/perl -w

use XML::DOM::BagOfTricks qw(:all);

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

my ($doc,$root) = createDocument('Pubs');

warn "doc : $doc, root : $root\n";

foreach my $pubname (sort keys %pubs) {
    my $pub = createElement($doc, 'PublicHouse','Name'=>$pubname ,'Brewery'=>$pubs{$pubname}{Brewery}, 'Food'=>$pubs{$pubname}{Food});

    my $pub_tube = createTextElement($doc,'TubeStation',$pubs{$pubname}{Tube});
    $pub->appendChild($pub_tube);

    my $pub_postcode = createTextElement($doc,'Postcode',$pubs{$pubname}{Postcode});
    $pub->appendChild($pub_postcode);

    $root->appendChild($pub);
}


print $root->toString, "\n";

