#!/usr/bin/env perl

use inc::Module::Install;
author( 'Tara L Andrews <aurum@cpan.org>' );
license( 'perl' );
perl_version( '5.012' );
all_from( 'lib/Text/Tradition/Directory.pm' );
requires( 'Class::Load' );
requires( 'DBI' );
requires( 'JSON' );
requires( 'KiokuDB::Backend::DBI' );
requires( 'KiokuDB::GC::Naive' );
requires( 'KiokuDB::TypeMap' );
requires( 'KiokuDB::TypeMap::Entry::Naive' );
requires( 'KiokuX::Model' );
requires( 'KiokuX::User::Util' );
requires( 'Moose' );
requires( 'Moose::Role' );
requires( 'Safe::Isa' );
requires( 'Text::Tradition' => '1.1' );
requires( 'TryCatch' );
requires( 'YAML::XS' );
requires( 'namespace::clean' );
build_requires( 'Test::Warn' );
build_requires( 'Test::Memory::Cycle' );
build_requires( 'Test::More::UTF8' );
&WriteAll;
