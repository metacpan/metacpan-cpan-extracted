#!/usr/bin/perl
use Module::Build;
my $mbld = Module::Build->new(
# 'module_name'                   => 'Tk::AbstractCanvas',
  'dist_name'                     => 'Tk-AbstractCanvas',
# 'dist_version_from'             => 'AbstractCanvas.pm',
  'dist_version'                  => '1.4.A7QFZHF',
  'dist_abstract'                 => 'Canvas with Abstract center, zoom, && rotate methods',
  'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
# 'create_readme'                 => '1',
# 'create_makefile_pl'            => '1', # 'traditional',
  'license'                       => 'gpl',
  'script_files'                  => {
  },
  'pm_files'                      => {
    'AbstractCanvas.pm'             => 'lib/Tk/AbstractCanvas.pm',
  },
  'requires'                      => {
    'Test'                          => '0',
    'Test::Pod'                     => '0',
    'Test::Pod::Coverage'           => '0',
    'Tk'                            => '0',
    'Tk::Canvas'                    => '0',
    'Tk::Derived'                   => '0',
    'Tk::pKGnAME'                   => '0',
  },
);
$mbld->create_build_script();