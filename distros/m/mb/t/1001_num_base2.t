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
    sub { ($] < 5.006) or eval(q{ 1     == 1 }) },
    sub { ($] < 5.006) or eval(q{ 0b1   == 1 }) },
    sub { ($] < 5.006) or eval(q{ 0b0   == 0 }) },
    sub { ($] < 5.006) or eval(q{ 0b01  == 1 }) },
    sub { ($] < 5.006) or eval(q{ 0b10  == 2 }) },
    sub { ($] < 5.006) or eval(q{ 0b11  == 3 }) },
    sub { ($] < 5.006) or eval(q{ 0b_11 == 3 }) },
    sub { ($] < 5.006) or eval(q{ 0b1_1 == 3 }) },
    sub { ($] < 5.006) or eval(q{ 0b11_ == 3 }) },
    sub {1},
# 11
    sub { ($] < 5.006) or mb::eval(q{ 1     == 1 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b1   == 1 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b0   == 0 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b01  == 1 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b10  == 2 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b11  == 3 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b_11 == 3 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b1_1 == 3 }) },
    sub { ($] < 5.006) or mb::eval(q{ 0b11_ == 3 }) },
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
