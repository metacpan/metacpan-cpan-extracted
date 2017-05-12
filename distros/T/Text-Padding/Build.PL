
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'simple way of formatting a text',
  'dist_author' => [
    'Jerome Quelin'
  ],
  'dist_name' => 'Text-Padding',
  'dist_version' => '1.110170',
  'license' => 'perl',
  'module_name' => 'Text::Padding',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Moose' => '0',
    'MooseX::Has::Sugar' => '0',
    'Text::Truncate' => '0',
    'perl' => '5.012'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
