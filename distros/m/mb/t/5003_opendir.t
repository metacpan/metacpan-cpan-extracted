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

END {
    closedir(DIR1);
    closedir(DIR2);
    closedir(DIR3);
}

@test = (
# 1
    sub { not CORE::eval(<<'END') },
        opendir(DIR1,"5003.NOTEXIST.A");
END
    sub { not mb::eval(<<'END') },
        opendir(DIR2,"5003.NOTEXIST.A");
END
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(<<'END') },
        opendir(DIR3,"5003.NOTEXIST.ソ");
END
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { CORE::eval(q{ mkdir "5003.A", 0777; }) },
    sub { CORE::eval(q{ open FILE,">5003.A/A";  print FILE 'A'; close FILE; }) },
    sub { CORE::eval(q{ open FILE,">5003.A/B";  print FILE 'A'; close FILE; }) },
    sub { CORE::eval(q{ open FILE,">5003.A/C";  print FILE 'A'; close FILE; }) },
    sub { CORE::eval(<<'END') },
        opendir(DIR,"5003.A");
        @_ = readdir(DIR);
        closedir(DIR);
        scalar(@_) == 5;
END
    sub { CORE::eval(q{ unlink "5003.A/A"; }) },
    sub { CORE::eval(q{ unlink "5003.A/B"; }) },
    sub { CORE::eval(q{ unlink "5003.A/C"; }) },
    sub { CORE::eval(q{ rmdir "5003.A"; }) },
    sub {1},
# 21
    sub { mb::eval(q{ mkdir "5003.A", 0777; }) },
    sub { mb::eval(q{ open FILE,">5003.A/A";  print FILE 'A'; close FILE; }) },
    sub { mb::eval(q{ open FILE,">5003.A/B";  print FILE 'A'; close FILE; }) },
    sub { mb::eval(q{ open FILE,">5003.A/C";  print FILE 'A'; close FILE; }) },
    sub { mb::eval(<<'END'); },
        opendir(DIR,"5003.A");
        @_ = readdir(DIR);
        closedir(DIR);
        scalar(@_) == 5;
END
    sub { mb::eval(q{ unlink "5003.A/A"; }) },
    sub { mb::eval(q{ unlink "5003.A/B"; }) },
    sub { mb::eval(q{ unlink "5003.A/C"; }) },
    sub { mb::eval(q{ rmdir "5003.A"; }) },
    sub {1},
# 31
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ mkdir "5003.ソ", 0777; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ open FILE,">5003.ソ/A";  print FILE 'A'; close FILE; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ open FILE,">5003.ソ/B";  print FILE 'A'; close FILE; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ open FILE,">5003.ソ/C";  print FILE 'A'; close FILE; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(<<'END') },
        opendir(DIR,"5003.ソ");
        @_ = readdir(DIR);
        closedir(DIR);
        scalar(@_) == 5;
END
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ unlink "5003.ソ/A"; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ unlink "5003.ソ/B"; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ unlink "5003.ソ/C"; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; mb::eval(q{ rmdir "5003.ソ"; }) },
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
