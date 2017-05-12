use strict;
use warnings;
use Test::More;

plan   eval { require Apache::AxKit::Provider }
     ? ( tests => 1 )
     : ( skip_all => "AxKit needed" )
     ;

require_ok( 'Apache::AxKit::Language::YPathScript' );
