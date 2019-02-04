#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Win32::Backup::Robocopy;

use lib '.';
use t::bkpscenario;

#######################################################################
# a real minimal bkp scenario
#######################################################################
my ($tbasedir,$tsrc,$tdst) = bkpscenario::create_dirs();
BAIL_OUT( "unable to create temporary folders!" ) unless $tbasedir;
note("created backup scenario in $tbasedir");

my $file1 = 'Foscolo_A_Zacinto.txt';
my $tfh1 = bkpscenario::open_file($tsrc,$file1);
BAIL_OUT( "unable to create temporary file!" ) unless $tfh1;

bkpscenario::update_file($tfh1,0);			

# a backup without history
my $bkp = Win32::Backup::Robocopy->new(
	name => 'test',
	source	 => $tsrc,
	dst => $tdst,	
);

# check parameters passed to restore call
dies_ok { $bkp->restore() } 
	"restore is expected to die without parameters";

dies_ok { $bkp->restore( to => $tsrc ) } 
	"restore is expected to die without 'from' parameter";

dies_ok { $bkp->restore( from => $tdst ) } 
	"restore is expected to die without 'to' parameter";

dies_ok { $bkp->restore( from => File::Spec->catdir ( Win32::GetNextAvailDrive(),'' )) } 
	"restore is expected to die if 'from' folder does not exists";

# a valid backup
$bkp->run;
# a valid restore
my $return = $bkp->restore(  
							from => File::Spec->catdir ( $tdst,'test' ), 
							to => $tbasedir 
);
ok ( $return->[0]{exit} < 8, "first restore completed succesfully" );

# update the file in source
$tfh1 = bkpscenario::open_file($tsrc,$file1);
BAIL_OUT( "unable to create temporary file!" ) unless $tfh1;
bkpscenario::update_file($tfh1,1);	

# a valid backup again
$bkp->run;
# a valid restore again
$return = $bkp->restore(  
							from => File::Spec->catdir ( $tdst,'test' ), 
							to => $tbasedir 
);
ok ( $return->[0]{exit} < 8, "second restore completed succesfully" );

# update the file in source
$tfh1 = bkpscenario::open_file($tsrc,$file1);
BAIL_OUT( "unable to create temporary file!" ) unless $tfh1;
bkpscenario::update_file($tfh1,2);
# update the file in source
$tfh1 = bkpscenario::open_file($tsrc,$file1);
BAIL_OUT( "unable to create temporary file!" ) unless $tfh1;
bkpscenario::update_file($tfh1,3);

# a valid backup again
$bkp->run;
# a valid restore again
$return = $bkp->restore(  
							from => File::Spec->catdir ( $tdst,'test' ), 
							to => $tbasedir 
);
ok ( $return->[0]{exit} < 8, "third restore completed succesfully" );

# check if last file is complete..
ok (bkpscenario::check_last_line($tbasedir, $file1, "  il fato illacrimata sepoltura.\n"),
	"file $file1 has the expected content in folder $tbasedir");

# a history backup on the same destination will fail as history restore
# because not ALL directories and file will be of the required timestamp format

# a backup with history
$bkp = Win32::Backup::Robocopy->new(
	name => 'test',
	source	 => $tsrc,
	dst => $tdst,
	history => 1,	
);

my (undef,undef,undef,undef,$createdfolder) = $bkp->run;


$return = $bkp->restore(  
							from => File::Spec->catdir ( $tdst,'test' ), 
							to => $tbasedir 
);
ok ( $return->[0]{exit} < 8, "fourth restore completed succesfully.." );

opendir my $dirh, $tbasedir or BAIL_OUT "cannot open $tbasedir for reading!";
while (my $item = readdir $dirh){
	if ($item eq $createdfolder){
		ok ($item eq $createdfolder,"..but the restore was not a history one");
		last;
	}
}
closedir $dirh or BAIL_OUT "cannot close $tbasedir!";
# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");
