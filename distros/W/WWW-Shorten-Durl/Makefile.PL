use inc::Module::Install;
name 'WWW-Shorten-Durl';
all_from 'lib/WWW/Shorten/Durl.pm';

requires 'WWW::Shorten' => '2.05';
tests 't/*.t';
build_requires 'Test::More';
resources repository => 'git://github.com/JEEN/p5-WWW-Shorten-Durl.git';
use_test_base;
auto_include;
WriteAll;
