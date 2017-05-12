use strict;
use warnings;
use Test::More qw[no_plan];
use File::Temp qw[tempdir];
use File::Spec;
use_ok('App::SmokeBrew');

unlink('smokebrew.cfg');

{
mkdir 'dist';
my $tmpdir = tempdir( DIR => 'dist', CLEANUP => 1 );
$tmpdir = File::Spec->rel2abs($tmpdir);
my $build  = File::Spec->catdir( $tmpdir, 'build' );
my $prefix = File::Spec->catdir( $tmpdir, 'prefix' );
open my $fh, '>', 'smokebrew.cfg' or die "$!\n";
print $fh <<HERE;
email=foo\@bar.com
builddir=$build
prefix=$prefix
mx=mx.foo.com
plugin=CPANPLUS::YACSmoke
perlargs=-Dusemallocwrap=y
perlargs=-Dusemymalloc=n
HERE
close $fh;
@ARGV = ('--configfile', 'smokebrew.cfg', '--perlargs', '-Dusethreads');
my $app = App::SmokeBrew->new_with_options();
isa_ok($app,'App::SmokeBrew');
is( $app->email, 'foo@bar.com', 'Email option is okay' );
is( $app->mx, 'mx.foo.com', 'MX option is okay' );
is( $app->builddir, $build, 'Build dir option is okay' );
is( $app->prefix, $prefix, 'Prefix dir option is okay' );
is( $app->plugin, 'App::SmokeBrew::Plugin::CPANPLUS::YACSmoke', 'Plugin option is okay' );
is( ref $app->perlargs, 'ARRAY', 'Perlargs is an ARRAYref');
}
