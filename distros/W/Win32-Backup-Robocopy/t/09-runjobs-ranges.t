#!perl
use 5.010;
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

# a bkp in a job mode
my $bkp = Win32::Backup::Robocopy->new( config => File::Spec->catfile($tbasedir,'my_config.json' ) );

# add a serie of job identical
$bkp->job(  name => 'test0', src => $tsrc, dst => $tdst, verbose => 1,
			cron => '0 0 25 12 *', first_time_run => 1);
$bkp->job(  name => 'test1', src => $tsrc, dst => $tdst, verbose => 1,
			cron => '0 0 25 12 *', first_time_run => 1);
$bkp->job(  name => 'test2', src => $tsrc, dst => $tdst, verbose => 1,
			cron => '0 0 25 12 *', first_time_run => 1);
$bkp->job(  name => 'test3', src => $tsrc, dst => $tdst, verbose => 1,
			cron => '0 0 25 12 *', first_time_run => 1);
$bkp->job(  name => 'test4', src => $tsrc, dst => $tdst, verbose => 1,
			cron => '0 0 25 12 *', first_time_run => 1);
$bkp->job(  name => 'test5', src => $tsrc, dst => $tdst, verbose => 1,
			cron => '0 0 25 12 *', first_time_run => 1);

			
# running only job number 3 
my ($stdout, $stderr, @result) = capture { $bkp->runjobs(3) };
my @lines = split '\n',$stdout;
ok($lines[0] eq 'considering job [test3]','right job considered in verbose mode');
ok($lines[1] eq 'executing job [test3]','right job executed');


# run only jobs 0,2,3
# NB runjobs accepts both STRING and ARRAY
($stdout, $stderr, @result) = capture { $bkp->runjobs(0,2..3) };
@lines = split '\n',$stdout;
ok($lines[0] eq 'considering job [test0]','considered [test0]');
ok($lines[1] eq 'executing job [test0]','executed [test0]');
ok($lines[4] =~ /^mkdir.*test0$/,'mkdir for test0');
ok($lines[9] eq 'considering job [test2]','considered [test2]');
ok($lines[10] eq 'executing job [test2]','executed [test2]');
ok($lines[13] =~ /^mkdir.*test2$/,'mkdir for test2');
ok($lines[18] eq 'considering job [test3]','considered [test3]');
ok($lines[19] =~ /^is not time to execute \[test3\].*00:00:00/,'not time for [test3]');

# run all jobs just to trigger them
($stdout, $stderr, @result) = capture { $bkp->runjobs() };

# check array range work as expected				=> 0,1,2
($stdout, $stderr, @result) = capture { $bkp->runjobs(0..2,1) };
@lines = split '\n',$stdout;
ok($lines[0] eq 'considering job [test0]','considered [test0]');
ok($lines[1] =~ /^is not time to execute \[test0\]/,'not time for [test0]');
ok($lines[2] eq 'considering job [test1]','considered [test1]');
ok($lines[3] =~ /^is not time to execute \[test1\]/,'not time for [test1]');
ok($lines[4] eq 'considering job [test2]','considered [test2]');
ok($lines[5] =~ /^is not time to execute \[test2\]/,'not time for [test2]');

# check array range work as expected				=> 0,1,5
($stdout, $stderr, @result) = capture { $bkp->runjobs(5,0..1) };
@lines = split '\n',$stdout;
ok($lines[0] eq 'considering job [test0]','considered [test0]');
ok($lines[1] =~ /^is not time to execute \[test0\]/,'not time for [test0]');
ok($lines[2] eq 'considering job [test1]','considered [test1]');
ok($lines[3] =~ /^is not time to execute \[test1\]/,'not time for [test1]');
ok($lines[4] eq 'considering job [test5]','considered [test5]');
ok($lines[5] =~ /^is not time to execute \[test5\]/,'not time for [test5]');

# dies with invalid ranges array
# CAVEAT: 4..0 result into an empty @_ which will mean ALL jobs!
# $bkp->runjobs(4..0);
# dies_ok {  $bkp->runjobs(4..0) } "invalid reverse range [4..0]";

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");

