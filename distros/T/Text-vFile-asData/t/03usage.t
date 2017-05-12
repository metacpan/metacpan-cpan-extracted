#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

# Show an example of API in use, and test it at the same time

use Text::vFile::asData;
my $data = Text::vFile::asData->new->parse(\*DATA);

is(ref $data, 'HASH', 'Got back a hash ref');

# Should have one VCALENDAR object
is(scalar @{ $data->{objects} }, 1, 'Found one object');
is($data->{objects}->[0]->{type}, 'VCALENDAR', '  and it\'s a VCALENDAR');

# Get all the properties of this object.  There should be two (the other
# properties in there, DTSTART, etc, belong to the VEVENT object
my @properties = keys %{ $data->{objects}->[0]->{properties} };
is(scalar @properties, 2, 'Got 2 properties, as expected');

is($data->{objects}->[0]->{properties}->{'VERSION'}->[0]->{value}, '2.0',
   'VERSION is 2.0');
is($data->{objects}->[0]->{properties}->{'PRODID'}->[0]->{value},
   '-//hacksw/handcal//NONSGML v1.0//EN', 'PRODID looks right');

# Get the event info
my $e = $data->{objects}->[0]->{objects}->[0];
is($e->{type}, 'VEVENT', 'First sub object is a VEVENT');

done_testing();

#  Local Variables:
#  cperl-indent-level: 4
#  End:

__DATA__

BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//hacksw/handcal//NONSGML v1.0//EN
BEGIN:VEVENT
DTSTART:19970714T170000Z
DTEND:19970715T035959Z
SUMMARY:Bastille Day Party
END:VEVENT
END:VCALENDAR


