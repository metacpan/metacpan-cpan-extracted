use Test::Tester;
use Test::More tests => 42;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stdout_unlike(sub {
                        print "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDOUT'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            stdout_unlike(sub {
                        print "TEST OUT\n";
                      },
                      'OUT',
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'stdout_unlike',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/(?-xism:OUT)/;
check_test( sub {
            stdout_unlike(sub {
                        print "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT:\nTEST OUT\n\nmatches:\n$regex\nnot expected\n",
            },'STDOUT matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stdout_unlike {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            stdout_unlike {
                        print "TEST OUT\n";
                      }
                      'OUT',
                      'Testing STDOUT'
            },{
              ok => 0,
              depth => 2,
              name => 'stdout_unlike',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/;
check_test( sub {
            stdout_unlike {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT:\nTEST OUT\n\nmatches:\n$regex\nnot expected\n",
            },'STDOUT matching failure'
          );
}
