#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
BEGIN {
    use_ok( 'MARC::Moose::Record' );
    use_ok( 'MARC::Moose::Field' );
    use_ok( 'MARC::Moose::Field::Std' );
    use_ok( 'MARC::Moose::Field::Control' );
    use_ok( 'MARC::Moose::Parser' );
    use_ok( 'MARC::Moose::Parser::Iso2709' );
    use_ok( 'MARC::Moose::Parser::Marcxml' );
    use_ok( 'MARC::Moose::Parser::MarcxmlSax' );
    use_ok( 'MARC::Moose::Formater' );
    use_ok( 'MARC::Moose::Formater::Iso2709' );
    use_ok( 'MARC::Moose::Formater::Marcxml' );
    use_ok( 'MARC::Moose::Formater::Yaml' );
    use_ok( 'MARC::Moose::Formater::Text' );
    use_ok( 'MARC::Moose::Reader' );
    use_ok( 'MARC::Moose::Reader::File' );
    use_ok( 'MARC::Moose::Reader::File::Iso2709' );
    use_ok( 'MARC::Moose::Reader::File::Marcxml' );
    use_ok( 'MARC::Moose::Reader::String');
    use_ok( 'MARC::Moose::Reader::String::Iso2709' );
    use_ok( 'MARC::Moose::Writer' );
}
