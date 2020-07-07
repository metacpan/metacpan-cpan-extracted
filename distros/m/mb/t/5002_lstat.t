# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
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
        /\Alstat\(\) on unopened filehandle _ at / ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub { mb::eval(q{ mkdir "5002.777.A", 0777;                         }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ mkdir "5002.777.ソ",0777;                         }) },
    sub { mb::eval(q{ open FILE,">5002.A";  print FILE "A"; close FILE; }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ open FILE,">5002.ソ"; print FILE "A"; close FILE; }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { CORE::eval(q{ @_ = lstat "5002.NOTEXTST.A";  scalar(@_) == 0 }) },
    sub { mb::eval(  q{ @_ = lstat "5002.NOTEXTST.A";  scalar(@_) == 0 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(  q{ @_ = lstat "5002.NOTEXTST.ソ"; scalar(@_) == 0 }) },
    sub { CORE::eval(q{ -e "5002.NOTEXTST.A";  @_ = eval q{ lstat _ }; scalar(@_) == 0 }) },
    sub { mb::eval(  q{ -e "5002.NOTEXTST.A";  @_ = eval q{ lstat _ }; scalar(@_) == 0 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(  q{ -e "5002.NOTEXTST.ソ"; @_ = eval q{ lstat _ }; scalar(@_) == 0 }) },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { CORE::eval(q{ @_ = lstat "5002.777.A";  scalar(@_) == 13 }) },
    sub { mb::eval(  q{ @_ = lstat "5002.777.A";  scalar(@_) == 13 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(  q{ @_ = lstat "5002.777.ソ"; scalar(@_) == 13 }) },
    sub { my @a = lstat "8007.777.A"; my @b = mb::_lstat "8007.777.A"; "@a" eq "@b" },
    sub { return 'SKIP' if $] >= 5.008; CORE::eval(q{ -e "5002.777.A";  @_ = eval q{ lstat _ }; scalar(@_) == 13 }) },
    sub { return 'SKIP' if $] <  5.008; CORE::eval(q{ -e "5002.777.A";  @_ = eval q{ lstat _ }; scalar(@_) == 0  }) },
    sub {                          mb::eval(  q{ -e "5002.777.A";  @_ = eval q{ lstat _ }; scalar(@_) == 0  }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/;                          mb::eval(  q{ -e "5002.777.ソ"; @_ = eval q{ lstat _ }; scalar(@_) == 0  }) },
    sub {1},
    sub {1},
# 31
    sub { CORE::eval(q{ @_ = lstat "5002.A";  scalar(@_) == 13 }) },
    sub { mb::eval(  q{ @_ = lstat "5002.A";  scalar(@_) == 13 }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(  q{ @_ = lstat "5002.ソ"; scalar(@_) == 13 }) },
    sub { my @a = lstat "8007.A"; my @b = mb::_lstat "8007.A"; "@a" eq "@b" },
    sub { return 'SKIP' if $] >= 5.008; CORE::eval(q{ -e "5002.A";  @_ = eval q{ lstat _ }; scalar(@_) == 13 }) },
    sub { return 'SKIP' if $] <  5.008; CORE::eval(q{ -e "5002.A";  @_ = eval q{ lstat _ }; scalar(@_) == 0  }) },
    sub {                          mb::eval(  q{ -e "5002.A";  @_ = eval q{ lstat _ }; scalar(@_) == 0  }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/;                          mb::eval(  q{ -e "5002.ソ"; @_ = eval q{ lstat _ }; scalar(@_) == 0  }) },
    sub {1},
    sub {1},
# 41
    sub { mb::eval(q{ rmdir "5002.777.A";  }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ rmdir "5002.777.ソ"; }) },
    sub { mb::eval(q{ unlink "5002.A";     }) },
    sub { return 'SKIP' if $^O !~ /MSWin32/; mb::eval(q{ unlink "5002.ソ";    }) },
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
