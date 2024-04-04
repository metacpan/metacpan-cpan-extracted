use Test::More;
use strict;
use warnings;
use Path::Tiny;
require lib::root;

my $app_dir = "app-root-test";
my $root    = path( Path::Tiny->rootdir, "tmp" );
my $app     = $root->child( $app_dir );
my @expected_lib_path
  = ( Path::Tiny->rootdir, qw|tmp app-root-test perl * lib| );

my %paths = (
  bin_script  => $app->child( qw|bin scripts script.pl| ),
  bin_script2 => $app->child( qw|bin script2.pl| ),
  one         => $app->child( qw|perl MyApp-One lib MyApp One.pm| ),
  two         => $app->child( qw|perl MyApp-Two lib MyApp Two Core.pm| ),
  three       => $app->child( qw|perl MyApp-Three lib MyApp Three.pm| ),
  perlversion => $app->child( qw|perl .perl-version| ),
  libroot     => $app->child( qw|perl .libroot| ),
  app2        => $app->child( qw|perl-app2 App2 lib App2 Main.pm| ),
  app2root    => $app->child( qw|perl-app2 .libroot| ),
  app3        => $app->child( qw|sub dir perl-app3 App3 lib App3 Main.pm| ),
  app3root    => $app->child( qw|sub dir perl-app3 .libroot| ),
  approot     => $app->child( qw|.app-root| ),
  app4 => $app->child( qw|sub dir perl-app4 App4 lib App4 Production.pm| ),
);

&create_appdir();

{
  # given a caller file loading lib::root:
  # find the default .libroot file path
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test perl .libroot| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ),
      'found default .libroot file';
  };
  lib::root->import(
    caller_file => $paths{ one },
    callback    => $cb,
  );
}

{
  # given a caller file loading lib::root:
  # use the .perl-version to determine perl modules root dir
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test perl .perl-version| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ), 'found .perl-version';
  };
  lib::root->import(
    caller_file => $paths{ two },
    callback    => $cb,
    rootfile    => '.perl-version',
  );
}

{
  # the caller is the bin script inside bin/scripts/script.pl
  # use the .perl-version to determine perl modules root dir that is cousin of bin
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test perl .perl-version| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ), 'found .perl-version';
  };
  lib::root->import(
    caller_file => $paths{ bin_script },
    perldir     => 'perl',
    callback    => $cb,
    rootfile    => '.perl-version',
  );
}

{
  # the caller is the bin script inside bin/script2.pl
  # use the .libroot to determine perl modules root dir that is cousin of bin
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test perl .libroot| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ), 'found .libroot';
  };
  lib::root->import(
    caller_file => $paths{ bin_script2 },
    perldir     => 'perl',
    callback    => $cb,
  );
}

{
  # the caller is the bin script inside bin/script2.pl
  # use the .libroot to determine perl modules for app2
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test perl-app2 .libroot| );
    my @expected_lib_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test perl-app2 * lib| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ), 'found .libroot';
  };
  lib::root->import(
    caller_file => $paths{ bin_script2 },
    perldir     => 'perl-app2',
    callback    => $cb,
  );
}

{
  # the caller is the bin script inside bin/script2.pl
  # use the .libroot to determine perl modules for app3
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = qw|/ tmp app-root-test sub dir perl-app3 .libroot|;
    my @expected_lib_path = ( Path::Tiny->rootdir,
      qw|tmp app-root-test sub dir perl-app3 * lib| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ), 'found .libroot';
  };
  lib::root->import(
    caller_file => $paths{ bin_script2 },
    perldir     => 'sub/dir/perl-app3',
    callback    => $cb,
  );
}

{
  # the caller is the bin script inside bin/scripts/script2.pl
  # use the .app-root plus the perldir to determine perl root dir
  # .app-root is in: /tmp/app-root-test/.app-root
  #   perldir is in: /tmp/app-root-test/sub/dir/perl-app4
  # perl libs is in: /tmp/app-root-test/sub/dir/perl-app4/*/lib
  my $cb = sub {
    my $libpaths = shift;
    my $rootfile = shift;
    my @expected_rootfile_path
      = ( Path::Tiny->rootdir, qw|tmp app-root-test .app-root| );
    my @expected_lib_path = ( Path::Tiny->rootdir,
      qw|tmp app-root-test sub dir perl-app4 * lib| );
    is $libpaths, path( @expected_lib_path ), 'modules are in perl/*/lib';
    is $rootfile, path( @expected_rootfile_path ), 'found .app-root';
  };
  lib::root->import(
    rootfile    => '.app-root',
    caller_file => $paths{ bin_script },
    perldir     => 'sub/dir/perl-app4',
    callback    => $cb,
  );
}

&cleanup();

sub create_appdir
{
  &cleanup();
  for my $key ( keys %paths ) { $paths{ $key }->touchpath; }
}

sub cleanup
{
  $app->remove_tree( { safe => 0 } );
}

done_testing;
