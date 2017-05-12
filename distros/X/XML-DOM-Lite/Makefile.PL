use inc::Module::Install;

name('XML-DOM-Lite');
author('Richard Hundt <richard@protea-systems.com>');
abstract('Lite Pure Perl XML DOM Parser');
license('artistic');
version_from('lib/XML/DOM/Lite.pm');
build_requires('Test::More');

requires('Scalar::Util');
requires('perl' => '5.8.3');

check_nmake();
&WriteAll();

