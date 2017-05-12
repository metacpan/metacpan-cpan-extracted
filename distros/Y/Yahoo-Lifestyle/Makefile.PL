#!/usr/local/bin/perl

use inc::Module::Install;

name        ('Yahoo-Lifestyle');
author      ('Hsin-Chan Chien <hcchien@hcchien.org>');
abstract    ('offer a simple interface for Yahoo! Taiwan Lifestyle open APIs.');
license     ('perl');
version_from('lib/Yahoo/Lifestyle.pm');
requires    (qw(
	    perl 5.8.1
	    Test::More 0
	    Yahoo::BBAuth 0
	    LWP::Simple 0
	    XML::Simple 0
	    ));
WriteAll    ( sign => 1 );

