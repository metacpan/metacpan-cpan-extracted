use inc::Module::Install;

name     'Text-MarkPerl';
all_from 'lib/Text/MarkPerl.pm';
author   q{mucker <mukcer@gmx.com>};
license  'perl';
version_from 'lib/Text/MarkPerl.pm';
install_script 'script/markperl.pl';

requires 'Modern::Perl' => 0;
requires 'Data::Pairs' => 0;
requires 'Text::Balanced' => 0;
requires 'HTML::Parser' => 0;

test_requires  'Capture::Tiny'  => 0;
test_requires  'Test::Differences'  => 0;
test_requires  'Test::More'  => '0.42';
no_index       'directory'   => 'demo';


build_requires 'Test::More';

auto_install;

WriteAll;

