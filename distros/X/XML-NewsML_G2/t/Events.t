#!/usr/bin/env perl

use Test::MockTime 'set_fixed_time';

BEGIN {
    set_fixed_time('1325422800');
}

use utf8;
use Test::More;

use lib 't';
use NewsML_G2_Test_Helpers qw(validate_g2 :vars);
use DateTime;

use warnings;
use strict;

use XML::NewsML_G2;

my $ni = XML::NewsML_G2::News_Item_Text->new(
    guid            => $guid_text,
    provider        => $prov_apa,
    message_id      => $apa_id,
    language        => 'de',
    title           => 'Event Ref Test',
    content_created => DateTime->now(),
    timezone        => 'UTC'
);

my $ev_ref = XML::NewsML_G2::Event_Ref->new(
    event_id => '0815',
    name     => 'Bierverkostung November 2019'
);
$ni->add_event_reference($ev_ref);

my $mt = XML::NewsML_G2::Media_Topic->new(
    name  => 'Freizeit, Modernes Leben',
    qcode => 10000000
);

my $loc = XML::NewsML_G2::Location->new(
    name      => '"Der Hannes", Pressgasse 29, 1040 Wien, Austria',
    latitude  => 48.1963122,
    longitude => 16.3619024,
    qcode     => ''
);

my $start = DateTime->from_epoch( epoch => 1575136800 );
my $end = $start->clone->add( hours => 5 );
my $event = XML::NewsML_G2::Event_Item->new(
    guid     => $guid_event_prefix . '0815',
    provider => $prov_apa,
    language => 'de',
    event_id => '0815',
    title    => 'Bierverkostung November 2019',
    subtitle => (
        "Monatliches Treffen von gutgelaunten und schönen Menschen, mit dem Ziel der Trunksucht zu fröhnen"
    ),
    summary => join( "\n",
        'Die diesmonatige Verkostung findet im Lokal "Hannes" in der Pressgasse (1040 Wien) statt',
        'Nach ein paar Begrüßungsworten durch den Vorsitzenden startet unmgehend das Trinkgelage',
    ),
    location => $loc,
    start    => $start,
    end      => $end,
    timezone => 'UTC'
);
$event->title->add_translation( 'en', 'Beer tasting november 2019' );
$event->subtitle->add_translation( 'en',
    'Monthly come-together of friendly and beautiful guys for drinking' );
$event->add_media_topic($mt);

my $concept = XML::NewsML_G2::Concept->new( main => $mt );
$concept->add_facet(
    XML::NewsML_G2::Facet->new(
        name  => 'Alkohol',
        qcode => 'alcohol'
    )
);
$event->add_concept($concept);
$event->add_coverage( 'Text', 'Bild' );

my $event2 = XML::NewsML_G2::Event_Item->new(
    guid       => $guid_event_prefix . '0816',
    provider   => $prov_apa,
    language   => 'de',
    event_id   => '0816',
    title      => 'Teeverkostung November 2019',
    doc_status => 'canceled',
    location   => $loc,
    start      => $start,
    end        => $end,
    timezone   => 'UTC'
);
my $nm = XML::NewsML_G2::News_Message->new( timezone => 'UTC' );

$nm->add_item($event);
$nm->add_item($event2);
$nm->add_item($ni);

my %schemes = (
    'eventid' => XML::NewsML_G2::Scheme->new(
        alias => 'myeventid',
        uri   => 'http://events.salzamt.at/list-of-events/'
    ),
    'facet' => XML::NewsML_G2::Scheme->new(
        alias => 'myfacet',
        uri   => 'http://facets.salzamt.at/myfacets/'
    ),
    'ncostat' => XML::NewsML_G2::Scheme->new(
        alias => 'ncostat',
        uri   => 'http://cv.iptc.org/newscodes/newscoveragestatus/'
    ),
);
my $sm = XML::NewsML_G2::Scheme_Manager->new(%schemes);

foreach (qw/2.28/) {
    my $writer = XML::NewsML_G2::Writer::News_Message->new(
        news_message   => $nm,
        scheme_manager => $sm,
        g2_version     => $_,
    );
    ok( my $dom = $writer->create_dom(), "V $_ DOM created" );
    validate_g2( $dom, $_, "NewsMsg_withEvents_$_" );
}

done_testing;
