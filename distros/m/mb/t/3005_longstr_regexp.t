# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (

# 1
    sub {                                 $_=<<'END1'; mb::eval(); },
('A' x 32765).'B' =~ /B/
END1
    sub {                                 $_=<<'END1'; mb::eval(); },
('A' x 32765).'B' !~ /C/
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 11
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); },
('A' x 32766).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); },
('A' x 32767).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); },
('A' x 32768).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); },
('A' x 32766).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); },
('A' x 32767).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.010001; $_=<<'END1'; mb::eval(); },
('A' x 32768).'B' !~ /C/
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 21
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); },
('A' x 65534).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); },
('A' x 65535).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); },
('A' x 65536).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); },
('A' x 65534).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); },
('A' x 65535).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.030000; $_=<<'END1'; mb::eval(); },
('A' x 65536).'B' !~ /C/
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 31
# REG_INF has been raised from 65,536 to 2,147,483,647
# https://perldoc.perl.org/perl5380delta#REG_INF-has-been-raised-from-65,536-to-2,147,483,647
#
# (However, there may not always be enough memory in the machine running the test.)

    sub { return 'SKIP' if $] < 5.038000; $_=<<'END1'; mb::eval(); },
('A' x (2147483646 / 100)).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.038000; $_=<<'END1'; mb::eval(); },
('A' x (2147483647 / 100)).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.038000; $_=<<'END1'; mb::eval(); },
('A' x (2147483648 / 100)).'B' =~ /B/
END1
    sub { return 'SKIP' if $] < 5.038000; $_=<<'END1'; mb::eval(); },
('A' x (2147483646 / 100)).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.038000; $_=<<'END1'; mb::eval(); },
('A' x (2147483647 / 100)).'B' !~ /C/
END1
    sub { return 'SKIP' if $] < 5.038000; $_=<<'END1'; mb::eval(); },
('A' x (2147483648 / 100)).'B' !~ /C/
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
