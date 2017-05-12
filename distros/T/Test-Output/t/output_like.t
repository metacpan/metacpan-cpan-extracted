use Test::Tester;
use Test::More tests => 154;
use Test::Output;

use strict;
use warnings;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err = qr/ERR/i;
check_test( sub {
            output_like(sub {
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
            },'STDOUT and STDOUT matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err;
check_test( sub {
            output_like(sub {
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
            },'STDOUT matching STDERR ignored success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/;
my $regex_err = qr/ERR/;
check_test( sub {
            output_like(sub {
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
            },'STDOUT ignored and STDERR matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err;
check_test( sub {
            output_like(sub {
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
              diag => "STDOUT is:\nTEST OUT\n\nnot:\n\nas expected\nSTDERR is:\nTEST ERR\n\nnot:\n\nas expected\n",
            },'STDOUT ignored and STDERR matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = 'OUT';
my $regex_err = qr/ERR/i;
check_test( sub {
            output_like(sub {
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
              name => 'output_like_STDOUT',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDOUT bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err = 'OUT';

check_test( sub {
            output_like(sub {
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
              name => 'output_like_STDERR',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/;
my $regex_err = qr/ERR/i;

check_test( sub {
            output_like(sub {
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
              diag => "STDOUT:\nTEST OUT\n\ndoesn't match:\n$regex_out\nas expected\n",
            },'STDOUT not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/i;
my $regex_err = qr/err/;

check_test( sub {
            output_like(sub {
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
              diag => "STDERR:\nTEST ERR\n\ndoesn't match:\n$regex_err\nas expected\n",
            },'STDERR not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/;
my $regex_err = qr/err/;

check_test( sub {
            output_like(sub {
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
              diag => "STDOUT:\nTEST OUT\n\ndoesn't match:\n$regex_out\nas expected\nSTDERR:\nTEST ERR\n\ndoesn't match:\n$regex_err\nas expected\n",
            },'STDOUT & STDERR not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err;

check_test( sub {
            output_like(sub {
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT & STDERR undef matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err;

check_test( sub {
            output_like(sub {
                        print STDERR "TEST OUT\n";
                      },
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
                    )
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDERR is:\nTEST OUT\n\nnot:\n\nas expected\n",
            },'STDOUT & STDERR not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err = qr/ERR/i;

check_test( sub {
            output_like {
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
            },'STDOUT and STDOUT matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err;

check_test( sub {
            output_like {
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
            },'STDOUT matching STDERR ignored success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err = qr/ERR/i;

check_test( sub {
            output_like {
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
            },'STDOUT ignored and STDERR matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err;

check_test( sub {
            output_like {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT is:\nTEST OUT\n\nnot:\n\nas expected\nSTDERR is:\nTEST ERR\n\nnot:\n\nas expected\n",
            },'STDOUT ignored and STDERR matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = 'OUT';
my $regex_err = qr/ERR/i;

check_test( sub {
            output_like {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              depth => 2,
              name => 'output_like_STDOUT',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDOUT bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/OUT/i;
my $regex_err = 'OUT';

check_test( sub {
            output_like {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              depth => 2,
              name => 'output_like_STDERR',
              diag => "'OUT' doesn't look much like a regex to me.\n",
            },'STDERR bad regex'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/;
my $regex_err = qr/ERR/i;

check_test( sub {
            output_like {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT:\nTEST OUT\n\ndoesn't match:\n$regex_out\nas expected\n",
            },'STDOUT not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/i;
my $regex_err = qr/err/;

check_test( sub {
            output_like {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDERR:\nTEST ERR\n\ndoesn't match:\n$regex_err\nas expected\n",
            },'STDERR not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out = qr/out/;
my $regex_err = qr/err/;

check_test( sub {
            output_like {
                        print "TEST OUT\n";
                        print STDERR "TEST ERR\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDOUT:\nTEST OUT\n\ndoesn't match:\n$regex_out\nas expected\nSTDERR:\nTEST ERR\n\ndoesn't match:\n$regex_err\nas expected\n",
            },'STDOUT & STDERR not matching failure'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err;

check_test( sub {
            output_like {
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 1,
              name => 'Testing STDOUT and STDERR match',
              diag => '',
            },'STDOUT & STDERR undef matching success'
          );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $regex_out;
my $regex_err;

check_test( sub {
            output_like {
                        print STDERR "TEST OUT\n";
                      }
                      $regex_out,
                      $regex_err,
                      'Testing STDOUT and STDERR match'
            },{
              ok => 0,
              name => 'Testing STDOUT and STDERR match',
              diag => "STDERR is:\nTEST OUT\n\nnot:\n\nas expected\n",
            },'STDOUT & STDERR not matching failure'
          );
}
