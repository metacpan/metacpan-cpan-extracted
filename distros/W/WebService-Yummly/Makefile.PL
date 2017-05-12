
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs =
  (
   'ABSTRACT' => 'Interface to Yummly API',
   'AUTHOR' => 'davehodg@cpan.com <David Hodgkinson>',
   'BUILD_REQUIRES' =>
   {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0',
    'Test::More'   => '0',
    'Pod::Coverage'   => '0',
    'Test::Pod::Coverage' => '0',
    'Test::Pod'   => '0',
    'Test::Most' => '0',
    'Test::Portability::Files' => '0',
    'Test::Synopsis' => '0',
    'Test::Vars' => '0',
    'Test::DistManifest' => '0',
    'Test::CPAN::Meta' => '0',
    'Test::EOL' => '0',
    'Test::HasVersion' => '0',
    'Test::Kwalitee' => '0',
    'Test::MinimumVersion' => '0',
    'Test::NoTabs' => '0',
    'Pod::Coverage::TrustPod' => '0',
   },
   'CONFIGURE_REQUIRES' => {
                            'ExtUtils::MakeMaker' => '6.31'
                           },
   'DISTNAME' => 'WebService-Yummly',
   'EXE_FILES' => [],
   'LICENSE' => 'perl',
   'NAME' => 'WebService::Yummly',
   'PREREQ_PM' =>
   {
    'HTML::TreeBuilder'   => '0',
    'WebService::Simple'  => '0',
    'URL::Encode'   => '0',
   },
   'VERSION' => '1.3',
   'test' => {
              'TESTS' => 't/*.t'
             }
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



