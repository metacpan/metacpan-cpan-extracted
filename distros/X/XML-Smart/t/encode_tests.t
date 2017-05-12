use strict                ;
use warnings              ;

use Test::More            ;

use XML::Smart            ;

use open ':encoding(utf8)';

our $directory = 'data_for_tests';

opendir ( my $_data_dir, $directory) or die $!;

while (my $file = readdir( $_data_dir ) ) {

    next if( $file eq '.'    ) ;
    next if( $file eq '..'   ) ;
    next if( $file =~ '.svn' ) ;
    next if( $file =~ /^bug/ ) ;

    subtest "Testing inclusion of data into xml $file" => sub {
    	_test_data_from( $file ) ;
    	done_testing()           ;
    };

    subtest "Testing embed of data into xml $file"     => sub {
	_test_embed_from( $file ) ;
	done_testing()           ;
    }
}

done_testing() ;


####################################################################################################
##                                      Helper Functions                                          ##
####################################################################################################


sub _test_embed_from { 

    my $infile = shift ;
    
    $infile    = $directory . "/" . $infile    ;

    open( my $_infile, $infile ) or die ( $! ) ;
    my @in_data = <$_infile>            ;
    my $in_data = join( "", @in_data )  ;
    close( $_infile )                          ;

    my $xml_input = '
<subject_list>
        <subject>' . $in_data . '
</subject>
</subject_list>
';

    my $xml_obj = new XML::Smart( $xml_input ) ;

    my $data = $xml_obj->data(
	'decode'    => 1 ,
	'noheader'  => 1 ,
	) ;

    $data =~ s/\n//gs;
    $data =~ s/\s+/ /gs;

    $xml_input =~ s/\n//gs;
    $xml_input =~ s/\s+/ /gs;
    
    cmp_ok( $data, 'eq', $xml_input ) ;

}


sub _test_data_from { 


    my $infile = shift ;
    
    $infile    = $directory . "/" . $infile    ;

    open( my $_infile, $infile ) or die ( $! ) ;
    my @in_data = <$_infile>            ;
    my $in_data = join( "", @in_data )  ;
    close( $_infile )                          ;


    my @utf8_array = ( $in_data, "GOOD DATA" ) ;
    my $utf8       = \@utf8_array              ;

    my $response_xml                        ;
    my $xml_obj         = XML::Smart->new() ;


    eval{
	$xml_obj->{ response }{ data } = $utf8 ;
    };
    if( $@ ){
	fail( "Hash Creation Error $@" ) ;
    }
    eval{
	$response_xml = $xml_obj->data()       ;
    };
    if( $@ ){
	fail( "XML Creation Error $@" )  ;
    }


    my $post_xml_data    = _get_data_from_xml( $response_xml )                    ;
    my $post_xml_in_data = $post_xml_data->{ response }{ data }->[0]->{ CONTENT } ;

    cmp_ok( $post_xml_in_data, 'eq', $in_data ) ;

    return 1 ;

}

sub _get_data_from_xml {
    
    my $xml = shift ;
    
    
    my $data_obj  ;
    
    eval {
        $data_obj = XML::Smart->new( $xml );
    };
    
    if( $@ ) {
        $xml =~ s/[^[:print:]]+//g         ;
        $data_obj = XML::Smart->new( $xml );
    }
    
    my $data_hash = $data_obj->tree();
    
    return $data_hash;
    
}

