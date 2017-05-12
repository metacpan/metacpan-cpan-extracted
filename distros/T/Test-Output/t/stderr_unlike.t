use Test::Tester;
use Test::More tests => 42;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex = qr/out/;
check_test( sub {
            stderr_unlike(sub {
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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            stderr_unlike(sub {
                        print STDERR "TEST OUT\n";
                      },
                      'OUT',
                      'Testing STDERR'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'stderr_unlike',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR matching success'
          );



{ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $regex = qr/OUT/;
check_test( sub {
            stderr_unlike(sub {
                        print STDERR "TEST OUT\n";
                      },
                      $regex,
                      'Testing STDERR'
                    )
            },{
              ok => 0,
              name => 'Testing STDERR',
              diag => "STDERR:\nTEST OUT\n\nmatches:\n$regex\nnot expected\n",
            },'STDERR not matching failure'
          );
}

{ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $regex = qr/out/;
check_test( sub {
            stderr_unlike {
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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
check_test( sub {
            stderr_unlike {
                        print STDERR "TEST OUT\n";
                      }
                      'OUT',
                      'Testing STDERR'
            },{
              ok => 0,
              depth => 2,
              name => 'stderr_unlike',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR matching success'
          );

{ # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $regex = qr/OUT/;
check_test( sub {
            stderr_unlike {
                        print STDERR "TEST OUT\n";
                      }
                      $regex,
                      'Testing STDERR'
            },{
              ok => 0,
              name => 'Testing STDERR',
              diag => "STDERR:\nTEST OUT\n\nmatches:\n$regex\nnot expected\n",
            },'STDERR not matching failure'
          );
}
