use strict;
use warnings;
use local::lib qw( --no-create );

use Capture::Tiny qw( capture );
use Path::Iterator::Rule ();
use Path::Tiny qw( path );
use Test::More;
use Test::TempDir::Tiny qw( tempdir );
use Test::RequiresInternet (
    'cpan.metacpan.org'        => 443,
    'cpanmetadb.plackperl.org' => 80,
    'fastapi.metacpan.org'     => 443,
);

my $dir;

BEGIN {
    $dir = tempdir();
}

# Install in local lib even if it's already installed elsewhere. However, we
# will add lazy to @INC *after* all of the other use statements, so that we
# don't accidentally try to install any test deps here.
use lazy ( '-L', $dir, '--reinstall', '-v' );

my ($cb) = grep { ref $_ eq 'CODE' } @INC;
my ( $stdout, $stderr, @result )
    = capture { $cb->( undef, 'Try::Tiny' ) };
like( $stderr, qr{installed}, 'module installed' );

my $rule = Path::Iterator::Rule->new->file->nonempty;
my $next = $rule->iter($dir);
my $found;
while ( defined( my $file = $next->() ) ) {
    if ( $file =~ m{Tiny.pm\z} ) {
        $found = 1;
        last;
    }
}
ok( $found, 'file installed locally' );

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

{
    my ( $stdout, $stderr, @result ) = eval {
        capture { $cb->( undef, 'Try::Tiny' ) }
    };
    like(
        $stderr,
        qr{Code in package "main" is attempting to load Try::Tiny from inside an eval, so we are not installing Try::Tiny},
        'module not installed from inside an eval'
    );
    note $stderr;
}

done_testing();
