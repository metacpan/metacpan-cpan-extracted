use 5.016;
use strict;
use warnings;

use ExtUtils::MakeMaker;

sub _find_in_path {
    my ($exe) = @_;
    my $path_env = $ENV{PATH} // '';
    for my $dir (split /[:;]/, $path_env) {
        next unless $dir;
        my $candidate = "$dir/$exe";
        return $candidate if -x $candidate;
        if ($^O eq 'MSWin32' && $exe !~ /\.exe$/i) {
            my $win_candidate = "$dir/$exe.exe";
            return $win_candidate if -x $win_candidate;
        }
    }
    return;
}

my $chromium_found;
for my $exe (qw(chromium chrome chromium-browser google-chrome msedge)) {
    $chromium_found = _find_in_path($exe);
    last if $chromium_found;
}
if (!$chromium_found) {
    warn "WARNING: Chromium/Chrome not found in PATH. ",
        "WWW::Crawl::Chromium will require chromium_path or chrome_path.\n";
}

my %dist;
if ($^O eq 'MSWin32') {
    $dist{COMPRESS} = q{perl -MIO::Compress::Gzip=gzip,:constants -e "my $$in = $$ARGV[0]; gzip($$in => qq($$in.gz), q(Level) => Z_BEST_COMPRESSION, q(BinModeIn) => 1) or die q(gzip failed); unlink $$in;"};
    $dist{SUFFIX}   = 'gz';
}

WriteMakefile(
    NAME         => 'WWW::Crawl',
    VERSION      => '0.5',
    ABSTRACT     => 'Lightweight web crawler with optional JS rendering',
    AUTHOR       => 'Ian Boddison <bod@cpan.org>',
    LICENSE      => 'perl',

    MIN_PERL_VERSION => '5.016',

    PREREQ_PM => {
        'HTTP::Tiny' => '0.083',
        'URI'        => '5.05',
        'JSON::PP'   => '2.00',
        'Carp'       => 0,
        'IPC::Run'   => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => 0,
    },

    clean => {
        FILES => 'WWW-Crawl-*',
    },

    dist => \%dist,
);
