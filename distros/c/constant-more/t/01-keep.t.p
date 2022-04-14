use strict;
use warnings;

use feature "say";

use constant::more {
        VERBOSE=>{
                opt=>"test_option=s",
                keep=>1
        }
};

say VERBOSE||0;
say "$_" for @ARGV;
