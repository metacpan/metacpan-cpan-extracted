#!/usr/bin/env perl

use 5.006;
use inc::Module::Install;

author		('Audrey Tang <audreyt@audreyt.org>');
name		('WWW-REST');
abstract	('Base class for REST resources');
perl_version    ('5.006');
version_from	('lib/WWW/REST.pm');
license         ('CC0');

include_deps	('Test::More', 5.006);
build_requires	('Test::More', 0);

requires(
    'URI'		    => 0,
    'HTTP::Request::Common' => 0,
    'LWP::UserAgent'	    => 0,
    'Class::Struct'	    => 0,
);

WriteAll( sign => 1 );
