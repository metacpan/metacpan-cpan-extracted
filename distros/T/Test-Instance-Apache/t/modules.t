use strict;
use warnings;

use Test::More;
use File::Temp;
use IO::All;

use Test::Instance::Apache::Modules;

my $tmp_dir = File::Temp->newdir;

my $modules = Test::Instance::Apache::Modules->new(
  server_root => $tmp_dir->dirname,
  modules => [ qw/ authz_core headers / ],
);

$modules->load_modules;

ok ( -d File::Spec->catdir( $tmp_dir->dirname, 'mods-available' ), "Mods Available Dir Created" );
ok ( -d File::Spec->catdir( $tmp_dir->dirname, 'mods-enabled' ), "Mods Enabled Dir Created" );

done_testing;
