use inc::Module::Install;

name 'Test-Log-Dispatch';
abstract 'Test what you are logging';
all_from 'lib/Test/Log/Dispatch.pm';
author 'Jonathan Swartz <swartz@pobox.com>';

perl_version '5.006';

build_requires 'Test::More'  => 0;

requires 'Log::Dispatch::Array' => 0;
requires 'List::MoreUtils' => 0;

license 'perl';

auto_install;

WriteAll;
