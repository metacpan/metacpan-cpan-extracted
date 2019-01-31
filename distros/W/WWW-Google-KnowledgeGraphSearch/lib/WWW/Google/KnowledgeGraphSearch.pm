package WWW::Google::KnowledgeGraphSearch;

$WWW::Google::KnowledgeGraphSearch::VERSION   = '0.06';
$WWW::Google::KnowledgeGraphSearch::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::KnowledgeGraphSearch - Interface to Google Knowledge Graph Search API.

=head1 VERSION

Version 0.06

=cut

use 5.006;
use URI;
use JSON;
use Data::Dumper;

use WWW::Google::UserAgent;
use WWW::Google::UserAgent::DataTypes qw(:all);
use WWW::Google::KnowledgeGraphSearch::Result;

use Moo;
use namespace::autoclean;
use Types::Standard qw(Bool Str Int);
extends 'WWW::Google::UserAgent';

our $BASE_URL = "https://kgsearch.googleapis.com/v1/entities:search";

our $ENTITY_TYPES = {
    'Book'                    => 1,
    'BookSeries'              => 1,
    'EducationalOrganization' => 1,
    'Event'                   => 1,
    'GovernmentOrganization'  => 1,
    'LocalBusiness'           => 1,
    'Movie'                   => 1,
    'MovieSeries'             => 1,
    'MusicAlbum'              => 1,
    'MusicGroup'              => 1,
    'MusicRecording'          => 1,
    'Organization'            => 1,
    'Periodical'              => 1,
    'Person'                  => 1,
    'Place'                   => 1,
    'SportsTeam'              => 1,
    'TVEpisode'               => 1,
    'TVSeries'                => 1,
    'VideoGame'               => 1,
    'VideoGameSeries'         => 1,
    'WebSite'                 => 1,
};

our $LANGUAGES = {
    'ab' => 1, 'aa' => 1, 'af' => 1, 'ak' => 1, 'sq' => 1, 'am' => 1, 'ar' => 1, 'an' => 1,
    'hy' => 1, 'as' => 1, 'av' => 1, 'ae' => 1, 'ay' => 1, 'az' => 1, 'bm' => 1, 'br' => 1,
    'eu' => 1, 'be' => 1, 'bn' => 1, 'bh' => 1, 'bi' => 1, 'bs' => 1, 'br' => 1, 'bg' => 1,
    'my' => 1, 'ca' => 1, 'ch' => 1, 'ce' => 1, 'ny' => 1, 'zh' => 1, 'cv' => 1, 'kw' => 1,
    'co' => 1, 'cr' => 1, 'hr' => 1, 'cs' => 1, 'da' => 1, 'dv' => 1, 'nl' => 1, 'dz' => 1,
    'en' => 1, 'eo' => 1, 'et' => 1, 'ee' => 1, 'fo' => 1, 'fj' => 1, 'fi' => 1, 'fr' => 1,
    'ff' => 1, 'gl' => 1, 'ka' => 1, 'de' => 1, 'el' => 1, 'gn' => 1, 'gu' => 1, 'ht' => 1,
    'ha' => 1, 'he' => 1, 'hz' => 1, 'hi' => 1, 'ho' => 1, 'hu' => 1, 'ia' => 1, 'id' => 1,
    'ie' => 1, 'ga' => 1, 'ig' => 1, 'ik' => 1, 'io' => 1, 'is' => 1, 'it' => 1, 'iu' => 1,
    'ja' => 1, 'jv' => 1, 'kl' => 1, 'kn' => 1, 'kr' => 1, 'ks' => 1, 'kk' => 1, 'km' => 1,
    'ki' => 1, 'rw' => 1, 'ky' => 1, 'kv' => 1, 'kg' => 1, 'ko' => 1, 'ku' => 1, 'kj' => 1,
    'la' => 1, 'lb' => 1, 'lg' => 1, 'li' => 1, 'ln' => 1, 'lo' => 1, 'lt' => 1, 'lu' => 1,
    'lv' => 1, 'gv' => 1, 'mk' => 1, 'mg' => 1, 'ms' => 1, 'ml' => 1, 'mt' => 1, 'mi' => 1,
    'mr' => 1, 'mh' => 1, 'mn' => 1, 'na' => 1, 'nv' => 1, 'nd' => 1, 'ne' => 1, 'ng' => 1,
    'nb' => 1, 'nn' => 1, 'no' => 1, 'ii' => 1, 'nr' => 1, 'oc' => 1, 'oj' => 1, 'cu' => 1,
    'om' => 1, 'or' => 1, 'os' => 1, 'pa' => 1, 'pi' => 1, 'fa' => 1, 'pl' => 1, 'ps' => 1,
    'pt' => 1, 'qu' => 1, 'rm' => 1, 'rn' => 1, 'ro' => 1, 'ru' => 1, 'sa' => 1, 'sc' => 1,
    'sd' => 1, 'se' => 1, 'sm' => 1, 'sg' => 1, 'sr' => 1, 'gd' => 1, 'sn' => 1, 'si' => 1,
    'sk' => 1, 'sl' => 1, 'so' => 1, 'st' => 1, 'es' => 1, 'su' => 1, 'sw' => 1, 'ss' => 1,
    'sv' => 1, 'ta' => 1, 'te' => 1, 'tg' => 1, 'th' => 1, 't1' => 1, 'bo' => 1, 'tk' => 1,
    'tl' => 1, 'tn' => 1, 'to' => 1, 'tr' => 1, 'ts' => 1, 'tt' => 1, 'tw' => 1, 'ty' => 1,
    'ug' => 1, 'uk' => 1, 'ur' => 1, 'uz' => 1, 've' => 1, 'vi' => 1, 'vo' => 1, 'wa' => 1,
    'cy' => 1, 'wo' => 1, 'fy' => 1, 'xh' => 1, 'yi' => 1, 'yo' => 1, 'za' => 1, 'zu' => 1,
};

