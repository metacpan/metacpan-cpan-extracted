use 5.006;
use inc::Module::Install;

name     'Test-If';
all_from 'lib/Test/If.pm';
version   my $v = '0.01';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'lib::abs', '0.90';
requires 'Test::More';
requires 'Test::Builder';

auto_install;

provides 'Test::If' => {
	version => $v,
	file    => 'lib/Test/If.pm',
};

WriteAll;

