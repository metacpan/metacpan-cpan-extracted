# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use File::Path;
use File::Basename;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
# always "0" because qx{chcp} cannot return right value on CPAN TEST
$MSWin32_MBCS = 0; # ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

chdir($FindBin::Bin);

@test = ();

# make working directory
use vars qw($tempdir $scriptno);
($scriptno) = File::Basename::basename(__FILE__) =~ /\A([0-9]+)/;
$tempdir = "$FindBin::Bin/$scriptno.$$.temp";
File::Path::mkpath($tempdir, 0, 0777);

END {
    # remove testee file
    rmdir($tempdir);
}

my @tester = ();

# stacked file test with no space like "-s-r-e"
#
for my $tester (
    '-s',
    '-s -e',
    '-s-e',
    '-s-r-e',
) {
    for my $testee (
        ['123' x 10, 0777, 10],
    ) {
        my($content,$mode,$want) = @{$testee};

        push @test, sub {
            return 'SKIP' if $^O =~ /cygwin/;

            # make testee file
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.A");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.A");

            # do test file
            my $a = $want;
            my $b = mb::eval(qq{($tester "$filename.A") / 3});

            # remove testee file
            mb::_unlink("$filename.A");

            # returns result
            if (not defined($a) and not defined($b)) {
                return 1;
            }
            elsif ($a eq $b) {
                return 1;
            }
            elsif ($a == $b) {
                return 1;
            }
            elsif (abs($a - $b) < 0.1) {
                return 1;
            }
            else {
                return 0, sprintf("$tester $filename(%03o), want=($a), got mb=($b)", $mode);
            }
        };
    }
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
