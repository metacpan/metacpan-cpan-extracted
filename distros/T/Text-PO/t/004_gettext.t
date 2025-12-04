#!perl
BEGIN
{
    use strict;
    use warnings;
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use_ok( 'Text::PO::Gettext' ) || BAIL_OUT( "Cannot load Text::PO::Gettext" );
    use Module::Generic::File qw( cwd file tempfile );
    use POSIX ();
    use I18N::Langinfo qw( langinfo );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
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
is( $po->currentLang, ( ( defined( $ENV{LANGUAGE} ) || defined( $ENV{LANG} ) ) ? [split( /:/, ( $ENV{LANGUAGE} || $ENV{LANG} ) )]->[0] : '' ), 'currentLang' );
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

# XXX Added in v0.1.2 on 2021-07-30
my $old = POSIX::setlocale( &POSIX::LC_ALL );
POSIX::setlocale( &POSIX::LC_ALL, $po->locale );
$rv = $po->getMonthsLong();
isa_ok( $rv, 'Module::Generic::Array', 'getMonthsLong' );
is( $rv->length, 12, 'getMonthsLong() -> array size' );
is( $rv->first, langinfo( &I18N::Langinfo::MON_1 ), 'getMonthsLong() -> first value' );
$rv = $po->getMonthsShort();
isa_ok( $rv, 'Module::Generic::Array', 'getMonthsShort' );
is( $rv->length, 12, 'getMonthsShort() -> array size' );
is( $rv->first, langinfo( &I18N::Langinfo::ABMON_1 ), 'getMonthsShort() -> first value' );
$rv = $po->getDaysLong();
isa_ok( $rv, 'Module::Generic::Array', 'getDaysLong' );
is( $rv->length, 7, 'getDaysLong() -> array size' );
is( $rv->first, langinfo( &I18N::Langinfo::DAY_1 ), 'getDaysLong() -> first value' );
$rv = $po->getDaysLong( monday_first => 1 );
isa_ok( $rv, 'Module::Generic::Array', 'getDaysLong( monday_first => 1 )' );
is( $rv->length, 7, 'getDaysLong( monday_first => 1 ) -> array size' );
is( $rv->first, langinfo( &I18N::Langinfo::DAY_2 ), 'getDaysLong( monday_first => 1 ) -> first value' );
$rv = $po->getDaysShort();
isa_ok( $rv, 'Module::Generic::Array', 'getDaysShort' );
is( $rv->length, 7, 'getDaysShort() -> array size' );
is( $rv->first, langinfo( &I18N::Langinfo::ABDAY_1 ), 'getDaysShort() -> first value' );
$rv = $po->getDaysShort( monday_first => 1 );
isa_ok( $rv, 'Module::Generic::Array', 'getDaysShort( monday_first => 1 )' );
is( $rv->length, 7, 'getDaysShort( monday_first => 1 ) -> array size' );
is( $rv->first, langinfo( &I18N::Langinfo::ABDAY_2 ), 'getDaysShort( monday_first => 1 ) -> first value' );
$rv = $po->getNumericDict();
isa_ok( $rv, 'Module::Generic::Hash', 'getNumericDict() returns an Module::Generic::Hash object' );
is( $rv->length, 6, 'getNumericDict() returns 6 properties' );
is( $rv->keys->sort->join( ',' )->scalar, 'currency,decimal,int_currency,negative_sign,precision,thousand', 'getNumericDict() properties' );
is( $po->locale, 'fr_FR', 'locale' );
my $lconv = POSIX::localeconv();
# €
$lconv->{currency_symbol} = '€' if( $lconv->{currency_symbol} eq 'EUR' );
is( $rv->{currency}, $lconv->{currency_symbol}, 'getNumericDict() -> currency' );
# ,
is( $rv->{decimal}, $lconv->{decimal_point}, 'getNumericDict() -> decimal' );
is( $rv->{int_currency}, $lconv->{int_curr_symbol}, 'getNumericDict() -> int_currency' );
is( $rv->{negative_sign}, $lconv->{negative_sign}, 'getNumericDict() -> negative_sign' );
is( $rv->{precision}, $lconv->{frac_digits}, 'getNumericDict() -> precision' );
is( $rv->{thousand}, $lconv->{thousands_sep}, 'getNumericDict() -> thousand' );
$rv = $po->getNumericPosixDict();
isa_ok( $rv, 'Module::Generic::Hash', 'getNumericPosixDict() returns an Module::Generic::Hash object' );
# is( $rv->length, 23, 'getNumericPosixDict returns 23 properties' );
$lconv->{ $_ } = unpack( "C*", $lconv->{ $_ } ) for( qw( grouping mon_grouping ) );
POSIX::setlocale( &POSIX::LC_ALL, $old );
foreach my $k ( sort( keys( %$lconv ) ) )
{
    is( $rv->{ $k }, $lconv->{ $k }, "getNumericPosixDict() -> $k" );
}

done_testing();



