package WebService::Kramerius::API4::Feed;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

sub custom {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['policy', 'type']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/feed/custom'.
		$self->_construct_opts($opts_hr));
}

sub mostdesirable {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['limit', 'offset', 'type']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/feed/mostdesirable'.
		$self->_construct_opts($opts_hr));
}

sub newest {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['limit', 'offset', 'type']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/feed/newest'.
		$self->_construct_opts($opts_hr));
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Kramerius::API4::Feed - Class to feed endpoint in Kramerius v4+ API.

=head1 SYNOPSIS

 use WebService::Kramerius::API4::Feed;

 my $obj = WebService::Kramerius::API4::Feed->new(%params);
 my $custom = $obj->custom($opts_hr);
 my $mostdesirable = $obj->mostdesirable($opts_hr);
 my $newest = $obj->newest($opts_hr);

=head1 METHODS

=head2 C<new>

 my $obj = WebService::Kramerius::API4::Feed->new(%params);

Constructor.

=over 8

=item * C<library_url>

Library URL.

This parameter is required.

Default value is undef.

=item * C<output_dispatch>

Output dispatch hash structure.
Key is content-type and value is subroutine, which converts content to what do you want.

Default value is blank hash array.

=back

Returns instance of object.

=head2 C<custom>

 my $custom = $obj->custom($opts_hr);

Get custom feed from Kramerius system.

C<$opts_hr> is reference to hash with options:

=over

=item * C<policy>

=item * C<type>

=back

Returns string with JSON.

=head2 C<mostdesirable>

 my $mostdesirable = $obj->mostdesirable($opts_hr);

Get most desirable feed from Kramerius system.

C<$opts_hr> is reference to hash with options:

=over

=item * C<limit>

=item * C<offset>

=item * C<type>

=back

Returns string with JSON.

=head2 C<newest>

 my $newest = $obj->newest($opts_hr);

Get newest feed from Kramerius system.

C<$opts_hr> is reference to hash with options:

=over

=item * C<limit>

=item * C<offset>

=item * C<type>

=back

Returns string with JSON.

=head1 ERRORS

 new():
         Parameter 'library_url' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

