use inc::Module::Install;

name     'Test-Dist';
all_from 'lib/Test/Dist.pm';
version my $v = '0.01';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'Test::If';
build_requires 'Test::NoWarnings';
build_requires 'lib::abs', '0.90';

requires 'ExtUtils::MakeMaker';
requires 'ExtUtils::Manifest';
requires 'Array::Diff';
requires 'Module::CPANTS::Analyse';

provides 'Test::Dist' => {
	version => $v,
	file    => 'lib/Test/Dist.pm',
};

auto_install;

WriteAll;

1;
