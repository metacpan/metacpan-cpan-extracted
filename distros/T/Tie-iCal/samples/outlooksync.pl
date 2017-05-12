=head1 USAGE

outlooksync.pl [--help] --ical <ics file path> [--olcal <dest cal>]

=head1 OPTIONS

=over 8

=item B<--help|-?>

Print this message.

=item B<--cal|-i>

Specify source RFC2445 iCalendar file to be synchronised, This option
is mandatory.

=item B<--olcal|-o>

Specify destination Outlook calendar folder to synchronise with.
If one is not specified then the default top level will be used.
If the specified calendar does not exist it will be created.

=head1 TODO

Sync based on last modification time.

=cut

use strict;

use Getopt::Long;
use Pod::Usage;

use vars qw/$verbose $icsFile $destFolder $ignoreCompleteTodos/;
BEGIN {
	my $help = 0;
	
	if (
		!GetOptions(
			'ical|i=s' => \$icsFile,
			'olcal|o=s' => \$destFolder,
			'ignorecompletetodos' => \$ignoreCompleteTodos,
			'verbose|v' => \$verbose,
			'help|?' => \$help,
		) || 
		$help ||
		!defined $icsFile
	) {
		pod2usage(-verbose => 2);
		exit;
	}
	
	if (!-f $icsFile) {
		print "Cannot find iCal file '$icsFile'. It will be created\n";
	}	
}

use Tie::iCal;
use Date::ICal;

use Data::Dumper;

use Win32::OLE qw(in with);
BEGIN {
	print STDERR "Loading all OLE typelibs will take some time...";
}
use Win32::OLE::Const 'Microsoft Outlook';
print STDERR "loaded.\n";

use Win32::OLE::Variant;
use Win32::OLE::NLS qw(:LOCALE :DATE);
$Win32::OLE::Warn = 3;

use Win32;

debug("Verbose logging is turned on.");
debug("Using iCalendar file '$icsFile'");

# get Outlook object
#
my $Outlook;
eval {
	$Outlook = Win32::OLE->GetActiveObject('Outlook.Application')
}; 
die "Could not find Outlook. Is it installed?" if $@;
unless (defined $Outlook) {
	$Outlook = Win32::OLE->new('Outlook.Application', sub {$_[0]->Quit;}) or die "Could not start Outlook.";
}

# get calendar, tasks and journal folder objects
#
#  * see if destination folder exists
#  * if it doesn't create one
#
my $olCalendarItems = getDestinationFolder('olFolderCalendar', $destFolder)->Items();
my $olTaskItems     = getDestinationFolder('olFolderTasks', $destFolder)->Items();
my $olJournalItems  = getDestinationFolder('olFolderJournal', $destFolder)->Items();

my @olEvents;
push @olEvents, in($olCalendarItems);
push @olEvents, in($olTaskItems);
push @olEvents, in($olJournalItems);

# tie iCalendar file to a Perl hash
#
my $tievar = tie my %icalEvents, 'Tie::iCal', $icsFile, 'debug' => 0 or die "Failed to tie file!\n";

# cycle through outlook events
#
#  * if an event does have an "iCalendarId" check it exists in ics file
#    and if it doesn't then add it.
#
#  * if an event does not have an "iCalendar Id", add it to a list to 
#    deal with later
#
debug("Processing Outlook events.");
my @olEventsWithoutIds;
my %olUids;
foreach my $olEvent (@olEvents) {
	if ($olEvent->{UserProperties}->{"iCalendar Id"}) {
		my $olUid = $olEvent->{UserProperties}->{"iCalendar Id"}->Value;
		if (exists $icalEvents{$olUid}) {
			debug("$olUid: Ignoring Outlook/iCal event.");
		}
		else {
			debug("$olUid: Adding Outlook event to iCal");
			olEventToIcal(\%icalEvents, $olUid, $olEvent);
		}
		$olUids{$olUid} = undef;
	}
	else {
		debug("<none>: Delay Outlook event without 'iCalendar Id'.");
		push @olEventsWithoutIds, $olEvent;
	}
}

# cycle through outlook events without uids
#
#  * add a unique uid
#  * add this event to ical
#
debug("Processing unidentified Outlook events.");
foreach my $olEvent (@olEventsWithoutIds) {
	my $newUid = createUniqueID(\%icalEvents);
	$olEvent->{UserProperties}->Add("iCalendar Id", olText);
	$olEvent->{UserProperties}->{"iCalendar Id"} = $newUid;
	$olEvent->Save;
		
	debug("$newUid: Adding Outlook event to iCal (new Uid).");
	olEventToIcal(\%icalEvents, $newUid, $olEvent);
	$olUids{$newUid} = undef;
}

# cycle through ical appointments
#
#  * if event has already been seen ignore
#
debug("Processing iCalendar events.");
my $i = 0;
while (my ($icalUid, $icalEvent) = each %icalEvents) { 
	
	if (!exists $olUids{$icalUid}) {
		if ($icalEvent->[0] eq 'VEVENT') {
			icalEventToOutlook($olCalendarItems, $icalUid, $icalEvent);
		}
		elsif ($icalEvent->[0] eq 'VTODO') {
			icalEventToOutlook($olTaskItems, $icalUid, $icalEvent);
		}
		else {
			debug("Unsupported iCalendar type '$icalEvent->[0]'.. skipping.");
		}
	}
	
	$i++;
}

debug("Processed $i ical records.");

exit;

