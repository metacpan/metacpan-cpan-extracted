use strict;
use warnings;

use feature "say";

use constant::more {
        VERBOSE=>{
                opt=>"test_option=s",
        }
};

say VERBOSE||0;
say "$_" for @ARGV;
