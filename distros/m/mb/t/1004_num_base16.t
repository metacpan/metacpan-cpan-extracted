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
        /\ABareword found where operator expected at / ? return :
        /\AMisplaced _ in number at /                  ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { eval(q{ 0x1    == 1   }) },
    sub { eval(q{ 0xFF   == 255 }) },
    sub { eval(q{ 0x_FF  == 255 }) },
    sub { eval(q{ 0xF_F  == 255 }) },
    sub { eval(q{ 0xFF_  == 255 }) },
    sub { eval(q{ 0xff   == 255 }) },
    sub { eval(q{ 0x_ff  == 255 }) },
    sub { eval(q{ 0xf_f  == 255 }) },
    sub { eval(q{ 0xff_  == 255 }) },
    sub {1},
# 11
    sub { mb::eval(q{ 0x1    == 1   }) },
    sub { mb::eval(q{ 0xFF   == 255 }) },
    sub { mb::eval(q{ 0x_FF  == 255 }) },
    sub { mb::eval(q{ 0xF_F  == 255 }) },
    sub { mb::eval(q{ 0xFF_  == 255 }) },
    sub { mb::eval(q{ 0xff   == 255 }) },
    sub { mb::eval(q{ 0x_ff  == 255 }) },
    sub { mb::eval(q{ 0xf_f  == 255 }) },
    sub { mb::eval(q{ 0xff_  == 255 }) },
    sub {1},
# 21
    sub { ($] < 5.014) or eval(q{ 0X1    == 1   }) },
    sub { ($] < 5.014) or eval(q{ 0XFF   == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0X_FF  == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0XF_F  == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0XFF_  == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0Xff   == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0X_ff  == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0Xf_f  == 255 }) },
    sub { ($] < 5.014) or eval(q{ 0Xff_  == 255 }) },
    sub {1},
# 31
    sub { ($] < 5.014) or mb::eval(q{ 0X1    == 1   }) },
    sub { ($] < 5.014) or mb::eval(q{ 0XFF   == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0X_FF  == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0XF_F  == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0XFF_  == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0Xff   == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0X_ff  == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0Xf_f  == 255 }) },
    sub { ($] < 5.014) or mb::eval(q{ 0Xff_  == 255 }) },
    sub {1},
# 41
    sub { ($] < 5.022) or eval(q{ 0x1.2P3  == 9        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.2P+3 == 9        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.2P-3 == 0.140625 }) },
    sub { ($] < 5.022) or eval(q{ 0x1.2p3  == 9        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.2p+3 == 9        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.2p-3 == 0.140625 }) },
    sub { ($] < 5.022) or eval(q{ 0x1.P3   == 8        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.P+3  == 8        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.P-3  == 0.125    }) },
    sub { ($] < 5.022) or eval(q{ 0x1.p3   == 8        }) },
# 51
    sub { ($] < 5.022) or eval(q{ 0x1.p+3  == 8        }) },
    sub { ($] < 5.022) or eval(q{ 0x1.p-3  == 0.125    }) },
    sub { ($] < 5.022) or eval(q{ 0x.2P3   == 1        }) },
    sub { ($] < 5.022) or eval(q{ 0x.2P+3  == 1        }) },
    sub { ($] < 5.022) or eval(q{ 0x.2P-3  == 0.015625 }) },
    sub { ($] < 5.022) or eval(q{ 0x.2p3   == 1        }) },
    sub { ($] < 5.022) or eval(q{ 0x.2p+3  == 1        }) },
    sub { ($] < 5.022) or eval(q{ 0x.2p-3  == 0.015625 }) },
    sub {1},
    sub {1},
# 61
    sub { ($] < 5.022) or mb::eval(q{ 0x1.2P3  == 9        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.2P+3 == 9        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.2P-3 == 0.140625 }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.2p3  == 9        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.2p+3 == 9        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.2p-3 == 0.140625 }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.P3   == 8        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.P+3  == 8        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.P-3  == 0.125    }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.p3   == 8        }) },
# 71
    sub { ($] < 5.022) or mb::eval(q{ 0x1.p+3  == 8        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x1.p-3  == 0.125    }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x.2P3   == 1        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x.2P+3  == 1        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x.2P-3  == 0.015625 }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x.2p3   == 1        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x.2p+3  == 1        }) },
    sub { ($] < 5.022) or mb::eval(q{ 0x.2p-3  == 0.015625 }) },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
