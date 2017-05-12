#ABSTRACT: XML Sitemap url entry
use strict;
use warnings;
package WWW::Sitemap::XML::URL;
BEGIN {
  $WWW::Sitemap::XML::URL::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::URL::VERSION = '2.02';
use Moose;
use WWW::Sitemap::XML::Types qw( Location ChangeFreq Priority ArrayRefOfImageObjects ArrayRefOfVideoObjects );
use MooseX::Types::DateTime::W3C qw( DateTimeW3C );
use XML::LibXML;
use WWW::Sitemap::XML::Google::Image;
use WWW::Sitemap::XML::Google::Video;



has 'loc' => (
    is => 'rw',
    isa => Location,
    required => 1,
    coerce => 1,
    predicate => 'has_loc',
);


has 'lastmod' => (
    is => 'rw',
    isa => DateTimeW3C,
    required => 0,
    coerce => 1,
    predicate => 'has_lastmod',
);


has 'changefreq' => (
    is => 'rw',
    isa => ChangeFreq,
    required => 0,
    coerce => 1,
    predicate => 'has_changefreq',
);


has 'priority' => (
    is => 'rw',
    isa => Priority,
    required => 0,
    predicate => 'has_priority',
);


has 'images' => (
    is => 'rw',
    isa => ArrayRefOfImageObjects,
    required => 0,
    coerce => 1,
    predicate => 'has_images',
);


has 'videos' => (
    is => 'rw',
    isa => ArrayRefOfVideoObjects,
    required => 0,
    coerce => 1,
    predicate => 'has_videos',
);


has 'mobile' => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    coerce => 0,
    predicate => 'has_mobile',
);


sub as_xml {
    my $self = shift;

    my $url = XML::LibXML::Element->new('url');

    do {
        my $name = $_;
        my $e = XML::LibXML::Element->new($name);

        $e->appendText( $self->$name );

        $url->appendChild( $e );

    } for 'loc',grep {
            eval('$self->has_'.$_) || defined $self->$_()
        } qw( lastmod changefreq priority );

    if ( $self->has_images ) {
        for my $image ( @{ $self->images || [] } ) {
            $url->appendChild( $image->as_xml );
        }
    }

    if ( $self->has_videos ) {
        for my $video ( @{ $self->videos || [] } ) {
            $url->appendChild( $video->as_xml );
        }
    }

    if ( $self->has_mobile && $self->mobile ) {
        my $e = XML::LibXML::Element->new('mobile:mobile');
        $url->appendChild( $e );
    }

    return $url;
}

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->$next(loc => $_[0]);
    }

    return $class->$next( @_ );
};

with 'WWW::Sitemap::XML::URL::Interface';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::URL - XML Sitemap url entry

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    my $url = WWW::Sitemap::XML::URL->new(
        loc => 'http://mywebsite.com/',
        lastmod => '2010-11-26',
        changefreq => 'always',
        priority => 1.0,
    );

XML output:

    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
       <url>
          <loc>http://mywebsite.com/</loc>
          <lastmod>2010-11-26</lastmod>
          <changefreq>always</changefreq>
          <priority>1.0</priority>
       </url>
    </urlset>

Google sitemap video, image and mobile extensions:

    my $url2 = WWW::Sitemap::XML::URL->new(
        loc => 'http://mywebsite.com/',
        lastmod => '2010-11-26',
        changefreq => 'always',
        priority => 1.0,
        mobile => 1,
        images => [
            {
                loc => 'http://mywebsite.com/image1.jpg',
                caption => 'Caption 1',
                title => 'Title 1',
                license => 'http://www.mozilla.org/MPL/2.0/',
                geo_location => 'Town, Region',
            },
            {
                loc => 'http://mywebsite.com/image2.jpg',
                caption => 'Caption 2',
                title => 'Title 2',
                license => 'http://www.mozilla.org/MPL/2.0/',
                geo_location => 'Town, Region',
            }
        ],
        videos => [
            content_loc => 'http://mywebsite.com/video1.flv',
            player => {
                loc => 'http://mywebsite.com/video_player.swf?video=1',
                allow_embed => "yes",
                autoplay => "ap=1",
            }
            thumbnail_loc => 'http://mywebsite.com/thumbs/1.jpg',
            title => 'Video Title 1',
            description => 'Video Description 1',
        ]

    );

