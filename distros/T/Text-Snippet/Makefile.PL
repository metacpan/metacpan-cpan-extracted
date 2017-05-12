
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Text::Snippet',
                       'DISTNAME' => 'Text-Snippet',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Brian Phillips <bphillips@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0',
                                             'Test::Exception' => '0',
                                             'File::Find' => '0',
                                             'File::Temp' => '0',
                                             'Data::Dumper' => '0'
                                           },
                       'ABSTRACT' => 'TextMate-like snippet functionality',
                       'EXE_FILES' => [],
                       'VERSION' => '0.04',
                       'PREREQ_PM' => {
                                        'List::Util' => '0',
                                        'Scalar::Util' => '0',
                                        'Text::Balanced' => '0',
                                        'overload' => '0',
                                        'Class::XSAccessor' => '0',
                                        'Carp' => '0'
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



