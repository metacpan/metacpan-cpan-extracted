use strict;
use vars qw{$VERSION};
BEGIN {
	require 5.003_96;
	$VERSION = '2.03';
}
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Text::Balanced',
	ABSTRACT     => 'Extract delimited text sequences from strings',
	VERSION_FROM => 'lib/Text/Balanced.pm',
	INSTALLDIRS  => ($] >= 5.007003 ? 'perl' : 'site'),
	PREREQ_PM    => {
		# Skip on Windows to avoid breaking ActivePerl PPMs
		# 0.47 means 5.6.2 or newer, which everyone on Win32 has.
		($^O eq 'MSWin32' ? () : ('Test::More' => '0.47')),
	},
	($] >= 5.005 ? (
		AUTHOR  => 'Adam Kennedy <adamk@cpan.org>',
	) : ()),
	($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : ()),
);
