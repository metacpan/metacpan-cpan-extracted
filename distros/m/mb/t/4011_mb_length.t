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
    sub { $_='ABC';      my $r=    length($_); $r == 3 },
    sub { $_='ABC';      my $r=    length;     $r == 3 },
    sub { $_='';         my $r=    length($_); $r == 0 },
    sub { $_='';         my $r=    length;     $r == 0 },
    sub { $_='ABC';      my $r=mb::length($_); $r == 3 },
    sub { $_='ABC';      my $r=mb::length;     $r == 3 },
    sub { $_='‚ ‚¢‚¤‚¦'; my $r=mb::length($_); $r == 4 },
    sub { $_='‚ ‚¢‚¤‚¦'; my $r=mb::length;     $r == 4 },
    sub { $_='';         my $r=mb::length($_); $r == 0 },
    sub { $_='';         my $r=mb::length;     $r == 0 },
# 11
    sub { $_='1‚ A‚¢!';  my $r=mb::length($_); $r == 5 },
    sub { $_='1‚ A‚¢!';  my $r=mb::length;     $r == 5 },
    sub {1},
    sub {1},
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
