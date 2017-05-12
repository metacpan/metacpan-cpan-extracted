use inc::Module::Install;

name('YAX');
author('Richard Hundt <perl@kulabs.com>');
abstract('Yet Another XML Library');
license('artistic');
version_from('lib/YAX.pm');
build_requires('Test::More');

my @depends = qw/
    Scalar::Util
/;

requires( map { $_ => undef } @depends );

check_nmake();
&WriteAll();
