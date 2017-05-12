use 5.014;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'WWW-Fimfiction';
all_from 'lib/WWW/Fimfiction.pm';

test_requires 'Test::More' => 0;

requires (
	'HTML::TreeBuilder' => 0,
	'LWP::UserAgent' => 0,
	'HTTP::Cookies' => 0,
	'XML::Twig' => 0,
	'JSON' => 0,
	'Carp' => 0,
);

recommends 'JSON::XS';

WriteAll;
