#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
# use Test::Exception;
# use Capture::Tiny qw(capture);
# use Win32::File qw(:DEFAULT GetAttributes SetAttributes);
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

done_testing();



