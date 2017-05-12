use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/WebService/Lucene.pm > README' );
}

name 'WebService-Lucene';
perl_version '5.008001';
all_from 'lib/WebService/Lucene.pm';

requires 'Class::Accessor';
requires 'Data::Page';
requires 'Digest::SHA1'; # for XML::Atom::Client
requires 'Encode';
requires 'Exception::Class';
requires 'Scalar::Util';
requires 'URI';
requires 'WWW::OpenSearch' => '0.11';    # uses URI::Template
requires 'XML::Atom'       => '0.25';    # fixes memleak
requires 'XML::LibXML';

test_requires 'Test::More';

WriteAll;
