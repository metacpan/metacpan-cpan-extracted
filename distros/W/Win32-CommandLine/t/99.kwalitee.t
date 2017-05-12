#!perl -w   -- -*- tab-width: 4; mode: perl -*-
# [no -T]: Test::Kwalitee->import() is File::Find tainted ("Insecure dependency in chdir...")

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{TEST_AUTHOR} or $ENV{TEST_ALL};
plan skip_all => 'TAINT mode not supported (Test::Kwalitee is File::Find tainted)' if in_taint_mode();

my $haveTestKwalitee = eval { require Test::Kwalitee; 1; };

plan skip_all => 'Test::Kwalitee required to test CPANTS kwalitee' if !$haveTestKwalitee;

local $ENV{AUTHOR_TESTING} = 1; ## Test::Kwalitee wants $ENV{AUTHOR_TESTING} and/or $ENV{RELEASE_TESTING} set or it will nag

#Test::Kwalitee->import( tests => [ qw( use_strict has_tests ) ] );                     # import specific kwalitee tests
#Test::Kwalitee->import( tests => [ qw( -has_test_pod -has_test_pod_coverage ) ] );     # disable specific kwalitee tests
import Test::Kwalitee;                                                                  # all kwalitee tests

{ ## TODO: change to only look in main directory for debian_cpants... ; remove warn vs change to carp vs no critic on that line only ; also, report as bug to kwalitee.pm
## no critic ( ErrorHandling::RequireCarping )
# clean up trash [from Kwalitee.pm]
# Module::CPANTS::Kwalitee::Distros suck!
#t/a_manifest..............1/1
##   Failed test at t/a_manifest.t line 13.
##          got: 1
##     expected: 0
## The following files are not named in the MANIFEST file: /home/apoc/workspace/VCS-perl-trunk/VCS-2.12.2/Debian_CPANTS.txt
## Looks like you failed 1 test of 1.
#t/a_manifest.............. Dubious, test returned 1 (wstat 256, 0x100)
foreach my $file ( qw( Debian_CPANTS.txt ../Debian_CPANTS.txt ) ) {
    if ( -e $file and -f _ ) {
        my $status = unlink( $file );
        if ( ! $status ) {
            warn "unable to unlink $file";
            }
        }
    }
}

#### SUBs ---------------------------------------------------------------------------------------##


sub is_tainted {
    ## no critic ( ProhibitStringyEval RequireCheckingReturnValueOfEval ) # ToDO: remove/revisit
    # URLref: [perlsec - Laundering and Detecting Tainted Data] http://perldoc.perl.org/perlsec.html#Laundering-and-Detecting-Tainted-Data
    return ! eval { eval(q{#} . substr(join(q{}, @_), 0, 0)); 1 };
    }

sub in_taint_mode {
    ## no critic ( RequireBriefOpen RequireInitializationForLocalVars ProhibitStringyEval RequireCheckingReturnValueOfEval ProhibitBarewordFileHandles ProhibitTwoArgOpen ) # ToDO: remove/revisit
    # modified from Taint source @ URLref: http://cpansearch.perl.org/src/PHOENIX/Taint-0.09/Taint.pm
    my $taint = q{};

    if (not is_tainted( $taint )) {
        $taint = substr("$0$^X", 0, 0);
        }

    if (not is_tainted( $taint )) {
        $taint = substr(join("", @ARGV, %ENV), 0, 0);
        }

    if (not is_tainted( $taint )) {
        local(*FILE);
        my $data = q{};
        for (qw(/dev/null nul / . ..), values %INC, $0, $^X) {
            # Why so many? Maybe a file was just deleted or moved;
            # you never know! :-)  At this point, taint checks
            # are probably off anyway, but this is the ironclad
            # way to get tainted data if it's possible.
            # (Yes, even reading from /dev/null works!)
            #
            last if open FILE, $_
            and defined sysread FILE, $data, 1
            }
        close( FILE );
        $taint = substr($data, 0, 0);
        }

    return is_tainted( $taint );
    }
