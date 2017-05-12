use strict;
use warnings;
use Test::More;

BEGIN {
  eval { use WorePAN 0.09; 1; }
    or plan skip_all => 'requires WorePAN 0.09';

  eval { use File::pushd; 1; }
    or plan skip_all => 'requires File::pushd';
}

my $worepan = WorePAN->new(
  files => ['ISHIGAKI/WorePAN-0.09.tar.gz'],
  no_network => 0,
  cleanup => 1,
  no_indices => 1,
  verbose => 0,
);

$worepan->walk(callback => sub {
  my $basedir = shift;

  # pass

  $basedir->file("xt/perms.t")->save(<<'TEST', {mkdir => 1});
use Test::PAUSE::Permissions;
local $ENV{RELEASE_TESTING} = 1;
all_permissions_ok('ISHIGAKI');
TEST

  my $dir = pushd($basedir);
  my $output = `prove -l xt/perms.t`;
  like $output => qr/Result: PASS/;
  # note $output;

  # Case: fail

  $basedir->file("xt/perms.t")->save(<<'TEST', {mkdir => 1});
use Test::PAUSE::Permissions;
local $ENV{RELEASE_TESTING} = 1;
all_permissions_ok('LOCAL');
TEST

  $output = `prove -l xt/perms.t`;
  like $output => qr/Result: FAIL/;
  # note $output;
});


$worepan = WorePAN->new(
  files => ['ISHIGAKI/DBD-SQLite-1.50.tar.gz'],
  no_network => 0,
  cleanup => 1,
  no_indices => 1,
  verbose => 0,
);

$worepan->walk(callback => sub {
  my $basedir = shift;

  # pass

  $basedir->file("xt/perms.t")->save(<<'TEST', {mkdir => 1});
use Test::PAUSE::Permissions;
local $ENV{RELEASE_TESTING} = 1;
all_permissions_ok('ISHIGAKI', {strict => 1});
TEST

  my $dir = pushd($basedir);
  my $output = `prove -l xt/perms.t`;
  like $output => qr/Result: PASS/;
  # note $output;

  # Case: fail

  $basedir->file("xt/perms.t")->save(<<'TEST', {mkdir => 1});
use Test::PAUSE::Permissions;
local $ENV{RELEASE_TESTING} = 1;
all_permissions_ok('ISHIGAKI', {strict => 1});
TEST

  $basedir->file("lib/DBD/SQLite/NOSUCHMODULE.pm")->save("package "."DBD::SQLite::NOSUCHMODULE; 1");
  my $manifest = $basedir->file("MANIFEST");
  $manifest->save($manifest->slurp."\nlib/DBD/SQLite/NOSUCHMODULE.pm\n");

  $output = `prove -l xt/perms.t`;
  like $output => qr/Result: FAIL/;
  note $output;
});

done_testing;
