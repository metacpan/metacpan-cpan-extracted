use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# check OS
BEGIN{
	unless ( $^O =~ /MSWin32|cygwin/i ){
		die "OS $^O unsupported!"; 
	}
}
# check robocopy.exe
BEGIN{
	require File::Spec;
	my $robocopy;
	# exe in ENV has precedence
	if ( $ENV{PERL_ROBOCOPY_EXE} ){
		print "ENV var PERL_ROBOCOPY_EXE set with value: [$ENV{PERL_ROBOCOPY_EXE}]\n";
		$robocopy = $ENV{PERL_ROBOCOPY_EXE};
	}
	# ..or we check in PATH
	# gently 'inspired' by File::Which
	# https://metacpan.org/source/PLICEASE/File-Which-1.23/lib/File/Which.pm
	else{
		my @paths = split( ';', $ENV{PATH} );
		s/"//g for @paths;
		@paths = grep length, @paths;
		foreach my $dir ( @paths ){
			my $candidate = File::Spec->catfile( $dir, 'robocopy.exe' );
			if ( -e -s $candidate ){
				$robocopy = $candidate;
				last;
			}
		}	
	}
	# check if defined
	unless ( defined $robocopy ){
		die "robocopy.exe not found! ".
				($ENV{PERL_ROBOCOPY_EXE} 	? 
				'' 							: 
				' (you can set environment variable PERL_ROBOCOPY_EXE to a custom path) ')
		;
	}
	# check if exist
	unless ( -e -s $robocopy ){
			die "given executable [$robocopy] is not here or is empty";
	}
	# check it returns a valid result
	my $ret = system "$robocopy /? >nul 2>&1";
	unless ( 16 == ($ret>>8) ){
		die "[$robocopy /? >nul 2>&1] did not returned the expected value";
	}
	# all went well..
	print "[$robocopy] seems to be valid\n"
}


WriteMakefile(
    NAME             => 'Win32::Backup::Robocopy',
    AUTHOR           => q{LorenzoTa <lorenzo@cpan.org>},
    VERSION_FROM     => 'lib/Win32/Backup/Robocopy.pm',
    ABSTRACT_FROM    => 'lib/Win32/Backup/Robocopy.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
		'Win32'				=> '0',
		'Win32::File'		=> '0',
		'Test::Exception' 	=> '0',
		'File::Path'		=> '0',
        
    },
    PREREQ_PM => {
        'Test::More' 		=> '0',
		'Carp'				=> '0',
		'File::Spec'		=> '0',
		'File::Path'		=> '0', # failed tests with 2.8 on 5.10
		'JSON::PP'			=> '0',
		'Capture::Tiny'		=> '0',
		'Algorithm::Cron'	=> '0',
		'Time::Piece'		=> '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Win32-Backup-Robocopy-*' },
);