has 'languages' => (is => 'ro', isa => Str,  default => sub { 'en'    });
has 'limit'     => (is => 'ro', isa => Int,  default => sub { 1       });

=head1 DESCRIPTION

The Knowledge Graph  Search  API  lets  you find entities in the Google Knowledge
Graph. The Google Knowledge Graph Search API requires the use of an API key which
you can get from the Google APIs console. The API provides 100,000 search queries
per day for free. If you need more, you may sign up for billing in the console.

The official Google API document can be found L<here|https://developers.google.com/knowledge-graph/reference/rest/v1/>.

Important:The version v1 of the Google Knowledge Graph Search API is in Labs and
its features might change unexpectedly until it graduates.

=head1 SYNOPSIS

    use strict; use warnings;
    use WWW::Google::KnowledgeGraphSearch;

    my $api_key = 'Your_API_Key';
    my $engine  = WWW::Google::KnowledgeGraphSearch->new(api_key => $api_key);
    my $result  = $engine->search('Taylor Swift');

    print $result->[0]->id, "\n";
    print $result->[0]->name, "\n";
    print $result->[0]->description, "\n";
    print $result->[0]->descriptionBody, "\n";
    print $result->[0]->resultScore, "\n";

See L<WWW::Google::KnowledgeGraphSearch::Result> for further details of the search result.

=head1 CONSTRUCTOR

The constructor expects application API Key C<api_key> mandatory, all others are
optional.

    +-----------+---------------------------------------------------------------+
    | Key       | Description                                                   |
    +-----------+---------------------------------------------------------------+
    | api_key   | API Key for Google Knowledge Graph Search API.                |
    |           |                                                               |
    | languages | A comma separated list of language codes (defined in ISO 639).|
    |           | Default is 'en'.                                              |
    |           |                                                               |
    | limit     | Limits the number of entities to be returned. Default is 1.   |
    +-----------+---------------------------------------------------------------+

