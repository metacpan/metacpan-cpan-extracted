
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                       'dist_abstract' => 'a rotating gauge for tk',
                       'dist_author' => [
                                          'Jerome Quelin'
                                        ],
                       'dist_name' => 'Tk-RotatingGauge',
                       'script_files' => [],
                       'module_name' => 'Tk::RotatingGauge',
                       'requires' => {
                                       'DateTime' => 0,
                                       'English' => 0,
                                       'FindBin' => 0,
                                       'Time::HiRes' => 0,
                                       'Test::More' => 0,
                                       'perl' => '5.008',
                                       'Tk::Canvas' => 0,
                                       'POSIX' => 0,
                                       'File::Find' => 0,
                                       'Tk::Derived' => 0,
                                       'Tk' => 0
                                     },
                       'license' => 'perl'
                     );


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
