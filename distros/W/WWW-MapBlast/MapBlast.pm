package WWW::MapBlast;
our $VERSION = 0.02;
our $DATE = "Mon Jun 25 18:13:00 2001 BST";

use LWP::UserAgent;
use HTTP::Request;
use HTML::TokeParser;
use strict;
use warnings;

=head1 NAME

WWW::MapBlast - latitude & longitude from postal codes.

=head1 SYNOPSIS

	use WWW::MapBlast;
	my ($lat, $lon) = WWW::MapBlast::latlon('United Kingdom','BN3 3AG');
	__END__;

=head1 DESCRIPTION

Simply accesses L<MapBlast.com|http://www.MapBlast.com> and
retrieves latitude and longitude information.

Only minimal error checking, so have a look through the source before you use.

=cut

our %countriesList = (
	"United States"=>"USA","AFG"=>"Afghanistan","Albania"=>"ALB","Algeria"=>"DZA",
	"American Samoa"=>"ASM","Andorra"=>"AND","Angola"=>"AGO","Anguilla"=>"AIA",
	"Antigua and Barbuda"=>"ATG","Argentina"=>"ARG","Armenia"=>"ARM","Aruba"=>"ABW",
	"Australia"=>"AUS","Austria"=>"AUT","Azerbaijan"=>"AZE","Bahamas"=>"BHS",
	"Bahrain"=>"BHR","Bangladesh"=>"BGD","Barbados"=>"BRB","Belarus"=>"BLR",
	"Belgium"=>"BEL","Belize"=>"BLZ","Benin"=>"BEN","Bermuda"=>"BMU",
	"Bhutan"=>"BTN","Bolivia"=>"BOL","Bosnia and Herzegovina"=>"BIH","Botswana"=>"BWA",
	"Brazil"=>"BRA","British Virgin Islands"=>"VGB","Brunei Darussalam"=>"BRN",
	"Bulgaria"=>"BGR","Burkina Faso"=>"BFA","Burundi"=>"BDI","Cambodia"=>"KHM",
	"Cameroon"=>"CMR","Canada"=>"CAN","Cape Verde"=>"CPV","Cayman Islands"=>"CYM",
	"Central African Republic"=>"CAF","Chad"=>"TCD",
	"Chile"=>"CHL","China"=>"CHN","Colombia"=>"COL","Comoros"=>"COM",
	"Congo"=>"COG","Cook Islands"=>"COK","Costa Rica"=>"CRI","Croatia"=>"HRV",
	"Cuba"=>"CUB","Cyprus"=>"CYP","Czech Republic"=>"CZE","Denmark"=>"DNK",
	"Djibouti"=>"DJI","Dominica"=>"DMA","Dominican Republic"=>"DOM","Ecuador"=>"ECU",
	"Egypt"=>"EGY","El Salvador"=>"SLV","Equatorial Guinea"=>"GNQ","Eritrea"=>"ERI",
	"Estonia"=>"EST","Ethiopia"=>"ETH","Falkland Islands"=>"FLK","Faroe Islands"=>"FRO",
	"Fiji"=>"FJI","Finland"=>"FIN","France"=>"FRA","French Guiana"=>"GUF",
	"French Polynesia"=>"PYF","Gabon"=>"GAB","Gambia"=>"GMB","Georgia"=>"GEO",
	"Germany"=>"DEU","Ghana"=>"GHA","Gibraltar"=>"GIB","Greece"=>"GRC",
	"Greenland"=>"GRL","Grenada"=>"GRD","Guadeloupe"=>"GLP","Guatemala"=>"GTM",
	"Guinea"=>"GIN","Guinea Bissau"=>"GNB","Guyana"=>"GUY","Haiti"=>"HTI",
	"Honduras"=>"HND","Hong Kong"=>"HKG","Hungary"=>"HUN","Iceland"=>"ISL",
	"India"=>"IND","Indonesia"=>"IDN","Iran"=>"IRN","Iraq"=>"IRQ",
	"Ireland"=>"IRL","Israel"=>"ISR","Italy"=>"ITA","Ivory Coast"=>"CIV",
	"Jamaica"=>"JAM","Japan"=>"JPN","Jordan"=>"JOR","Kazakhstan"=>"KAZ",
	"Kenya"=>"KEN","Kiribati"=>"KIR","Kuwait"=>"KWT","Kyrgyzstan"=>"KGZ",
	"Laos"=>"LAO","Latvia"=>"LVA","Lebanon"=>"LBN","Lesotho"=>"LSO",
	"Liberia"=>"LBR","Libya"=>"LBY",",Liechtenstein"=>"LIE","Lithuania"=>"LTU",
	"Luxembourg"=>"LUX","Macau"=>"MAC","Macedonia"=>"MKD","Madagascar"=>"MDG",
	"Malawi"=>"MWI","Malaysia"=>"MYS","Maldives"=>"MDV","Mali"=>"MLI",
	"Malta"=>"MLT","Marshall Islands"=>"MHL","Martinique"=>"MTQ","Mauritania"=>"MRT",
	"Mauritius"=>"MUS","Mexico"=>"MEX","Micronesia"=>"FSM","Moldova"=>"MDA",
	"Monaco"=>"MCO","Mongolia"=>"MNG","Montserrat"=>"MSR","Morocco"=>"MAR",
	"Mozambique"=>"MOZ","Myanmar"=>"MMR","Namibia"=>"NAM","Nepal"=>"NPL",
	"Netherlands"=>"NLD","Netherlands Antilles"=>"ANT","New Caledonia"=>"NCL","New Zealand"=>"NZL",
	"Nicaragua"=>"NIC","Niger"=>"NER","Nigeria"=>"NGA","Norfolk Island"=>"NFK",
	"North Korea"=>"PRK","Northern Mariana Islands"=>"MNP","Norway"=>"NOR","Oman"=>"OMN",
	"Pakistan"=>"PAK","Palau"=>"PLW","Panama"=>"PAN","Papua New Guinea"=>"PNG",
	"Paraguay"=>"PRY","Peru"=>"PER","Philippines"=>"PHL","Poland"=>"POL",
	"Portugal"=>"PRT","Puerto Rico"=>"PRI","Qatar"=>"QAT","Reunion"=>"REU",
	"Romania"=>"ROM","Russia"=>"RUS","Rwanda"=>"RWA","Saint Helena"=>"SHN",
	"Saint Kitts and Nevis"=>"KNA","Saint Lucia"=>"LCA","Saint Pierre and Miquelon"=>"SPM","Saint Vincent/Grenadines"=>"VCT","Samoa"=>"WSM","San Marino"=>"SMR",
	"Saotome and Principe"=>"STP","Saudi Arabia"=>"SAU","Senegal"=>"SEN","Seychelles"=>"SYC",
	"Sierra Leone"=>"SLE","Singapore"=>"SGP","Slovak Republic"=>"SVK","Slovenia"=>"SVN",
	"Solomon Islands"=>"SLB","Somalia"=>"SOM","South Africa"=>"ZAF","South Korea"=>"KOR",
	"Spain"=>"ESP","Sri Lanka"=>"LKA","Sudan"=>"SDN","Suriname"=>"SUR",
	"Swaziland"=>"SWZ","Sweden"=>"SWE","Switzerland"=>"CHE","Syria"=>"SYR",
	"Taiwan"=>"TWN","Tajikistan"=>"TJK","Tanzania"=>"TZA","Thailand"=>"THA",
	"Togo"=>"TGO","Tokelau"=>"TKL","Tonga"=>"TON","Trinidad and Tobago"=>"TTO",
	"Tunisia"=>"TUN","Turkey"=>"TUR","Turkmenistan"=>"TKM","Turks and Caicos Islands"=>"TCA",
	"Uganda"=>"UGA","Ukraine"=>"UKR","United Arab Emirates"=>"ARE","United Kingdom"=>"GBR",
	"United States"=>"USA","US Virgin Islands"=>"VIR","Uruguay"=>"URY","Uzbekistan"=>"UZB",
	"Vanuatu"=>"VUT","Vatican"=>"VAT","Venezuela"=>"VEN","Vietnam"=>"VNM",
	"Western Sahara"=>"ESH","Yemen"=>"YEM","Yugoslavia"=>"YUG","Zambia"=>"ZMB",
	"Zimbabwe"=>"ZWE"
);


