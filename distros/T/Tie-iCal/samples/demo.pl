use Tie::iCal;
use Data::Dumper;

print "TIEHASH test..";
tie %events, 'Tie::iCal', "./demo.ics", 'debug' => 0 or die "Failed to tie file!\n";
print "ok\n";

print "FETCH test..\n";
print Dumper($events{'413dd998-67d6-11d9-9a33-e4a59cf11a95'});

print "FETCH cache test..\n";
print Dumper($events{'413dd998-67d6-11d9-9a33-e4a59cf11a95'});

print "EXISTS test..\n";
if (exists $events{'calsrv.example.com-873970198738777@example.com'}) {
	print "Found key 'calsrv.example.com-873970198738777\@example.com', printing it..\n";
	print Dumper($events{'calsrv.example.com-873970198738777@example.com'})."\n";
}
if (!exists $events{'this_UID_does_not_exist'}) {
	print "Did not find non-existant key\n";
}

print "FIRSTKEY test..\n";
print each(%events)."\n";

print "NEXTKEY test..\n";
#~ print "list keys..\n";
#~ foreach (keys %events) { print $_."\n" }
#~ print "list values..\n";
#~ foreach (values %events) { print Dumper($_)."\n" }

while (($key, $value) = each %events) { print $key, "\n" }  

print "COUNT test..\n";
print scalar(%events)."\n";

print "DELETE test..\n";
use File::Copy;
copy("./demo.ics","./democopy.ics");
tie %eventscopy, 'Tie::iCal', "./democopy.ics", 'debug' => 1 or die "Failed to tie file!\n";
delete $eventscopy{'1ce81410-4769-11d9-8693-ee0b0a9128b1'};
if (!exists $events{'1ce81410-4769-11d9-8693-ee0b0a9128b1'}) {
	print "Did not find deleted key\n";
}

print "STORE test..\n";
$eventscopy{"A-UNIQUE-ID"} = [
	'VEVENT',
	{
		'URL' => 'http//myurl.com',
		'SUMMARY' => 'my event',
		'CLASS' => 'PRIVATE',
		'LOCATION' => 'my location',
		'X' => [{'MEMBER' => 'AlarmEmailAddress'},	'me@myaddress'],
		'STATUS' => 'TENTATIVE',
		'DTSTAMP' => '20050116T154856Z',
		'DTEND' => '20050118T170000Z',
		'VALARM' => [
			{
				'TRIGGER' => [{'VALUE' => 'DURATION'}, '-PT1S']
			}
		],
		'DESCRIPTION' => 'my note',
		'X-MOZILLA-ALARM-DEFAULT-LENGTH' => '0',
		'RRULE' => {
			'FREQ' => 'WEEKLY',
			'BYDAY' => [
				'TU',
				'WE',
				'TH'
			],
			'INTERVAL' => '1'
		},
		'EXDATE' => '20050118T000000',
		'DTSTART' => '20050118T160000Z',
        'ATTENDEE' => [
            [{'CN' => 'BIG A','ROLE' => 'CHAIR','PARTSTAT' => 'ACCEPTED'},'MailtoA@example.com'],
            [{'CN' => 'B','RSVP' => 'TRUE','CUTYPE' => 'INDIVIDUAL'},'MailtoB@example.com'],
            ['MailtoB@example.com']
        ]
	}
];

print "hit Enter to test CLEAR..\n";
getc(STDIN);
print "CLEAR test..\n";
%eventscopy = ();