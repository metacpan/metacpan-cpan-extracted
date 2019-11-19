#!/usr/bin/env perl

use Test::MockTime 'set_fixed_time';

BEGIN {
    set_fixed_time('1325422800');
}

use utf8;
use Test::More;
use DateTime::Format::XSD;
use XML::LibXML;

use version;

use lib 't';
use NewsML_G2_Test_Helpers
    qw(create_ni_graphics test_ni_picture test_ni_versions validate_g2 :vars);

use warnings;
use strict;

use XML::NewsML_G2;

my $ni = create_ni_graphics();

# AGD : altId = shortname@excelsa.doc
my $graphics = XML::NewsML_G2::Graphics->new(
    mimetype  => 'application/illustrator',
    rendition => 'print',
    altId     => '1031-14-Wetter'
);
ok( $ni->add_remote( 'file://tmp/files/123.ai', $graphics ),
    'Adding remote graphics works' );

my $sm = test_ni_picture( $ni, 'NewsItemGraphicsPicture' );
test_ni_versions(
    $ni, $sm,
    'NewsItemGraphics',
    '*' => sub {
        my ( $dom, $xpc, $version ) = @_;
        is( $xpc->findvalue('//nar:contentSet/nar:remoteContent/nar:altId'),
            '1031-14-Wetter', 'correct Graphics altId in XML' );
        like(
            $xpc->findvalue(
                '//nar:contentSet/nar:remoteContent/@contenttype'),
            qr|application/illustrator|,
            'graphics mimetype in XML'
        );
    }
);

done_testing;
