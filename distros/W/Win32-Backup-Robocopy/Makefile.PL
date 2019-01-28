use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN{
	unless ( $^O =~ /MSWin32|cygwin/i ){
		die "OS $^O unsupported!"; 
	}
}

WriteMakefile(
    NAME             => 'Win32::Backup::Robocopy',
    AUTHOR           => q{LorenzoTa <lorenzo@cpan.org>},
    VERSION_FROM     => 'lib/Win32/Backup/Robocopy.pm',
    ABSTRACT_FROM    => 'lib/Win32/Backup/Robocopy.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        
    },
    PREREQ_PM => {
        'Test::More' => '0',
		'Carp'		=> '0',
		'File::Spec'		=> '0',
		'File::Path'		=> '0',
		'JSON::PP'		=> '0',
		'Capture::Tiny'		=> '0',
		'DateTime::Tiny'		=> '0',
		'Algorithm::Cron'		=> '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Win32-Backup-Robocopy-*' },
);
