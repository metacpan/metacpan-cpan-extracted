#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Capture::Tiny qw(capture);
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

# add some line to file
$tfh1 = bkpscenario::open_file($tsrc,$file1);
bkpscenario::update_file($tfh1,1);

# modify another time the file and do an HISTORY backup
$tfh1 = bkpscenario::open_file($tsrc,$file1);
bkpscenario::update_file($tfh1,2);

# a final append to the file
$tfh1 = bkpscenario::open_file($tsrc,$file1);
bkpscenario::update_file($tfh1,3);

my $bkp = Win32::Backup::Robocopy->new(
	name => 'test2',
	source	 => $tsrc,
	dst => $tdst,
	history => 1,
	verbose => 0,
);

my ($stdout, $stderr, $exit, $exitstr,$createdfolder) = $bkp->run();

# get the position of last HISTORY backup
my $completedest = File::Spec->catdir($bkp->{dst},$bkp->{name});
opendir my $lastdir, 
			$completedest,
			or BAIL_OUT ("Unable to read directory [$completedest]!");
my @ordered_dirs = sort grep {!/^\./} readdir($lastdir);
my $lastfilepath = File::Spec->catfile( $completedest, $ordered_dirs[-1], $file1);


# some restore:
# verbosity 1
my ($out, $err, @res) = capture {
		$bkp->restore(from=> $completedest, to => $tbasedir, 
		verbose => 1);
};
ok (3 == (split "\n", $out), "4 lines expected with verbosity = 1");

# verbosity 2
($out, $err, @res) = capture {
		$bkp->restore(from=> $completedest, to => $tbasedir, upto=> $ordered_dirs[-2], 
		verbose => 2);
};
ok ((split "\n", $out) > 30 , "30+ lines expected with verbosity = 2");

# verbosity 0
($out, $err, @res) = capture {
		$bkp->restore(from=> $completedest, to => $tbasedir,
		verbose => 0);
};
ok (0 == (split "\n", $out), "0 lines expected with verbosity = 0");


# a new backup with verbosity 2
$bkp = Win32::Backup::Robocopy->new(
	name => 'test2',
	source	 => $tsrc,
	dst => $tdst,
	history => 1,
	verbose => 2,
);

# verbosity non specified inherit from backup
($out, $err, @res) = capture {
		$bkp->restore(from=> $completedest, to => $tbasedir,
		);
};
ok (30 < (split "\n", $out), "verbosity propagates correctly from backup to restore");

# and overwritten succesfully 
($out, $err, @res) = capture {
		$bkp->restore(from=> $completedest, to => $tbasedir,
		verbose => 0,
		);
};
ok ( 0 == (split "\n", $out), "verbosity overwritten succesfully by restore");

$bkp = Win32::Backup::Robocopy->new( configuration => File::Spec->catfile($tbasedir,'my_config.json'), verbose => 0 );
# check verbosity of job method if inherited
($out, $err, @res) = capture {
		$bkp->job( name=>'test3', src=>$tsrc,
			cron=>'0 0 25 12 *', history=>1,
			first_time_run=>1,
			);
};
ok ( 0 == (split "\n", $out), "verbosity inherited ok when adding job");

# check verbosity overwritten by job method
($out, $err, @res) = capture {
		$bkp->job( name=>'test3', src=>$tsrc,
			cron=>'0 0 25 12 *', history=>1,
			first_time_run=>1,
			verbose => 3);
};
ok ( 34 < (split "\n", $out), "verbosity overidden ok when adding job");


# check if last file is complete..
open  my $lastfile, '<', File::Spec->catfile($tbasedir, $file1) or 
					BAIL_OUT ("unable to open file to check it ($file1 in $tbasedir)!");
my $last_line;
while(<$lastfile>){ $last_line = $_}
close $lastfile or BAIL_OUT("unable to close file!");
ok( $last_line eq "  il fato illacrimata sepoltura.\n","file $file1 has the expected content in folder $tbasedir");

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");


done_testing();
