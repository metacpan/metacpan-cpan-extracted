#!perl

use strict;
use warnings;
use Test::More tests => 2;
use XML::OPDS;

my $feed = XML::OPDS->new(prefix => 'http://amusewiki.org',
                          author => 'XML::OPDS 0.06',
                          updated => DateTime->new(year => 2016, month => 3, day => 1,
                                                   time_zone => 'Europe/Belgrade'));

$feed->add_to_navigations_new_level(
                          title => 'Root',
                          href => '/',
                         );
$feed->add_to_acquisitions(
                           href => '/second/title',
                           title => 'Second title',
                           files => [ '/second/title.epub' ],
                           image => '/path/myimage.png',
                           thumbnail => '/path/to/thumbnail',
                           description => 'blablabla',
                          );

like $feed->render, qr{rel="http://opds-spec.org/image"};
like $feed->render, qr{href="http://amusewiki.org/path/myimage.png"};
