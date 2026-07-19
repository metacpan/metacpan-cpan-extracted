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
my $endchar = (qw( A B ƒ\ ))[0];

# make working directory
use vars qw($tempdir $scriptno);
($scriptno) = File::Basename::basename(__FILE__) =~ /\A([0-9]+)/;
$tempdir = "$FindBin::Bin/$scriptno.$$.temp";
File::Path::mkpath($tempdir, 0, 0777);

# On MSWin32, unlink() of the previous testee is asynchronous (the name
# stays delete-pending for a moment) and on-access virus scanners can hold
# a just-created file open, so re-creating the same name back-to-back
# thousands of times fails sporadically (mb-0.65 CPAN Testers FAIL:
# exactly 1 of 4200 subtests, at a different subtest number per report).
# Therefore every subtest gets a serial-numbered testee name, creation is
# checked and briefly retried, and a persistent transient failure skips
# the subtest instead of failing it.
use vars qw($testee_serial);
$testee_serial = 0;

sub make_testee_file {
    my($file,$content,$mode) = @_;
    for my $retry (1..5) {
        if (open(TESTEE,">$file")) {
            binmode(TESTEE);
            print TESTEE $content;
            close(TESTEE);
            chmod($mode, $file);
            if (-e $file) {
                return 1;
            }
        }
        select(undef,undef,undef,0.1);
    }
    return 0;
}

sub make_testee_dir {
    my($dir,$mode) = @_;
    for my $retry (1..5) {
        mkdir($dir, $mode);
        if (-d $dir) {
            return 1;
        }
        select(undef,undef,undef,0.1);
    }
    return 0;
}

END {
    # remove testee files (a transient unlink failure may leave some)
    File::Path::rmtree($tempdir, 0, 0);
}

my @tester = ();

# do test -r -w -d
#
for my $tester (' -r -w -d ') {
    for my $testee (
        ['123', 0777, ''],
        ['123', 0377, ''],
    ) {
        my($content,$mode,$want) = @{$testee};

        push @test, sub {

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.A", $content, $mode) or return 'SKIP';

            # do test file
            my $a = $want;
            my $b = mb::eval(qq{$tester "$filename.A"});

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

# do test -r -w -f
#
for my $tester (' -r -w -f ') {
    for my $testee (
        ['123', 0777, 1 ],
        ['123', 0177, ''],
    ) {
        my($content,$mode,$want) = @{$testee};

        push @test, sub {
            return 'SKIP' if $^O =~ /cygwin/;
            return 'SKIP' if $> == 0; # root always passes file permission tests

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.A", $content, $mode) or return 'SKIP';

            # do test file
            my $a = $want;
            my $b = mb::eval(qq{$tester "$filename.A"});

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

# do test -s -r -w -f
#
for my $tester (' -s -r -w -f ') {
    for my $testee (
        ['123', 0777, 3],
    ) {
        my($content,$mode,$want) = @{$testee};

        push @test, sub {

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.A", $content, $mode) or return 'SKIP';

            # do test file
            my $a = $want;
            my $b = mb::eval(qq{$tester "$filename.A"});

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
