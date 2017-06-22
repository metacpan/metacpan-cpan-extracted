package WWW::Google::CustomSearch;

$WWW::Google::CustomSearch::VERSION   = '0.35';
$WWW::Google::CustomSearch::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::CustomSearch - Interface to Google JSON/Atom Custom Search.

=head1 VERSION

Version 0.35

=cut

use 5.006;
use JSON;
use Data::Dumper;
use URI;

use WWW::Google::UserAgent;
use WWW::Google::UserAgent::DataTypes qw(:all);
use WWW::Google::CustomSearch::Params qw($FIELDS);
use WWW::Google::CustomSearch::Result;

use Moo;
use Types::Standard qw(Bool);
use namespace::clean;
extends 'WWW::Google::UserAgent';

our $BASE_URL = "https://www.googleapis.com/customsearch/v1";

has 'prettyprint'      => (is => 'ro', isa => TrueFalse);
has 'c2coff'           => (is => 'ro', isa => Bool);
has 'fileType'         => (is => 'ro', isa => FileType);
has 'hl'               => (is => 'ro', isa => InterfaceLang);
has 'cr'               => (is => 'ro', isa => CountryC);
has 'gl'               => (is => 'ro', isa => CountryCode);
has 'filter'           => (is => 'ro', isa => Bool, default => sub { return 1 });
has 'imgColorType'     => (is => 'ro', isa => ColorType);
has 'imgDominantColor' => (is => 'ro', isa => DominantColor);
has 'imgSize'          => (is => 'ro', isa => ImageSize);
has 'imgType'          => (is => 'ro', isa => ImageType);
has 'lr'               => (is => 'ro', isa => LanguageC);
has 'num'              => (is => 'ro', default => sub { return 10 });
has 'safe'             => (is => 'ro', default => sub { return 'off' });
has 'searchType'       => (is => 'ro', isa => SearchType);
has 'siteSearchFilter' => (is => 'ro', isa => SearchFilter);
has 'start'            => (is => 'ro', default => sub { return 1 });
has 'alt'              => (is => 'ro', isa => FileType, default => sub { return 'json' });

has [ qw(callback fields quotaUser userIp cref cx dateRestrict exactTerms
         excludeTerms googlehost highRange hq linkSite lowRange orTerms
         relatedSite rights sort siteSearch) ] => (is => 'ro');

=head1 DESCRIPTION

This  module  is  intended  for  anyone  who wants to write applications that can
interact with the JSON/Atom Custom Search API. With Google Custom Search, you can
harness the power of Google to create a customized search experience for your own
website.  You  can  use the JSON/Atom Custom Search API to retrieve Google Custom
Search results programmatically.

The JSON / Atom Custom Search  API  requires the use of an API key, which you can
get from the Google APIs console. The API provides 100 search queries per day for
free. If you need more, you may sign up for billing in the console.

The official Google API document can be found L<here|https://developers.google.com/custom-search/json-api/v1/overview>.
For more information about the Google custom search, please click L<here|https://developers.google.com/custom-search/json-api/v1/reference/cse/list>.

Important:The version v1 of the Google JSON/Atom Custom Search API is in Labs and
its features might change unexpectedly until it graduates.

=head1 SYNOPSIS

=head2 Single Page Search

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key=>$api_key, cx=>$cx);
    my $result  = $engine->search('Google');

    print "Search time: ", $result->searchTime, "\n";
    foreach my $item (@{$result->items}) {
       print "Snippet: ", $item->snippet, "\n";
    }

=head2 Multiple Page Search

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key=>$api_key, cx=>$cx);
    my $result  = $engine->search('Google');

    if (defined $result) {
        my $page_count = 2;
        my $page_no    = 1;
        print "Result Count: ", $result->totalResults, "\n";
        while (defined $result && ($page_no <= $page_count)) {
            print "Page [$page_no]:\n\n";
            foreach my $item (@{$result->items}) {
                print "Snippet: ", $item->snippet, "\n";
            }
            print "----------------------------------\n\n";

            sleep 10;
            my $page = $result->nextPage;
            $result  = $page->fetch;
            $page_no++;
        }
    }

See L<WWW::Google::CustomSearch::Result> for further details of the search result.

=head1 LANGUAGES (lr)

    +-----------------------+---------------------------------------------------+
    | Language              | Value                                             |
    +-----------------------+---------------------------------------------------+
    | Arabic                | lang_ar                                           |
    | Bulgarian             | lang_bg                                           |
    | Catalan               | lang_ca                                           |
    | Chinese (Simplified)  | lang_zh-CN                                        |
    | Chinese (Traditional) | lang_zh-TW                                        |
    | Croatian              | lang_hr                                           |
    | Czech                 | lang_cs                                           |
    | Danish                | lang_da                                           |
    | Dutch                 | lang_nl                                           |
    | English               | lang_en                                           |
    | Estonian              | lang_et                                           |
    | Finnish               | lang_fi                                           |
    | French                | lang_fr                                           |
    | German                | lang_de                                           |
    | Greek                 | lang_el                                           |
    | Hebrew                | lang_iw                                           |
    | Hungarian             | lang_hu                                           |
    | Icelandic             | lang_is                                           |
    | Indonesian            | lang_id                                           |
    | Italian               | lang_it                                           |
    | Japanese              | lang_ja                                           |
    | Korean                | lang_ko                                           |
    | Latvian               | lang_lv                                           |
    | Lithuanian            | lang_lt                                           |
    | Norwegian             | lang_no                                           |
    | Polish                | lang_pl                                           |
    | Portuguese            | lang_pt                                           |
    | Romanian              | lang_ro                                           |
    | Russian               | lang_ru                                           |
    | Serbian               | lang_sr                                           |
    | Slovak                | lang_sk                                           |
    | Slovenian             | lang_sl                                           |
    | Spanish               | lang_es                                           |
    | Swedish               | lang_sv                                           |
    | Turkish               | lang_tr                                           |
    +-----------------------+---------------------------------------------------+

