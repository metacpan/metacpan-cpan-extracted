# End-to-end test for lazy's @INC hook against a real install.
#
# What this proves:
#   Given a "missing" module that lazy is asked to load, the hook installed
#   into @INC by `use lazy` invokes App::cpm::CLI and the module ends up on
#   disk inside the requested -L directory.
#
# How it works:
#   - We stage a tiny fixture distribution (Local::StaticInstall) under
#     t/test-data/darkpan. That dist sets x_static_install: 1 in its META,
#     so the install exercises App::cpm's static-install code path.
#   - `use lazy` is told to install into a per-test tempdir and to prefer
#     the local darkpan (--resolver 02packages,$darkpan) over the public
#     CPAN. The first resolver hit is what gets used, so the darkpan wins.
#   - We then locate lazy's @INC code-ref hook and call it directly with
#     'Local::StaticInstall' to simulate Perl asking @INC for the module.
#     Calling the hook directly (instead of `require Local::StaticInstall`)
#     keeps the test honest even if lazy's hook ordering changes.
#
# Network dependency:
#   Test::RequiresInternet skips the test when the listed hosts are
#   unreachable. cpan.metacpan.org and metadb are still consulted for
#   resolution metadata that the local darkpan does not provide on its
#   own, so this test is *not* fully offline.
#
# When this test fails on a smoker:
#   The diag block at the bottom dumps stderr, stdout, the cpm build log
#   (if cpm pointed at one), the installed file list, and the Perl /
#   App::cpm versions in play. That last bit matters: failures have
#   historically clustered around specific App::cpm versions — the
#   0.998000–0.999.x range is broken for x_static_install, fixed in
#   v1.0.0 (see GH#36), so version info up-front is what unblocks
#   debugging.

use strict;
use warnings;

use Test::More import => [qw( diag done_testing like ok plan )];

# App::cpm 0.998000 through 0.999.x die with "Invalid option linkage for
# install_base=s" when installing this fixture's x_static_install
# distribution. The bug was introduced in 0.998000 and fixed in v1.0.0;
# 0.997017 (and earlier) and v1.0.0+ both work. The bug reproduces on
# every Perl we tested, so the gate is on the cpm version, not on $].
# Our DynamicPrereqs cap pins Perl < 5.24 to 0.997017, so this skip is
# a runtime safety net for smokers that may already have a broken cpm
# installed (GH#36).
use App::cpm ();
use version  ();

BEGIN {
    my $v = version->parse($App::cpm::VERSION);
    if ( $v >= version->parse('0.998000') && $v < version->parse('v1.0.0') ) {
        plan skip_all =>
            "App::cpm $App::cpm::VERSION static-install path is broken; see GH#36";
    }
}

use local::lib qw( --no-create );

use Capture::Tiny        qw( capture );
use Path::Iterator::Rule ();
use Test::RequiresInternet (
    'cpan.metacpan.org'        => 443,
    'cpanmetadb.plackperl.org' => 80,
    'fastapi.metacpan.org'     => 443,
);

my $darkpan;
my $dir;

BEGIN {
    use Path::Tiny qw( path tempdir );

    $darkpan = path('t/test-data/darkpan')->stringify;
    $dir     = tempdir();
}

# Install in local lib even if it's already installed elsewhere. However, we
# will add lazy to @INC *after* all of the other use statements, so that we
# don't accidentally try to install any test deps here.
#
# Args explained:
#   -L $dir                     install into the per-test tempdir
#   --workers 1                 deterministic single-process install for
#                               cleaner diag output
#   --resolver 02packages,$dp   prefer the local darkpan
#   --resolver metadb           on perl < 5.16 only: secondary resolver
#                               needed because some resolution paths fail
#                               on old perls (added in commit 8b8220f5)
#   --reinstall                 force install even if already present in @INC
#   -v                          verbose stderr — the test asserts on it
use lazy (
    '-L', $dir, '--workers', 1, '--resolver',
    '02packages,' . $darkpan,
    $^V < 5.16 ? ( '--resolver', 'metadb' ) : (),
    '--reinstall', '-v'
);

# Find the @INC code-ref that `use lazy` just installed and call it
# directly with the fixture name. The hook returns nothing useful — its
# side effect is the actual install via App::cpm::CLI->run.
my ($cb) = grep { ref $_ eq 'CODE' } @INC;
my ( $stdout, $stderr, @result )
    = capture { $cb->( undef, 'Local::StaticInstall' ) };

# App::cpm prints "DONE install Local-StaticInstall-..." (and similar) to
# stderr in verbose mode. We just look for "installed" as a loose proof.
like( $stderr, qr{installed}, 'module installed' );

# Walk the local lib looking for the .pm we expect cpm to have written.
my $rule = Path::Iterator::Rule->new->file->nonempty;
my $found;
{
    my $next = $rule->iter($dir);
    while ( defined( my $file = $next->() ) ) {
        if ( $file =~ m{StaticInstall.pm\z} ) {
            $found = 1;
            last;
        }
    }
    ok( $found, 'file installed locally' );
}

# Failure-only diagnostics. The smoker reports we get back are often the
# only signal we have, so dump everything that is cheap to produce.
if ( !$found ) {

    # Versions first — these are usually the most useful signal when a
    # smoker fails (see GH#36 for the version-correlation analysis).
    diag "Perl version: $^V";
    diag "App::cpm version: "
        . ( defined $App::cpm::VERSION ? $App::cpm::VERSION : '(unknown)' );

    diag 'STDERR: ' . $stderr;
    diag 'STDOUT: ' . $stdout;

    # cpm writes a per-run build log and prints "See <path> for details"
    # when an install fails. Slurp it inline so the smoker report is
    # self-contained.
    if ( $stderr =~ m{See (.*) for details} ) {
        diag path($1)->slurp;
    }

    diag 'The following files were installed:';
    my $next = $rule->iter($dir);
    while ( defined( my $file = $next->() ) ) {
        diag $file;
    }
}

done_testing();
