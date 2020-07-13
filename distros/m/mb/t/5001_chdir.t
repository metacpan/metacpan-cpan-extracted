# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
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
    sub {                                        mb::eval(q{ mkdir "5001.A", 0777; }) },
    sub {                                        mb::eval(q{ chdir "5001.A";       }) },
    sub {                                        mb::eval(q{ chdir "..";           }) },
    sub {                                        mb::eval(q{ rmdir "5001.A";       }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ mkdir "5001.ƒ\",0777; }) },
    sub { return 'SKIP' unless $MSWin32_MBCS; not mb::eval(q{ chdir "5001.ƒ\";      }) },
    sub { return 'SKIP' unless $MSWin32_MBCS;     mb::eval(q{ rmdir "5001.ƒ\";      }) },
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
