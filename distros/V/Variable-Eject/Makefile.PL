use 5.010;
use inc::Module::Install;

name     'Variable-Eject';
all_from 'lib/Variable/Eject.pm';
version   my $v = '0.02';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

perl_version 5.010;

build_requires 'lib::abs' => '0.90';
build_requires 'Test::If';
build_requires 'Test::More';

requires 'uni::perl'      => '0.03';
requires 'Devel::Declare' => '0.005011'; # recommended
#requires 'Devel::Declare' => '0.005002'; # tested with
requires 'Lexical::Alias' => '0.04';

provides 'Variable::Eject' => {
	version => $v,
	file    => 'lib/Variable/Eject.pm',
};

auto_install;

WriteAll;

