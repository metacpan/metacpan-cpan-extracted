# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AMisplaced _ in number at / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { eval(q{ 1    == 1   }) },
    sub { eval(q{ 123  == 123 }) },
    sub { eval(q{ 1_23 == 123 }) },
    sub { eval(q{ 12_3 == 123 }) },
    sub { eval(q{ 123_ == 123 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { mb::eval(q{ 1    == 1   }) },
    sub { mb::eval(q{ 123  == 123 }) },
    sub { mb::eval(q{ 1_23 == 123 }) },
    sub { mb::eval(q{ 12_3 == 123 }) },
    sub { mb::eval(q{ 123_ == 123 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { eval(q{ .1    == 0.1   }) },
    sub { eval(q{ .123  == 0.123 }) },
    sub { eval(q{ .1_23 == 0.123 }) },
    sub { eval(q{ .12_3 == 0.123 }) },
    sub { eval(q{ .123_ == 0.123 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { mb::eval(q{ .1    == 0.1   }) },
    sub { mb::eval(q{ .123  == 0.123 }) },
    sub { mb::eval(q{ .1_23 == 0.123 }) },
    sub { mb::eval(q{ .12_3 == 0.123 }) },
    sub { mb::eval(q{ .123_ == 0.123 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { eval(q{ 1.2E3  == 1200   }) },
    sub { eval(q{ 1.2E+3 == 1200   }) },
    sub { eval(q{ 1.2E-3 }) == mb::eval(q{ 1.2E-3 }) },
    sub { eval(q{ 1.2e3  == 1200   }) },
    sub { eval(q{ 1.2e+3 == 1200   }) },
    sub { eval(q{ 1.2e-3 }) == mb::eval(q{ 1.2e-3 }) },
    sub { eval(q{ 1.E3   == 1000   }) },
    sub { eval(q{ 1.E+3  == 1000   }) },
    sub { eval(q{ 1.E-3  == 0.001  }) },
    sub { eval(q{ 1.e3   == 1000   }) },
# 51
    sub { eval(q{ 1.e+3  == 1000   }) },
    sub { eval(q{ 1.e-3  == 0.001  }) },
    sub { eval(q{ .2E3   == 200    }) },
    sub { eval(q{ .2E+3  == 200    }) },
    sub { eval(q{ .2E-3  == 0.0002 }) },
    sub { eval(q{ .2e3   == 200    }) },
    sub { eval(q{ .2e+3  == 200    }) },
    sub { eval(q{ .2e-3  == 0.0002 }) },
    sub {1},
    sub {1},
# 61
    sub { mb::eval(q{ 1.2E3  == 1200   }) },
    sub { mb::eval(q{ 1.2E+3 == 1200   }) },
    sub { mb::eval(q{ 1.2E-3 }) == eval(q{ 1.2E-3 }) },
    sub { mb::eval(q{ 1.2e3  == 1200   }) },
    sub { mb::eval(q{ 1.2e+3 == 1200   }) },
    sub { mb::eval(q{ 1.2e-3 }) == eval(q{ 1.2e-3 }) },
    sub { mb::eval(q{ 1.E3   == 1000   }) },
    sub { mb::eval(q{ 1.E+3  == 1000   }) },
    sub { mb::eval(q{ 1.E-3  == 0.001  }) },
    sub { mb::eval(q{ 1.e3   == 1000   }) },
# 71
    sub { mb::eval(q{ 1.e+3  == 1000   }) },
    sub { mb::eval(q{ 1.e-3  == 0.001  }) },
    sub { mb::eval(q{ .2E3   == 200    }) },
    sub { mb::eval(q{ .2E+3  == 200    }) },
    sub { mb::eval(q{ .2E-3  == 0.0002 }) },
    sub { mb::eval(q{ .2e3   == 200    }) },
    sub { mb::eval(q{ .2e+3  == 200    }) },
    sub { mb::eval(q{ .2e-3  == 0.0002 }) },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
