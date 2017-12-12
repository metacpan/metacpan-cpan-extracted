use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Circle',
   dist_name   => 'circle-be',
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   requires => {
      'Attribute::Storage' => '0.09',
      'Class::Method::Modifiers' => 0,
      'Data::Dump' => 0,
      'File::Basename' => 0,
      'File::Path' => 0,
      'File::ShareDir' => 0,
      'IO::Async::Listener' => '0.64',
      'IO::Async::Loop' => '0.37',
      'Module::Pluggable' => '4.1', # force_search_all_paths
      'Net::Async::IRC' => '0.10',
      'Net::Async::Tangence::Server' => '0.13',
      'String::Tagged' => '0.11',
      'Struct::Dumb' => 0,
      'Tangence::Message' => '0.11',
      'Tangence::Object' => '0.18',
      'Tangence::Registry' => '0.20', # late-loading of classes
      'YAML' => 0,
      'perl' => '5.010',
   },
   test_requires => {
      'Test::Identity' => 0,
      'Test::More' => 0,
   },
   share_dir => {
      module => { "Circle" => "share" },
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
