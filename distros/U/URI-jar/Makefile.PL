use inc::Module::Install;

name('URI-jar');
author('Toru Yamaguchi');
version_from('lib/URI/jar.pm');
abstract('Java ARchive URI');
license('perl');

requires('URI');

use_test_base;

auto_include;
auto_install;

WriteAll;
