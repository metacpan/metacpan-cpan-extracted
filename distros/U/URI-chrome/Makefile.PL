use inc::Module::Install;

name('URI-chrome');
author('Toru Yamaguchi <zigorou@cpan.org>');
version_from('lib/URI/chrome.pm');
abstract('Mozilla chrome uri');
license('perl');

requires('URI');
requires('Carp::Clan');

use_test_base;

auto_include;
auto_install;

WriteAll;
