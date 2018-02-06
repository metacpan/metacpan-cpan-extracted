#!perl -w  -- -*- tab-width: 4; mode: perl -*-
# [no -T]: Test::MinimumVersion::all_minimum_version_from_metayml_ok() is File::Find tainted (via "Insecure dependency in chdir")

use strict;
use warnings;

{
## no critic ( ProhibitOneArgSelect RequireLocalizedPunctuationVars )
my $fh = select STDIN; $|++; select STDOUT; $|++; select STDERR; $|++; select $fh;  # DISABLE buffering on STDIN, STDOUT, and STDERR
}

use Test::More;

plan skip_all => 'Author tests [to run: set TEST_AUTHOR]' unless $ENV{AUTOMATED_TESTING} or $ENV{TEST_AUTHOR} or $ENV{TEST_RELEASE} or $ENV{TEST_ALL};

use version qw();
my @modules = ( 'Test::MinimumVersion 0.008' ); # @modules = ( '<MODULE> [[<MIN_VERSION>] <MAX_VERSION>]', ... )
my $haveRequired = 1;
foreach (@modules) {my ($module, $min_v, $max_v) = split(' '); my $v = eval "require $module; $module->VERSION();"; if ( !$v || ($min_v && ($v < version->new($min_v))) || ($max_v && ($v > version->new($max_v))) ) { $haveRequired = 0; my $out = $module . ($min_v?' [v'.$min_v.($max_v?" - $max_v":'+').']':''); diag("$out is not available"); }}  ## no critic (ProhibitStringyEval)

plan skip_all => 'TAINT mode not supported (Test::MinimumVersion::all_minimum_version_from_metayml_ok() is File::Find tainted)' if in_taint_mode();
plan skip_all => '[ '.join(', ',@modules).' ] required for testing' if !$haveRequired;

Test::MinimumVersion::all_minimum_version_from_metayml_ok();

#to find hints for specific versions: perl -MPerl::MinimumVersion -e "$pmv = Perl::MinimumVersion->new( 'lib/<NAME.pm>' ); @m=$pmv->version_markers(); for ($i = 0; $i<(@m/2); $i++) {print qq{$m[$i*2] = { @{$m[$i*2+1]} }\n};}

#FROM Test-SubCalls-1.08
##!/usr/bin/perl
#
## Test that our declared minimum Perl version matches our syntax
#
#use strict;
#BEGIN {
#   $|  = 1;
#   $^W = 1;
#}
#
#my $MODULE = 'Test::MinimumVersion 0.008';
#
## Don't run tests for installs
#use Test::More;
#unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
#   plan( skip_all => "Author tests not required for installation" );
#}
#
## Load the testing module
#eval "use $MODULE";
#if ( $@ ) {
#   $ENV{RELEASE_TESTING}
#   ? die( "Failed to load required release-testing module $MODULE" )
#   : plan( skip_all => "$MODULE not available for testing" );
#}
#
#all_minimum_version_from_metayml_ok();


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