=head1 Country Collection Values (cr)

    +----------------------------------------------+----------------------------+
    | Country                                      | Country Collection Name    |
    +----------------------------------------------+----------------------------+
    | Afghanistan                                  | countryAF                  |
    | Albania                                      | countryAL                  |
    | Algeria                                      | countryDZ                  |
    | American Samoa                               | countryAS                  |
    | Andorra                                      | countryAD                  |
    | Angola                                       | countryAO                  |
    | Anguilla                                     | countryAI                  |
    | Antarctica                                   | countryAQ                  |
    | Antigua and Barbuda                          | countryAG                  |
    | Argentina                                    | countryAR                  |
    | Armenia                                      | countryAM                  |
    | Aruba                                        | countryAW                  |
    | Australia                                    | countryAU                  |
    | Austria                                      | countryAT                  |
    | Azerbaijan                                   | countryAZ                  |
    | Bahamas                                      | countryBS                  |
    | Bahrain                                      | countryBH                  |
    | Bangladesh                                   | countryBD                  |
    | Barbados                                     | countryBB                  |
    | Belarus                                      | countryBY                  |
    | Belgium                                      | countryBE                  |
    | Belize                                       | countryBZ                  |
    | Benin                                        | countryBJ                  |
    | Bermuda                                      | countryBM                  |
    | Bhutan                                       | countryBT                  |
    | Bolivia                                      | countryBO                  |
    | Bosnia and Herzegovina                       | countryBA                  |
    | Botswana                                     | countryBW                  |
    | Bouvet Island                                | countryBV                  |
    | Brazil                                       | countryBR                  |
    | British Indian Ocean Territory               | countryIO                  |
    | Brunei Darussalam                            | countryBN                  |
    | Bulgaria                                     | countryBG                  |
    | Burkina Faso                                 | countryBF                  |
    | Burundi                                      | countryBI                  |
    | Cambodia                                     | countryKH                  |
    | Cameroon                                     | countryCM                  |
    | Canada                                       | countryCA                  |
    | Cape Verde                                   | countryCV                  |
    | Cayman Islands                               | countryKY                  |
    | Central African Republic                     | countryCF                  |
    | Chad                                         | countryTD                  |
    | Chile                                        | countryCL                  |
    | China                                        | countryCN                  |
    | Christmas Island                             | countryCX                  |
    | Cocos (Keeling) Islands                      | countryCC                  |
    | Colombia                                     | countryCO                  |
    | Comoros                                      | countryKM                  |
    | Congo                                        | countryCG                  |
    | Congo, the Democratic Republic of the        | countryCD                  |
    | Cook Islands                                 | countryCK                  |
    | Costa Rica                                   | countryCR                  |
    | Cote D'ivoire                                | countryCI                  |
    | Croatia (Hrvatska)                           | countryHR                  |
    | Cuba                                         | countryCU                  |
    | Cyprus                                       | countryCY                  |
    | Czech Republic                               | countryCZ                  |
    | Denmark                                      | countryDK                  |
    | Djibouti                                     | countryDJ                  |
    | Dominica                                     | countryDM                  |
    | Dominican Republic                           | countryDO                  |
    | East Timor                                   | countryTP                  |
    | Ecuador                                      | countryEC                  |
    | Egypt                                        | countryEG                  |
    | El Salvador                                  | countrySV                  |
    | Equatorial Guinea                            | countryGQ                  |
    | Eritrea                                      | countryER                  |
    | Estonia                                      | countryEE                  |
    | Ethiopia                                     | countryET                  |
    | European Union                               | countryEU                  |
    | Falkland Islands (Malvinas)                  | countryFK                  |
    | Faroe Islands                                | countryFO                  |
    | Fiji                                         | countryFJ                  |
    | Finland                                      | countryFI                  |
    | France                                       | countryFR                  |
    | France, Metropolitan                         | countryFX                  |
    | French Guiana                                | countryGF                  |
    | French Polynesia                             | countryPF                  |
    | French Southern Territories                  | countryTF                  |
    | Gabon                                        | countryGA                  |
    | Gambia                                       | countryGM                  |
    | Georgia                                      | countryGE                  |
    | Germany                                      | countryDE                  |
    | Ghana                                        | countryGH                  |
    | Gibraltar                                    | countryGI                  |
    | Greece                                       | countryGR                  |
    | Greenland                                    | countryGL                  |
    | Grenada                                      | countryGD                  |
    | Guadeloupe                                   | countryGP                  |
    | Guam                                         | countryGU                  |
    | Guatemala                                    | countryGT                  |
    | Guinea                                       | countryGN                  |
    | Guinea-Bissau                                | countryGW                  |
    | Guyana                                       | countryGY                  |
    | Haiti                                        | countryHT                  |
    | Heard Island and Mcdonald Islands            | countryHM                  |
    | Holy See (Vatican City State)                | countryVA                  |
    | Honduras                                     | countryHN                  |
    | Hong Kong                                    | countryHK                  |
    | Hungary                                      | countryHU                  |
    | Iceland                                      | countryIS                  |
    | India                                        | countryIN                  |
    | Indonesia                                    | countryID                  |
    | Iran, Islamic Republic of                    | countryIR                  |
    | Iraq                                         | countryIQ                  |
    | Ireland                                      | countryIE                  |
    | Israel                                       | countryIL                  |
    | Italy                                        | countryIT                  |
    | Jamaica                                      | countryJM                  |
    | Japan                                        | countryJP                  |
    | Jordan                                       | countryJO                  |
    | Kazakhstan                                   | countryKZ                  |
    | Kenya                                        | countryKE                  |
    | Kiribati                                     | countryKI                  |
    | Korea, Democratic People's Republic of       | countryKP                  |
    | Korea, Republic of                           | countryKR                  |
    | Kuwait                                       | countryKW                  |
    | Kyrgyzstan                                   | countryKG                  |
    | Lao People's Democratic Republic             | countryLA                  |
    | Latvia                                       | countryLV                  |
    | Lebanon                                      | countryLB                  |
    | Lesotho                                      | countryLS                  |
    | Liberia                                      | countryLR                  |
    | Libyan Arab Jamahiriya                       | countryLY                  |
    | Liechtenstein                                | countryLI                  |
    | Lithuania                                    | countryLT                  |
    | Luxembourg                                   | countryLU                  |
    | Macao                                        | countryMO                  |
    | Macedonia, the Former Yugosalv Republic of   | countryMK                  |
    | Madagascar                                   | countryMG                  |
    | Malawi                                       | countryMW                  |
    | Malaysia                                     | countryMY                  |
    | Maldives                                     | countryMV                  |
    | Mali                                         | countryML                  |
    | Malta                                        | countryMT                  |
    | Marshall Islands                             | countryMH                  |
    | Martinique                                   | countryMQ                  |
    | Mauritania                                   | countryMR                  |
    | Mauritius                                    | countryMU                  |
    | Mayotte                                      | countryYT                  |
    | Mexico                                       | countryMX                  |
    | Micronesia, Federated States of              | countryFM                  |
    | Moldova, Republic of                         | countryMD                  |
    | Monaco                                       | countryMC                  |
    | Mongolia                                     | countryMN                  |
    | Montserrat                                   | countryMS                  |
    | Morocco                                      | countryMA                  |
    | Mozambique                                   | countryMZ                  |
    | Myanmar                                      | countryMM                  |
    | Namibia                                      | countryNA                  |
    | Nauru                                        | countryNR                  |
    | Nepal                                        | countryNP                  |
    | Netherlands                                  | countryNL                  |
    | Netherlands Antilles                         | countryAN                  |
    | New Caledonia                                | countryNC                  |
    | New Zealand                                  | countryNZ                  |
    | Nicaragua                                    | countryNI                  |
    | Niger                                        | countryNE                  |
    | Nigeria                                      | countryNG                  |
    | Niue                                         | countryNU                  |
    | Norfolk Island                               | countryNF                  |
    | Northern Mariana Islands                     | countryMP                  |
    | Norway                                       | countryNO                  |
    | Oman                                         | countryOM                  |
    | Pakistan                                     | countryPK                  |
    | Palau                                        | countryPW                  |
    | Palestinian Territory                        | countryPS                  |
    | Panama                                       | countryPA                  |
    | Papua New Guinea                             | countryPG                  |
    | Paraguay                                     | countryPY                  |
    | Peru                                         | countryPE                  |
    | Philippines                                  | countryPH                  |
    | Pitcairn                                     | countryPN                  |
    | Poland                                       | countryPL                  |
    | Portugal                                     | countryPT                  |
    | Puerto Rico                                  | countryPR                  |
    | Qatar                                        | countryQA                  |
    | Reunion                                      | countryRE                  |
    | Romania                                      | countryRO                  |
    | Russian Federation                           | countryRU                  |
    | Rwanda                                       | countryRW                  |
    | Saint Helena                                 | countrySH                  |
    | Saint Kitts and Nevis                        | countryKN                  |
    | Saint Lucia                                  | countryLC                  |
    | Saint Pierre and Miquelon                    | countryPM                  |
    | Saint Vincent and the Grenadines             | countryVC                  |
    | Samoa                                        | countryWS                  |
    | San Marino                                   | countrySM                  |
    | Sao Tome and Principe                        | countryST                  |
    | Saudi Arabia                                 | countrySA                  |
    | Senegal                                      | countrySN                  |
    | Serbia and Montenegro                        | countryCS                  |
    | Seychelles                                   | countrySC                  |
    | Sierra Leone                                 | countrySL                  |
    | Singapore                                    | countrySG                  |
    | Slovakia                                     | countrySK                  |
    | Slovenia                                     | countrySI                  |
    | Solomon Islands                              | countrySB                  |
    | Somalia                                      | countrySO                  |
    | South Africa                                 | countryZA                  |
    | South Georgia and the South Sandwich Islands | countryGS                  |
    | Spain                                        | countryES                  |
    | Sri Lanka                                    | countryLK                  |
    | Sudan                                        | countrySD                  |
    | Suriname                                     | countrySR                  |
    | Svalbard and Jan Mayen                       | countrySJ                  |
    | Swaziland                                    | countrySZ                  |
    | Sweden                                       | countrySE                  |
    | Switzerland                                  | countryCH                  |
    | Syrian Arab Republic                         | countrySY                  |
    | Taiwan, Province of China                    | countryTW                  |
    | Tajikistan                                   | countryTJ                  |
    | Tanzania, United Republic of                 | countryTZ                  |
    | Thailand                                     | countryTH                  |
    | Togo                                         | countryTG                  |
    | Tokelau                                      | countryTK                  |
    | Tonga                                        | countryTO                  |
    | Trinidad and Tobago                          | countryTT                  |
    | Tunisia                                      | countryTN                  |
    | Turkey                                       | countryTR                  |
    | Turkmenistan                                 | countryTM                  |
    | Turks and Caicos Islands                     | countryTC                  |
    | Tuvalu                                       | countryTV                  |
    | Uganda                                       | countryUG                  |
    | Ukraine                                      | countryUA                  |
    | United Arab Emirates                         | countryAE                  |
    | United Kingdom                               | countryUK                  |
    | United States                                | countryUS                  |
    | United States Minor Outlying Islands         | countryUM                  |
    | Uruguay                                      | countryUY                  |
    | Uzbekistan                                   | countryUZ                  |
    | Vanuatu                                      | countryVU                  |
    | Venezuela                                    | countryVE                  |
    | Vietnam                                      | countryVN                  |
    | Virgin Islands, British                      | countryVG                  |
    | Virgin Islands, U.S.                         | countryVI                  |
    | Wallis and Futuna                            | countryWF                  |
    | Western Sahara                               | countryEH                  |
    | Yemen                                        | countryYE                  |
    | Yugoslavia                                   | countryYU                  |
    | Zambia                                       | countryZM                  |
    | Zimbabwe                                     | countryZW                  |
    +----------------------------------------------+----------------------------+