XML output:

    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:mobile="http://www.google.com/schemas/sitemap-mobile/1.0"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"
        xmlns:video="http://www.google.com/schemas/sitemap-video/1.1">
       <url>
          <loc>http://mywebsite.com/</loc>
          <lastmod>2010-11-26</lastmod>
          <changefreq>always</changefreq>
          <priority>1.0</priority>
          <mobile:mobile/>
          <image:image>
             <image:loc>http://mywebsite.com/image1.jpg</image:loc>
             <image:caption>Caption 1</image:caption>
             <image:title>Title 1</image:title>
             <image:license>http://www.mozilla.org/MPL/2.0/</image:license>
             <image:geo_location>Town, Region</image:geo_location>
          </image:image>
          <image:image>
             <image:loc>http://mywebsite.com/image2.jpg</image:loc>
             <image:caption>Caption 2</image:caption>
             <image:title>Title 2</image:title>
             <image:license>http://www.mozilla.org/MPL/2.0/</image:license>
             <image:geo_location>Town, Region</image:geo_location>
          </image:image>
          <video:video>
             <video:content_loc>http://mywebsite.com/video1.flv</video:content_loc>
             <video:title>Video Title 1</video:title>
             <video:description>Video Description 1</video:description>
             <video:thumbnail_loc>http://mywebsite.com/thumbs/1.jpg</video:thumbnail_loc>
             <video:player_loc allow_embed="yes" autoplay="ap=1">http://mywebsite.com/video_player.swf?video=1</video:player_loc>
          </video:video>

       </url>
    </urlset>

=head1 DESCRIPTION

WWW::Sitemap::XML::URL represents single url entry in sitemap file.

Class implements L<WWW::Sitemap::XML::URL::Interface>.

=head1 ATTRIBUTES

=head2 loc

URL of the page.

isa: L<WWW::Sitemap::XML::Types/"Location">

Required.

=head2 lastmod

The date of last modification of the page.

isa: L<MooseX::Types::DateTime::W3C/"DateTimeW3C">

Optional.

=head2 changefreq

How frequently the page is likely to change.

isa: L<WWW::Sitemap::XML::Types/"ChangeFreq">

Optional.

=head2 priority

The priority of this URL relative to other URLs on your site.

isa: L<WWW::Sitemap::XML::Types/"Priority">

Optional.

=head2 images

Array reference of images on page.

Note: This is a Google sitemap extension.

isa: L<WWW::Sitemap::XML::Types/"ArrayRefOfImageObjects">

Optional.

=head2 videos

Array reference of videos on page.

Note: This is a Google sitemap extension.

isa: L<WWW::Sitemap::XML::Types/"ArrayRefOfVideoObjects">

Optional.

=head2 mobile

Flag indicating that page serves feature phone content.

A mobile sitemap must contain only URLs that serve feature phone web content.
All other URLs are ignored by the Google crawling mechanisms so, if you have
non-featurephone content, create a separate sitemap for those URLs.

Note: This is a Google sitemap extension.

isa: C<Bool>

Optional.

=head1 METHODS

=head2 as_xml

Returns L<XML::LibXML::Element> object representing the C<E<lt>urlE<gt>> entry in the sitemap.

=head1 SEE ALSO

L<http://www.sitemaps.org/protocol.php>

L<WWW::Sitemap::XML::Google::Image>

L<WWW::Sitemap::XML::Google::Video>

L<https://support.google.com/webmasters/answer/183668>

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
