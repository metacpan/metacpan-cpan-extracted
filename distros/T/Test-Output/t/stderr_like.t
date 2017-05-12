use Test::Tester;
use Test::More tests => 42;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/i;
check_test( sub {
            stderr_like(sub {
                        print STDERR "TEST OUT\n";
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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = 'OUT';
check_test( sub {
            stderr_like(sub {
                        print STDERR "TEST OUT\n";
                      },
                      'OUT',
                      'Testing STDERR'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'stderr_like',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR bad regex success'
          );
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stderr_like(sub {
                        print STDERR "TEST OUT\n";
                      },
                      qr/out/,
                      'Testing STDERR'
                    )
            },{
              ok => 0,
              name => 'Testing STDERR',
              diag => "STDERR:\nTEST OUT\n\ndoesn't match:\n$regex\nas expected\n",
            },'STDERR not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/OUT/i;
check_test( sub {
            stderr_like {
                        print STDERR "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDERR'
            },{
              ok => 1,
              name => 'Testing STDERR',
              diag => '',
            },'STDERR matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = 'OUT';
check_test( sub {
            stderr_like {
                        print STDERR "TEST OUT\n";
                      }
                      'OUT',
                      'Testing STDERR'
            },{
              ok => 0,
              depth => 2,
              name => 'stderr_like',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR bad regex success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stderr_like {
                        print STDERR "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDERR'
            },{
              ok => 0,
              name => 'Testing STDERR',
              diag => "STDERR:\nTEST OUT\n\ndoesn't match:\n$regex\nas expected\n",
            },'STDERR not matching failure'
          );
}
