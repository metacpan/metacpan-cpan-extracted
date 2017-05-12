use Config;
use Data::Dumper;
use constant {  MIN_PERL_VERSION => 5.008001 };
unless ( $] >= MIN_PERL_VERSION ){
	print STDERR "Perl 5.8.1 required would not build\n";
	exit;
}

unless ( $ENV{FORCE} || $^O=~m/MSWin32/i || $^O=~/Cygwin/i ) {
	print STDERR "Win32 required. Would not build\n";
	exit;
};

# ActivePerl && MinGW Fix
# It seems than with MinGW && AvtivePerl 
# is badly linking we are correcting this
BEGIN{
	if ($Config{ cc } =~m/\bgcc\b/ ){
		$ENV{ACTIVEPERL_CONFIG_libs} = '-lkernel32' ;
	};
};

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Win32::FindFile',
    VERSION_FROM      => 'lib/Win32/FindFile.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	ABSTRACT_FROM  => 'lib/Win32/FindFile.pm', # retrieve abstract from module
	AUTHOR         => 'A.G. Grishayev <gtoly@cpan.org>',
    LIBS              => [], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    $ExtUtils::MakeMaker::VERSION >= 6.48 ?  (MIN_PERL_VERSION => MIN_PERL_VERSION) : (),
	$ExtUtils::MakeMaker::VERSION >= 6.31 ?  ( LICENSE => 'perl') : (),

	# Un-comment this if you add C files to link with later:
	# OBJECT            => '$(O_FILES)', # link all the C files too
);
