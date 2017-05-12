use inc::Module::Install;

name     'Test-Script-Run';
all_from 'lib/Test/Script/Run.pm';
readme_from 'lib/Test/Script/Run.pm';
author   'sunnavy <sunnavy@bestpractical.com>';
license  'perl';

test_requires 'Test::More';
requires 'IPC::Run3';
requires 'Test::Exception';
recommends($^O =~ /MSWin/ ? 'Win32::ShellQuote' : 'String::ShellQuote' );

auto_install;
recursive_author_tests('xt/');

WriteAll;

