#!perl
BEGIN
{
    use strict;
    use warnings;
    use open ':std' => ':utf8';
    use Test::More qw( no_plan );
    use_ok( 'Text::PO::Gettext' ) || BAIL_OUT( "Cannot load Text::PO::Gettext" );
    use Module::Generic::File qw( cwd file tempfile );
    our $DEBUG = 0;
};

use utf8;
my $cwd = cwd();
my $path = $cwd->join( $cwd, 't' );

# category is implicitly LC_MESSAGES
my $po = Text::PO::Gettext->new(
    debug   => $DEBUG,
    domain  => 'com.example.api',
    locale  => 'fr_FR',
    path    => $path,
);
isa_ok( $po, 'Text::PO::Gettext', 'Text::PO::Gettext object instantiated' );
diag( Text::PO::Gettext->error ) if( !defined( $po ) );
is( $po->charset, 'utf-8', 'charset' );
is( $po->contentEncoding, '8bit', 'contentEncoding' );
is( $po->contentType, 'text/plain; charset=utf-8', 'contentType' );
is( $po->currentLang, ( $ENV{LANGUAGE} || $ENV{LANG} ), 'currentLang' );
is( $po->dgettext( 'com.example.api', 'Bad Request' ), 'Mauvaise requête', 'dgettext' );
is( $po->dngettext( 'com.example.api', 'You have %d message', 'You have %d messages', 1 ), 'Vous avez %d message', 'dngettext with count of 1' );
is( $po->dngettext( 'com.example.api', 'You have %d message', 'You have %d messages', 2 ), 'Vous avez %d messages', 'dngettext with count of 2' );
is( $po->domain, 'com.example.api', 'domain' );
ok( $po->exists( 'fr_FR' ), 'exists -> fr_FR' );

my $po_ja = Text::PO::Gettext->new(
    debug   => $DEBUG,
    domain  => 'com.example.api',
    locale  => 'ja_JP',
    path    => $path,
    # accepts json po file
    use_json=> 1,
);
isa_ok( $po_ja, 'Text::PO::Gettext', 'Text::PO::Gettext object instantiated' );

