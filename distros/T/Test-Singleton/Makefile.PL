use inc::Module::Install;

name('Test-Singleton');
author('Toni Prug <toni@irational.org>');
abstract('Testing for Singleton Class');
license('gpl');
version_from('lib/Test/Singleton.pm');

build_requires(qw(
	    Test::Builder::Tester 0
	    Class::Singleton 0
));

requires(qw(
	    Test::More 0.44
	    Test::Builder 0.16
));

auto_install;
WriteAll;
