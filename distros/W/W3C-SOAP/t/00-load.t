#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use_ok('W3C::SOAP');
use_ok('W3C::SOAP::Base');
use_ok('W3C::SOAP::Client');
use_ok('W3C::SOAP::Document');
use_ok('W3C::SOAP::Document::Node');
use_ok('W3C::SOAP::Exception');
use_ok('W3C::SOAP::Header');
use_ok('W3C::SOAP::Header::Security');
use_ok('W3C::SOAP::Header::Security::Username');
use_ok('W3C::SOAP::WSDL');
use_ok('W3C::SOAP::WSDL::Parser');
use_ok('W3C::SOAP::WSDL::Document');
use_ok('W3C::SOAP::WSDL::Document::Operation');
use_ok('W3C::SOAP::WSDL::Document::Service');
use_ok('W3C::SOAP::WSDL::Document::Node');
use_ok('W3C::SOAP::WSDL::Document::Binding');
use_ok('W3C::SOAP::WSDL::Document::Port');
use_ok('W3C::SOAP::WSDL::Document::Policy');
use_ok('W3C::SOAP::WSDL::Document::Message');
use_ok('W3C::SOAP::WSDL::Document::InOutPuts');
use_ok('W3C::SOAP::WSDL::Document::PortType');
use_ok('W3C::SOAP::WSDL::Meta::Method');
use_ok('W3C::SOAP::WSDL::Utils');
use_ok('W3C::SOAP::Parser');
use_ok('W3C::SOAP::XSD');
use_ok('W3C::SOAP::XSD::Document::SimpleType');
use_ok('W3C::SOAP::XSD::Document::Type');
use_ok('W3C::SOAP::XSD::Document::Node');
use_ok('W3C::SOAP::XSD::Document::Element');
use_ok('W3C::SOAP::XSD::Document::List');
use_ok('W3C::SOAP::XSD::Document::ComplexType');
use_ok('W3C::SOAP::XSD::Parser');
use_ok('W3C::SOAP::XSD::Traits');
use_ok('W3C::SOAP::XSD::Document');
use_ok('W3C::SOAP::XSD::Types');
use_ok('W3C::SOAP::Utils');


diag( "Testing W3C::SOAP::XSD::VERSION, Perl $], $^X" );
done_testing();
