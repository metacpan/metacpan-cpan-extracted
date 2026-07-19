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

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\AUse of -l on filehandle _ at / ? return :
        warn $_[0];
    };
}

@test = ();
my $endchar = (qw( A B ƒ\ ))[2];

# When $endchar eq 'A', "$filename.A" and "$filename.$endchar" are one and the
# same file, so the make_testee_*() pair of every subtest below created, and the
# mb::_unlink()/rmdir() pair removed, a single testee twice.  On MSWin32 that is
# precisely the same-name re-creation this script was rewritten to avoid, and it
# doubles the file I/O of the whole script for no extra coverage.  Touch the
# second name only when it really is a second name.
my $endchar_is_dup = ($endchar eq 'A');

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

# These are ALL 27 file test operators of Perl; @tester used to be padded with
# 73 more copies of -A to round the subtest count up to 100 x 42 = 4200.  Each
# element is used on its own (never stacked as -X -Y -Z), so every one of those
# copies re-ran the 42 subtests of -A -- 73% of the run time of this script for
# no extra coverage.  The padding is dropped: 27 x 42 = 1134 subtests, every one
# of them distinct.  The plan follows scalar(@test), so it adjusts by itself.
my @tester =
#        0__________________________1_____________________________2_____________________
#        1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7
    qw(
        -A -B -C -M -O -R -S -T -W -X -b -c -d -e -f -g -k -l -o -p -r -s -t -u -w -x -z
    );

# do test not exist file
#
for my $tester (@tester) {
    my $mode = '';

    # CORE::eval("-X testee") vs. mb::eval("-X testee")
    push @test, sub {
        return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

        # make testee file
        my $filename = "$tempdir/NOTEXISTS";

        # do test file
        my $a = CORE::eval(qq{$tester "$filename.A"});
        my $b =   mb::eval(qq{$tester "$filename.$endchar"});

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
            return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
        }
    };

    # CORE::eval("-X _") vs. mb::eval("-X testee")
    push @test, sub {
        return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

        # make testee file
        my $filename = "$tempdir/NOTEXISTS";

        # do test file
        my $a = CORE::eval(qq{$tester "$filename.A"});
           $a = CORE::eval(qq{$tester _});
        my $b =   mb::eval(qq{$tester "$filename.$endchar"});

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
            return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
        }
    };

    # CORE::eval("-X testee") vs. mb::eval("-X _")
    push @test, sub {
        return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

        # make testee file
        my $filename = "$tempdir/NOTEXISTS";

        # do test file
        my $a = CORE::eval(qq{$tester "$filename.A"});
        my $b =   mb::eval(qq{$tester "$filename.$endchar"});
           $b =   mb::eval(qq{$tester _});

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
            return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
        }
    };
}

# do test files
#
for my $tester (@tester) {
    for my $testee (
        ['',     0777],
        ['1',    0777],
        ['12',   0777],
        ['123',  0777],
        ['123',  0377],
        ['123',  0577],
        ['123',  0677],
        ["\x00", 0777],
    ) {
        my($content,$mode) = @{$testee};

        # CORE::eval("-X testee") vs. mb::eval("-X testee")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.A",        $content, $mode) or return 'SKIP';
            if (not $endchar_is_dup) {
                make_testee_file("$filename.$endchar", $content, $mode) or return 'SKIP';
            }

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            mb::_unlink("$filename.A");
            mb::_unlink("$filename.$endchar") if not $endchar_is_dup;

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };

        # CORE::eval("-X _") vs. mb::eval("-X testee")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.A",        $content, $mode) or return 'SKIP';
            if (not $endchar_is_dup) {
                make_testee_file("$filename.$endchar", $content, $mode) or return 'SKIP';
            }

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
               $a = CORE::eval(qq{$tester _});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            mb::_unlink("$filename.A");
            mb::_unlink("$filename.$endchar") if not $endchar_is_dup;

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };

        # CORE::eval("-X testee") vs. mb::eval("-X _")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.A",        $content, $mode) or return 'SKIP';
            if (not $endchar_is_dup) {
                make_testee_file("$filename.$endchar", $content, $mode) or return 'SKIP';
            }

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});
               $b =   mb::eval(qq{$tester _});

            # remove testee file
            mb::_unlink("$filename.A");
            mb::_unlink("$filename.$endchar") if not $endchar_is_dup;

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };
    }
}

# do test EXE file
#
for my $tester (@tester) {
    for my $testee (
        ['1', 0777],
    ) {
        my($content,$mode) = @{$testee};

        # CORE::eval("-X testee") vs. mb::eval("-X testee")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.EXE", $content, $mode) or return 'SKIP';

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.EXE"});
            my $b =   mb::eval(qq{$tester "$filename.EXE"});

            # remove testee file
            mb::_unlink("$filename.EXE");

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };

        # CORE::eval("-X _") vs. mb::eval("-X testee")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.EXE", $content, $mode) or return 'SKIP';

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.EXE"});
               $a = CORE::eval(qq{$tester _});
            my $b =   mb::eval(qq{$tester "$filename.EXE"});

            # remove testee file
            mb::_unlink("$filename.EXE");

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };

        # CORE::eval("-X testee") vs. mb::eval("-X _")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee file
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_file("$filename.EXE", $content, $mode) or return 'SKIP';

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.EXE"});
            my $b =   mb::eval(qq{$tester "$filename.EXE"});
               $b =   mb::eval(qq{$tester _});

            # remove testee file
            mb::_unlink("$filename.EXE");

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };
    }
}

# do test directories
#
for my $tester (@tester) {
    for my $testee (
        [0777],
        [0377],
        [0577],
        [0677],
    ) {
        my($mode) = @{$testee};

        # CORE::eval("-X testee") vs. mb::eval("-X testee")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee directory
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_dir("$filename.A",        $mode) or return 'SKIP';
            if (not $endchar_is_dup) {
                make_testee_dir("$filename.$endchar", $mode) or return 'SKIP';
            }

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            rmdir("$filename.A");
            rmdir("$filename.$endchar") if not $endchar_is_dup;

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };

        # CORE::eval("-X _") vs. mb::eval("-X testee")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee directory
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_dir("$filename.A",        $mode) or return 'SKIP';
            if (not $endchar_is_dup) {
                make_testee_dir("$filename.$endchar", $mode) or return 'SKIP';
            }

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
               $a = CORE::eval(qq{$tester _});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            rmdir("$filename.A");
            rmdir("$filename.$endchar") if not $endchar_is_dup;

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };

        # CORE::eval("-X testee") vs. mb::eval("-X _")
        push @test, sub {
            return 'SKIP' if not ((length($endchar) == 1) or $MSWin32_MBCS);

            # make testee directory
            my $filename = "$tempdir/testee" . (++$testee_serial);
            make_testee_dir("$filename.A",        $mode) or return 'SKIP';
            if (not $endchar_is_dup) {
                make_testee_dir("$filename.$endchar", $mode) or return 'SKIP';
            }

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});
               $b =   mb::eval(qq{$tester _});

            # remove testee file
            rmdir("$filename.A");
            rmdir("$filename.$endchar") if not $endchar_is_dup;

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
                return 0, sprintf("$tester $filename(%03o), core=($a), mb=($b)", $mode);
            }
        };
    }
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
