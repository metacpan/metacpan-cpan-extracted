#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use File::Spec;
use Win32::Backup::Robocopy;

use lib '.';
use t::bkpscenario;

my $ret = bkpscenario::check_robocopy_version();
ok ( scalar keys %$ret > 0, "robocopy.exe details retrieved" );
my $verbose;
foreach my $ver ( keys %$ret ){	
	note "FOUND: $ver => ",$$ret{$ver} ? $$ret{$ver} : 'NOT DEFINED';
	BAIL_OUT( "Bugged version 5.1.2600.26 of robocopy.exe spotted" ) if $$ret{$ver} eq '5.1.2600.26'; 
	unless ( $$ret{$ver} =~ /^6|^10/ ){
		$verbose = 1;		
	}
}
bkpscenario::check_robocopy_version('VERBOSE') if $verbose;

# this is almost the same check present in the BEGIN block of Makefile.PL
my $robocopy;
# exe in ENV has precedence
if ( $ENV{PERL_ROBOCOPY_EXE} ){
	print "ENV var PERL_ROBOCOPY_EXE set with value: [$ENV{PERL_ROBOCOPY_EXE}]\n";
	$robocopy = $ENV{PERL_ROBOCOPY_EXE};
}
# ..or we check in PATH
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
unless ( -e -s $robocopy ){
		BAIL_OUT "given executable [$robocopy] is not here or is empty\n";
}
my $exit = system "$robocopy /? >nul 2>&1";
ok ( 16 == ($exit>>8), "[$robocopy /? >nul 2>&1] returned the expected value");
# all went well..
note "[$robocopy] seems to be valid\n";


done_testing();