=head1 Country Codes (gl)

    +----------------------------------------------+----------------------------+
    | Country                                      | Country Code               |
    +----------------------------------------------+----------------------------+
    | Afghanistan                                  | af                         |
    | Albania                                      | al                         |
    | Algeria                                      | dz                         |
    | American Samoa                               | as                         |
    | Andorra                                      | ad                         |
    | Angola                                       | ao                         |
    | Anguilla                                     | ai                         |
    | Antarctica                                   | aq                         |
    | Antigua and Barbuda                          | ag                         |
    | Argentina                                    | ar                         |
    | Armenia                                      | am                         |
    | Aruba                                        | aw                         |
    | Australia                                    | au                         |
    | Austria                                      | at                         |
    | Azerbaijan                                   | az                         |
    | Bahamas                                      | bs                         |
    | Bahrain                                      | bh                         |
    | Bangladesh                                   | bd                         |
    | Barbados                                     | bb                         |
    | Belarus                                      | by                         |
    | Belgium                                      | be                         |
    | Belize                                       | bz                         |
    | Benin                                        | bj                         |
    | Bermuda                                      | bm                         |
    | Bhutan                                       | bt                         |
    | Bolivia                                      | bo                         |
    | Bosnia and Herzegovina                       | ba                         |
    | Botswana                                     | bw                         |
    | Bouvet Island                                | bv                         |
    | Brazil                                       | br                         |
    | British Indian Ocean Territory               | io                         |
    | Brunei Darussalam                            | bn                         |
    | Bulgaria                                     | bg                         |
    | Burkina Faso                                 | bf                         |
    | Burundi                                      | bi                         |
    | Cambodia                                     | kh                         |
    | Cameroon                                     | cm                         |
    | Canada                                       | ca                         |
    | Cape Verde                                   | cv                         |
    | Cayman Islands                               | ky                         |
    | Central African Republic                     | cf                         |
    | Chad                                         | td                         |
    | Chile                                        | cl                         |
    | China                                        | cn                         |
    | Christmas Island                             | cx                         |
    | Cocos (Keeling) Islands                      | cc                         |
    | Colombia                                     | co                         |
    | Comoros                                      | km                         |
    | Congo                                        | cg                         |
    | Congo, the Democratic Republic of the        | cd                         |
    | Cook Islands                                 | ck                         |
    | Costa Rica                                   | cr                         |
    | Cote D'ivoire                                | ci                         |
    | Croatia                                      | hr                         |
    | Cuba                                         | cu                         |
    | Cyprus                                       | cy                         |
    | Czech Republic                               | cz                         |
    | Denmark                                      | dk                         |
    | Djibouti                                     | dj                         |
    | Dominica                                     | dm                         |
    | Dominican Republic                           | do                         |
    | Ecuador                                      | ec                         |
    | Egypt                                        | eg                         |
    | El Salvador                                  | sv                         |
    | Equatorial Guinea                            | gq                         |
    | Eritrea                                      | er                         |
    | Estonia                                      | ee                         |
    | Ethiopia                                     | et                         |
    | Falkland Islands (Malvinas)                  | fk                         |
    | Faroe Islands                                | fo                         |
    | Fiji                                         | fj                         |
    | Finland                                      | fi                         |
    | France                                       | fr                         |
    | French Guiana                                | gf                         |
    | French Polynesia                             | pf                         |
    | French Southern Territories                  | tf                         |
    | Gabon                                        | ga                         |
    | Gambia                                       | gm                         |
    | Georgia                                      | ge                         |
    | Germany                                      | de                         |
    | Ghana                                        | gh                         |
    | Gibraltar                                    | gi                         |
    | Greece                                       | gr                         |
    | Greenland                                    | gl                         |
    | Grenada                                      | gd                         |
    | Guadeloupe                                   | gp                         |
    | Guam                                         | gu                         |
    | Guatemala                                    | gt                         |
    | Guinea                                       | gn                         |
    | Guinea-Bissau                                | gw                         |
    | Guyana                                       | gy                         |
    | Haiti                                        | ht                         |
    | Heard Island and Mcdonald Islands            | hm                         |
    | Holy See (Vatican City State)                | va                         |
    | Honduras                                     | hn                         |
    | Hong Kong                                    | hk                         |
    | Hungary                                      | hu                         |
    | Iceland                                      | is                         |
    | India                                        | in                         |
    | Indonesia                                    | id                         |
    | Iran, Islamic Republic of                    | ir                         |
    | Iraq                                         | iq                         |
    | Ireland                                      | ie                         |
    | Israel                                       | il                         |
    | Italy                                        | it                         |
    | Jamaica                                      | jm                         |
    | Japan                                        | jp                         |
    | Jordan                                       | jo                         |
    | Kazakhstan                                   | kz                         |
    | Kenya                                        | ke                         |
    | Kiribati                                     | ki                         |
    | Korea, Democratic People's Republic of       | kp                         |
    | Korea, Republic of                           | kr                         |
    | Kuwait                                       | kw                         |
    | Kyrgyzstan                                   | kg                         |
    | Lao People's Democratic Republic             | la                         |
    | Latvia                                       | lv                         |
    | Lebanon                                      | lb                         |
    | Lesotho                                      | ls                         |
    | Liberia                                      | lr                         |
    | Libyan Arab Jamahiriya                       | ly                         |
    | Liechtenstein                                | li                         |
    | Lithuania                                    | lt                         |
    | Luxembourg                                   | lu                         |
    | Macao                                        | mo                         |
    | Macedonia, the Former Yugosalv Republic of   | mk                         |
    | Madagascar                                   | mg                         |
    | Malawi                                       | mw                         |
    | Malaysia                                     | my                         |
    | Maldives                                     | mv                         |
    | Mali                                         | ml                         |
    | Malta                                        | mt                         |
    | Marshall Islands                             | mh                         |
    | Martinique                                   | mq                         |
    | Mauritania                                   | mr                         |
    | Mauritius                                    | mu                         |
    | Mayotte                                      | yt                         |
    | Mexico                                       | mx                         |
    | Micronesia, Federated States of              | fm                         |
    | Moldova, Republic of                         | md                         |
    | Monaco                                       | mc                         |
    | Mongolia                                     | mn                         |
    | Montserrat                                   | ms                         |
    | Morocco                                      | ma                         |
    | Mozambique                                   | mz                         |
    | Myanmar                                      | mm                         |
    | Namibia                                      | na                         |
    | Nauru                                        | nr                         |
    | Nepal                                        | np                         |
    | Netherlands                                  | nl                         |
    | Netherlands Antilles                         | an                         |
    | New Caledonia                                | nc                         |
    | New Zealand                                  | nz                         |
    | Nicaragua                                    | ni                         |
    | Niger                                        | ne                         |
    | Nigeria                                      | ng                         |
    | Niue                                         | nu                         |
    | Norfolk Island                               | nf                         |
    | Northern Mariana Islands                     | mp                         |
    | Norway                                       | no                         |
    | Oman                                         | om                         |
    | Pakistan                                     | pk                         |
    | Palau                                        | pw                         |
    | Palestinian Territory, Occupied              | ps                         |
    | Panama                                       | pa                         |
    | Papua New Guinea                             | pg                         |
    | Paraguay                                     | py                         |
    | Peru                                         | pe                         |
    | Philippines                                  | ph                         |
    | Pitcairn                                     | pn                         |
    | Poland                                       | pl                         |
    | Portugal                                     | pt                         |
    | Puerto Rico                                  | pr                         |
    | Qatar                                        | qa                         |
    | Reunion                                      | re                         |
    | Romania                                      | ro                         |
    | Russian Federation                           | ru                         |
    | Rwanda                                       | rw                         |
    | Saint Helena                                 | sh                         |
    | Saint Kitts and Nevis                        | kn                         |
    | Saint Lucia                                  | lc                         |
    | Saint Pierre and Miquelon                    | pm                         |
    | Saint Vincent and the Grenadines             | vc                         |
    | Samoa                                        | ws                         |
    | San Marino                                   | sm                         |
    | Sao Tome and Principe                        | st                         |
    | Saudi Arabia                                 | sa                         |
    | Senegal                                      | sn                         |
    | Serbia and Montenegro                        | cs                         |
    | Seychelles                                   | sc                         |
    | Sierra Leone                                 | sl                         |
    | Singapore                                    | sg                         |
    | Slovakia                                     | sk                         |
    | Slovenia                                     | si                         |
    | Solomon Islands                              | sb                         |
    | Somalia                                      | so                         |
    | South Africa                                 | za                         |
    | South Georgia and the South Sandwich Islands | gs                         |
    | Spain                                        | es                         |
    | Sri Lanka                                    | lk                         |
    | Sudan                                        | sd                         |
    | Suriname                                     | sr                         |
    | Svalbard and Jan Mayen                       | sj                         |
    | Swaziland                                    | sz                         |
    | Sweden                                       | se                         |
    | Switzerland                                  | ch                         |
    | Syrian Arab Republic                         | sy                         |
    | Taiwan, Province of China                    | tw                         |
    | Tajikistan                                   | tj                         |
    | Tanzania, United Republic of                 | tz                         |
    | Thailand                                     | th                         |
    | Timor-Leste                                  | tl                         |
    | Togo                                         | tg                         |
    | Tokelau                                      | tk                         |
    | Tonga                                        | to                         |
    | Trinidad and Tobago                          | tt                         |
    | Tunisia                                      | tn                         |
    | Turkey                                       | tr                         |
    | Turkmenistan                                 | tm                         |
    | Turks and Caicos Islands                     | tc                         |
    | Tuvalu                                       | tv                         |
    | Uganda                                       | ug                         |
    | Ukraine                                      | ua                         |
    | United Arab Emirates                         | ae                         |
    | United Kingdom                               | uk                         |
    | United States                                | us                         |
    | United States Minor Outlying Islands         | um                         |
    | Uruguay                                      | uy                         |
    | Uzbekistan                                   | uz                         |
    | Vanuatu                                      | vu                         |
    | Venezuela                                    | ve                         |
    | Viet Nam                                     | vn                         |
    | Virgin Islands, British                      | vg                         |
    | Virgin Islands, U.S.                         | vi                         |
    | Wallis and Futuna                            | wf                         |
    | Western Sahara                               | eh                         |
    | Yemen                                        | ye                         |
    | Zambia                                       | zm                         |
    | Zimbabwe                                     | zw                         |
    +----------------------------------------------+----------------------------+

