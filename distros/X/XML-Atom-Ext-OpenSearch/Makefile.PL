use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/XML/Atom/Ext/OpenSearch.pm > README' );
}

perl_version '5.008';

name 'XML-Atom-Ext-OpenSearch';
all_from 'lib/XML/Atom/Ext/OpenSearch.pm';

requires 'XML::Atom' => '0.28';

test_requires 'Test::More';
extra_tests;

repository "http://github.com/bricas/xml-atom-ext-opensearch";

WriteAll;
