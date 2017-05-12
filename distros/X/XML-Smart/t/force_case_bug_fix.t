#!perl -T
use 5.006                   ;
use strict                  ;
use warnings FATAL => 'all' ;
use Test::More              ;

use XML::Smart              ;  


my @xml = <DATA>            ;
my $xml = join( '', @xml )  ;

subtest 'Force case' => sub {

    my $XML1 = new XML::Smart ( $xml,
				lowarg => 1,
				lowtag => 1,
	); 

    my $XML2 = new XML::Smart ( $xml,
				lowarg => 1,
				lowtag => 1,
	); 

    my $data = $XML1->tree()->{ note }{ to }{ CONTENT } ;

    cmp_ok( $data, 'eq', 'Tove', 'Force to downcase: bug id 17834' );
    done_testing() ;

};

done_testing() ;


__DATA__
<note>
    <TO>Tove</TO>
    <from>Jani</from>
    <heading>Reminder</heading>
    <BODY>Don't forget me this weekend!</BODY>
</note>
