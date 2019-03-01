#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Capture::Tiny qw(capture);
use Win32::File qw(:DEFAULT GetAttributes SetAttributes);
use Win32::Backup::Robocopy;

use lib '.';
use t::bkpscenario;

plan tests => 12;

# run croaks if destination drive does not exists
my $nobkp = Win32::Backup::Robocopy->new( 
	name => 'impossible',
	src	 => '.',
	dst => File::Spec->catdir ( Win32::GetNextAvailDrive(),'' )
);
my ($out, $err, @res) = capture {
		dies_ok { $nobkp->run } 'run is expected to die with no existing destination drive';
};


# run croaks if invalid name was given for destination
$nobkp = Win32::Backup::Robocopy->new( 
	name => 'impos??????sible',
	verbose => 1,
	src	 => 'X:/supposed/to/not/exist/for/testing',
	dst => '.', 
);
($out, $err, @res) = capture {
		dies_ok { $nobkp->run } 'run is expected to die with invalid folder name';
};


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

# check $exit code: now has to be 1 as for new file backed up
my $bkp = Win32::Backup::Robocopy->new(
	name => 'test',
	source	 => $tsrc,
	dst => $tdst,	
);
my ($stdout, $stderr, $exit, $exitstr) = $bkp->run();
ok ( $exit == 1, "new file $file1 correctly backed up" );

# check $exit code: now has to be 0 as for no new file 
($stdout, $stderr, $exit, $exitstr) = $bkp->run( emptysufolders => 1 );
if( not ok ( $exit == 0, "no new file present" ) ) {
	diag "basedir : $tbasedir\n",
		 "tempsrc : $tsrc\n",
		 "tempdst : $tdst\n",
		 "file    : $file1\n";
	diag "Dumping returned values from 'run'..\n";
	diag "stdout : $stdout\n";
	diag "stdrerr: $stderr\n";
	diag "exit   : $exit\n";
	diag "string : $exitstr\n";
	
	bkpscenario::check_robocopy_version('verbose');

}

# add some line to file
# check $exit code: now has to be 1 as for modified file
$tfh1 = bkpscenario::open_file($tsrc,$file1);
bkpscenario::update_file($tfh1,1);
($stdout, $stderr, $exit, $exitstr) = $bkp->run( emptysufolders => 1 );
ok ( $exit == 1, "updated file $file1 correctly backed up" );

# try to backuk *.doc
($stdout, $stderr, $exit, $exitstr) = $bkp->run( files => '*.doc' );
#ok ( $exit == 0, "no *.doc files to backed up" );
if( not ok ( $exit == 0, "no *.doc files to backed up" ) ) {
	diag "basedir : $tbasedir\n",
		 "tempsrc : $tsrc\n",
		 "tempdst : $tdst\n",
		 "file    : $file1\n";
	diag "Dumping returned values from 'run'..\n";
	diag "stdout : $stdout\n";
	diag "stdrerr: $stderr\n";
	diag "exit   : $exit\n";
	diag "string : $exitstr\n";

	bkpscenario::check_robocopy_version('verbose');
	
}

# check archive attribute was removed from the file
my $attr;
my $getattrexit = GetAttributes( File::Spec->catfile($tsrc, $file1), $attr );
BAIL_OUT( "impossible to retrieve attributes of $file1" ) unless $getattrexit;
my $archiveset = $attr & ARCHIVE;
#cmp_ok($archiveset, '==', 0, "ARCHIVE bit not present in $file1");
if( not cmp_ok($archiveset, '==', 0, "ARCHIVE bit not present in $file1") ) {
	diag "basedir : $tbasedir\n",
		 "tempsrc : $tsrc\n",
		 "tempdst : $tdst\n",
		 "file    : $file1\n",
		 "attr    : $attr\n",
		 "archive : $archiveset\n";

	bkpscenario::check_robocopy_version('verbose');
	
}

# modify another time the file and do an HISTORY backup
$tfh1 = bkpscenario::open_file($tsrc,$file1);
bkpscenario::update_file($tfh1,2);

$bkp = Win32::Backup::Robocopy->new(
	name => 'test2',
	source	 => $tsrc,
	dst => $tdst,
	history => 1
);
my $createdfolder;
($stdout, $stderr, $exit, $exitstr,$createdfolder) = $bkp->run();
# check $exit code: now has to be 1 as for modified file
ok ( $exit == 1, "updated file $file1 correctly backed up using history = 1" );

# check run with HISTORY returned the created folder
ok (defined $createdfolder, "history backup returned created folder [$createdfolder]");
# just to be sure another folder is created while history => 1
sleep 2;

# a final append to the file
$tfh1 = bkpscenario::open_file($tsrc,$file1);
bkpscenario::update_file($tfh1,3);

# now we pass extraparam '/A+:R' meaning to set READONLY attribute on destination file
($stdout, $stderr, $exit, $exitstr) = $bkp->run( extraparam => '/A+:R' );
# check $exit code: now has to be 1 as for modified file
ok ( $exit == 1, "updated file $file1 correctly backed up in a new folder while history = 1" );

# get the position of last HISTORY backup
my $completedest = File::Spec->catdir($bkp->{dst},$bkp->{name});
opendir my $lastdir, 
			$completedest,
			or BAIL_OUT ("Unable to read directory [$completedest]!");
my @ordered_dirs = sort grep {!/^\./} readdir($lastdir);
my $lastfilepath = File::Spec->catfile( $completedest, $ordered_dirs[-1], $file1);

# check the READONLY attributes was set in destination because of extraparam => '/A+:R'
my $lastattr;
my $lastgetattrexit = GetAttributes( $lastfilepath, $lastattr );
BAIL_OUT( "impossible to retrieve attributes of $lastfilepath".__LINE__ ) unless $lastgetattrexit;
my $lastreadonlyset = $lastattr & READONLY;
cmp_ok( $lastreadonlyset, '==', 1, "READONLY bit is present in dir $ordered_dirs[-1] file $file1");

# check if last file is complete..
open my $lastfile, '<', $lastfilepath or 
					BAIL_OUT ("unable to open file to check it ($file1 in $bkp->{dst} $ordered_dirs[-1])!");
my $last_line;
while(<$lastfile>){ $last_line = $_}
close $lastfile or BAIL_OUT("unable to close file!");
ok( $last_line eq "  il fato illacrimata sepoltura.\n","file $file1 has the expected content in folder $ordered_dirs[-1]");

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");