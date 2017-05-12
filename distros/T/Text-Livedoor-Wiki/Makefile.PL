use strict;
use warnings;
use inc::Module::Install;

name 'Text-Livedoor-Wiki';
author 'polocky';
all_from 'lib/Text/Livedoor/Wiki.pm';
requires 'Test::Deep'        => 0;
requires 'Test::Base'        => 0.56 ;
requires 'Test::Exception'   => 0;
requires 'Test::Memory::Cycle'=>0;
requires 'Module::Pluggable' => 0;
requires 'UNIVERSAL::require' => 0;
requires 'Class::Data::Inheritable' => 0;
requires 'Scalar::Util' => 0;
license 'perl';
auto_install;
WriteAll;

