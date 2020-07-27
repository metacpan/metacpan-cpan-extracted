# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

open FILE,">6016.bat"; print FILE "\x00"; close FILE;
open FILE,">6016.cmd"; print FILE "\x00"; close FILE;
open FILE,">6016.com"; print FILE "\x00"; close FILE;
open FILE,">6016.exe"; print FILE "\x00"; close FILE;

END {
    unlink "6016.bat";
    unlink "6016.cmd";
    unlink "6016.com";
    unlink "6016.exe";
}

@test = (
# 1
    sub { not CORE::eval(q{ -x "6016.bat" }) xor mb::eval(q{ -x "6016.bat" }) },
    sub { not CORE::eval(q{ -x "6016.cmd" }) xor mb::eval(q{ -x "6016.cmd" }) },
    sub { not CORE::eval(q{ -x "6016.com" }) xor mb::eval(q{ -x "6016.com" }) },
    sub { not CORE::eval(q{ -x "6016.exe" }) xor mb::eval(q{ -x "6016.exe" }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { not mb::eval(q{ (-x "6016.bat") xor (-x "6016.bat") }) },
    sub { not mb::eval(q{ (-x "6016.cmd") xor (-x "6016.cmd") }) },
    sub { not mb::eval(q{ (-x "6016.com") xor (-x "6016.com") }) },
    sub { not mb::eval(q{ (-x "6016.exe") xor (-x "6016.exe") }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { not CORE::eval(q{ (-x "6016.bat") xor (-x _) }) },
    sub { not CORE::eval(q{ (-x "6016.cmd") xor (-x _) }) },
    sub { not CORE::eval(q{ (-x "6016.com") xor (-x _) }) },
    sub { not CORE::eval(q{ (-x "6016.exe") xor (-x _) }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { not mb::eval(q{ (-x "6016.bat") xor (-x _) }) },
    sub { not mb::eval(q{ (-x "6016.cmd") xor (-x _) }) },
    sub { not mb::eval(q{ (-x "6016.com") xor (-x _) }) },
    sub { not mb::eval(q{ (-x "6016.exe") xor (-x _) }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
