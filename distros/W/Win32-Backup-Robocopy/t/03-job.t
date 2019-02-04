#!perl
use 5.014;
use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Win32::Backup::Robocopy;

use lib '.';
use t::bkpscenario;

my ($tbasedir,$tsrc,$tdst) = bkpscenario::create_dirs();
BAIL_OUT( "unable to create temporary folders!" ) unless $tbasedir;
note("created backup scenario in $tbasedir");

# new in JOB mode just needs conf croaks if destination drive does not exists
my $bkp = Win32::Backup::Robocopy->new( conf => File::Spec->catfile($tbasedir,'my_config.json') );
ok ( ref $bkp->{jobs} eq 'ARRAY', 'jobs is an array reference');

# config is a valid alias for conf
$bkp = Win32::Backup::Robocopy->new( config => File::Spec->catfile($tbasedir,'my_config.json') );
ok ( defined $bkp->{conf}, 'config as alias for conf');

# configuration is a valid alias for conf
$bkp = Win32::Backup::Robocopy->new( configuration => File::Spec->catfile($tbasedir,'my_config.json') );
ok ( defined $bkp->{conf}, 'configuration as alias for conf');

# $bkp has only 3 fields
ok(keys %$bkp == 3, 'just 3 fields in bkp object');

# job dies if nothing is given
dies_ok { $bkp->job } 'job method expected to die without a name, a source and a cron string';

# job dies unless name is given
dies_ok { $bkp->job(src=>'.',cron=>'0 0 25 1 *') } 'job method  expected to die without a name';

# job dies unless crontab is given
dies_ok { $bkp->job(src=>'x:\\',name=>'test') } 'job method  expected to die without a crontab string';

# job dies unless source is given
dies_ok { $bkp->job(cron=>'0 0 25 1 *',name=>'test') } 'job method  expected to die without a source';



SKIP: {
		# TODO: spot why this does NOT dies correctly in 5.10
		# even if the test of the module dies..
		skip if $] lt '5.014';
		# job dies with an incorrect crontab
		dies_ok { $bkp->job(cron=>'one 0 0 25',src=>'x:\\',name=>'test') } 'job method  expected to die with an invalid crontab';
}


# a correct invocation
$bkp->job(name=>'test',src=>'x:/',cron=>'0 0 25 1 *');


# jobs queue has one element
ok(@{$bkp->{jobs}} == 1, 'first job correctly pushed into jobs queue');
 
# job has taken all defaults from new and run
foreach my $field (qw( 	name src dst files history archive 
						archiveremove subfolders emptysubfolders 
						verbose )) {
	ok(defined ${$bkp->{jobs}}[0]->{$field}, "$field defined in job" );
}

# a second job with different arguments
$bkp->job( name=>'test2', src=>$tsrc,
			cron=>'0 0 25 12 *', history=>1,
			first_time_run=>1);

# jobs queue has two element
ok(@{$bkp->{jobs}} == 2, 'second job correctly pushed into jobs queue');

# next_time and next_time_descr ignored if passed
$bkp->job ( name=>'test3', src=>$tsrc, debug=>1,
			cron=>'0 0 21 09 *', history=>1, first_time_run=>1,
			#invalid params!!
			next_time => 42,
			next_time_descr => 'quarantadue'
			);
ok(${$bkp->{jobs}}[2]->{next_time} == 0, 'next_time only set internally: is 0 if first_time_run is true'); 
ok(${$bkp->{jobs}}[2]->{next_time_descr} ne 'quarantadue', 'next_time_descr only set internally'); 
ok(${$bkp->{jobs}}[2]->{next_time_descr} eq '--AS SOON AS POSSIBLE--', 'next_time_descr set internally to default label if first_time_run is true'); 

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");