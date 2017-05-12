use Tie::iCal;

unlink "unique.ics", "nonunique.ics";
open ICS, ">nonunique.ics";
while (<main::DATA>) { print ICS $_ }
close ICS;

tie %events, 'Tie::iCal', "nonunique.ics", 'debug' => 0 or die "Failed to tie file!\n";
tie %newevents, 'Tie::iCal', "unique.ics", 'debug' => 0 or die "Failed to tie file!\n";

print STDERR "Converting nonunique.ics to unique.ics..\n";
while (($uid, $event) = each %events) { 
	my $newuid = createUniqueID(\%events);
	print STDERR "Converting old key $uid to new key $newuid..\n";
	$newevents{$newuid} = $event;
}
print STDERR "done\n";

untie %events;
untie %newevents;
exit;

# modified mozilla recipe
#
sub createUniqueID {
	my $href = shift;
	my $newID = "";
	while ($newID eq "" || exists $$href{$newID}) {
		$newID = int(900000000 + rand(100000000));
	}
	return $newID;
}

__END__
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Numen Inest/NONSGML Tie::iCal 0.11//EN
BEGIN:VEVENT
UID:9999
SUMMARY:My Event
DTSTART;VALUE=DATE:20031225
DTEND;VALUE=DATE:20031226
END:VEVENT
BEGIN:VEVENT
UID:9999
SUMMARY:My Event
DTSTART;VALUE=DATE:20031225
DTEND;VALUE=DATE:20031226
END:VEVENT
BEGIN:VEVENT
UID:9999
SUMMARY:My Event
DTSTART;VALUE=DATE:20031225
DTEND;VALUE=DATE:20031226
END:VEVENT
BEGIN:VEVENT
UID:9999
SUMMARY:My Event
DTSTART;VALUE=DATE:20031225
DTEND;VALUE=DATE:20031226
END:VEVENT
BEGIN:VEVENT
UID:9999
SUMMARY:My Event
DTSTART;VALUE=DATE:20031225
DTEND;VALUE=DATE:20031226
END:VEVENT
BEGIN:VEVENT
UID:9999
SUMMARY:My Event
DTSTART;VALUE=DATE:20031225
DTEND;VALUE=DATE:20031226
END:VEVENT
END:VCALENDAR