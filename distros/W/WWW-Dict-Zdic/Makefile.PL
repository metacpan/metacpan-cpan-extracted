use strict;
use warnings;
use inc::Module::Install;

name 'WWW-Dict-Zdic';
all_from 'lib/WWW/Dict/Zdic.pm';

requires
    'WWW::Dict' => 0,
    'Class::Field' => 0,
    'WWW::Mechanize' => 0,
    'Encode' => 0,
    'URI::Escape' => 0,
    'HTML::Entities' =>0,
    'HTML::TagParser' =>0;

build_requires 'Test::More' => 0;

install_script  'bin/dict-zdic';

auto_install;
WriteAll;
