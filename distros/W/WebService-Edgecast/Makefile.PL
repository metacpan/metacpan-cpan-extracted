
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Perl interface to Edgecast\'s SOAP API',
  'AUTHOR' => 'James Conerly <jconerly@cpan.org>',
  'BUILD_REQUIRES' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'DISTNAME' => 'WebService-Edgecast',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'WebService::Edgecast',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Std::Fast::Storable' => '0',
    'Module::Pluggable' => '0',
    'Moose' => '0',
    'SOAP::WSDL::Client::Base' => '0',
    'SOAP::WSDL::XSD::Typelib::Builtin::double' => '0',
    'SOAP::WSDL::XSD::Typelib::Builtin::int' => '0',
    'SOAP::WSDL::XSD::Typelib::Builtin::long' => '0',
    'SOAP::WSDL::XSD::Typelib::Builtin::short' => '0',
    'SOAP::WSDL::XSD::Typelib::Builtin::string' => '0',
    'SOAP::WSDL::XSD::Typelib::Builtin::unsignedInt' => '0',
    'SOAP::WSDL::XSD::Typelib::ComplexType' => '0',
    'SOAP::WSDL::XSD::Typelib::Element' => '0',
    'Scalar::Util' => '0',
    'XML::Simple' => '0'
  },
  'VERSION' => '0.01.00',
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



