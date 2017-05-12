use strict;
use warnings;
use Test::More;

plan   eval { require Apache2::TomKit::Processor::AbstractProcessor } 
     ? ( tests => 1 )
     : ( skip_all => "TomKit needed" )
     ;

require_ok( 'Apache2::TomKit::Processor::XPathScript' );
