#!/usr/bin/perl
  use Module::Build;
      Module::Build->new(
  # 'module_name'                   => 'Time::PT',
    'dist_name'                     => 'Time-PT',
  # 'dist_version_from'             => 'PT.pm',
    'dist_version'                  => '1.2.565EHOV',
    'dist_abstract'                 => 'objects to store an instant in time',
    'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
  # 'create_readme'                 => '1',
  # 'create_makefile_pl'            => '1',
    'license'                       => 'gpl',
    'script_files'                  => {
      'bin/pt'                        => '1',
      'bin/fpt'                       => '1',
      'bin/lspt'                      => '1',
    },
    'requires'                      => {
      'Time::Zone'                    => '0',
      'Time::DayOfWeek'               => '0',
      'Time::Local'                   => '0',
      'Time::DaysInMonth'             => '0',
      'Time::HiRes'                   => '0',
      'Math::BaseCnv'                 => '0',
    },
  )->create_build_script();