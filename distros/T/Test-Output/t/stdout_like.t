use Test::Tester;
use Test::More tests => 42;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/i;
check_test( sub {
            stdout_like(sub {
                        print "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDOUT'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            stdout_like(sub {
                        print "TEST OUT\n";
                      },
                      'OUT',
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'stdout_like',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stdout_like(sub {
                        print "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT:\nTEST OUT\n\ndoesn't match:\n$regex\nas expected\n",
            },'STDOUT not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/i;
check_test( sub {
            stdout_like {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT matching success'
          );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            stdout_like {
                        print "TEST OUT\n";
                      }
                      'OUT',
                      'Testing STDOUT'
            },{
              ok => 0,
              depth => 2,
              name => 'stdout_like',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stdout_like {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT:\nTEST OUT\n\ndoesn't match:\n$regex\nas expected\n",
            },'STDOUT not matching failure'
          );
}
