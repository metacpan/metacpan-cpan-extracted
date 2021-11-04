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
    sub { eval(q{ 1    == 1 }) },
    sub { eval(q{ 01   == 1 }) },
    sub { eval(q{ 00   == 0 }) },
    sub { eval(q{ 001  == 1 }) },
    sub { eval(q{ 010  == 8 }) },
    sub { eval(q{ 011  == 9 }) },
    sub { eval(q{ 0_11 == 9 }) },
    sub { eval(q{ 01_1 == 9 }) },
    sub { eval(q{ 011_ == 9 }) },
    sub {1},
# 11
    sub { mb::eval(q{ 1    == 1 }) },
    sub { mb::eval(q{ 01   == 1 }) },
    sub { mb::eval(q{ 00   == 0 }) },
    sub { mb::eval(q{ 001  == 1 }) },
    sub { mb::eval(q{ 010  == 8 }) },
    sub { mb::eval(q{ 011  == 9 }) },
    sub { mb::eval(q{ 0_11 == 9 }) },
    sub { mb::eval(q{ 01_1 == 9 }) },
    sub { mb::eval(q{ 011_ == 9 }) },
    sub {1},
# 21
    sub { ($] < 5.034) or eval(q{ 1     == 1 }) },
    sub { ($] < 5.034) or eval(q{ 0o1   == 1 }) },
    sub { ($] < 5.034) or eval(q{ 0o0   == 0 }) },
    sub { ($] < 5.034) or eval(q{ 0o01  == 1 }) },
    sub { ($] < 5.034) or eval(q{ 0o10  == 8 }) },
    sub { ($] < 5.034) or eval(q{ 0o11  == 9 }) },
    sub { ($] < 5.034) or eval(q{ 0o_11 == 9 }) },
    sub { ($] < 5.034) or eval(q{ 0o1_1 == 9 }) },
    sub { ($] < 5.034) or eval(q{ 0o11_ == 9 }) },
    sub {1},
# 31
    sub { ($] < 5.034) or mb::eval(q{ 1     == 1 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o1   == 1 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o0   == 0 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o01  == 1 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o10  == 8 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o11  == 9 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o_11 == 9 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o1_1 == 9 }) },
    sub { ($] < 5.034) or mb::eval(q{ 0o11_ == 9 }) },
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
