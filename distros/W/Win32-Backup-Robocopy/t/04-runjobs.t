#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
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

my $conf = File::Spec->catfile($tbasedir,'my_config.json');

# a bkp in a job mode
my $bkp = Win32::Backup::Robocopy->new( config => $conf );

# add a job  with first_time_run=>1
$bkp->job(  name => 'test3', src => $tsrc, dst => $tdst,
			cron => '0 0 25 12 *', first_time_run => 1, verbose => 1);

# this time it must return executing job [name]
my ($stdout, $stderr, @result) = capture { $bkp->runjobs() };
like( (split "\n",$stdout)[1], qr/^executing job \[test3\]/, "right output of first_time_run (executing..)");

# now it must says it's not time to run: first_time_run run only once!
($stdout, $stderr, @result) = capture { $bkp->runjobs() };
like( (split "\n",$stdout)[1], qr/^is not time to execute/, "right output of first_time_run (skipping..)");

undef $bkp;
$bkp = Win32::Backup::Robocopy->new( configuration => File::Spec->catfile($tbasedir,'my_config.json' ));
# same source different dest and second with history
$bkp->job(	name=>'test3',src=>$tsrc,
			dst=>$tdst,cron=>'0 0 25 1 *',
			history=>0,first_time_run => 1);
			
$bkp->job(	name=>'test4',src=>$tsrc,
			dst=>$tdst,cron=>'0 0 25 1 *',
			history=>1,first_time_run => 1);

($stdout, $stderr, @result) = capture { $bkp->runjobs() };

# inside test3 must be a file
ok(-e File::Spec->catfile($tdst,'test3',$file1),'file exists in  directory test3');

# get the position of last HISTORY backup
opendir my $lastdir, File::Spec->catdir($tdst,'test4') or BAIL_OUT ("Unble to read directory test4!");
my @ordered_dirs = sort grep {!/^\./} readdir($lastdir);
my $lastfilepath = File::Spec->catfile( $bkp->{dst}, $ordered_dirs[-1], $file1);

ok( ! -e File::Spec->catfile($tdst,'test4',$file1),'file does not exists in  directory test4');

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");