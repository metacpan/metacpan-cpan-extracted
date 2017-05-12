use strict;
use inc::Module::Install;

name('WWW-RobotRules-Parser');
all_from('lib/WWW/RobotRules/Parser.pm');

requires("LWP::UserAgent");
requires("URI");
build_requires('Test::More');

auto_install;
WriteAll;