=for comment filename=kramerius_feed_custom.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::Feed;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 library_url\n";
         exit 1;
 }
 my $library_url = $ARGV[0];

 my $obj = WebService::Kramerius::API4::Feed->new(
         'library_url' => $library_url,
 );

 my $custom_json = $obj->custom;

 print $custom_json."\n";

 # Output for 'http://kramerius.mzk.cz/', pretty print.
 # {
 #   "data": [
 #     {
 #       "issn": "",
 #       "author": [
 #         "Činčera, Josef K."
 #       ],
 #       "pid": "uuid:9ebcb206-24b7-4dc7-b367-3d9ad7179c23",
 #       "model": "monograph",
 #       "datumstr": "1923",
 #       "title": "Šachy",
 #       "root_pid": "uuid:9ebcb206-24b7-4dc7-b367-3d9ad7179c23",
 #       "root_title": "Šachy",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:65713490-24e7-11e3-a5bb-005056827e52",
 #       "model": "periodical",
 #       "datumstr": "1890-1924",
 #       "title": "Rašple: humoristický list dělného lidu : humoristicko-satyrický list dělného lidu : list politicko-humoristický",
 #       "root_pid": "uuid:65713490-24e7-11e3-a5bb-005056827e52",
 #       "root_title": "Rašple: humoristický list dělného lidu : humoristicko-satyrický list dělného lidu : list politicko-humoristický",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Gershwin, George",
 #         "Rich, Fred",
 #         "Hotel Astor Orchestra",
 #         "Crooners (hudební skupina)"
 #       ],
 #       "pid": "uuid:59e708b6-c462-4610-90c5-ac5ca030050a",
 #       "model": "soundrecording",
 #       "datumstr": "1914",
 #       "title": "Oh, Kay!. Clap yo' hands : fox trot. Do-do-do : fox trot",
 #       "root_pid": "uuid:59e708b6-c462-4610-90c5-ac5ca030050a",
 #       "root_title": "Oh, Kay!. Clap yo' hands : fox trot. Do-do-do : fox trot",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:58d629d0-a466-11e8-a81d-5ef3fc9bb22f",
 #       "model": "periodical",
 #       "datumstr": "1926",
 #       "title": "Moravský illustrovaný zpravodaj : společenský, nepolitický týdeník",
 #       "root_pid": "uuid:58d629d0-a466-11e8-a81d-5ef3fc9bb22f",
 #       "root_title": "Moravský illustrovaný zpravodaj : společenský, nepolitický týdeník",
 #       "policy": "private"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Zýbal, František,"
 #       ],
 #       "pid": "uuid:593878da-bfbb-4579-a1b5-743897383f78",
 #       "model": "monograph",
 #       "datumstr": "1941",
 #       "title": "Malovaná mládež: humoresky ze života slováckých junáků",
 #       "root_pid": "uuid:593878da-bfbb-4579-a1b5-743897383f78",
 #       "root_title": "Malovaná mládež: humoresky ze života slováckých junáků",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:259f2cc0-973f-11e4-b7ae-001018b5eb5c",
 #       "model": "periodical",
 #       "datumstr": "1909-1931",
 #       "title": "Kopřivy: list satyrický",
 #       "root_pid": "uuid:259f2cc0-973f-11e4-b7ae-001018b5eb5c",
 #       "root_title": "Kopřivy: list satyrický",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "mime": "image/jpeg",
 #       "pid": "uuid:d22baf06-7fb6-4488-bc6f-995b644fd085",
 #       "model": "page",
 #       "datumstr": "1920",
 #       "title": "[1]",
 #       "root_pid": "uuid:ba4934d1-0a1e-4a01-a89d-c948477ca833",
 #       "root_title": "Plán Velkého Brna",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Mácha Karel Hynek,"
 #       ],
 #       "pid": "uuid:f5a09c95-2fd8-11e0-83a8-0050569d679d",
 #       "model": "monograph",
 #       "datumstr": "1896",
 #       "title": "Máj",
 #       "root_pid": "uuid:f5a09c95-2fd8-11e0-83a8-0050569d679d",
 #       "root_title": "Máj",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Rais, Karel Václav"
 #       ],
 #       "pid": "uuid:530719f5-ee95-4449-8ce7-12b0f4cadb22",
 #       "model": "monograph",
 #       "datumstr": "1889",
 #       "title": "Když slunéčko svítí",
 #       "root_pid": "uuid:530719f5-ee95-4449-8ce7-12b0f4cadb22",
 #       "root_title": "Když slunéčko svítí",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Mahen, Jiří"
 #       ],
 #       "pid": "uuid:b53d33f0-70a5-11e5-9690-005056827e51",
 #       "model": "monograph",
 #       "datumstr": "1921",
 #       "title": "Jak se dělá divadlo?: nezbytná příručka pro všechna divadla a pro ochotníky",
 #       "root_pid": "uuid:b53d33f0-70a5-11e5-9690-005056827e51",
 #       "root_title": "Jak se dělá divadlo?: nezbytná příručka pro všechna divadla a pro ochotníky",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "1802-6265",
 #       "pid": "uuid:bdc405b0-e5f9-11dc-bfb2-000d606f5dc6",
 #       "model": "periodical",
 #       "datumstr": "1936 - 1945",
 #       "title": "Lidové noviny",
 #       "root_pid": "uuid:bdc405b0-e5f9-11dc-bfb2-000d606f5dc6",
 #       "root_title": "Lidové noviny",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "0862-7967",
 #       "pid": "uuid:f1c7c08d-8f64-4b66-be28-5f209c2c7021",
 #       "model": "periodical",
 #       "datumstr": "1885-1928,1945-2001",
 #       "title": "Rovnost : list sociálních demokratů českých",
 #       "root_pid": "uuid:f1c7c08d-8f64-4b66-be28-5f209c2c7021",
 #       "root_title": "Rovnost : list sociálních demokratů českých",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "0862-1985",
 #       "pid": "uuid:13f650ad-6447-11e0-8ad7-0050569d679d",
 #       "model": "periodical",
 #       "datumstr": "1987-",
 #       "title": "Duha",
 #       "root_pid": "uuid:13f650ad-6447-11e0-8ad7-0050569d679d",
 #       "root_title": "Duha",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "mime": "image/jpeg",
 #       "pid": "uuid:c53e4155-5748-11e3-8d00-0050569d679d",
 #       "model": "page",
 #       "datumstr": "[1902]",
 #       "title": "[a]",
 #       "root_pid": "uuid:4d38f82d-eff9-4d74-93cf-01d6a71dc00d",
 #       "root_title": "Novy hanácky pěsničke",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Martini Johann Georg"
 #       ],
 #       "pid": "uuid:2fa33e93-7bb8-441c-aa5a-0f63bd565b94",
 #       "model": "graphic",
 #       "datumstr": "1844",
 #       "title": "Brünn",
 #       "root_pid": "uuid:2fa33e93-7bb8-441c-aa5a-0f63bd565b94",
 #       "root_title": "Brünn",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:a101de00-2119-11e3-a5bb-005056827e52",
 #       "model": "periodical",
 #       "datumstr": "1897-1921",
 #       "title": "Brněnské noviny",
 #       "root_pid": "uuid:a101de00-2119-11e3-a5bb-005056827e52",
 #       "root_title": "Brněnské noviny",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:eb3adc60-dd58-11e2-9923-005056827e52",
 #       "model": "periodical",
 #       "datumstr": "1848-1921",
 #       "title": "Brünner Zeitung",
 #       "root_pid": "uuid:eb3adc60-dd58-11e2-9923-005056827e52",
 #       "root_title": "Brünner Zeitung",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Masaryk, Tomáš Garrigue"
 #       ],
 #       "pid": "uuid:1400b020-1959-11e3-9319-005056827e51",
 #       "model": "monograph",
 #       "datumstr": "1919",
 #       "title": "Ideály humanitní: (několik kapitol)",
 #       "root_pid": "uuid:1400b020-1959-11e3-9319-005056827e51",
 #       "root_title": "Ideály humanitní: (několik kapitol)",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:1715b00c-4885-43b9-86cc-db9f41f2cccf",
 #       "model": "graphic",
 #       "datumstr": "1910-1940",
 #       "title": "[Neznámý muž s dýmkou]",
 #       "root_pid": "uuid:1715b00c-4885-43b9-86cc-db9f41f2cccf",
 #       "root_title": "[Neznámý muž s dýmkou]",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "mime": "image/jpeg",
 #       "pid": "uuid:c4d92170-dd82-11e6-b333-5ef3fc9ae867",
 #       "model": "page",
 #       "datumstr": "[1905]",
 #       "title": "[1]",
 #       "root_pid": "uuid:1f7250f0-c83b-11e6-8032-005056827e52",
 #       "root_title": "Album von Brünn",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "mime": "image/jpeg",
 #       "pid": "uuid:a32dbd70-9375-11e7-a9a4-005056827e51",
 #       "model": "page",
 #       "datumstr": "1907",
 #       "title": "[1a]",
 #       "root_pid": "uuid:16361ef0-5b01-11e7-b9d9-005056827e52",
 #       "root_title": "Moravské ovoce: Pojednání o ovocných odrůdách doporučených ku pěstování v českých krajích markrabství Moravského",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Machát, František",
 #         "Neubert, Václav"
 #       ],
 #       "pid": "uuid:5e1e9cd8-eecd-4627-9a1a-09c53caaf9a8",
 #       "model": "map",
 #       "datumstr": "[mezi 1918 a 1920]",
 #       "title": "Stát československý",
 #       "root_pid": "uuid:5e1e9cd8-eecd-4627-9a1a-09c53caaf9a8",
 #       "root_title": "Stát československý",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "pid": "uuid:fa14a490-3d00-11e6-8746-005056825209",
 #       "model": "periodical",
 #       "datumstr": "1922-1943",
 #       "title": "Salon: společnost, sport, divadlo, film, moda, výtvarné umění",
 #       "root_pid": "uuid:fa14a490-3d00-11e6-8746-005056825209",
 #       "root_title": "Salon: společnost, sport, divadlo, film, moda, výtvarné umění",
 #       "policy": "private"
 #     },
 #     {
 #       "issn": "",
 #       "author": [
 #         "Vrchlický, Jaroslav"
 #       ],
 #       "pid": "uuid:7b5117e0-cc57-11e3-b110-005056827e51",
 #       "model": "monograph",
 #       "datumstr": "1913",
 #       "title": "Noc na Karlštejně: veselohra o 3 jednáních",
 #       "root_pid": "uuid:7b5117e0-cc57-11e3-b110-005056827e51",
 #       "root_title": "Noc na Karlštejně: veselohra o 3 jednáních",
 #       "policy": "public"
 #     },
 #     {
 #       "issn": "",
 #       "mime": "image/jpeg",
 #       "pid": "uuid:4ac1bb48-5774-11e3-ae9f-0050569d679d",
 #       "model": "page",
 #       "datumstr": "1898",
 #       "title": "[a]",
 #       "root_pid": "uuid:3da9a2e8-5c49-4279-8537-f0f59c0562d4",
 #       "root_title": "Hasičská kronika",
 #       "policy": "public"
 #     }
 #   ]
 # }

