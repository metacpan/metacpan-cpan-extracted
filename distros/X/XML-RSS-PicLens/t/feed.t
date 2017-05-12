#!perl

use strict;
use warnings;
use lib qw( t/lib );
use Test::More;
use Test::XML;
use Data::Section -setup;
use XML::RSS::PicLens;

my @SCHEDULE = (
  {
    name => 'empty',
    like => 'empty',
    make => sub { },
  },
  {
    name => 'full',
    like => 'full',
    make => sub {
      my $pl = shift;
      $pl->add_image(
        image     => 'pl_images/A.jpg',
        thumbnail => 'pl_thumbs/A.jpg',
      );
      $pl->add_image( image     => 'pl_images/B.jpg', );
      $pl->add_image( thumbnail => 'pl_thumbs/C.jpg', );
      $pl->add_image(
        title     => 'Image D',
        thumbnail => 'pl_thumbs/D.jpg',
      );
      $pl->add_image(
        title => 'Image E',
        image => 'pl_images/E.jpg',
      );
      $pl->add_image(
        link  => 'http://hexten.net/',
        image => 'pl_images/F.jpg',
      );
      $pl->add_image(
        image     => 'pl_images/Z.jpg',
        thumbnail => 'pl_thumbs/Z.jpg',
      );
      $pl->add_content(
        content      => 'pl_images/foo.flv',
        content_type => 'video/x-flv',
        thumbnail    => 'pl_thumbs/foo.jpg',
      );
    },
  },
);

plan tests => @SCHEDULE * 4;

for my $case ( @SCHEDULE ) {
  my $name = $case->{name};
  my $like = $case->{like};
  my $make = $case->{make};

  my $ref = __PACKAGE__->section_data( $like );

  ok my $pl = XML::RSS::PicLens->new, "$name: created";
  isa_ok $pl, 'XML::RSS::PicLens';

  $make->( $pl );

  my $got = $pl->as_string;

  # diag $got;

  is_well_formed_xml( $got, "$name: XML well formed" );
  is_xml( $got, $$ref, "$name: XML matches" );
}

# vim:ts=4:sw=4:et:ft=perl

__DATA__
__[ empty ]__
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<rss version="2.0" 
  xmlns:media="http://search.yahoo.com/mrss">
    <channel>
        <title/>
        <description/>
        <link/>
    </channel>
</rss>
__[ full ]__
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<rss version="2.0" 
  xmlns:media="http://search.yahoo.com/mrss">
    <channel>
        <title/>
        <description/>
        <link/>
        <item>
            <title>A.jpg</title>
            <link>pl_images/A.jpg</link>
            <media:thumbnail url="pl_thumbs/A.jpg"/>
            <media:content url="pl_images/A.jpg"/>
        </item>                  
        <item>
            <title>B.jpg</title>
            <link>pl_images/B.jpg</link>
            <media:content url="pl_images/B.jpg"/>
        </item>                  
        <item>
            <title>C.jpg</title>
            <link>pl_thumbs/C.jpg</link>
            <media:thumbnail url="pl_thumbs/C.jpg"/>
        </item>                  
        <item>
            <title>Image D</title>
            <link>pl_thumbs/D.jpg</link>
            <media:thumbnail url="pl_thumbs/D.jpg"/>
        </item>                  
        <item>
            <title>Image E</title>
            <link>pl_images/E.jpg</link>
            <media:content url="pl_images/E.jpg"/>
        </item>                  
        <item>
            <title>F.jpg</title>
            <link>http://hexten.net/</link>
            <media:content url="pl_images/F.jpg"/>
        </item>                  
        <item>
            <title>Z.jpg</title>
            <link>pl_images/Z.jpg</link>
            <media:thumbnail url="pl_thumbs/Z.jpg"/>
            <media:content url="pl_images/Z.jpg"/>
        </item>                               
        <item>
            <title>foo.flv</title>
            <link>pl_images/foo.flv</link>
            <media:thumbnail url="pl_thumbs/foo.jpg"/>
            <media:content url="pl_images/foo.flv" type="video/x-flv"/>
        </item>                               
    </channel>
</rss>
