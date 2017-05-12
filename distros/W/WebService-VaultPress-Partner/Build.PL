
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'The VaultPress Partner API Client',
  'dist_author' => [
    'SymKat <symkat@symkat.com>'
  ],
  'dist_name' => 'WebService-VaultPress-Partner',
  'dist_version' => '0.05',
  'license' => 'bsd',
  'module_name' => 'WebService::VaultPress::Partner',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'JSON' => '0',
    'LWP' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
