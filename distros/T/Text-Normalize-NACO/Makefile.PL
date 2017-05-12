use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Text/Normalize/NACO.pm > README' );
}

perl_version '5.008';    # need 5.008 for unicode

name 'Text-Normalize-NACO';
all_from 'lib/Text/Normalize/NACO.pm';

requires 'Text::Unidecode';

test_requires 'Test::More';

repository "http://github.com/bricas/text-normalize-naco/tree/master";

WriteAll;
