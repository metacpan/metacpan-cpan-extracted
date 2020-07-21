use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Variable::Eject',
	VERSION_FROM      => 'lib/Variable/Eject.pm',
	ABSTRACT_FROM     => 'lib/Variable/Eject.pm',
	PREREQ_PM         => {
		'uni::perl'      => 0.03,
		'Devel::Declare' => '0.005011',
		'Lexical::Alias' => '0.04'
	},
	TEST_REQUIRES => {
		'lib::abs'      => 0.90,
		'Test::If'      => 0,
		'Test::More'    => 0,
	},
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LICENSE           => 'perl',
);

__END__
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