ok( $po->exists( 'ja-JP' ), 'exists -> ja-JP' );
my $rv = $po->fetchLocale( 'Bad Request' );
isa_ok( $rv, 'Module::Generic::Array', 'fetchLocale' );
ok( $rv->length == 2, 'fetchLocale -> array length' );
is( $po->getDataPath(), undef, 'getDataPath -> undef' );
{
    my $domain_path = $cwd->join( $cwd, 't' );
    local $ENV{TEXTDOMAINDIR} = $domain_path;
    is( $po->getDataPath(), $domain_path, "getDataPath -> $domain_path" );
}
$rv = $po->getDomainHash({ domain => 'com.example.api', locale => 'fr_FR' });
is( ref( $rv ), 'HASH', 'getDomainHash returned data type' );
is( $po->getLangDataPath(), undef, 'getLangDataPath -> undef' );
{
    my $locale_path = $cwd->join( $cwd, qw( t fr_FR ) );
    local $ENV{TEXTLOCALEDIR} = $locale_path;
    is( $po->getLangDataPath(), $locale_path, "getLangDataPath -> $locale_path" );
}
$rv = $po->getLanguageDict( 'ja_JP' );
is( ref( $rv ), 'HASH', 'getLanguageDict' );
is( $po->getLanguageDict( 'fr_BE' ), undef, 'getLanguageDict(fr_BE) -> fail' );
is( $po->getLocale(), 'fr_FR', 'getLocale' );
is( $po->getLocales( 'Bad Request' ), "<span lang=\"fr-FR\">Mauvaise requête</span>\n<span lang=\"ja-JP\">不正リクエスト</span>", 'getLocales' );
is( $po->getLocalesf( 'Unknown properties: %s', 'pouec' ), "<span lang=\"fr-FR\">Propriété inconnue: pouec</span>\n<span lang=\"ja-JP\">不明プロパティ：pouec</span>", 'getLocalesf' );
$rv = $po->getMetaKeys();
isa_ok( $rv, 'Module::Generic::Array', 'getMetaKeys returned value' );
is( $rv->length, 11, 'getMetaKeys returned array size' );
is( $po->getMetaValue( 'last_translator' ), 'John Doe <john.doe@example.com>', 'getMetaValue' );
is( $po->getText( 'Internal Server Error' ), 'Erreur interne de serveur', 'getText' );
is( $po->getTextf( 'Unknown properties: %s', 'pouec' ), 'Propriété inconnue: pouec', 'getTextf' );
is( $po->gettext( 'Bad Request' ), 'Mauvaise requête', 'gettext' );
ok( $po->isSupportedLanguage( 'ja-JP' ), 'isSupportedLanguage' );
is( $po->language, 'fr_FR', 'language' );
is( $po->languageTeam, 'French <john.doe@example.com>', 'languageTeam' );
is( $po->lastTranslator, 'John Doe <john.doe@example.com>', 'lastTranslator' );
is( $po->mimeVersion, '1.0', 'mimeVersion' );
is( $po->locale, 'fr_FR', 'locale' );
is( $po->locale_unix( 'fr-FR.utf-8' ), 'fr_FR.utf-8', 'locale_unix(fr-FR.utf-8) -> fr_FR.utf-8' );
is( $po->locale_unix( 'fr_FR.utf-8' ), 'fr_FR.utf-8', 'locale_unix(fr_FR.utf-8) -> fr_FR.utf-8' );
is( $po->locale_unix( 'fr.utf-8' ), 'fr.utf-8', 'locale_unix(fr.utf-8) -> fr.utf-8' );
is( $po->locale_unix( 'fr' ), 'fr', 'locale_unix(fr) -> fr' );
is( $po->locale_web( 'fr-FR.utf-8' ), 'fr-FR.utf-8', 'locale_web(fr-FR.utf-8) -> fr-FR.utf-8' );
is( $po->locale_web( 'fr_FR.utf-8' ), 'fr-FR.utf-8', 'locale_web(fr_FR.utf-8) -> fr-FR.utf-8' );
is( $po->locale_web( 'fr.utf-8' ), 'fr.utf-8', 'locale_web(fr.utf-8) -> fr.utf-8' );
is( $po->locale_web( 'fr' ), 'fr', 'locale_web(fr) -> fr' );
is( $po->ngettext( 'You have %d message', 'You have %d messages', 1 ), 'Vous avez %d message', 'ngettext with count of 1' );
is( $po->ngettext( 'You have %d message', 'You have %d messages', 2 ), 'Vous avez %d messages', 'ngettext with count of 2' );
is( $po->path, $path, 'path' );
$rv = $po->plural;
isa_ok( $rv, 'Module::Generic::Array', 'plural returned value' );
is( $rv->length, 2, 'plural returned array size' );
is( $rv->first, 1, 'plural array first entry' );
is( $rv->last, 'n>1', 'plural array second entry' );
is( $po->pluralForms, 'nplurals=1; plural=n>1;', 'pluralForms' );
$rv = $po->po_object;
isa_ok( $rv, 'Text::PO', 'po_object' );
$rv = $po->poRevisionDate;
isa_ok( $rv, 'DateTime', 'poRevisionDate returns a DateTime object' );
is( "$rv", '2019-10-03 19-44+0000', 'poRevisionDate' );
$rv = $po->potCreationDate;
isa_ok( $rv, 'DateTime', 'potCreationDate returns a DateTime object' );
is( "$rv", '2019-10-03 19-44+0000', 'potCreationDate' );
is( $po->projectIdVersion, 'MyProject 0.1', 'projectIdVersion' );
is( $po->reportBugsTo, 'john.doe@example.com', 'reportBugsTo' );

done_testing();