=head1 Commentary

Set $CHAT if you wish to see what's going on during net access.

=cut

our $CHAT;

=head1 Subroutine latlon (country, postcode)

Accepts a country name and a postal code, returns the relative latitude and longitude as defined by MapBlast.com

The argument C<country> must match a key of the module's C<%countriesList> hash, so it may be an idea to check your input against those keys before calling.

Will try to connect four times, and return C<undef> on failure.

B<Note> that latitude and longitude is not (C<x>,C<y>) !

=cut

sub latlon { my ($country, $postcode) = (shift,shift);
	for (0..3){
		warn "Trying $_...\n" if $CHAT;
		my $doc = get_document($country,$postcode);
		@_ = extract_latlon($doc);
		last if defined $_[0];
	}
	return @_;
}


#
# SUB get_document
# Accepts a country name, and a postcode
# Returns:
#
sub get_document { my ($country,$postcode) = (shift,shift);
	die "get_document requires a \$country,\$postcode arrity" if not defined $country or not defined $postcode;
	warn "No code for country <$country>." and return undef if not exists $countriesList{$country};
	$postcode =~ s/\s//g;

	my $ua = LWP::UserAgent->new;											# Create a new UserAgent
	$ua->agent('Mozilla/25.'.(localtime)." (PERL __PACKAGE__ $VERSION");	# Give it a type name
	warn "Attempting to access ...\n" if $CHAT;

	my $url =
			'http://www.mapblast.com/myblast/map.mb?'
			. 'CMD=GEO&req_action=crmap&AD4='. $countriesList{$country}
			. '&AD3='.$postcode
			. '&x=0&y=0';

	# Format URL request
	my $req = new HTTP::Request ('GET',$url) or die "...could not GET.\n" and return undef;
	my $res = $ua->request($req);						# $res is the object UA returned
	if (not $res->is_success()) {						# If successful
		warn"...failed.\n" if $CHAT;
		return undef
	}
	warn "...ok.\n" if $CHAT;

	return $res->content;
}