sub debug {
	print STDERR $_[0]."\n" if $verbose;
}

sub getDestinationFolder {
	my ($olFolderType, $destFolderName) = @_;

	my $olFolder = $Outlook->GetNamespace("MAPI")->GetDefaultFolder(&{\&{$olFolderType}}());
	
	if (defined $destFolderName) {
		debug("Searching for Outlook folder type '$olFolderType' called '$destFolderName'.");
		my $calExists = 0;
		foreach my $cal (in($olFolder->Folders())) {
			if ($cal->{name} eq $destFolderName) {
				$calExists = 1;
				debug("Found destination folder '$destFolderName'.");
				last;
			}
		}

		if (!$calExists) {
			debug("destination calendar '$destFolderName' does not exists.. creating.");
			$olFolder->{Folders}->Add($destFolderName);
		}

		return $olFolder->Folders($destFolderName);
	}
	else {
		debug("Using default Outlook folder for type '$olFolderType'.");
		return $olFolder;
	}

}

sub icalEventToOutlook {
	my ($olEvents, $icalUid, $icalEvent) = @_;
	
	debug("$icalUid: Adding event to Outlook.");
	
	my $olEvent = $olEvents->Add();
	
	$olEvent->{UserProperties}->Add("iCalendar Id", olText);
	$olEvent->{UserProperties}->{"iCalendar Id"} = $icalUid;
	
	if ($icalEvent->[0] eq 'VEVENT') {
		setOutlookValue($olEvent, 'Subject',         $icalEvent->[1]->{SUMMARY});
		setOutlookValue($olEvent, 'Body',            $icalEvent->[1]->{DESCRIPTION});
		setOutlookValue($olEvent, 'Location',        $icalEvent->[1]->{LOCATION});
		setOutlookValue($olEvent, 'Start',           tiedDateToVariant($icalEvent->[1]->{DTSTART})); 
		setOutlookValue($olEvent, 'End',             tiedDateToVariant($icalEvent->[1]->{DTEND}));
	}
	elsif ($icalEvent->[0] eq 'VTODO') {
		setOutlookValue($olEvent, 'Subject',         $icalEvent->[1]->{SUMMARY});
		setOutlookValue($olEvent, 'Body',            $icalEvent->[1]->{DESCRIPTION});
		setOutlookValue($olEvent, 'StartDate',       tiedDateToVariant($icalEvent->[1]->{DTSTART})); 
		setOutlookValue($olEvent, 'DueDate',         tiedDateToVariant($icalEvent->[1]->{DUE}));
		setOutlookValue($olEvent, 'PercentComplete', $icalEvent->[1]->{'PERCENT-COMPLETE'});
	}

	$olEvent->Save;

	#print Dumper($icalEvent->[1])."\n";
}

sub setOutlookValue {
	my ($olEvent, $key, $value) = @_;
	if ($value ne '') {
		$olEvent->{$key} = $value;
	}
}

sub olEventToIcal {
	my ($icalEventsHref, $olUid, $olEvent) = @_;

	debug("$olUid: Adding event to iCalendar.");

	if ($olEvent->{MessageClass} eq 'IPM.Appointment') {	
		$icalEventsHref->{$olUid} = [
			'VEVENT',
			{
				'SUMMARY' => $olEvent->{Subject},
				'DESCRIPTION' => $olEvent->{Body},
				'LOCATION' => $olEvent->{Location},
				'DTSTART' => variantDateToIcal($olEvent->{start}),
				'DTEND'   => variantDateToIcal($olEvent->{end}),
			}
		];
	}
	elsif ($olEvent->{MessageClass} eq 'IPM.Task') {	
		$icalEventsHref->{$olUid} = [
			'VTODO',
			{
				'SUMMARY' => $olEvent->{Subject},
				'DESCRIPTION' => $olEvent->{Body},
				'DTSTART' => variantDateToIcal($olEvent->{StartDate}),
				'DUE'   => variantDateToIcal($olEvent->{DueDate}),
				'PERCENT-COMPLETE' => $olEvent->{PercentComplete},
			}
		];
	}
	else {
		# TODO: IPM.Activity
		debug("Unsupported Outlook message class '$olEvent->{MessageClass}'.. skipping.");
	}

	#print $olEvent->{isrecurring}."\n";
}

sub tiedDateToVariant {
	if (ref($_[0]) eq '') {
		return icalDateToVariant($_[0]);
	}
	elsif (ref($_[0]) eq 'ARRAY') {
		return icalDateToVariant($_[0]->[1]); # big assumption?
	}
	else {
		debug("Unrecognized ical date format");
		return undef;
	}	
}

sub icalDateToVariant {
	my $x = Date::ICal->new(ical => $_[0]);
	my $s = sprintf ("%s/%s/%s %s:%s", $x->day, $x->month, $x->year, $x->hour, $x->min);
	return $s;
	#return Variant(VT_DATE, $s);
}

sub variantDateToIcal {
	my ($year, $month, $day) = split(/ /, $_[0]->Date("yyyy M d"));
	my ($hour, $minute, $sec) = split(/ /, $_[0]->Time("H m s"));
	return Date::ICal->new(
		year => $year, month => $month, day => $day, 
		hour => $hour, min => $minute, sec => $sec
	)->ical;
}

# modified mozilla recipe
#
sub createUniqueID {
	my $href = shift;
	my $newID = "";
	while ($newID eq "" || exists $$href{$newID}) {
		$newID = Win32::GuidGen();
	}
	return $newID;
}
