# cpanfile
requires 'perl', '5.008004';

requires 'Exporter',               '5.7';
requires 'File::Find::Rule',       '0.33';
requires 'File::Find::Rule::Perl', '1.13';
requires 'File::Slurp::Tiny',      '0.003';
requires 'List::AllUtils',         '0.09';
requires 'Parse::CPAN::Meta',      '1.4414';
requires 'Software::LicenseUtils', '0.10301';
requires 'Test::Builder',          '1.001006';
requires 'Try::Tiny',              '0.22';
requires 'constant',               '1.27';
requires 'parent',                 '0.228';
requires 'version',                '0.9909';

on test => sub {
	requires 'Test::More',     '1.001006';
	requires 'Test::Requires', '0.08';

	suggests 'ExtUtils::MakeMaker',   '6.82';
	suggests 'File::Spec::Functions', '3.47';
	suggests 'Test::Pod',             '1.48';
	suggests 'Test::Pod::Coverage',   '1.1';
};

