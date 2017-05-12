
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.31',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Perl interface to Edgecast\'s SOAP API',
  'dist_author' => [
    'James Conerly <jconerly@cpan.org>'
  ],
  'dist_name' => 'WebService-Edgecast',
  'dist_version' => '0.01.00',
  'license' => 'artistic_2',
  'module_name' => 'WebService::Edgecast',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
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
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