=head1 Interface Language (hl)

    +---------------------------+-----------------------------------------------+
    | Display Language          | Parameter Value                               |
    +---------------------------+-----------------------------------------------+
    | Afrikaans                 | af                                            |
    | Albanian                  | sq                                            |
    | Amharic                   | sm                                            |
    | Arabic                    | ar                                            |
    | Azerbaijani               | az                                            |
    | Basque                    | eu                                            |
    | Belarusian                | be                                            |
    | Bengali                   | bn                                            |
    | Bihari                    | bh                                            |
    | Bosnian                   | bs                                            |
    | Bulgarian                 | bg                                            |
    | Catalan                   | ca                                            |
    | Chinese (Simplified)      | zh-CN                                         |
    | Chinese (Traditional)     | zh-TW                                         |
    | Croatian                  | hr                                            |
    | Czech                     | cs                                            |
    | Danish                    | da                                            |
    | Dutch                     | nl                                            |
    | English                   | en                                            |
    | Esperanto                 | eo                                            |
    | Estonian                  | et                                            |
    | Faroese                   | fo                                            |
    | Finnish                   | fi                                            |
    | French                    | fr                                            |
    | Frisian                   | fy                                            |
    | Galician                  | gl                                            |
    | Georgian                  | ka                                            |
    | German                    | de                                            |
    | Greek                     | el                                            |
    | Gujarati                  | gu                                            |
    | Hebrew                    | iw                                            |
    | Hindi                     | hi                                            |
    | Hungarian                 | hu                                            |
    | Icelandic                 | is                                            |
    | Indonesian                | id                                            |
    | Interlingua               | ia                                            |
    | Irish                     | ga                                            |
    | Italian                   | it                                            |
    | Japanese                  | ja                                            |
    | Javanese                  | jw                                            |
    | Kannada                   | kn                                            |
    | Korean                    | ko                                            |
    | Latin                     | la                                            |
    | Latvian                   | lv                                            |
    | Lithuanian                | lt                                            |
    | Macedonian                | mk                                            |
    | Malay                     | ms                                            |
    | Malayam                   | ml                                            |
    | Maltese                   | mt                                            |
    | Marathi                   | mr                                            |
    | Nepali                    | ne                                            |
    | Norwegian                 | no                                            |
    | Norwegian (Nynorsk)       | nn                                            |
    | Occitan                   | oc                                            |
    | Persian                   | fa                                            |
    | Polish                    | pl                                            |
    | Portuguese (Brazil)       | pt-BR                                         |
    | Portuguese (Portugal)     | pt-PT                                         |
    | Punjabi                   | pa                                            |
    | Romanian                  | ro                                            |
    | Russian                   | ru                                            |
    | Scots Gaelic              | gd                                            |
    | Serbian                   | sr                                            |
    | Sinhalese                 | si                                            |
    | Slovak                    | sk                                            |
    | Slovenian                 | sl                                            |
    | Spanish                   | es                                            |
    | Sudanese                  | su                                            |
    | Swahili                   | sw                                            |
    | Swedish                   | sv                                            |
    | Tagalog                   | tl                                            |
    | Tamil                     | ta                                            |
    | Telugu                    | te                                            |
    | Thai                      | th                                            |
    | Tigrinya                  | ti                                            |
    | Turkish                   | tr                                            |
    | Ukrainian                 | uk                                            |
    | Urdu                      | ur                                            |
    | Uzbek                     | uz                                            |
    | Vietnamese                | vi                                            |
    | Welsh                     | cy                                            |
    | Xhosa                     | xh                                            |
    | Zulu                      | zu                                            |
    +---------------------------+-----------------------------------------------+

