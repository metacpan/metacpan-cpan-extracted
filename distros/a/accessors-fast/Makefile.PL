use inc::Module::Install;

name     'accessors-fast';
all_from 'lib/accessors/fast.pm';
version   my $v = '0.03';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs', '0.90';

requires 'constant::def', '0.01';
requires 'Class::Accessor::Fast';
requires 'Class::C3';
requires 'Hash::Util';
recommends 'Class::Accessor::Fast::XS';

provides 'accessors::fast' => {
	version => $v,
	file    => 'lib/accessors/fast.pm',
};

auto_install;

WriteAll;

