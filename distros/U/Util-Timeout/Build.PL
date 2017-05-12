
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'thin wrapper around Sys::SigAction::timeout_call',
  'dist_author' => [
    'Ben Hengst <notbenh@cpan.org>'
  ],
  'dist_name' => 'Util-Timeout',
  'dist_version' => '0.01',
  'license' => 'perl',
  'module_name' => 'Util::Timeout',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Devel::Declare::Parser::Sublike' => '0.017',
    'Exporter::Declare' => '0.103',
    'POSIX' => '0',
    'Sys::SigAction' => '0.11',
    'Test::Most' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
