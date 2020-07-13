# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

@test = (
# 1
    sub { mb::eval(q{ mkdir "5004.777.A", 0777;                         }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ mkdir "5004.777.ソ",0777;                         }) },
    sub { mb::eval(q{ open FILE,">5004.A";  print FILE "A"; close FILE; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ open FILE,">5004.ソ"; print FILE "A"; close FILE; }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { CORE::eval(q{ @_ = stat "5004.NOTEXTST.A";  scalar(@_) == 0 }) },
    sub { mb::eval(  q{ @_ = stat "5004.NOTEXTST.A";  scalar(@_) == 0 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(  q{ @_ = stat "5004.NOTEXTST.ソ"; scalar(@_) == 0 }) },
    sub { CORE::eval(q{ -e "5004.NOTEXTST.A";  @_ = stat _; scalar(@_) == 0 }) },
    sub { mb::eval(  q{ -e "5004.NOTEXTST.A";  @_ = stat _; scalar(@_) == 0 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(  q{ -e "5004.NOTEXTST.ソ"; @_ = stat _; scalar(@_) == 0 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { CORE::eval(q{ @_ = stat "5004.777.A";  scalar(@_) == 13 }) },
    sub { mb::eval(  q{ @_ = stat "5004.777.A";  scalar(@_) == 13 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(  q{ @_ = stat "5004.777.ソ"; scalar(@_) == 13 }) },
    sub { my @a = stat "5004.777.A"; my @b = mb::_stat "5004.777.A"; "@a" eq "@b" },
    sub { CORE::eval(q{ -e "5004.777.A";  @_ = stat _; scalar(@_) == 13 }) },
    sub { mb::eval(  q{ -e "5004.777.A";  @_ = stat _; scalar(@_) == 13 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(  q{ -e "5004.777.ソ"; @_ = stat _; scalar(@_) == 13 }) },
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { CORE::eval(q{ @_ = stat "5004.A";  scalar(@_) == 13 }) },
    sub { mb::eval(  q{ @_ = stat "5004.A";  scalar(@_) == 13 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(  q{ @_ = stat "5004.ソ"; scalar(@_) == 13 }) },
    sub { my @a = stat "5004.A"; my @b = mb::_stat "5004.A"; "@a" eq "@b" },
    sub { CORE::eval(q{ -e "5004.A";  @_ = stat _; scalar(@_) == 13 }) },
    sub { mb::eval(  q{ -e "5004.A";  @_ = stat _; scalar(@_) == 13 }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(  q{ -e "5004.ソ"; @_ = stat _; scalar(@_) == 13 }) },
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { mb::eval(q{ rmdir "5004.777.A";  }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ rmdir "5004.777.ソ"; }) },
    sub { mb::eval(q{ unlink "5004.A";     }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ unlink "5004.ソ";    }) },
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
