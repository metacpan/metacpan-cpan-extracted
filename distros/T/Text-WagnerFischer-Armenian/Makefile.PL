#!/usr/bin/perl
use 5.008003;
use inc::Module::Install;
author( 'Tara L Andrews <aurum@cpan.org>' );
license( 'perl' );
all_from( 'lib/Text/WagnerFischer/Armenian.pm' );
requires( 'Text::WagnerFischer' );
requires( 'perl' => 5.008003 );
&WriteAll;
