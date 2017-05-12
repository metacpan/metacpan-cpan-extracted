#! perl
use warnings;
use strict;
use Data::Dumper; $Data::Dumper::Indent = 1;

# $Id$

use Test::More tests => 5;

use constant EPOCHOFFSET => 1204286400; # 29 Feb 2008 12:00:00 GMT

my @cgtime = localtime;
my @fgtime = localtime( EPOCHOFFSET );
{
    use fixedtime epoch_offset => EPOCHOFFSET;
    my @ftime = localtime;
    is_deeply \@ftime, \@fgtime, 
              "localtime() is fixed (@{[ scalar localtime ]})"
        or diag Dumper \@ftime;

    { # nested calls should update the fixed stamp
        use fixedtime epoch_offset => EPOCHOFFSET + 60 * 60;
        my @fltime = @fgtime; $fltime[2] += 1;
        my @ltime = localtime;
        is_deeply \@ltime, \@fltime,
                  "localtime() in scope (@{[ scalar localtime ]})"
            or diag Dumper \@ltime;
    }

    @ftime = localtime;
    is_deeply \@ftime, \@fgtime,
              "localtime() is back  (@{[ scalar localtime ]})"
        or diag Dumper \@ftime;


    no fixedtime;
    my @gtime = localtime;
    is_deeply \@gtime, \@cgtime, "times compare (@{[ scalar localtime ]})"
        or diag Dumper \@gtime;
}
my @gtime = localtime;
is_deeply \@gtime, \@cgtime, "times compare (@{[ scalar localtime ]})"
    or diag Dumper \@gtime;
