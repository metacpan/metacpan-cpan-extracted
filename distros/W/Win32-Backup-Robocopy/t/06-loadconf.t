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

# configuration in temp dir
my $conf = File::Spec->catfile($tbasedir,'my_config.json');

# a bkp in a job mode
my $bkp = Win32::Backup::Robocopy->new( config => $conf );
$bkp->job(name=>'test7',src=>$tsrc,dst=>$tdst,cron=>'0 0 25 1 *', first_time_run => 1);
$bkp->job(name=>'test8',src=>$tsrc,dst=>$tdst,cron=>'0 0 25 1 *');
$bkp->_write_conf();

$bkp = Win32::Backup::Robocopy->new( config => $conf );

# ok if jobs loaded
ok( @{$bkp->{jobs} } == 2, 'two jobs in the main object loaded from file' );

# each job is into a hash
foreach my $ele ( @{$bkp->{jobs}} ){
	ok( ref $ele eq 'HASH', "job is inside a hash");
}

# corrupting the data ;=)
# adding unexpected element
${ ${$bkp->{jobs}}[0]}{ unexpected } = 1;
$bkp->_write_conf();
my ($stdout, $stderr, @result) = capture { $bkp = Win32::Backup::Robocopy->new( config => $conf ) };

ok( $stderr =~ /unexpected elements in job/, "warning if extra element present in job");

# corrupting the data
# removing 'name' field
open my $fhr, '<', $conf or BAIL_OUT "unable to open";
open my $fhw, '>', $conf.'a' or BAIL_OUT "unable to open";
while (<$fhr>){ print $fhw $_ unless $_ =~ /name/}
close $fhr or BAIL_OUT "unable to close";
close $fhw or BAIL_OUT "unable to close";


# dies if name is not present
dies_ok { $bkp = Win32::Backup::Robocopy->new( config => $conf.'a' ) } 
		"expecting to die with an invalid configuration (missing field)";

# corrupting the data
# an unexpected datastructure
open  $fhw, '>', $conf.'b' or BAIL_OUT "unable to open";
print $fhw "[\n[]\n]";
close $fhw or BAIL_OUT "unable to close";

# dies if not an hash ref
dies_ok { $bkp = Win32::Backup::Robocopy->new( config => $conf.'b' )} 
		"expecting to die with an invalid configuration (job is not an HASH ref)";

# corrupting the data
# an insane content
open  $fhw, '>', $conf.'b' or BAIL_OUT "unable to open";
print $fhw "akatasbra";
close $fhw or BAIL_OUT "unable to close";

# dies if malformed json
dies_ok { $bkp = Win32::Backup::Robocopy->new( config => $conf.'b' )} 
		"expecting to die with an invalid configuration (malformed JSON string)";

# remove the backup scenario
bkpscenario::clean_all($tbasedir);
note("removed backup scenario in $tbasedir");