=head1 File Types

    +--------------------------------+------------------------------------------+
    | File Type                      | Extension                                |
    +--------------------------------+------------------------------------------+
    | Adobe Flash                    | .swf                                     |
    | Adobe Portable Document Format | .pdf                                     |
    | Adobe PostScript               | .ps                                      |
    | Autodesk Design Web Format     | .dwf                                     |
    | Google Earth                   | .kml, .kmz                               |
    | GPS eXchange Format            | .gpx                                     |
    | Hancom Hanword                 | .hwp                                     |
    | HTML                           | .htm, .html                              |
    | Microsoft Excel                | .xls, .xlsx                              |
    | Microsoft PowerPoint           | .ppt, .pptx                              |
    | Microsoft Word                 | .doc, .docx                              |
    | OpenOffice presentation        | .odp                                     |
    | OpenOffice spreadsheet         | .ods                                     |
    | OpenOffice text                | .odt                                     |
    | Rich Text Format               | .rtf, .wri                               |
    | Scalable Vector Graphics       | .svg                                     |
    | TeX/LaTeX                      | .tex                                     |
    | Text                           | .txt, .text                              |
    | Basic source code              | .bas                                     |
    | C/C++ source code              | .c, .cc, .cpp, .cxx, .h, .hpp            |
    | C# source code                 | .cs                                      |
    | Java source code               | .java                                    |
    | Perl source code               | .pl                                      |
    | Python source code             | .py                                      |
    | Wireless Markup Language       | .wml, .wap                               |
    | XML                            | .xml                                     |
    +--------------------------------+------------------------------------------+

