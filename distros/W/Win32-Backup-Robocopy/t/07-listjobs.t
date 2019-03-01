#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Win32::Backup::Robocopy;

use lib '.';
use t::bkpscenario;

#######################################################################
# a real minimal bkp scenario
#######################################################################
my ($tbasedir,$tsrc,$tdst) = bkpscenario::create_dirs();
BAIL_OUT( "unable to create temporary folders!" ) unless $tbasedir;
note("created backup scenario in $tbasedir");

my $bkp = Win32::Backup::Robocopy->new( conf =>  File::Spec->catfile($tbasedir,'test_backup') );

ok (0 == scalar $bkp->listjobs, 'zero returned in scalar context if no jobs are configured');

$bkp->job(name=>'job1',src=>'X:/supposed/to/not/exist/for/testing',cron=>'5 * * 1 *',history=>1);
$bkp->job(name=>'job2',src=>'X:/supposed/to/not/exist/for/testing',cron=>'3 * * 4 *',history=>1);

ok( 2 == scalar $bkp->listjobs(),'correct number of elements in scalar context' );

my @arr = $bkp->listjobs();
ok( 2 == @arr,'correct number of elements in list context' );

foreach my $ele ( @arr ){
	ok( $ele =~ /name = job\d src =.*files =.*cron =.*next_time_descr =.*/,'correct output in list context');
}

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");