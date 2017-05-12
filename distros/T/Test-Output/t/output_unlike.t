use Test::Tester;
use Test::More tests => 112;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/ERR/i;
my $regex_err = qr/OUT/i;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT and STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err = qr/OUT/i;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT and STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/ERR/i;
my $regex_err;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT and STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = 'OUT';
my $regex_err = qr/err/;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'output_unlike_STDOUT',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDOUT bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err = 'OUT';
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 0,
              depth => 2,
              name => 'output_unlike_STDERR',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/;
my $regex_err = qr/ERR/i;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDERR:\nTEST ERR\n\nmatches:\n$regex_err\nnot expected\n",
            },'STDERR matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/i;
my $regex_err = qr/err/;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT:\nTEST OUT\n\nmatches:\n$regex_out\nnot expected\n",
            },'STDOUT matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/;
my $regex_err = qr/ERR/;
check_test( sub {
            output_unlike(sub {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT:\nTEST OUT\n\nmatches:\n$regex_out\nnot expected\nSTDERR:\nTEST ERR\n\nmatches:\n$regex_err\nnot expected\n",
            },'STDERR matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/ERR/;
my $regex_err = qr/OUT/;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT and STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err = qr/OUT/;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT and STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/ERR/i;
my $regex_err;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT and STDOUT not matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = 'OUT';
my $regex_err = qr/err/;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              depth => 2,
              name => 'output_unlike_STDOUT',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDOUT bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err = 'OUT';
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              depth => 2,
              name => 'output_unlike_STDERR',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/;
my $regex_err = qr/ERR/i;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDERR:\nTEST ERR\n\nmatches:\n$regex_err\nnot expected\n",
            },'STDERR matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/i;
my $regex_err = qr/err/;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT:\nTEST OUT\n\nmatches:\n$regex_out\nnot expected\n",
            },'STDOUT matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/;
my $regex_err = qr/ERR/;
check_test( sub {
            output_unlike {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT:\nTEST OUT\n\nmatches:\n$regex_out\nnot expected\nSTDERR:\nTEST ERR\n\nmatches:\n$regex_err\nnot expected\n",
            },'STDERR matching failure'
          );
}