=head1 CONSTRUCTOR

The constructor expects application API Key and Custom search engine  identifier.
Use either C<cx>/C<cref> to specify the custom search engine you want to  perform
this search. If both are specified, C<cx> is used.

    +------------------+--------------------------------------------------------+
    | Key              | Description                                            |
    +------------------+--------------------------------------------------------+
    | api_key          | Your application API Key.                              |
    |                  |                                                        |
    | callback         | Callback function. Name of the JavaScript callback     |
    |                  | function that handles the response.                    |
    |                  |                                                        |
    | fields           | Selector specifying a subset of fields to include in   |
    |                  | the response.                                          |
    |                  |                                                        |
    | prettyprint      | Returns a response with indentations and line breaks.  |
    |                  | If prettyprint=true, the results returned by the server|
    |                  | will be human readable (pretty printed).               |
    |                  |                                                        |
    | userIp           | IP address of the end user for whom the API call is    |
    |                  | being made.                                            |
    |                  |                                                        |
    | quotaUser        | Alternative to userIp. Lets you enforce per-user quotas|
    |                  | from a server-side application even in cases when the  |
    |                  | user's IP address is unknown. You can choose any       |
    |                  | arbitrary string that uniquely identifies a user, but  |
    |                  | it is limited to 40 characters. Overrides userIp if    |
    |                  | both are provided.                                     |
    |                  |                                                        |
    | c2coff           | Enables or disables Simplified and Traditional Chinese |
    |                  | Search. The default value for this parameter is 0,     |
    |                  | meaning that the feature is enabled. Supported values  |
    |                  | are:                                                   |
    |                  | * 1 - Disabled                                         |
    |                  | * 2 - Enabled (default)                                |
    |                  |                                                        |
    | cr               | Restricts search results to documents originating in a |
    |                  | particular country.                                    |
    |                  | See section "Country Collection Name" for valid data.  |
    |                  |                                                        |
    | cref             | For a linked custom search engine.                     |
    |                  |                                                        |
    | cx               | For a search engine created with the Google Custom     |
    |                  | Search page.                                           |
    |                  |                                                        |
    | dateRestrict     | Restricts results to URLs based on date. Supported     |
    |                  |values include:                                         |
    |                  | * d[number]: requests results from the specified number|
    |                  |   of past days.                                        |
    |                  | * w[number]: requests results from the specified number|
    |                  |   of past weeks.                                       |
    |                  | * m[number]: requests results from the specified number|
    |                  |   of past months.                                      |
    |                  | * y[number]: requests results from the specified number|
    |                  |   of past years.                                       |
    |                  |                                                        |
    | exactTerms       | Identifies a phrase that all documents in the search   |
    |                  | results must contain.                                  |
    |                  |                                                        |
    | excludeTerms     | Identifies a word or phrase that should not appear in  |
    |                  | any documents in the search results.                   |
    |                  |                                                        |
    | fileType         | Restricts results to files of a specified extension.   |
    |                  |                                                        |
    | filter           | Controls turning on / off the duplicate content filter.|
    |                  | * filter=0 - Turns off the duplicate content filter.   |
    |                  | * filter=1 - Turns on the duplicate content filter     |
    |                  |              (default).                                |
    |                  |                                                        |
    | gl               | Geolocation of end user. The gl parameter value is a   |
    |                  | two-letter country code. See section "Country Codes".  |
    |                  |                                                        |
    | googlehost       | The local Google domain (for example, google.com,      |
    |                  | google.de, or google.fr) to use to perform the search. |
    |                  | Default "www.google.com".                              |
    |                  |                                                        |
    | highRange        | Specifies the ending value for a search range.         |
    |                  |                                                        |
    | hl               | Sets the user interface language. Explicitly setting   |
    |                  | this parameter improves the performance and the quality|
    |                  | of your search results.See section "Interface Language"|
    |                  |                                                        |
    | hq               | Appends the specified query terms to the query, as if  |
    |                  |they were combined  with a logical AND operator.        |
    |                  |                                                        |
    | imgColorType     | Returns black and white, grayscale, or color images.   |
    |                  | Acceptable values are mono, gray, and color.           |
    |                  |                                                        |
    | imgDominantColor | Returns images of a specific dominant color. Acceptable|
    |                  | values are "black", "blue", "brown", "gray", "green",  |
    |                  | "pink", "purple", "teal", "white", "yellow".           |
    |                  |                                                        |
    | imgSize          | Returns images of a specified size. Acceptable values  |
    |                  | are "huge","icon","large","medium","small","xlarge",   |
    |                  | "xxlarge".                                             |
    |                  |                                                        |
    | imgType          | Returns images of a type. Acceptable values are        |
    |                  | "clipart", "face", "news", "lineart", "photo".         |
    |                  |                                                        |
    | linkSite         | Specifies that all search results should contain a link|
    |                  | to a particular URL                                    |
    |                  |                                                        |
    | lowRange         | Specifies the starting value for a search range.       |
    |                  |                                                        |
    | lr               | The language restriction for the search results.       |
    |                  |                                                        |
    | num              | Number of search results to return. Valid values are   |
    |                  | integers between 1 and 10, Default is 10.              |
    |                  |                                                        |
    | orTerms          | Provides additional search terms to check for in a     |
    |                  | document,where each document in the search results must|
    |                  | contain at least one of the additional search terms.   |
    |                  |                                                        |
    | relatedSite      | Specifies that all search results should be pages that |
    |                  | are related to the specified URL.                      |
    |                  |                                                        |
    | rights           | Filters based on licensing. Supported values include:  |
    |                  | * cc_publicdomain                                      |
    |                  | * cc_attribute                                         |
    |                  | * cc_sharealike                                        |
    |                  | * cc_noncommercial                                     |
    |                  | * cc_nonderived, and combinations of these.            |
    |                  |                                                        |
    | safe             | Search safety level. Default is off. Possible values   |
    |                  | are:                                                   |
    |                  | * high -enables highest level of safe search filtering.|
    |                  | * medium - enables moderate safe search filtering.     |
    |                  | * off - disables safe search filtering.                |
    |                  |                                                        |
    | searchType       | Specifies the search type: image.  If unspecified,     |
    |                  | results are limited to webpages.                       |
    |                  |                                                        |
    | siteSearch       | Specifies all search results should be pages from a    |
    |                  | given site.                                            |
    |                  |                                                        |
    | siteSearchFilter | Controls whether to include or exclude results from the|
    |                  | site named in the siteSearch parameter. Acceptable     |
    |                  | values are:                                            |
    |                  | * "e": exclude                                         |
    |                  | * "i": include                                         |
    |                  |                                                        |
    | sort             | The sort expression to apply to the results.           |
    |                  |                                                        |
    | start            | The index of the first result to return. Default is 1. |
    +------------------+--------------------------------------------------------+

