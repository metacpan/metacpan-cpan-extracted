#!/usr/bin/env perl
# $File: //member/autrijus/only-latest/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 8676 $ $only: 2003/11/01 06:14:05 $

use 5.006;
use inc::Module::Install;

name	    ( 'only-latest' );
abstract    ( 'Always use the latest version of a module in @INC' );
author	    ( 'Autrijus Tang (autrijus@autrijus.org)' );
version_from( 'lib/only/latest.pm' );
license	    ( 'perl' );
sign	    ( 1 );

&Meta->write;
&Makefile->write;