=head1 EXAMPLE2

=for comment filename=kramerius_feed_mostdesirable.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::Feed;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 library_url [offset] [limit]\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $offset = $ARGV[1] || 0;
 my $limit = $ARGV[2] || 1;

 my $obj = WebService::Kramerius::API4::Feed->new(
         'library_url' => $library_url,
 );

 my $mostdesirable_json = $obj->mostdesirable({
         'limit' => $limit,
         'offset' => $offset,
 });

 print $mostdesirable_json."\n";

 # Output for 'http://kramerius.mzk.cz/', pretty print.
 # {
 #   "rss": "https://kramerius.mzk.cz/search/inc/home/mostDesirables-rss.jsp",
 #   "data": [
 #     {
 #       "issn": "",
 #       "author": [
 #         "Veselá, Jarmila",
 #         "Vlach, Karel",
 #         "Werich, Jan",
 #         "Zeman, Bohumil",
 #         "Zíma, Josef",
 #         "Černý, Miroslav",
 #         "Čeřovská, Judita",
 #         "Adam, Richard",
 #         "Benešová, Věra",
 #         "Benš, Pavel",
 #         "Brom, Gustav",
 #         "Chladil, Milan",
 #         "Cortés, Rudolf",
 #         "Duda, Karel",
 #         "Hertl, František",
 #         "Jelínek, Jiří",
 #         "Kopecký, Miloš",
 #         "Kubernát, Richard",
 #         "Kučerová, Marta",
 #         "Martinová, Eva",
 #         "Popper, Jiří",
 #         "Procházka, Tomáš",
 #         "Simonová, Yvetta",
 #         "Směták, Milan",
 #         "Vašíček, Jiří",
 #         "Orchestr Mirko Foreta",
 #         "Sestry Allanovy (hudební skupina)",
 #         "Kučerovci (hudební skupina)",
 #         "Brněnský estrádní rozhlasový orchestr",
 #         "Orchestr Divadla hl. m. Prahy v Karlíně",
 #         "Orchestr Gustava Broma",
 #         "Orchestr Jaroslava Echtnera",
 #         "Orchestr Jiřího Procházky",
 #         "Orchestr Karla Krautgartnera",
 #         "Orchestr Karla Vlacha"
 #       ],
 #       "pid": "uuid:49f861c4-0ce0-4bce-be0a-af7f071c5933",
 #       "model": "soundrecording",
 #       "datumstr": "p1992",
 #       "title": "Hity 50. let. 2",
 #       "root_pid": "uuid:49f861c4-0ce0-4bce-be0a-af7f071c5933",
 #       "root_title": "Hity 50. let. 2",
 #       "policy": "private"
 #     }
 #   ]
 # }

