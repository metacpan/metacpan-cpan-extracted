#!perl -T
use 5.006                   ;
use strict                  ;
use warnings FATAL => 'all' ;
use Test::More              ;

use XML::Smart              ;  


my @xml = <DATA>            ;
my $xml = join( '', @xml )  ;

subtest 'Copy' => sub {

    my $xml_ob      = XML::Smart->new( $xml ) ;
    my $xml_ob_copy = $xml_ob->copy() ;

    cmp_ok( $xml_ob->nodes_keys, 'eq', $xml_ob_copy->nodes_keys, 'Basic Copy Test' );

    $xml_ob = $xml_ob->{ test };
    $xml_ob_copy = $xml_ob->copy() ;

    cmp_ok( $xml_ob->nodes_keys, 'eq', $xml_ob_copy->nodes_keys, 'Stepped Copy Test' );

    done_testing() ;

};

done_testing() ;


__DATA__
<test>
   <entry name="test1"/>
   <entry name="test2"/>
</test>
