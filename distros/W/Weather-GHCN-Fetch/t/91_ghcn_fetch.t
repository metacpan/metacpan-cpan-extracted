use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test::More  tests => 12;
use Test::Exception;

use Weather::GHCN::App::Fetch;

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
    BAIL_OUT "*E* cached folder is missing";
}

my $Refresh;       # control caching

my @cachefiles = path($Cachedir)->children;
if (@cachefiles > 0) {
    # do not contact the server
    $Refresh = 'never';
    ok $TRUE, "using cached files: $Cachedir\n";
} else {
    # The cache is empty, enable refreshing the cache.
    # Note that it may take some time to fetch the pages.
    # Expect the cache to be about 45 Mb
    $Refresh = 'always';
    ok $TRUE, "creating cache: $Cachedir\n";
}

BAIL_OUT "\n*E* test profile not found or unreadable: " . $PROFILE
    if not -r $PROFILE;


my $ghcn_fetch = path($Bin, '../bin', 'ghcn_fetch.pl')->stringify;

my @cmd = (
    'perl',
    '-I'  . $Lib,
    $ghcn_fetch,
);

local $, = ' ';

my $stdout;
my $stderr;
my @args;

subtest 'deabbrev' => sub {
    my $ro = Weather::GHCN::Options->deabbrev_refresh_option('y');
    is $ro, 'yearly', 'deabbrev_refresh_option';

    my $rt = Weather::GHCN::Options->deabbrev_report_type('da');
    is $rt, 'daily', 'deabbrev_report_type';
};

subtest 'get_user_options (_no_tk and _tk)' => sub {
    local @ARGV = qw(-report detail);
    my $opt_href = Weather::GHCN::App::Fetch::get_user_options_no_tk;
    is $opt_href->{'report'}, 'detail', 'get_user_options_no_tk';

    local @ARGV = qw(-report detail);

    if ( check_install(module=>'Tk') and check_install(module=>'Tk::Getopt')) {
        $opt_href = Weather::GHCN::App::Fetch::get_user_options_tk;
        is $opt_href->{'report'}, 'detail', 'get_user_options_tk';
    } else {
        ok 1, 'Tk or Tk::Getopt not installed';
    }
};

subtest 'option validation' => sub {
    my @opttable = ( Weather::GHCN::Options->get_tk_options_table() );

    @opttable = ( Weather::GHCN::Options->get_tk_options_table() );
    my $valid_rt = Weather::GHCN::Options->valid_report_type('detail',\@opttable);
    ok $valid_rt,  'valid_report_type - detail valid';
    ok !Weather::GHCN::Options->valid_report_type('xxx',\@opttable),     'valid_report_type - xxx invalid';

    my $ro = Weather::GHCN::Options->valid_refresh_option('never',\@opttable);
    ok  $ro,'valid_refresh_option - never valid';
    ok !Weather::GHCN::Options->valid_refresh_option('xxx',\@opttable),  'valid_refresh_option - xxx invalid';
};

subtest 'output to clipboard' => sub {
    if ( not check_install( module => 'Win32::Clipboard') ) {
        plan skip_all => 'no Win32::Clipboard';
    }

    my $clip = Win32::Clipboard();
    $clip->Empty();
    @args = (
        @cmd,
        '-country',     'US',
        '-state',       'NY',
        '-location',    'New York',
        '-active',      '1900-1910',
        '-report',      'yearly',
        '-refresh',     'never',
        '-profile',     $PROFILE,
        '-cachedir',    $Cachedir,
        '-outclip',
    );
    ($stdout, $stderr) = capture {
        system(@args) == 0 or syserror();
    };
    my $got = $clip->Get();
    like $got, qr/Year\s+Decade\s+TMAX\s+TMIN.*?\d{4}/ms, 'clipboard output';
};

subtest 'kml and color options' => sub {
    my @args = (
        '-kml',         '',
        '-color',       'azure',
        '-location',    'CA006105976,CA006105978',
        '-refresh',     'never',
        '-profile',     $PROFILE,
        '-cachedir',    $Cachedir,
    );

    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args );
    };

    like $stdout, qr/xml.*kml/ms, 'kml "" to stdout';

    my $tempfile = Path::Tiny->tempfile( TEMPLATE => '91_ghcn_fetch_t_XXXXXX', SUFFIX => '.tmp' );

    $args[1] = $tempfile->stringify;

    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args );
    };

    my $kml = $tempfile->slurp;

    like $kml, qr/xml.*kml/ms, 'kml <file>';
};

