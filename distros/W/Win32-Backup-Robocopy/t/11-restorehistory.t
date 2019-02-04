#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Win32::Backup::Robocopy;

use lib '.';
use t::bkpscenario;


# invalid strings
dies_ok { Win32::Backup::Robocopy->_validate_upto( 'akatasbra' ) } 
	"_validate_upto is expected to die with insane string 1";

dies_ok { Win32::Backup::Robocopy->_validate_upto( '2008-09:21T20-02-00' ) } 
	"_validate_upto is expected to die with insane string 2";

dies_ok { Win32::Backup::Robocopy->_validate_upto( '2008:09-21T20-02-00' ) } 
	"_validate_upto is expected to die with insane string 3";

dies_ok { Win32::Backup::Robocopy->_validate_upto( '' ) } 
	"_validate_upto is expected to die with insane string 4";

# this epoch corresponds to: 2008-09-21T20:02:00	
my $epoch = 1222027320; 

# epoch
ok ( Win32::Backup::Robocopy::_validate_upto( $epoch ) eq $epoch,
	"_validate_upto ok with seconds since epoch");

# valid strings 
ok ( Win32::Backup::Robocopy::_validate_upto( '2008-09-21T20:02:00' ) eq $epoch,
	"_validate_upto ok with valid string 1");

ok ( Win32::Backup::Robocopy::_validate_upto( '2008-09-21T20:02-00' ) eq $epoch,
	"_validate_upto ok with valid string 2");

ok ( Win32::Backup::Robocopy::_validate_upto( '2008-09-21T20-02:00' ) eq $epoch,
	"_validate_upto ok with valid string 3");
	
ok ( Win32::Backup::Robocopy::_validate_upto( '2008-09-21T20-02-00' ) eq $epoch,
	"_validate_upto ok with valid string 4");


SKIP: {
		# DateTime::Tiny object
        eval { require DateTime::Tiny; 1 } or skip "DateTime::Tiny not installed";
        my $datetimetiny = DateTime::Tiny->from_string( '2008-09-21T20:02:00' );
        ok ( Win32::Backup::Robocopy::_validate_upto( $datetimetiny ) eq $epoch,
			"_validate_upto ok with DateTime::Tiny object");
		
		# DateTime object
        eval { require DateTime; 1 } or skip "DateTime not installed";
        my $datetime = $datetimetiny->DateTime;
        ok ( Win32::Backup::Robocopy::_validate_upto( $datetime ) eq $epoch,
			"_validate_upto ok with DateTime object");
}


#######################################################################
# a real minimal bkp scenario
#######################################################################
my ($tbasedir,$tsrc,$tdst) = bkpscenario::create_dirs('test-backup');
BAIL_OUT( "unable to create temporary folders!" ) unless $tbasedir;
note("created backup scenario in $tbasedir");

my $file1 = 'Foscolo_A_Zacinto.txt';		

# a backup with history
my $bkp = Win32::Backup::Robocopy->new(
	name => 'test',
	source	 => $tsrc,
	dst => $tdst,
	history => 1,	
);
# make 4 history backup folders to have a history restore
my @created_folders;
foreach my $part(0..3){
	my $tfh1 = bkpscenario::open_file($tsrc,$file1);
	BAIL_OUT( "unable to create temporary file!" ) unless $tfh1;
	bkpscenario::update_file($tfh1, $part);
	my (undef,undef,$exit,undef,$createdfolder) = $bkp->run;
	BAIL_OUT "failed backup!" unless $exit < 8;
	push @created_folders,$createdfolder;
	note ("updated $file1 and backed up to $createdfolder");
	sleep 2;	
}

# restore all backups because of no 'upto' parameter
$bkp->restore(  
				from => File::Spec->catdir ( $tdst,'test' ), 
				to => $tbasedir 
);

# check if restored file is complete..
ok (bkpscenario::check_last_line($tbasedir, $file1, "  il fato illacrimata sepoltura.\n"),
	"restored file $file1 has the expected content ( restoring all history folders )");

# restore upto third backup	
$bkp->restore(  
				from => File::Spec->catdir ( $tdst,'test' ), 
				to => $tbasedir,
				upto => $created_folders[2],
				# BROKEN verbose =>1,
);					
# check if restored file has right content
ok (bkpscenario::check_last_line($tbasedir, $file1, "  baciò la sua petrosa Itaca Ulisse"),
	"restored file $file1 has the expected content ( restoring upto $created_folders[2] )");

# restore upto second backup
$bkp->restore(  
				from => File::Spec->catdir ( $tdst,'test' ), 
				to => $tbasedir,
				upto => $created_folders[1],
				# BROKEN verbose =>1,
);					
# check if restored file has right content
ok (bkpscenario::check_last_line($tbasedir, $file1, "  l'inclito verso di colui che l'acque"),
	"restored file $file1 has the expected content ( restoring upto $created_folders[1] )");

# restore upto first backup
$bkp->restore(  
				from => File::Spec->catdir ( $tdst,'test' ), 
				to => $tbasedir,
				upto => $created_folders[0],
				# BROKEN verbose =>1,
);					
# check if restored file has right content
ok (bkpscenario::check_last_line($tbasedir, $file1, "  del greco mar da cui vergine nacque"),
	"restored file $file1 has the expected content ( restoring upto $created_folders[0] )");
	
# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");					