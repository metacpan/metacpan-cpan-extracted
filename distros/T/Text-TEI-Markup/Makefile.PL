#!/usr/bin/perl
use 5.008003;
use inc::Module::Install;
author( 'Tara L Andrews <aurum@cpan.org>' );
license( 'perl' );
all_from( 'lib/Text/TEI/Markup.pm' );
requires( 'perl' => '5.008003' );
requires( 'XML::LibXML' );
test_requires( 'Convert::Number::Armenian' );
test_requires( 'Test::More::UTF8' );
test_requires( 'Test::Warn' );
test_requires( 'XML::LibXML::XPathContext' );
&WriteAll;
