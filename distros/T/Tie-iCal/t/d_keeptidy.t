#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 5 }

open ICS, ">test.ics";
while (<main::DATA>) { print ICS $_ }
close ICS;

use Tie::iCal;

# TIEHASH
ok(tie my %events, 'Tie::iCal', "test.ics", 'debug' => 0);


# DELETE
delete $events{'1ce81410-4769-11d9-8693-ee0b0a9128b1'};
ok(!exists $events{'1ce81410-4769-11d9-8693-ee0b0a9128b1'});

# STORE
$events{'A-UNIQUE-ID'} = [
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
my ($comp2, $hash2) = @{$events{'A-UNIQUE-ID'}};
ok($comp2 eq 'VEVENT');
ok(${$hash2}{'LOCATION'} eq 'my location');

# CLEAR
%events = ();
ok(-z 'test.ics');

untie %events;
#unlink 'test.ics';
exit;

__END__
BEGIN:VCALENDAR
VERSION
 :2.0
PRODID
 :-//Mozilla.org/NONSGML Mozilla Calendar V1.0//EN
BEGIN:VEVENT
UID
 :413dd998-67d6-11d9-9a33-e4a59cf11a95
SUMMARY
 :my event
DESCRIPTION
 :my note
LOCATION
 :my location
URL
 :http://myurl.com
STATUS
 :TENTATIVE
CLASS
 :PRIVATE
X-MOZILLA-ALARM-DEFAULT-LENGTH
 :0
X
 ;MEMBER=AlarmEmailAddress
 :me@myaddress
RRULE
 :FREQ=WEEKLY;INTERVAL=1;BYDAY=TU,WE,TH
EXDATE
 :20050118T000000
DTSTART
 :20050118T160000Z
DTEND
 :20050118T170000Z
DTSTAMP
 :20050116T154856Z
BEGIN:VALARM
TRIGGER
 ;VALUE=DURATION
 :-PT1S
END:VALARM
END:VEVENT
END:VCALENDAR