package WebService::DetectLanguage::Language;
$WebService::DetectLanguage::Language::VERSION = '0.04';
use 5.006;
use Moo;

has code => ( is => 'ro' );
has name => ( is => 'lazy' );

my %code2name = (
           aa => "AFAR",
           ab => "ABKHAZIAN",
           af => "AFRIKAANS",
           ak => "AKAN",
           am => "AMHARIC",
           ar => "ARABIC",
           as => "ASSAMESE",
           ay => "AYMARA",
           az => "AZERBAIJANI",
           ba => "BASHKIR",
           be => "BELARUSIAN",
           bg => "BULGARIAN",
           bh => "BIHARI",
           bi => "BISLAMA",
           bn => "BENGALI",
           bo => "TIBETAN",
           br => "BRETON",
           bs => "BOSNIAN",
          bug => "BUGINESE",
           ca => "CATALAN",
          ceb => "CEBUANO",
          chr => "CHEROKEE",
           co => "CORSICAN",
          crs => "SESELWA",
           cs => "CZECH",
           cy => "WELSH",
           da => "DANISH",
           de => "GERMAN",
           dv => "DHIVEHI",
           dz => "DZONGKHA",
          egy => "EGYPTIAN",
           el => "GREEK",
           en => "ENGLISH",
           eo => "ESPERANTO",
           es => "SPANISH",
           et => "ESTONIAN",
           eu => "BASQUE",
           fa => "PERSIAN",
           fi => "FINNISH",
           fj => "FIJIAN",
           fo => "FAROESE",
           fr => "FRENCH",
           fy => "FRISIAN",
           ga => "IRISH",
           gd => "SCOTS_GAELIC",
           gl => "GALICIAN",
           gn => "GUARANI",
          got => "GOTHIC",
           gu => "GUJARATI",
           gv => "MANX",
           ha => "HAUSA",
          haw => "HAWAIIAN",
           hi => "HINDI",
          hmn => "HMONG",
           hr => "CROATIAN",
           ht => "HAITIAN_CREOLE",
           hu => "HUNGARIAN",
           hy => "ARMENIAN",
           ia => "INTERLINGUA",
           id => "INDONESIAN",
           ie => "INTERLINGUE",
           ig => "IGBO",
           ik => "INUPIAK",
           is => "ICELANDIC",
           it => "ITALIAN",
           iu => "INUKTITUT",
           iw => "HEBREW",
           ja => "JAPANESE",
           jw => "JAVANESE",
           ka => "GEORGIAN",
          kha => "KHASI",
           kk => "KAZAKH",
           kl => "GREENLANDIC",
           km => "KHMER",
           kn => "KANNADA",
           ko => "KOREAN",
           ks => "KASHMIRI",
           ku => "KURDISH",
           ky => "KYRGYZ",
           la => "LATIN",
           lb => "LUXEMBOURGISH",
           lg => "GANDA",
           lif => "LIMBU",
           ln => "LINGALA",
           lo => "LAOTHIAN",
           lt => "LITHUANIAN",
           lv => "LATVIAN",
          mfe => "MAURITIAN_CREOLE",
           mg => "MALAGASY",
           mi => "MAORI",
           mk => "MACEDONIAN",
           ml => "MALAYALAM",
           mn => "MONGOLIAN",
           mr => "MARATHI",
           ms => "MALAY",
           mt => "MALTESE",
           my => "BURMESE",
           na => "NAURU",
           ne => "NEPALI",
           nl => "DUTCH",
           no => "NORWEGIAN",
           nr => "NDEBELE",
          nso => "PEDI",
           ny => "NYANJA",
           oc => "OCCITAN",
           om => "OROMO",
           or => "ORIYA",
           pa => "PUNJABI",
           pl => "POLISH",
           ps => "PASHTO",
           pt => "PORTUGUESE",
           qu => "QUECHUA",
           rm => "RHAETO_ROMANCE",
           rn => "RUNDI",
           ro => "ROMANIAN",
           ru => "RUSSIAN",
           rw => "KINYARWANDA",
           sa => "SANSKRIT",
          sco => "SCOTS",
           sd => "SINDHI",
           sg => "SANGO",
           si => "SINHALESE",
           sk => "SLOVAK",
           sl => "SLOVENIAN",
           sm => "SAMOAN",
           sn => "SHONA",
           so => "SOMALI",
           sq => "ALBANIAN",
           sr => "SERBIAN",
           ss => "SISWANT",
           st => "SESOTHO",
           su => "SUNDANESE",
           sv => "SWEDISH",
           sw => "SWAHILI",
          syr => "SYRIAC",
           ta => "TAMIL",
           te => "TELUGU",
           tg => "TAJIK",
           th => "THAI",
           ti => "TIGRINYA",
           tk => "TURKMEN",
           tl => "TAGALOG",
          tlh => "KLINGON",
           tn => "TSWANA",
           to => "TONGA",
           tr => "TURKISH",
           ts => "TSONGA",
           tt => "TATAR",
           ug => "UIGHUR",
           uk => "UKRAINIAN",
           ur => "URDU",
           uz => "UZBEK",
           ve => "VENDA",
           vi => "VIETNAMESE",
           vo => "VOLAPUK",
          war => "WARAY_PHILIPPINES",
           wo => "WOLOF",
           xh => "XHOSA",
           yi => "YIDDISH",
           yo => "YORUBA",
           za => "ZHUANG",
           zh => "CHINESE_SIMPLIFIED",
    "zh-Hant" => "CHINESE_TRADITIONAL",
           zu => "ZULU",

);

sub _build_name
{
    my $self = shift;

    return $code2name{ $self->code } // "UNKNOWN";
}

1;

=head1 NAME

WebService::DetectLanguage::Language - a data object holding language code and name

=head1 SYNOPSIS

 my @languages = $api->languages();
 foreach my $lang (@languages) {
     printf "code=%s  name=%s\n", $lang->code, $lang->name;
 }

=head1 DESCRIPTION

This module is a class for language information returned
by the C<detect()>, C<multi_detect()>, or C<languages()> methods
of L<WebService::DetectLanguage>.

See the documentation of that module for more details.


=head1 ATTRIBUTES

=head2 code

A short code identifying the language.
Most of these are two letters (for example "tl" for Tagalog),
but some are three letters (for example "chr" for Cherokee),
and at the time of writing there is one other: "zh-Hant" is the code for Traditional Chinese.

=head2 name

The name of the language.
Names are all in upper case, and have underscores rather than spaces.


=head1 SEE ALSO

L<WebService::DetectLanguage> the main module for talking
to the language detection API at detectlanguage.com.

L<https://detectlanguage.com/languages> is a list of all the
languages supported by the API, giving both code and name.

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

