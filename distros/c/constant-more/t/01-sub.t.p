use strict;
use warnings;

use feature qw<say state>;

use constant::more {
        VERBOSE=>{
                opt=>"test_option=s",
                sub=>sub {
                        state $i=0;
                        ($_[0].$i++, $_[1]);
                }
        }
};

say test_option1||0;
say test_option2||0;
say "$_" for @ARGV;