=head1 LANGUAGE ISO 639

    +-------------------+-------------------------------------------------------+
    | Language          | Value                                                 |
    +-------------------+-------------------------------------------------------+
    | Abkhazian         | ab                                                    |
    | Afar              | aa                                                    |
    | Afrikaan          | af                                                    |
    | Akan              | ak                                                    |
    | Albanian          | sq                                                    |
    | Amharic           | am                                                    |
    | Arabic            | ar                                                    |
    | Aragonese         | an                                                    |
    | Armenian          | hy                                                    |
    | Assamese          | as                                                    |
    | Avaric            | av                                                    |
    | Avestan           | ae                                                    |
    | Aymara            | ay                                                    |
    | Azerbaijani       | az                                                    |
    | Bambara           | bm                                                    |
    | Bashkir           | br                                                    |
    | Basque            | eu                                                    |
    | Belarusian        | be                                                    |
    | Bengali           | bn                                                    |
    | Bihari languages  | bh                                                    |
    | Bislama           | bi                                                    |
    | Bosnian           | bs                                                    |
    | Breton            | br                                                    |
    | Bulgarian         | bg                                                    |
    | Burmese           | my                                                    |
    | Catalan           | ca                                                    |
    | Chamorro          | ch                                                    |
    | Chechen           | ce                                                    |
    | Chichewa          | ny                                                    |
    | Chinese           | zh                                                    |
    | Chuvash           | cv                                                    |
    | Cornish           | kw                                                    |
    | Corsican          | co                                                    |
    | Cree              | cr                                                    |
    | Croatian          | hr                                                    |
    | Czech             | cs                                                    |
    | Danish            | da                                                    |
    | Divehi            | dv                                                    |
    | Dutch             | nl                                                    |
    | Dzongkha          | dz                                                    |
    | English           | en                                                    |
    | Esperanto         | eo                                                    |
    | Estonian          | et                                                    |
    | Ewe               | ee                                                    |
    | Faroese           | fo                                                    |
    | Fijian            | fj                                                    |
    | Finnish           | fi                                                    |
    | French            | fr                                                    |
    | Fulah             | ff                                                    |
    | Galician          | gl                                                    |
    | Georgian          | ka                                                    |
    | German            | de                                                    |
    | Greek             | el                                                    |
    | Guarani           | gn                                                    |
    | Gujarati          | gu                                                    |
    | Haitian           | ht                                                    |
    | Hausa             | ha                                                    |
    | Hebrew            | he                                                    |
    | Herero            | hz                                                    |
    | Hindi             | hi                                                    |
    | Hiri Motu         | ho                                                    |
    | Hungarian         | hu                                                    |
    | Interlingua       | ia                                                    |
    | Indonesian        | id                                                    |
    | Interlingue       | ie                                                    |
    | Irish             | ga                                                    |
    | Igbo              | ig                                                    |
    | Inupiaq           | ik                                                    |
    | Ido               | io                                                    |
    | Icelandic         | is                                                    |
    | Italian           | it                                                    |
    | Inuktitut         | iu                                                    |
    | Japanese          | ja                                                    |
    | Javanese          | jv                                                    |
    | Kalaallisut       | kl                                                    |
    | Kannada           | kn                                                    |
    | Kanuri            | kr                                                    |
    | Kashmiri          | ks                                                    |
    | Kazakh            | kk                                                    |
    | Central Khmer     | km                                                    |
    | Kikuyu            | ki                                                    |
    | Kinyarwanda       | rw                                                    |
    | Kirghiz           | ky                                                    |
    | Komi              | kv                                                    |
    | Kongo             | kg                                                    |
    | Korean            | ko                                                    |
    | Kurdish           | ku                                                    |
    | Kuanyama          | kj                                                    |
    | Latin             | la                                                    |
    | Luxembourgish     | lb                                                    |
    | Ganda             | lg                                                    |
    | Limburgan         | li                                                    |
    | Lingala           | ln                                                    |
    | Lao               | lo                                                    |
    | Lithuanian        | lt                                                    |
    | Luba-Katanga      | lu                                                    |
    | Latvian           | lv                                                    |
    | Manx              | gv                                                    |
    | Macedonian        | mk                                                    |
    | Malagasy          | mg                                                    |
    | Malay             | ms                                                    |
    | Malayalam         | ml                                                    |
    | Maltese           | mt                                                    |
    | Maori             | mi                                                    |
    | Marathi           | mr                                                    |
    | Marshallese       | mh                                                    |
    | Mongolian         | mn                                                    |
    | Nauru             | na                                                    |
    | Navajo            | nv                                                    |
    | North Ndebele     | nd                                                    |
    | Nepali            | ne                                                    |
    | Ndonga            | ng                                                    |
    | Norwegian Bokmal  | nb                                                    |
    | Norwegian Nynorsk | nn                                                    |
    | Norwegian         | no                                                    |
    | Sichuan Yi        | ii                                                    |
    | South Ndebele     | nr                                                    |
    | Occitan           | oc                                                    |
    | Ojibwa            | oj                                                    |
    | Church Slavic     | cu                                                    |
    | Oromo             | om                                                    |
    | Oriya             | or                                                    |
    | Ossetian          | os                                                    |
    | Panjabi           | pa                                                    |
    | Pali              | pi                                                    |
    | Persian           | fa                                                    |
    | Polish            | pl                                                    |
    | Pashto            | ps                                                    |
    | Portuguese        | pt                                                    |
    | Quechua           | qu                                                    |
    | Romansh           | rm                                                    |
    | Rundi             | rn                                                    |
    | Romanian          | ro                                                    |
    | Russian           | ru                                                    |
    | Sanskrit          | sa                                                    |
    | Sardinian         | sc                                                    |
    | Sindhi            | sd                                                    |
    | Northern Sami     | se                                                    |
    | Samoan            | sm                                                    |
    | Sango             | sg                                                    |
    | Serbian           | sr                                                    |
    | Gaelic            | gd                                                    |
    | Shona             | sn                                                    |
    | Sinhala           | si                                                    |
    | Slovak            | sk                                                    |
    | Slovenian         | sl                                                    |
    | Somali            | so                                                    |
    | Southern Sotho    | st                                                    |
    | Spanish           | es                                                    |
    | Sundanese         | su                                                    |
    | Swahili           | sw                                                    |
    | Swati             | ss                                                    |
    | Swedish           | sv                                                    |
    | Tamil             | ta                                                    |
    | Telugu            | te                                                    |
    | Tajik             | tg                                                    |
    | Thai              | th                                                    |
    | Tigrinya          | t1                                                    |
    | Tibetan           | bo                                                    |
    | Turkmen           | tk                                                    |
    | Tagalog           | tl                                                    |
    | Tswana            | tn                                                    |
    | Tonga             | to                                                    |
    | Turkish           | tr                                                    |
    | Tsonga            | ts                                                    |
    | Tatar             | tt                                                    |
    | Twi               | tw                                                    |
    | Tahitian          | ty                                                    |
    | Uighur            | ug                                                    |
    | Ukrainian         | uk                                                    |
    | Urdu              | ur                                                    |
    | Uzbek             | uz                                                    |
    | Venda             | ve                                                    |
    | Vietnamese        | vi                                                    |
    | Volapuk           | vo                                                    |
    | Walloon           | wa                                                    |
    | Welsh             | cy                                                    |
    | Wolof             | wo                                                    |
    | Western Frisian   | fy                                                    |
    | Xhosa             | xh                                                    |
    | Yiddish           | yi                                                    |
    | Yoruba            | yo                                                    |
    | Zhuang            | za                                                    |
    | Zulu              | zu                                                    |
    +-------------------+-------------------------------------------------------+

