use strict;
use warnings;

use Test::More;
BEGIN {
    eval {
       require Test::Without::Module;
       Test::Without::Module->import(qw(File::ReadBackwards Data::Dump DBI Statistics::Descriptive));
    };
    if ($@){
        Test::More::plan( skip_all => "Test::Without::Module required for testing module absence" );
    }
}
Test::More::plan( tests =>1 );
use_ok("ToolSet::y", "can load ToolSet::y without other fuzz");
