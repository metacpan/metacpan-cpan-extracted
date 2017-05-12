use strict;
use warnings;

use Test::More;

# rt108500
if ( !$ENV{'RELEASE_TESTING'} ) {

   plan( skip_all => "RELEASE_TESTING not set in environment" );
}

eval {

     require Test::Pod;
};

if ( $@ ) {

   plan( skip_all => "Test::Pod required" );
}

Test::Pod->import();
all_pod_files_ok();
