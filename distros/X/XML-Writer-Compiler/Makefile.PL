
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'produce aoa from tree',
  'AUTHOR' => 'Terrence Brannon',
  'BUILD_REQUIRES' => {
    'Class::MOP' => '0',
    'HTML::Element' => '0',
    'HTML::Element::Library' => '0',
    'Test::Kit' => '0',
    'Test::More' => '0',
    'Test::XML' => '0',
    'XML::Element' => '0',
    't::lib::My::Shopping' => '0',
    't::lib::T' => '0',
    't::lib::U' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'XML-Writer-Compiler',
  'EXE_FILES' => [
    'bin/tmp.xml',
    'bin/xwc',
    'bin/tmp.xml',
    'bin/xwc'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'XML::Writer::Compiler',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Data::Diver' => '0',
    'Data::Dumper' => '0',
    'File::Path' => '0',
    'File::Spec' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Perl::Tidy' => '0',
    'XML::TreeBuilder' => '0',
    'XML::Writer' => '0',
    'XML::Writer::String' => '0',
    'autodie' => '0'
  },
  'VERSION' => '1.112060',
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



