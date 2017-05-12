
use strict;
use warnings;

use Module::Build 0.3601;

my %module_build_args = (
                          'build_requires' => {
                                               'Devel::SimpleTrace' => '0',
                                               'English'            => '0',
                                               'File::Spec'         => '0',
                                               'Find::Lib'          => '0',
                                               'HTTP::Request'      => '0',
                                               'Module::Build'      => '0.3601',
                                               'Path::Class'        => '0',
                                               'Test::More'         => '0',
                                               'constant'           => '0',
                                               'vars'               => '0'
                                              },
                          'configure_requires' => {
                                                   'ExtUtils::MakeMaker' => '6.31',
                                                   'Module::Build'       => '0.3601'
                                                  },
                          'dist_abstract'        => 'CSS3 selectors support for WWW::Mechanize',
                          'dist_author'          => ['San Kumar (original author)'],
                          'dist_name'            => 'WWW-Mechanize-Query',
                          'dist_version'         => '1.40',
                          'license'              => 'perl',
                          'module_name'          => 'WWW::Mechanize::Query',
                          'recommends'           => {},
                          'recursive_test_files' => 1,
                          'requires'             => {
                                         'Cache::FileCache'       => '0',
                                         'Carp'                   => '0',
                                         'Data::Dump'             => '0',
                                         'Moose'                  => '0',
                                         'Storable'               => '2.21',
                                         'Mojo::DOM'              => '0',
                                         'WWW::Mechanize'         => '0',
                                         'WWW::Mechanize::Cached' => '0',
                                        },
                          'script_files' => []
                        );

my $build = Module::Build->new( %module_build_args );

$build->create_build_script;
