use strict;
use warnings;
use Test::More tests => 58;

BEGIN { use_ok 'Text::Microformat' }
open IN, 't/hcal/hcalendar_01-component-vevent-dtstart-date.html';
local $/;
my $html = <IN>;
my $uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('dtstart'), '19970903');
}

open IN, 't/hcal/hcalendar_02-component-vevent-dtstart-datetime.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('dtstart'), '19970903T163000Z');
}

open IN, 't/hcal/hcalendar_03-component-vevent-dtend-date.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('dtstart'), '19970903');
    is($thing->Get('dtend'), '19970904');
}

open IN, 't/hcal/hcalendar_04-component-vevent-dtend-datetime.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('dtstart'), '19970903T160000Z');
    is($thing->Get('dtend'), '19970903T180000Z');
}

open IN, 't/hcal/hcalendar_05-calendar-simple.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'), 'http://www.web2con.com/');
    is($thing->Get('dtstart'), '2005-10-05');
    is($thing->Get('dtend'), '2005-10-08');
    is($thing->Get('location'), 'Argent Hotel, San Francisco, CA');
}

open IN, 't/hcal/hcalendar_06-component-vevent-uri-relative.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'), 'http://hg.microformats.org/squidlist/calendar/12279/2006/1/15');
    is($thing->Get('summary'), 'Bad Movie Night - Gigli (blame mike spiegelman)');
    is($thing->Get('dtstart'), '20060115T000000');
}

open IN, 't/hcal/hcalendar_07-component-vevent-description-simple.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('description'), 'Project xyz Review Meeting Minutes');
}

open IN, 't/hcal/hcalendar_08-component-vevent-multiple-classes.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'), 'http://www.web2con.com/');
    is($thing->Get('summary'), 'Web 2.0 Conference');
    is($thing->Get('dtstart'), '2005-10-05');
    is($thing->Get('dtend'), '2005-10-08');
    is($thing->Get('location'), 'Argent Hotel, San Francisco, CA');
}

open IN, 't/hcal/hcalendar_09-component-vevent-summary-in-img-alt.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'), 'http://conferences.oreillynet.com/et2006/');
    is($thing->Get('summary'), ''); # todo
    is($thing->Get('dtstart'), '20060306');
    is($thing->Get('dtend'), '20060310');
    is($thing->Get('location'), 'Manchester Grand Hyatt in San Diego, CA');
}

open IN, 't/hcal/hcalendar_10-component-vevent-entity.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('summary'), 'Cricket & Tennis Centre');
    is($thing->Get('description'), 'Melbourne\'s Cricket & Tennis Centres are in the heart of the city');
}

open IN, 't/hcal/hcalendar_11-component-vevent-summary-in-subelements.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('summary'), 'Welcome! John Battelle, Tim O\'Reilly');
    is($thing->Get('dtstart'), '20051005T1630-0700');
    is($thing->Get('dtend'), '20051005T1645-0700');
}

open IN,
't/hcal/hcalendar_12-component-vevent-summary-url-in-same-class.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'),
        'http://www.laughingsquid.com/squidlist/calendar/12377/2006/1/25');
    is($thing->Get('summary'), 'Art Reception for Tom Schultz and Felix Macnee');
    is($thing->Get('dtstart'), '20060125T000000');
}

open IN, 't/hcal/hcalendar_13-component-vevent-summary-url-property.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('summary'), 'ORD-SFO/AA 1655');
    is($thing->Get('url'),
        'http://dps1.travelocity.com/dparcobrand.ctl?smls=Y&Service=YHOE&.intl=us&aln_name=AA&flt_num=1655&dep_arp_name=&arr_arp_name=&dep_dt_dy_1=23&dep_dt_mn_1=Jan&dep_dt_yr_1=2006&dep_tm_1=9:00am');
}

open IN, 't/hcal/hcalendar_14-calendar-anniversary.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('summary'), 'Our Blissful Anniversary');
    is($thing->Get('dtstamp'), undef); # todo
    is($thing->Get('uid'), '19970901T130000Z-123403@host.com');
    is($thing->Get('dtstart'), '19971102');
}

open IN, 't/hcal/hcalendar_15-calendar-xml-lang.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'), 'http://www.web2con.com/');
    is($thing->Get('summary'), 'Web 2.0 Conference');
    is($thing->Get('dtstart'), '2005-10-05');
    is($thing->Get('dtend'), '2005-10-08');
    is($thing->Get('location'), 'Argent Hotel, San Francisco, CA');
}

open IN, 't/hcal/hcalendar_16-calendar-force-outlook.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('url'), 'http://www.web2con.com/');
    is($thing->Get('dtstart'), '2005-10-05');
    is($thing->Get('dtend'), '2005-10-08');
    is($thing->Get('location'), 'Argent Hotel, San Francisco, CA');
}

open IN,
't/hcal/hcalendar_17-component-vevent-description-value-in-subelements.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
foreach my $thing ($uformat->find) {
    is($thing->Get('description'), 'RESOLUTION: to have a 3rd PAW ftf meeting 18-19 Jan in Maryland; location contingent on confirmation from timbl');
    is($thing->Get('summary'), '3rd PAW ftf meeting');
    is($thing->Get('dtstart'), '2006-01-18');
    is($thing->Get('dtend'), '2006-01-20');
    is($thing->Get('location'), 'Maryland');
}

open IN, 't/hcal/hcalendar_18-component-vevent-uid.html';
local $/;
$html = <IN>;
$uformat = Text::Microformat->new($html);
my @formats = $uformat->find();
is($formats[0]->Get('uid'), 'http://example.com/foo.html');
is($formats[1]->Get('uid'), 'another hcal event');
is($formats[2]->Get('uid'), 'another hcal event');
is($formats[3]->Get('uid'), ''); # todo
is($formats[4]->Get('uid'), ''); # todo
