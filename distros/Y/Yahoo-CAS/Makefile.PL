#!/usr/local/bin/perl

use inc::Module::Install;

name        ('Yahoo-CAS');
author      ('Hsin-Chan Chien <hcchien@hcchien.org>');
abstract    ('offer a simple interface for Yahoo! Taiwan CAS open APIs.');
license     ('perl');
version_from('lib/Yahoo/CAS.pm');
requires    (qw(
	    perl 5.8.1
	    Test::More 0
	    LWP::Simple 0
	    XML::Simple 0
	    ));
WriteAll    ( sign => 1 );

