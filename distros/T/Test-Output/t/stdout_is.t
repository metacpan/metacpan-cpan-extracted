use Test::Tester;
use Test::More tests => 35;
use Test::Output;

use strict;
use warnings;

check_test( sub {
            stdout_is(sub {
                        print "TEST OUT\n";
                      },
                      "TEST OUT\n",
                      'Testing STDOUT'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT matches success'
          );

check_test( sub {
            stdout_is(sub {
                        print "TEST", " ", "OUT", "\n";
                      },
                      "TEST OUT\n",
                      'Testing STDOUT'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT matches success'
          );

check_test( sub {
            stdout_is(sub {
                        local $, = " ";
                        print "TEST", "OUT\n";
                      },
                      "TEST OUT\n",
                      'Testing STDOUT'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT matches success'
          );

check_test( sub {
            stdout_is(sub {
                        printf("TEST OUT - %d\n",42);
                      },
                      "TEST OUT - 42\n",
                      'Testing STDOUT printf'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT printf',
              diag => '',
            },'STDOUT printf matches success'
          );

check_test( sub {
            stdout_is(sub {
                        print "TEST OUT";
                      },
                      "TEST OUT STDOUT",
                      'Testing STDOUT failure'
                    )
            }, {
              ok => 0,
              name => 'Testing STDOUT failure',
              diag => "STDOUT is:\nTEST OUT\nnot:\nTEST OUT STDOUT\nas expected\n",
            },'STDOUT not matching failure'
          );

__END__

# This doesn't work yet
SKIP: {
skip 'Perl 5.10 required for this test', 7 unless $] >= 5.010;
BEGIN { eval "use feature qw(say)" if $] >= 5.010 };

check_test( sub {
            stdout_is { 
                        eval 'say( "TEST OUT" );';
                      }
                      "TEST OUT\n",
                      'Testing STDOUT'
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT matches success'
          );
};
