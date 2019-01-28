#!perl
use 5.010;
use strict;
use warnings;
use Test::More qw(no_plan);
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

# configuration in tempp dir
my $conf = File::Spec->catfile($tbasedir,'my_config_tris.json');

# a bkp in a job mode
my $bkp = Win32::Backup::Robocopy->new( config => $conf );
$bkp->job(name=>'test5_first_time_run',src=>$tsrc,dst=>$tdst,cron=>'0 0 25 1 *', first_time_run => 1);
$bkp->job(name=>'test6',src=>$tsrc,dst=>$tdst,cron=>'0 0 25 1 *');
$bkp->_write_conf();

# check the file exists
ok( -e -f -r $conf, 'configuration written in the rigth file');

# READ the configuration 
my $json = JSON::PP->new->utf8->pretty->canonical;
open my $fh, '<', $conf or BAIL_OUT "unable to read $conf";
my $lines;
{
	local $/ = '';
	$lines = <$fh>;
}
close $fh or BAIL_OUT "impossible to close $conf";
my $data = $json->decode( $lines );

# check returned datastructure
ok( ref $data eq 'ARRAY', "json data conatains an array");
ok ( ref $data->[0] eq 'HASH', 'the array contains hash');
ok( ${$data->[0]}{name} eq 'test5_first_time_run','hash element name correctly found');
ok( ${$data->[0]}{next_time} == 0,'test5_first_time_run has time = 0 because of first_time_run set to 1');

# RUNJOBS
my ($stdout, $stderr, @result) = capture { $bkp->runjobs() };


# READ the configuration second time to see if updated
$json = JSON::PP->new->utf8->pretty->canonical;
open $fh, '<', $conf or BAIL_OUT "unable to read $conf";
undef $lines;
{
	local $/ = '';
	$lines = <$fh>;
}
close $fh or BAIL_OUT "impossible to close $conf";
$data = $json->decode( $lines );

# check returned datastructure
ok( ${$data->[0]}{first_time_run} == 0,'test5_first_time_run has first_time_run = 0 because already run');
ok( ${$data->[0]}{next_time} > 0,'test5_first_time_run has time > 0 because already run');

# chck both object and configuration have the same data
is_deeply( $data, $bkp->{jobs}, 'job data from JSON file is deeply equal to jobs data in the bkp object');


# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");