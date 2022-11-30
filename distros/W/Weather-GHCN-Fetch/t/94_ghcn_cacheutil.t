use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test::More  tests => 8;
use Test::Exception;

use Weather::GHCN::App::CacheUtil;

use Capture::Tiny             qw( capture );
use Const::Fast;
use English                   qw( -no_match_vars );
use Module::Load::Conditional qw( check_install );
use Path::Tiny;

use if $OSNAME eq 'MSWin32', 'Win32::Clipboard';

my $Bin = $FindBin::Bin;
my $Lib = $Bin . '/../lib';

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $PROFILE => path($Bin)->child('ghcn_fetch.yaml')->stringify;


my $Cachedir = path($Bin,'ghcn_cache')->stringify;

if (not -d $Cachedir) {
    BAIL_OUT '*E* cache folder is missing: ' . $Cachedir;
}

BAIL_OUT "\n*E* test profile not found or unreadable: " . $PROFILE
    if not -r $PROFILE;


# my $ghcn_cacheutil = path($Bin, '../bin', 'ghcn_cacheutil')->stringify;

# my @cmd = (
    # 'perl',
    # '-I'  . $Lib,
    # $ghcn_cacheutil,
# );

local $, = ' ';

my $GHCN;
my $Opt;
my $Alias_href;
my $Files_href;

BEGIN {
    # create a short alias name for that long package name
    *CU:: = \*Weather::GHCN::App::CacheUtil::;
}

subtest 'round' => sub {
    is CU::round(0  ), 0, 'round 0';
    is CU::round(0.4), 0, 'round 0.4';
    is CU::round(0.5), 1, 'round 0.5';
    is CU::round(0.6), 1, 'round 0.6';
    is CU::round(1  ), 1, 'round 1';
};

subtest 'match_type' => sub {
    is CU::match_type( 'D', ''   ), 1, 'match D <empty>';
    is CU::match_type( 'A', 'A'  ), 1, 'match A A';
    is CU::match_type( 'A', 'AD' ), 1, 'match A AD';
    is CU::match_type( 'C', 'C'  ), 1, 'match C C';
    is CU::match_type( 'C', 'AC' ), 1, 'match C AC';
    is CU::match_type( 'D', 'D'  ), 1, 'match D D';
    is CU::match_type( 'D', 'A'  ), 0, 'no match D A';
    is CU::match_type( 'D', 'AC' ), 0, 'no match D AC';
};

subtest 'get_options' => sub {
    my @argv = qw();
    $CU::Opt = CU::get_options( \@argv );
    like ref $CU::Opt, qr/^Hash::Wrap::Class::/, 'get_options with no args';
};

subtest 'get_ghcn' => sub {
    $GHCN = CU::get_ghcn( $PROFILE, $Cachedir );
    isa_ok $GHCN, 'Weather::GHCN::StationTable';
    is $GHCN->cachedir, $Cachedir, 'ghcn->cachedir';
    is ref $GHCN->profile_href, 'HASH', '$ghcn->profile_href is a HASH';
    ok 0 < keys $GHCN->profile_href->%*, '$ghcn->profile_href has multiple keys';
};

subtest 'get_alias_stnids' => sub {
    my $Alias_href = CU::get_alias_stnids( $GHCN->profile_href );
    is scalar keys $Alias_href->%*, 5, 'get_alias_stnids returned 5 stnids';
};

subtest 'load_cached_files' => sub {
    my $cache_pto = path($GHCN->cachedir);  # pto = Path::Tiny object
    $Files_href = CU::load_cached_files($GHCN, $cache_pto, $Alias_href);
    is scalar keys $Files_href->%*, 6, 'load_cached_files returned 6 entries';
    my $includes = grep { $_->{INCLUDE} } values $Files_href->%*;
    is $includes, 6, 'filter_files worked';
};

subtest 'report_daily_files' => sub {
    my $total_kb;
    my ($stdout, $stderr) = capture {
        $total_kb = CU::report_daily_files($Files_href);       
    };
    ok $total_kb > 0, 'report_daily_files returned non-zero kb';
    like $stdout, qr/T StationId/, 'report_daily_files generated output';
};

subtest '-outclip' => sub {
    plan skip_all => 'testing clipboard output seems to fail during dzil -release';
};

done_testing();

######################################################################
# Subroutines
######################################################################

sub syserror {
    if ($? == -1) {
        warn "failed to execute: $!\n";
    }
    elsif ($? & 127) {
        printf {*STDERR} "child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    else {
        printf {*STDERR} "child exited with value %d\n", $? >> 8;
    }
}