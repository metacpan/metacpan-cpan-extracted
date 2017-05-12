use strict;
use warnings;
use lib '../lib';
use Benchmark qw(:all) ;

timethese(500000, {
    'TryCatch' => sub {
        TEST::TryCatch::test();
    },

    'Try::Catch' => sub {
        TEST::Try::Catch::test();
    },
    
    'Try::Tiny' => sub {
        TEST::Try::Tiny::test();
    }
});


package TEST::TryCatch; {
    use TryCatch;
    sub test {
        try {
            # die "Try::Catch";
        } catch ($e){
            if ($e eq "n"){

            }
        }; 
    }
}

package TEST::Try::Catch; {
    use Try::Catch;
    sub test {
        try {
            # die "Try::Catch";
        } catch {
            if ($_ eq "n"){

            }
        };
    }
}

package TEST::Try::Tiny; {
    use Try::Tiny;
    sub test {
        try {
            # die "Try::Tiny";
        } catch {
            if ($_ eq "n"){

            }
        };
    }
}

1;
