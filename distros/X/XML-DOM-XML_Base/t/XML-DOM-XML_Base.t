# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-DOM-XML_Base.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('XML::DOM::XML_Base') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok( my $parser = XML::DOM::Parser->new() );

my $xml = qq(
  <ecto x="1" xml:base="a/">
    <meso x="2" xml:base="b/">
      <endo x="3" xml:base="c/"/>
    </meso>
  </ecto>
);

ok( my $dom = $parser->parse( $xml ) );

# get some elements
ok( my $endo = $dom->getElementsByTagName( 'endo' )->item( 0 ) );
ok( my $meso = $dom->getElementsByTagName( 'meso' )->item( 0 ) );
ok( my $ecto = $dom->getElementsByTagName( 'ecto' )->item( 0 ) );

ok( $endo->getBase() eq 'a/b/c/' );
ok( $meso->getBase() eq 'a/b/' );
ok( $ecto->getBase() eq 'a/' );

ok( $endo->getAttributeWithBase( 'x' ) eq 'a/b/c/3' );
ok( $meso->getAttributeWithBase( 'x' ) eq 'a/b/2' );
ok( $ecto->getAttributeWithBase( 'x' ) eq 'a/1' );
