# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use XML::GDOME;

use constant TEST_STRING_GER => "Hänsel und Gretel";
use constant TEST_STRING_GER2 => "täst";
use constant TEST_STRING_UTF => 'test';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

ok( ELEMENT_NODE, 1 );

# encoding();

ok( decodeFromUTF8('iso-8859-1',
                   encodeToUTF8('iso-8859-1',
                                TEST_STRING_GER2 ) ),
    TEST_STRING_GER2 );


ok( decodeFromUTF8( 'UTF-8' ,
                     encodeToUTF8('UTF-8', TEST_STRING_UTF ) ),
    TEST_STRING_UTF );



eval {
    my $str = encodeToUTF8( "EUC-JP" ,"Föö" );
};
ok( length( $@ ) );