#
# extract_latlon
# Accepts an HTML result page from a MapBlast.com search
# Extracts the latitude/longitude from a link within the page
# - such as http://www.mapblast.com/myblast/driveSilo.mb?&IC_2=51.592423:-0.171996:8:&CT_2=51.592423:-0.171995:20000&AD4_2=GBR&apmenu_2=&apcode_2=&GAD1_2=&GAD2_2=Leslie+Road&GAD3_2=London%2c+N2+8BH&GMI_2=&MA=1&phone_2="
# Retunrs lat/lon, and the address as three scalars
#
sub extract_latlon { my $doc = shift;
	my $token;
	my $address = ' ';
	my $p = HTML::TokeParser->new(\$doc) or die "Couldn't create TokePraser: $!";

	# Get the address
	while ($token = $p->get_token){
		if (@$token[1] eq 'input'
			and defined @$token[2]
			and exists %{@$token[2]}->{name}
			and exists %{@$token[2]}->{value}
			and %{@$token[2]}->{name} =~ /^GAD\d$/
			and %{@$token[2]}->{value} !~ m/^\s*$/
		){
			$_ = %{@$token[2]}->{value};
			if (defined $address and $address !~ m/$_/i){
				$address .=  "$_,";
			}
		}
	}
	$address = substr( $address, 1, length($address)-2 ) if defined $address;
	$address =~ s/,+(\w)/, $1/g;	# MapBlast returns ugly lists
	return "Address not found" if not defined $address and $doc=~/Address not found/i;

	# Get the co-ords
	$p = HTML::TokeParser->new(\$doc) or die "Couldn't create TokePraser: $!";
	while ($token = $p->get_token
	and not (@$token[1] eq 'img' and %{@$token[2]}->{src} eq '/myblast/images/topnav/mapsiloon.gif')
	){}
	while ($token = $p->get_token and @$token[1] ne 'a'){}
 	if (defined @$token[2]){
		%{@$token[2]}->{href} =~ m/IC_2=([\d:.-]+)&/;
	 	if (defined $1){
	 		my ($lat,$lon,$rubbish) = split(/:/,$1,3);
			return ($lat,$lon,$address);
		}
	}
	warn "Unexpected format from MapBlast.com.\n";
	return undef;
}


=head1 LATITUDE AND LONGITUDE

After L<http://www.mapblast.com/myblast/helpFaq.mb#2|http://www.mapblast.com/myblast/helpFaq.mb#2>:

=over 4

Zero degrees latitude is the equator, with the North pole at 90 degrees latitude and the South pole at -90 degrees latitude.
one degree is approximately 69 miles. Greenwich, England is at 51.466 degrees north of the equator.

Zero degrees longitude goes through Greenwich, England.
Again, Each 69 miles from this meridian represents approximately 1 degree of longitude.
East/West is plus/minus respectively.

=back

=head1 PREREQUISITES

	LWP::UserAgent;
	HTTP::Request;
	HTML::TokeParser;
	strict;
	warnings.

=head1 EXPORTS

None by default.

=head1 REVISIONS

=item 0.02

Now returns street addresses in addition to latitude and longitude.

=head1 SEE ALSO

L<LWP::UserAgent>, L<HTTP::Request>, L<HTML::TokeParser>.

=head1 AUTHOR

Lee Goddard L<lgoddard@cpan.org|mailto:lgoddard@cpan.org>.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2001 - All Rights Reserved.

This library is free software and may be used only under the same terms as Perl itself.

=cut

1;
__END__
