use inc::Module::Install 1.06;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/XML/RSS/JavaScript.pm > README' );
}

perl_version '5.006';

name 'XML-RSS-JavaScript';
all_from 'lib/XML/RSS/JavaScript.pm';
no_index directory => 'css';

requires 'XML::RSS' => '1.31';

test_requires 'Test::More';

repository "http://github.com/bricas/xml-rss-javascript";

WriteAll;
