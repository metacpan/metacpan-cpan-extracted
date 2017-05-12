
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'YUI::Loader',
                       'DISTNAME' => 'YUI-Loader',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Robert Krimen <robertkrimen@gmail.com>',
                       'BUILD_REQUIRES' => {
                                             'Directory::Scratch' => '0',
                                             'Test::Most' => '0'
                                           },
                       'ABSTRACT' => 'Load (and cache) the Yahoo JavaScript YUI framework',
                       'EXE_FILES' => [],
                       'VERSION' => '0.071',
                       'PREREQ_PM' => {
                                        'Scalar::Util' => '0',
                                        'HTML::Declare' => '0',
                                        'File::Copy' => '0',
                                        'URI' => '0',
                                        'Carp::Clan::Share' => '0',
                                        'LWP::UserAgent' => '0',
                                        'Path::Class' => '0',
                                        'Algorithm::Dependency' => '0',
                                        'JSON' => '2.08',
                                        'Path::Abstract' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM}; 
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod}; 
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



