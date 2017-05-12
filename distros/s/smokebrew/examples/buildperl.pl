use strict;
use warnings;
use App::SmokeBrew::BuildPerl;

my $bp = App::SmokeBrew::BuildPerl->new(
  version     => '5.12.0',
  builddir   => 'dist/build',
  prefix      => 'dist/prefix',
  skiptest    => 1,
  verbose     => 1,
  conf_opts   => [ '-Dusemallocwrap=y', '-Dusemymalloc=n' ],
);

my $prefix = $bp->build_perl();

print $prefix, "\n";