subtest 'station ids from file' => sub {
    my $tempfile1 = Path::Tiny->tempfile( TEMPLATE => '91_ghcn_fetch_t_1_XXXXXX', SUFFIX => '.tmp' );

    $tempfile1->touch; # create an empty file

    my $tempfile2 = Path::Tiny->tempfile( TEMPLATE => '91_ghcn_fetch_t_2_XXXXXX', SUFFIX => '.tmp' );

    my @stnids = qw( CA006105976 CA006105978 );
    $tempfile2->spew( join "\n", @stnids );

    @args = (
        '-report',      '',
        '-refresh',     'never',
        '-profile',     $PROFILE,
        '-cachedir',    $Cachedir,
    );
   
    *STDIN_SAVED = *STDIN;
    open *STDIN, '<', $tempfile1 or die;

    throws_ok {
        Weather::GHCN::App::Fetch->run( \@args );
    } qr/no station id's found/, 'no stnids found in input';

    close *STDIN or warn $!;
    *STDIN = *STDIN_SAVED;


    *STDIN_SAVED = *STDIN;
    open *STDIN, '<', $tempfile2 or die;

    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args );
    };

    like $stderr, qr/2\s+stations/, 'found 2 stations';

    close *STDIN or die $!;
    *STDIN = *STDIN_SAVED;
};

subtest 'fetch New York station metadata' => sub {
    @args = (
            '-country',     'US',
            '-state',       'NY',
            '-location',    'New York',
            '-active',      '1900-1910',
            '-report',      '',
            '-refresh',     'never',
            '-profile',     $PROFILE,
            '-cachedir',    $Cachedir,
    );

    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args );
    };

    my @result = split "\n", $stdout;

    my $hdr;
    my $matches;
    foreach my $r (@result) {
        next unless $r;
        $hdr++      if $r =~ m{ \A StationId \t Country }xms;
        $matches++  if $r =~ m{ NEW \s YORK }xms;
        last if $r =~ m{ \A Options: }xms;
    }

    is $hdr, 1, 'Weather::GHCN::App::Fetch returned a header';
    is $matches, 11, 'Weather::GHCN::App::Fetch returned 9 entries for NEW YORK';
};

subtest '-loc cda -report monthly -range 2000-2001 -dataonly' => sub {
    @args = (
            '-location',    'cda',
            '-report',      'monthly',
            '-range',       '2000-2001',
            '-dataonly',
            '-refresh',     'never',
            '-profile',     $PROFILE,
            '-cachedir',    $Cachedir,
    );

    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args );
    };

    like $stdout, qr/Year\s+Month\s+Decade.*?TMAX\s+TMIN.*?\d{4}/ms, 'data found';
    unlike $stdout, qr/Notes:.*?StationId.*?Options:/ms, 'no station data in stdout';
};

subtest 'fetch daily -loc cda -range 2000-2001 -fmonth 6 -performance' => sub {
    @args = (
            'daily',
            '-location',    'cda',
            '-fmonth',      6,
            '-range',       '2000-2000',
            '-performance',
            '-refresh',     'never',
            '-profile',     $PROFILE,
            '-cachedir',    $Cachedir,
    );

    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args );
    };

    like $stdout, qr/Year\s+Month\s+Day.*?TMAX\s+TMIN.*?\d{4}/ms, 'data found';
    like $stdout, qr/Notes:.*?StationId.*?Options:/ms, 'no station data in stdout';
    like $stdout, qr/Timing statistics/ms, 'performance statistics found';
};

subtest 'fetch with unrecognized options' => sub {
    @args = (
            'daily',
            '-location',    'cda',
            '-fmonth',      6,
            '-range',       '2000-2000',
            '-INVALID_OPTION',
            '-refresh',     'never',
            '-profile',     $PROFILE,
            '-cachedir',    $Cachedir,
    );

    throws_ok {
        Weather::GHCN::App::Fetch->run( \@args );
    } qr/unrecognized options: -INVALID_OPTION/ms, 'invalid option';
};

#---------------------------------------------------------------------
# ADD NEW TESTS ABOVE THIS COMMENT!!!
#---------------------------------------------------------------------

# Putting this test last, because for some unknown reason it causes
# all subsequent test to fail
subtest 'options readme, usage and help' => sub {
    @args = ('-readme');
    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args )
    };
    like $stdout, qr/Source:/, $args[0];

    @args = ( '-usage' );
    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args )
    };
    like $stdout, qr/Usage:/, $args[0];

    @args = ('-?');
    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args )
    };
    like $stdout, qr/Usage:/, $args[0];

    @args = ('-help');
    ($stdout, $stderr) = capture {
        Weather::GHCN::App::Fetch->run( \@args )
    };
    like $stdout, qr/NAME/, $args[0];
};

# DO NOT ADD TEST HERE!

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