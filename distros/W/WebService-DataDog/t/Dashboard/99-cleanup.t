#!perl -T

use strict;
use warnings;

use Test::Most 'bail',  tests => 2;

SKIP:
{
	skip( 'Temporary dashboard id file (deprecated version) does not exist.', 1 )
		if ! -e 'webservice-datadog-dashboard-dashid-deprecated.tmp';

	ok(
		unlink( 'webservice-datadog-dashboard-dashid-deprecated.tmp' ),
		'Remove temporary dashboard id file - deprecated version',
	);
}

SKIP:                                                                           
{                                                                               
  skip( 'Temporary dashboard id file does not exist.', 1 )                      
    if ! -e 'webservice-datadog-dashboard-dashid.tmp';                          
                                                                                
  ok(                                                                           
    unlink( 'webservice-datadog-dashboard-dashid.tmp' ),                        
    'Remove temporary dashboard id file',                                       
  );                                                                            
}

