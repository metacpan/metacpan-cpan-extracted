use inc::Module::Install;

name     'WWW-FreshBooks-API';
all_from 'lib/WWW/FreshBooks/API.pm';
author   'Anthony Decena <anthony@mindelusions.com>';
license  'perl';

build_requires  'Test::More';
requires		'Class::Accessor::Children::Fast' => '0.02';
requires		'Iterator::Simple' => 0;
requires		'LWP::UserAgent' => 0;
requires		'XML::Simple' => 0;

auto_install;

WriteAll;

