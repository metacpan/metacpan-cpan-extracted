
use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my %WriteMakefileArgs = (
                          'ABSTRACT'       => 'CSS3 selectors support for WWW::Mechanize',
                          'AUTHOR'         => 'San Kumar (original author)',
                          'BUILD_REQUIRES' => {
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
                          'CONFIGURE_REQUIRES' => {
                                                   'ExtUtils::MakeMaker' => '6.31',
                                                   'Module::Build'       => '0.3601'
                                                  },
                          'DISTNAME'  => 'WWW-Mechanize-Query',
                          'EXE_FILES' => [],
                          'LICENSE'   => 'perl',
                          'NAME'      => 'WWW::Mechanize::Query',
                          'PREREQ_PM' => {
                                          'Cache::FileCache'       => '0',
                                          'Carp'                   => '0',
                                          'Data::Dump'             => '0',
                                          'Moose'                  => '0',
                                          'Storable'               => '2.21',
                                          'Mojo::DOM'              => '0',
                                          'WWW::Mechanize'         => '0',
                                          'WWW::Mechanize::Cached' => '0',
                                         },
                          'VERSION' => '0.03',
                          'test'    => {'TESTS' => 't/*.t'}
                        );

unless ( eval { ExtUtils::MakeMaker->VERSION( 6.56 ) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod ( keys %$br ) {
        if ( exists $pp->{$mod} ) {
            $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
        } else {
            $pp->{$mod} = $br->{$mod};
        }
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION( 6.52 ) };

WriteMakefile( %WriteMakefileArgs );

