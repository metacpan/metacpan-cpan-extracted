use strict;
use warnings;
use local::lib qw( --no-create );

use Capture::Tiny        qw( capture );
use Path::Iterator::Rule ();
use Test::More import => [qw( diag done_testing like ok )];
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
use lazy (
    '-L', $dir, '--workers', 1, '--resolver',
    '02packages,' . $darkpan,
    $^V < 5.16 ? ( '--resolver', 'metadb' ) : (),
    '--reinstall', '-v'
);

# Acme::CPANAuthors::Canadian has static_install enabled.  This may resolve
# some issues with circular requires on CPAN Testers reports.
my ($cb) = grep { ref $_ eq 'CODE' } @INC;
my ( $stdout, $stderr, @result )
    = capture { $cb->( undef, 'Local::StaticInstall' ) };
like( $stderr, qr{installed}, 'module installed' );

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

# Mostly helpful for CPANTesters reports
if ( !$found ) {
    diag 'STDERR: ' . $stderr;
    diag 'STDOUT: ' . $stdout;
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
