#! /usr/bin/perl -w 

use strict;
use Cwd;

#directory where the WSRF::Lite client scripts are located
my $DirPath = "../client-scripts";

my $baseDir = getcwd();

#catch kills, return to correct working directory and exit
$SIG{INT} = sub { die "Cntrl-C caught - script exiting\n"; };

my $newTT = "2009-02-08T20:31:19Z";

#wsrf::lite supports three types of Counter
# URL to Service => namespace of service
my %CounterTypes = (
	'http://localhost:50000/Session/Counter/Counter' =>
	  'http://www.sve.man.ac.uk/Counter',
	'http://localhost:50000/Session/CounterFactory/CounterFactory' =>
	  'http://www.sve.man.ac.uk/CounterFactory',
	'http://localhost:50000/MultiSession/Counter/Counter'    
	  => 'http://www.sve.man.ac.uk/Counter'
);

my $NoPasses = 0;

#remove old log file
if ( -e $baseDir . "/testlog" ) {
	unlink( $baseDir . "/testlog" )
	  or die "Could not remove old result file $baseDir/testlog: $!\n";
}

print "Changing directory to $DirPath\n";
chdir($DirPath) or die "Could not change durectory to $DirPath: $!\n";

foreach my $key ( keys %CounterTypes ) {
	print ">>>>>>>>>>>>>>>Testing for $key\n";
	eval { runCounterTests( $key, $CounterTypes{$key} ); };
	if ($@) {
		chdir($baseDir) or die "Could not cd to $baseDir\n";
		print "Test Failed: " . $@;
		print "$NoPasses tests passed\n";
		die;
	}
	print "\n\nTesting complete for $key <<<<<<<\n\n\n";
}

#Test ServiceGroup
print "Changing directory to " . $DirPath . "/ServiceGroup\n";
chdir( $DirPath . "/ServiceGroup" )
  or die "Could not change directory to $DirPath/ServiceGroup: $!\n";

print ">>>>>>Creating ServiceGroup>>>>>\n";
my ($ServiceGroupURI);
eval {
	$ServiceGroupURI =
	  createServiceGroup(
				"http://localhost:50000/Session/myServiceGroup/myServiceGroup");
};
if ($@) {
	chdir($baseDir) or die "Could not cd to $baseDir\n";
	print "Test Failed: " . $@;
	print "$NoPasses tests passed\n";
	die;
}
print "ServiceGroup created: $ServiceGroupURI <<<<<<\n";
$NoPasses++;

print ">>>>>>Adding Entry to $ServiceGroupURI\n";
eval { addService($ServiceGroupURI); };
if ($@) {
	print "Test Failed: " . $@;

	#remove the service group
	print "Changing directory to $DirPath to remove ServiceGroup\n";

	#$DirPath could be relative - must change to base path first
	chdir($baseDir) or die "Could not change directory to $baseDir: $!\n";
	chdir($DirPath) or die "Could not change durectory to $DirPath: $!\n";
	destroy($ServiceGroupURI);
	print "$NoPasses tests passed\n";
	chdir($baseDir) or die "Could not cd to $baseDir\n";
	die;
}
print "service added to $ServiceGroupURI <<<<<<<<\n\n";
$NoPasses++;

#remove the service group
print "Changing directory to $DirPath to remove ServiceGroup\n";

#$DirPath could be relative - must change to base path first
chdir($baseDir) or die "Could not change directory to $baseDir: $!\n";
chdir($baseDir) or die "Could not change directory to $baseDir: $!\n";
chdir($DirPath) or die "Could not change directory to $DirPath: $!";
destroy($ServiceGroupURI);

print "Changing directory to $baseDir\n\n";
chdir($baseDir) or die "Could not change directory to $baseDir: $!\n";
print "All $NoPasses Tests executed successfully.\n";

exit 0;

########################## sub-routines ########################################

