use strict;
use warnings;
use English;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg =
'Author test. Set the environment variable TEST_AUTHOR to enable this test.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Spelling required to check spelling of POD';
    plan( skip_all => $msg );
}

Test::Spelling::add_stopwords(<DATA>);
Test::Spelling::all_pod_files_spelling_ok();
__DATA__
API
CGI
DateTime
DummyServer.pl
Ipenburg
JSON
NOS
PHP
RT
Readonly
TestNOSOpen
URI
apikey
cpan
org
pl
rt