=head1 KNOWLEDGE GRAPH ENTITY TYPES

The API search the following knowledge graph entity types:

    +---------------------------------------------------------------------------+
    | Book                                                                      |
    | BookSeries                                                                |
    | EducationalOrganization                                                   |
    | Event                                                                     |
    | GovernmentOrganization                                                    |
    | LocalBusiness                                                             |
    | Movie                                                                     |
    | MovieSeries                                                               |
    | MusicAlbum                                                                |
    | MusicGroup                                                                |
    | MusicRecording                                                            |
    | Organization                                                              |
    | Periodical                                                                |
    | Person                                                                    |
    | Place                                                                     |
    | SportsTeam                                                                |
    | TVEpisode                                                                 |
    | TVSeries                                                                  |
    | VideoGame                                                                 |
    | VideoGameSeries                                                           |
    | WebSite                                                                   |
    +---------------------------------------------------------------------------+

=head1 METHODS

=head2 search($query_string)

Get search result L<WWW::Google::KnowledgeGraphSearch::Result>.

    use strict; use warnings;
    use WWW::Google::KnowledgeGraphSearch;

    my $api_key = 'Your_API_Key';
    my $engine  = WWW::Google::KnowledeGraphSearch->new(api_key => $api_key);
    my $result  = $engine->search('Taylor Swift');

    print $result->[0]->id, "\n";
    print $result->[0]->name, "\n";
    print $result->[0]->description, "\n";
    print $result->[0]->descriptionBody, "\n";
    print $result->[0]->resultScore, "\n";

=cut

sub search {
    my ($self, $query, $ids, $types) = @_;
    die "ERROR: Missing query string." unless defined $query;

    my $url = URI->new($BASE_URL);
    my $params = {
        key       => $self->api_key,
        limit     => $self->limit,
        languages => $self->languages,
        query     => $query,
    };

    if (defined $ids) {
        $params->{ids} = $ids;
    }

    if (defined $types) {
        die "ERROR: Invalid entity type $types."
            unless (exists $ENTITY_TYPES->{$types});
        $params->{types} = $types;
    }

    $url->query_form($params);

    my $response = $self->get($url);
    my $contents = from_json($response->{content});

    my $results = [];
    foreach my $result (@{$contents->{itemListElement}}) {
        push @$results, WWW::Google::KnowledgeGraphSearch::Result->new(raw => $result);
    }

    return $results;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-KnowledgeGraphSearch>

=head1 BUGS

Please  report  any bugs or feature requests to C<bug-www-google-knowledgegraphsearch  at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-KnowledgeGraphSearch>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::KnowledgeGraphSearch

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-KnowledgeGraphSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-KnowledgeGraphSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-KnowledgeGraphSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-KnowledgeGraphSearch/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Mohammad S Anwar.

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

1; # End of WWW::Google::KnowledgeGraphSearch
