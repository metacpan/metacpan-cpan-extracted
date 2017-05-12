use Test::Tester;
use Test::More tests => 49;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/i;
check_test( sub {
            combined_like(sub {
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
{
my $regex = qr/ERR/i;
check_test( sub {
            combined_like(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex,
                      'Testing STDERR'
                    )
            },{
              ok => 1,
              name => 'Testing STDERR',
              diag => '',
            },'STDERR matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            combined_like(sub {
                        print "TEST OUT\n";
                      },
                      'OUT',
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'combined_like',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            combined_like(sub {
                        print "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDOUT'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT & STDERR:\nTEST OUT\n\ndon't match:\n$regex\nas expected\n",
            },'STDOUT not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/i;
check_test( sub {
            combined_like {
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
            combined_like {
                        print "TEST OUT\n";
                      }
                      'OUT',
                      'Testing STDOUT'
            },{
              ok => 0,
              depth => 2,
              name => 'combined_like',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'bad regex'
          );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            combined_like {
                        print "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDOUT'
            },{
              ok => 0,
              name => 'Testing STDOUT',
              diag => "STDOUT & STDERR:\nTEST OUT\n\ndon't match:\n$regex\nas expected\n",
            },'STDOUT not matching failure'
          );
}