sub runCounterTests {
	my ( $URL, $URI ) = @_;

	print "Attempting to create a Counter using\n $URL\n";
	my ($CounterEPR);
	$CounterEPR = createCounter( URL => $URL, URI => $URI );
	print "Counter created with address $CounterEPR\n\n";
	$NoPasses++;

	print "Attempting to change TerminationTime for Counter\n $CounterEPR\n";
	my ($newTT);
	eval { $newTT = changeTerminationTime($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print "New TerminationTime for Counter is $newTT\n\n";
	$NoPasses++;

	print "Attempting to use GetResourceProperty on Counter\n $CounterEPR\n";
	my ($count);
	eval { $count = getResourceProperty($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print "Value of count for Counter is $count\n\n";
	$NoPasses++;

	print
"Attempting to use GetMultipleResourceProperty on Counter\n $CounterEPR\n";
	my ( $newcount, $TT );
	eval { ( $newcount, $TT ) = getMultipleResourceProperty($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print
"Value of count for Counter is $newcount, value of TerminationTime is $TT\n\n";
	$NoPasses++;

	print "Attempting to add a value to the Counter\n $CounterEPR\n";
	eval { $newcount = add($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print "Value of count for Counter is $newcount.\n\n";
	$NoPasses++;

	print "Attempting to insert property foo into Counter\n $CounterEPR\n";
	eval { insertResourceProperty($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print "foo inserted into Counter.\n\n";
	$NoPasses++;

	print "Attempting to update property foo of Counter\n $CounterEPR\n";
	eval { updateResourceProperty($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print "foo updated in Counter.\n\n";
	$NoPasses++;

	print "Attempting to delete property foo from Counter\n $CounterEPR\n";
	eval { deleteResourceProperty($CounterEPR); };
	if ($@) {
		print "Caught Exception, destroying $CounterEPR\n";
		destroy($CounterEPR);
		print "$CounterEPR destroyed, throwing exception\n";
		die $@;
	}
	print "foo deleted from Counter.\n\n";
	$NoPasses++;

	print "Attempting to destroy Counter\n $CounterEPR\n";
	destroy($CounterEPR);
	print "Counter destroyed\n\n";
	$NoPasses++;

	return;
}

sub getMultipleResourceProperty {
	my $URL     = shift @_;
	my $basecmd = "wsrf_getMultipleResourceProperties.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " count TerminationTime";

	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to get count for Counter: " . $URL
	  if ( $output eq "" );

	my @lines = split( /\n/, $output );

	shift @lines;    #remove extra line of output
	my $i = 0;
	foreach my $line (@lines) {
		$i++ if ( $line =~ m/count/o  && $line =~ m/0/o );
		$i++ if ( $line =~ m/$newTT/o && $line =~ m/TerminationTime/o );
	}

	die
"Failed in getMultipleResourceProperty, did not get count and Termintation values"
	  unless ( $i == 2 );

	return ( 0, $newTT );
}

sub getResourceProperty {
	my $URL = shift @_;

	my $basecmd = "wsrf_getResourceProperties.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " count";

	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to get count for Counter: " . $URL
	  if ( $output eq "" );

	my @lines = split( /\n/, $output );
	my ( $dummy, $count );
	foreach my $line (@lines) {
		if ( $line =~ m/count/o ) {
			( $dummy, $count ) = split( /=/, $line );
		}
	}

	die "Failed in getResourceProperty, $count not defined."
	  unless defined($count);

	die "Failed in getResourceProperty, value of count, $count, is not 0."
	  if ( $count != 0 );

	return $count;

}

sub createCounter {
	my %arg = @_;

	my $basecmd = "wsrf_createCounterResource.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $arg{URL} . " " . $arg{URI};

	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to create Counter with URL: "
	  . $arg{URL}
	  . " and URI "
	  . $arg{URI}
	  if ( $output eq "" );

	my @lines = split( /\n/, $output );
	my ( $dummy, $CounterEndPoint );
	foreach my $line (@lines) {
		if ( $line =~ m/EndPoint/o ) {
			( $dummy, $CounterEndPoint ) = split( /=/, $line );
		}
	}

	die "Failed in createCounter, no Counter EndPoint returned."
	  unless defined($CounterEndPoint);

	return $CounterEndPoint;
}

sub changeTerminationTime {
	my $URL = shift @_;

	my $basecmd = "wsrf_setTerminationTime.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " " . $newTT;

	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to set TerminationTime for Counter: " . $URL
	  . " and TT"
	  . $newTT
	  if ( $output eq "" );

	my @lines = split( /\n/, $output );
	my (@dummy);
	foreach my $line (@lines) {

		#line looks like "   New Termination time: 2009-02-08T20:31:19Z"
		if ( $line =~ m/New Termination time/o ) {
			@dummy = split( /:/, $line );
		}
	}

	shift @dummy;
	my $TerminationTime = join( ':', @dummy );

	die "Failed in changeTerminationTime, $TerminationTime not defined."
	  unless defined($TerminationTime);

	#strip of any extra white space
	$TerminationTime =~ s/\s//og;

	die
"Failed in changeTerminationTime, times do not match $TerminationTime and $newTT."
	  if ( $TerminationTime ne $newTT );

	return $TerminationTime;
}

sub destroy {
	my $URL = shift @_;

	my $basecmd = "wsrf_destroyResource.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL;

	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to destroy Counter: " . $URL
	  if ( $output eq "" );

}

sub add {
	my $URL = shift @_;

	my $basecmd = "wsrf_client.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " http://vermont/Counter add 1";
	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to add value to Counter: " . $URL . "\n $NoPasses Tests passed"
	  if ( $output eq "" );

	my @lines = split( /\n/, $output );
	my ( $dummy, $count );
	foreach my $line (@lines) {

		#line looks like "   New Termination time: 2009-02-08T20:31:19Z"
		if ( $line =~ m/add/o ) {
			( $dummy, $count ) = split( /=/, $line );
		}
	}

	die "Fail in add, no count returned.\n $NoPasses Tests passed"
	  unless defined($count);

	die "Fail in add, wrong value for count returned, got $count instead of 1."
	  unless ( $count == 1 );

	return 1;
}

sub insertResourceProperty {
	my $URL = shift @_;

	my $basecmd = "wsrf_insertResourceProperty.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " foo bar";
	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to insert foo into Counter: " . $URL
	  . "\n $NoPasses Tests passed"
	  if ( $output eq "" );

	die "Failed to insert property foo correctly into Counter: " . $URL
	  unless ( $output =~ m/Inserted Property foo/o );

}

sub updateResourceProperty {
	my $URL = shift @_;

	my $basecmd = "wsrf_updateResourceProperty.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " foo blah";
	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to update foo property in Counter: " . $URL
	  if ( $output eq "" );

	die "Failed to update property foo correctly in Counter: " . $URL
	  unless ( $output =~ m/Updated Property foo/o );
}

sub deleteResourceProperty {
	my $URL = shift @_;

	my $basecmd = "wsrf_deleteResourceProperty.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL . " foo";
	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to delete property foo from Counter: " . $URL
	  if ( $output eq "" );

	die "Failed to correctly delete property foo from Counter: " . $URL
	  unless ( $output =~ m/Deleted Property foo/ );
}

sub createServiceGroup {
	my $URL = shift @_;

	my $basecmd = "wsrf_createServiceGroup.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL;
	print "\nExecuting...\n \"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to create ServiceGroup: " . $URL
	  if ( $output eq "" );

	my @lines = split( /\n/, $output );
	my ( $dummy, $GroupEndPoint );
	foreach my $line (@lines) {
		if ( $line =~ m/EndPoint/o ) {
			( $dummy, $GroupEndPoint ) = split( /=/, $line );
		}
	}

	die "Failed in createServiceGroup, no Servicegroup EndPoint returned."
	  unless defined($GroupEndPoint);

	return $GroupEndPoint;

}

sub addService {
	my $URL = shift @_;

	my $basecmd = "wsrf_ServiceGroupAdd.pl";

	die "Cannot find script \"$basecmd\" in " . getcwd() . "\n"
	  unless -e "./$basecmd";

	my $cmd = "perl $basecmd " . $URL;
	print "\nExecuting...\n\"$cmd 2>> $baseDir/testlog\"\n";
	my $output = `$cmd 2>> $baseDir/testlog`;
	print $output;

	die "Failed to add a Service to ServiceGroup: " . $URL
	  if ( $output eq "" );

	die "Failed to correctly to add service to ServiceGroup: " . $URL
	  unless ( $output =~ m/Added a dummy service to the ServiceGroup/ );
}

