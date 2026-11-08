#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::PP ();
use Digest::SHA qw(sha1_hex);
use Text::JSCalendar;

# jscalendar-icalendar-29 3.4, 2.3.3, 2.3.22, 2.3.24, 2.3.46 and
# jscalendarbis-22 1.5.11: a Link becomes ATTACH, IMAGE, URL or LINK by its
# "rel", whose default is "enclosure".

my $jscal = Text::JSCalendar->new();
my $true = JSON::PP::true();
sub unfold { my $i = shift; $i =~ s/\r?\n[ \t]//g; return $i }
sub lines { my ($ical, $name) = @_; return [ $ical =~ m/^($name[;:][^\r\n]*)/mg ] }

my $Event = {
  '@type' => 'Event', uid => 'links1@example.com', title => 'Links',
  start => '2025-06-02T10:00:00', timeZone => 'Etc/UTC', duration => 'PT1H',
  links => {
    att  => { '@type' => 'Link', href => 'https://example.com/a.pdf', rel => 'enclosure',
              title => 'a.pdf', contentType => 'application/pdf', size => 42 },
    bare => { '@type' => 'Link', href => 'https://example.com/b.pdf' },
    ico  => { '@type' => 'Link', href => 'https://example.com/i.png', rel => 'icon',
              title => 'Icon', contentType => 'image/png', display => { badge => $true } },
    d1   => { '@type' => 'Link', href => 'https://example.com/about', rel => 'describedby', title => 'About' },
    d2   => { '@type' => 'Link', href => 'https://example.com/more', rel => 'describedby' },
    src  => { '@type' => 'Link', href => 'https://example.com/events', rel => 'https://example.com/linkrel/source',
              title => 'Venue' },
  },
};

my $ical = unfold($jscal->eventsToVCalendar($Event));
my $attach = lines($ical, 'ATTACH');
is(scalar @$attach, 2, 'enclosure and a link without rel (default enclosure) are ATTACH');
like("@$attach", qr/FILENAME=a\.pdf/, 'ATTACH title is FILENAME');
like($ical, qr/^IMAGE;[^\n]*FILENAME=Icon[^\n]*:https:\/\/example\.com\/i\.png\r?$/m, 'icon is IMAGE, title FILENAME');
like($ical, qr/^IMAGE;[^\n]*DISPLAY=BADGE/m, 'with DISPLAY');
my $url = lines($ical, 'URL');
is(scalar @$url, 1, 'only one URL');
like($url->[0], qr/LABEL=About.*:https:\/\/example\.com\/about$/, 'the first describedby is URL, title LABEL');
my $link = lines($ical, 'LINK');
is(scalar @$link, 2, 'the second describedby and the other rel are LINK');
like("@$link", qr/LINKREL="?https:\/\/example\.com\/linkrel\/source"?/, 'LINK carries LINKREL');
like("@$link", qr/LINKREL=describedby/i, 'including describedby on the demoted one');
unlike("@$attach @$url", qr/LINKREL/, 'no LINKREL on ATTACH or URL');

my ($Back) = $jscal->vcalendarToEvents($ical);
is_deeply([sort keys %{$Back->{links}}], [sort keys %{$Event->{links}}], 'keys survive via JSID');
is($Back->{links}{att}{rel}, 'enclosure', 'ATTACH reads as enclosure');
is($Back->{links}{bare}{rel}, 'enclosure', 'the link without rel comes back as enclosure');
is($Back->{links}{ico}{rel}, 'icon', 'IMAGE reads as icon');
is($Back->{links}{ico}{title}, 'Icon', 'IMAGE title from FILENAME');
is_deeply($Back->{links}{ico}{display}, { badge => $true }, 'IMAGE DISPLAY');
is($Back->{links}{d1}{rel}, 'describedby', 'URL reads as describedby');
is($Back->{links}{d1}{title}, 'About', 'URL title from LABEL');
is($Back->{links}{d2}{rel}, 'describedby', 'a LINK with LINKREL=describedby too');
is($Back->{links}{src}{rel}, 'https://example.com/linkrel/source', 'LINKREL reads as rel');
is($Back->{links}{src}{title}, 'Venue', 'LINK title from LABEL');

# the spec's own examples (2.3.24, 2.3.46), keyed without JSID
my ($Ex) = $jscal->vcalendarToEvents(join("\r\n",
  'BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:x', 'BEGIN:VEVENT', 'UID:ex@example.com',
  'DTSTAMP:20250101T000000Z', 'DTSTART:20250602T100000Z',
  'LINK;LINKREL="https://example.com/linkrel/source";LABEL=Venue;VALUE=URI:https://example.com/events',
  'LINK;VALUE=UID:not-a-uri',
  'URL:https://example.com/myurl',
  'END:VEVENT', 'END:VCALENDAR', ''));
is_deeply($Ex->{links}{sha1_hex('https://example.com/myurl')},
  { href => 'https://example.com/myurl', rel => 'describedby' }, 'URL example');
is_deeply($Ex->{links}{sha1_hex('https://example.com/events')},
  { href => 'https://example.com/events', rel => 'https://example.com/linkrel/source', title => 'Venue' },
  'LINK example');
is(scalar keys %{$Ex->{links}}, 2, 'a LINK of value type UID does not convert');

# no JSID when the key is the one the reader would make anyway
my $plain = unfold($jscal->eventsToVCalendar({ %$Event, links => {
  sha1_hex('https://example.com/x') => { '@type' => 'Link', href => 'https://example.com/x', rel => 'describedby' } } }));
unlike($plain, qr/^URL;[^\n]*JSID/m, 'default key: no JSID');

done_testing;
