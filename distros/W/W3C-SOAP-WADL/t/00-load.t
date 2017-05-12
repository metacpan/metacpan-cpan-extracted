#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

use_ok('W3C::SOAP::WADL::Document::Response');
use_ok('W3C::SOAP::WADL::Document::ResourceType');
use_ok('W3C::SOAP::WADL::Document::Resources');
use_ok('W3C::SOAP::WADL::Document::Resource');
use_ok('W3C::SOAP::WADL::Document::Request');
use_ok('W3C::SOAP::WADL::Document::Representation');
use_ok('W3C::SOAP::WADL::Document::Param');
use_ok('W3C::SOAP::WADL::Document::Option');
use_ok('W3C::SOAP::WADL::Document::Method');
use_ok('W3C::SOAP::WADL::Document::Link');
use_ok('W3C::SOAP::WADL::Document::Grammars');
use_ok('W3C::SOAP::WADL::Document::Doc');
use_ok('W3C::SOAP::WADL::XSD');
use_ok('W3C::SOAP::WADL::Document');
use_ok('W3C::SOAP::WADL::Element');
use_ok('W3C::SOAP::WADL::Meta::Method');
use_ok('W3C::SOAP::WADL::Traits');
use_ok('W3C::SOAP::WADL::Parser');
use_ok('W3C::SOAP::WADL::Utils');
use_ok('W3C::SOAP::WADL');

diag( "Testing W3C::SOAP::WADL $W3C::SOAP::WADL::VERSION, Perl $], $^X" );
done_testing();