=cut

sub BUILD {
  my ($self) = @_;

  die("ERROR: cx or cref must be specified.") unless ($self->cx || $self->cref);

  $self->_validate;
}

=head1 METHODS

=head2 search($query_string)

Get search result L<WWW::Google::CustomSearch::Result> for the given query, which
can be used to probe for further information about the search result.

    use strict; use warnings;
    use WWW::Google::CustomSearch;

    my $api_key = 'Your_API_Key';
    my $cx      = 'Search_Engine_Identifier';
    my $engine  = WWW::Google::CustomSearch->new(api_key=>$api_key, cx=>$cx, start=>2);
    my $result  = $engine->search('Google');

=cut

sub search {
    my ($self, $query) = @_;
    die "ERROR: Missing query string." unless defined $query;

    my $url      = $self->_url($query);
    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    return WWW::Google::CustomSearch::Result->new(raw => $contents, api_key => $self->api_key);
}

#
# PRIVATE METHODS
#

sub _validate {
    my ($self) = @_;

    foreach my $key (keys %{$FIELDS}) {
        next unless (defined $self->{$key} && exists $FIELDS->{$key}->{check});

        die "ERROR: Invalid data for param: $key [$self->{$key}]"
            unless ($FIELDS->{$key}->{check}->($self->{$key}));
    }
}

sub _url {
    my ($self, $query) = @_;

    my $url = URI->new($BASE_URL);
    my $params = {
        'key' => $self->api_key,
        'q'   => $query,
    };

    if (($self->cx) || ($self->cx && $self->cref)) {
        $params->{'cx'} = $self->cx;
    }
    elsif ($self->cref) {
        $params->{'cref'} = $self->cref;
    }

    foreach my $key (keys %{$FIELDS}) {
        next unless defined $self->{$key};
        my $value_template = sprintf('%%%s', $FIELDS->{$key}->{type});
        $params->{$key} = sprintf($value_template, $self->{$key});
    }

    $url->query_form($params);

    return $url;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-CustomSearch>

=head1 CONTRIBUTORS

David Kitcher-Jones (m4ddav3)

=head1 BUGS

Please  report  any bugs or feature requests to C<bug-www-google-customsearch  at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-CustomSearch>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::CustomSearch

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-CustomSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-CustomSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-CustomSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-CustomSearch/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::CustomSearch
