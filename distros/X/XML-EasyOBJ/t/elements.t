
use strict;
use Test;
use XML::EasyOBJ;
use FindBin qw/$Bin/;

BEGIN { plan tests => 7 }

ok( my $doc = XML::EasyOBJ->new( "$Bin/read.xml" ) );
ok( my @maps = $doc->MAP, 6 );

ok( my @elements = $doc->MAP(0)->KINGDOM(0)->getElement(), 6 );
ok( $doc->MAP(0)->KINGDOM(0)->getElement()->getTagName, 'PLAYER' );
ok( $doc->MAP(0)->KINGDOM(0)->getElement('',2)->getTagName, 'RELIGION' );

my $list = '';
for ( @elements ) {
    $list .= $_->getTagName;
}

ok( $list, 'PLAYERNAMERELIGIONRULERDIPLOMACYNOTES' );
ok( ! $doc->MAP(0)->KINGDOM(0)->getElement('',6) );

