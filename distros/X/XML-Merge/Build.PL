#!/usr/bin/perl
use Module::Build;
my $mbld = Module::Build->new(
# 'module_name'                   => 'XML::Merge',
  'dist_name'                     => 'XML-Merge',
# 'dist_version_from'             => 'Tidy.pm',
  'dist_version'                  => '1.4',
  'dist_abstract'                 => 'flexibly merge XML documents',
  'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
# 'create_readme'                 => '1',
# 'create_makefile_pl'            => '1', # 'traditional',
  'license'                       => 'gpl_3',
  'script_files'                  => {
  },
  'pm_files'                      => {
    'Merge.pm'                      => 'lib/XML/Merge.pm',
  },
  'requires'                      => {
    'Test'                          => '0',
    'Test::More'                    => '0',
    'Test::Pod'                     => '0',
    'Test::Pod::Coverage'           => '0',
    'Carp'                          => '0',
    'XML::Tidy'                     => '0',
  },
);
$mbld->create_build_script();