=head1 EXAMPLE3

=for comment filename=kramerius_feed_newest.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::Feed;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 library_url [offset] [limit]\n";
         exit 1;
 }
 my $library_url = $ARGV[0];
 my $offset = $ARGV[1] || 0;
 my $limit = $ARGV[2] || 1;

 my $obj = WebService::Kramerius::API4::Feed->new(
         'library_url' => $library_url,
 );

 my $newest_json = $obj->newest({
         'limit' => $limit,
         'offset' => $offset,
 });

 print $newest_json."\n";

 # Output for 'http://kramerius.mzk.cz/', pretty print.
 # {
 #   "rss": "https://kramerius.mzk.cz/search/inc/home/newest-rss.jsp",
 #   "data": [
 #     {
 #       "issn": "978-80-244-2204-6",
 #       "author": [
 #         "Kubáček, Lubomír",
 #         "Tesaříková, Eva",
 #         "Univerzita Palackého Přírodovědecká fakulta"
 #       ],
 #       "pid": "uuid:bf0e3480-4bbf-11ee-b8f0-005056827e52",
 #       "model": "monograph",
 #       "datumstr": "2008",
 #       "title": "Weakly nonlinear regression models",
 #       "root_pid": "uuid:bf0e3480-4bbf-11ee-b8f0-005056827e52",
 #       "root_title": "Weakly nonlinear regression models",
 #       "policy": "private"
 #     }
 #   ]
 # }

=head1 DEPENDENCIES

L<WebService::Kramerius::API4::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WebService-Kramerius-API4>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2015-2023

BSD 2-Clause License

=head1 VERSION

0.02

=cut
