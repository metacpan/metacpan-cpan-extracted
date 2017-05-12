use inc::Module::Install 1.00;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/WWW/OpenSearch.pm > README' );
}

perl_version '5.008001';

name 'WWW-OpenSearch';
all_from 'lib/WWW/OpenSearch.pm';

# handle broken LWP 5.810
my $broken_lwp = eval { require LWP; LWP->VERSION eq '5.810'; };

requires 'Data::Page'  => 2.00;
requires 'LWP'         => ( $broken_lwp ? '5.811' : '5.60' );
requires 'XML::Feed'   => 0.08;
requires 'XML::LibXML' => 1.58;
requires 'Encode';
requires 'URI';
requires 'URI::Template';

test_requires 'Test::More';

repository 'http://github.com/bricas/www-opensearch';

WriteAll;
