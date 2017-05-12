use Test::Tester;
use Test::More tests => 49;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            combined_unlike(sub {
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
{
my $regex = qr/err/;
check_test( sub {
            combined_unlike(sub {
                        print "TEST OUT\n";
                        print "TEST ERR\n";
                      },
                      $regex,
                      'Testing STDERR'
                    )
            },{
              ok => 1,
              name => 'Testing STDERR',
              diag => '',
            },'STDERR not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            combined_unlike(sub {
                        print "TEST OUT\n";
                      },
                      'OUT',
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'combined_unlike',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/;
check_test( sub {
            combined_unlike(sub {
                        print "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT & STDERR:\nTEST OUT\n\nmatching:\n$regex\nnot expected\n",
            },'STDOUT matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            combined_unlike {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 1,
              name => 'Testing STDOUT',
              diag => '',
            },'codeblock STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            combined_unlike {
                        print "TEST OUT\n";
                      }
                      'OUT',
                      'Testing STDOUT'
            },{
              ok => 0,
              depth => 2,
              name => 'combined_unlike',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'codeblock bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/;
check_test( sub {
            combined_unlike {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT & STDERR:\nTEST OUT\n\nmatching:\n$regex\nnot expected\n",
            },'codeblock STDOUT matching failure'
          );
}
