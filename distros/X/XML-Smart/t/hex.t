#!perl -T
use 5.006                   ;
use strict                  ;
use warnings FATAL => 'all' ;
use Test::More              ;

use XML::Smart              ;  


subtest 'Raw Binary Data' => sub {

    my $bin_data_string = '‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ' ;
    my @bin_data = split( //, $bin_data_string ) ;
    foreach my $bin_elem ( @bin_data ) { 
	cmp_ok( XML::Smart::_data_type( $bin_elem ), '==', 4, 'RawBinData: ' . "0x" . unpack("H*", $bin_elem ) );
    }

    done_testing() ;
};

subtest 'Raw Binary Data Unimplemented' => sub { 

    
    my @bin_data = (     
	0x80, 0x81, 0x8d, 0x8f, 0x90, 0xa0 
	);
    
    foreach my $bin_elem ( @bin_data ) { 
	my $bin_elem_converted = pack("H*", $bin_elem );
	cmp_ok( XML::Smart::_data_type( $bin_elem ), '==', 1, 'RawBinData Unimplemented: ' . "0x" . $bin_elem );
    }

    done_testing() ;

};

done_testing() ;

