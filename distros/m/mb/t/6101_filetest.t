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
my $endchar = (qw( A B ƒ\ ))[0];

# make working directory
use vars qw($tempdir $scriptno);
($scriptno) = File::Basename::basename(__FILE__) =~ /\A([0-9]+)/;
$tempdir = "$FindBin::Bin/$scriptno.$$.temp";
File::Path::mkpath($tempdir, 0, 0777);

END {
    # remove testee file
    rmdir($tempdir);
}

my @tester = 
#        0__________________________1_____________________________2_____________________........3
#        1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5  6  7  8  9  0
    qw(
        -A -B -C -M -O -R -S -T -W -X -b -c -d -e -f -g -k -l -o -p -r -s -t -u -w -x -z -A -A -A
        -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A
        -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A -A
        -A -A -A -A -A -A -A -A -A -A
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
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.A");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.A");
            open(FILE,">$filename.$endchar");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.$endchar");

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            mb::_unlink("$filename.A");
            mb::_unlink("$filename.$endchar");

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
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.A");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.A");
            open(FILE,">$filename.$endchar");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.$endchar");

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
               $a = CORE::eval(qq{$tester _});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            mb::_unlink("$filename.A");
            mb::_unlink("$filename.$endchar");

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
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.A");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.A");
            open(FILE,">$filename.$endchar");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.$endchar");

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});
               $b =   mb::eval(qq{$tester _});

            # remove testee file
            mb::_unlink("$filename.A");
            mb::_unlink("$filename.$endchar");

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
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.EXE");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.EXE");

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
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.EXE");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.EXE");

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
            my $filename = "$tempdir/testee";
            open(FILE,">$filename.EXE");
            binmode(FILE);
            print FILE $content;
            close(FILE);
            chmod($mode, "$filename.EXE");

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
            my $filename = "$tempdir/testee";
            mkdir("$filename.A",        $mode);
            mkdir("$filename.$endchar", $mode);

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            rmdir("$filename.A");
            rmdir("$filename.$endchar");

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
            my $filename = "$tempdir/testee";
            mkdir("$filename.A",        $mode);
            mkdir("$filename.$endchar", $mode);

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
               $a = CORE::eval(qq{$tester _});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});

            # remove testee file
            rmdir("$filename.A");
            rmdir("$filename.$endchar");

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
            my $filename = "$tempdir/testee";
            mkdir("$filename.A",        $mode);
            mkdir("$filename.$endchar", $mode);

            # do test file
            my $a = CORE::eval(qq{$tester "$filename.A"});
            my $b =   mb::eval(qq{$tester "$filename.$endchar"});
               $b =   mb::eval(qq{$tester _});

            # remove testee file
            rmdir("$filename.A");
            rmdir("$filename.$endchar");

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
