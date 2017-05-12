use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Circle::FE::Gtk',
   dist_name   => 'circle-fe-gtk',
   requires => {
      'Glib' => 0,
      'Gtk2' => 0,
      'IO::Async' => '0.14',
      'IO::Async::Loop::Glib' => 0,
      'Net::Async::Tangence::Client' => '0.08',
      'Tangence::ObjectProxy' => '0.18',
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   share_dir => {
      dist => "share",
   },
   license => 'gpl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
