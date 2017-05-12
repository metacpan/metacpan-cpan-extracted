#ABSTRACT: XML Sitemap Google extension video entry
use strict;
use warnings;
package WWW::Sitemap::XML::Google::Video;
BEGIN {
  $WWW::Sitemap::XML::Google::Video::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::Google::Video::VERSION = '2.02';
use Moose;
use WWW::Sitemap::XML::Types qw( Location VideoPlayer Max100CharsStr Max2048CharsStr );
use XML::LibXML;



has 'content_loc' => (
    is => 'rw',
    isa => Location,
    coerce => 1,
    predicate => 'has_content_loc',
);


has 'player' => (
    is => 'rw',
    isa => VideoPlayer,
    required => 0,
    coerce => 1,
    predicate => 'has_player',
);


has 'title' => (
    is => 'rw',
    isa => Max100CharsStr,
    required => 1,
    predicate => 'has_title',
);


has 'description' => (
    is => 'rw',
    isa => Max2048CharsStr,
    required => 1,
    predicate => 'has_description',
);


has 'thumbnail_loc' => (
    is => 'rw',
    isa => Location,
    required => 1,
    predicate => 'has_thumbnail_loc',
);


sub as_xml {
    my $self = shift;

    my $video = XML::LibXML::Element->new('video:video');

    do {
        my $name = $_;
        my $e = XML::LibXML::Element->new("video:$name");

        $e->appendText( $self->$name );

        $video->appendChild( $e );

    } for 'content_loc',grep {
            eval('$self->has_'.$_) || defined $self->$_()
        } qw( title description thumbnail_loc );

    if ( $self->has_player) {
        $video->appendChild( $self->player->as_xml );
    }

    return $video;
}

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->$next(content_loc => $_[0]);
    }

    return $class->$next( @_ );
};

with 'WWW::Sitemap::XML::Google::Video::Interface';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::Google::Video - XML Sitemap Google extension video entry

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    my $video = WWW::Sitemap::XML::Google::Video->new(
        content_loc => 'http://mywebsite.com/video1.flv',
        player => {
            loc => 'http://mywebsite.com/video_player.swf?video=1',
            allow_embed => "yes",
            autoplay => "ap=1",
        },
        thumbnail_loc => 'http://mywebsite.com/thumbs/1.jpg',
        title => 'Video Title 1',
        description => 'Video Description 1',
    );

XML output:

    <?xml version="1.0" encoding="UTF-8"?>
    <video:video>
      <video:content_loc>http://mywebsite.com/video1.flv</video:content_loc>
      <video:title>Video Title 1</video:title>
      <video:description>Video Description 1</video:description>
      <video:thumbnail_loc>http://mywebsite.com/thumbs/1.jpg</video:thumbnail_loc>
      <video:player_loc allow_embed="yes" autoplay="ap=1">http://mywebsite.com/video_player.swf?video=1</video:player_loc>
    </video:video>

=head1 DESCRIPTION

WWW::Sitemap::XML::Google::Video represents single video entry in sitemap file.

Class implements L<WWW::Sitemap::XML::Google::Video::Interface>.

=head1 ATTRIBUTES

=head2 content_loc

At least one of L<"player"> and L<"content_loc"> is required.
This should be a I<.mpg>, I<.mpeg>, I<.mp4>, I<.m4v>, I<.mov>, I<.wmv>, I<.asf>, I<.avi>, I<.ra>, I<.ram>, I<.rm>, I<.flv>,
or other video file format, and can be omitted if L<"player"> is specified. However, because Google
needs to be able to check that the Flash object is actually a player for video (as opposed to some other use of Flash, e.g. games and
animations), it's helpful to provide both.

isa: L<WWW::Sitemap::XML::Types/"Location">

=head2 player

    $video->player({
        loc => 'http://mywebsite.com/video_player.swf?video=1',
        allow_embed => "yes",
        autoplay => "ap=1",
    });

At least one of L<"player"> and L<"content_loc"> is required.
A URL pointing to a Flash player for a specific video. In general,
this is the information in the src element of an <embed> tag
and should not be the same as the content of the <loc> tag.
Since each video is uniquely identified by its content URL (the
location of the actual video file) or, if a content URL is not
present, a player URL (a URL pointing to a player for the video),
you must include either the L<"player_loc"> or
L<"content_loc"> tags. If these tags are omitted and we
can't find this information, we'll be unable to index your video.

isa: L<WWW::Sitemap::XML::Types/"VideoPlayer">

=head2 title

The title of the video.

isa: L<WWW::Sitemap::XML::Types/"Max100CharsStr">

Required.

=head2 description

The description of the video.

isa: L<WWW::Sitemap::XML::Types/"Max2048CharsStr">

Required.

=head2 thumbnail_loc

A URL pointing to the URL for the video thumbnail image file. We can
accept most image sizes/types but recommend your thumbnails are at
least 120x90 pixels in .jpg, .png, or. gif formats.

isa: L<WWW::Sitemap::XML::Types/"Location">

Required.

=head1 METHODS

=head2 as_xml

Returns L<XML::LibXML::Element> object representing the C<E<lt>video:videoE<gt>> entry in the sitemap.

=head1 SEE ALSO

L<https://support.google.com/webmasters/answer/183668>

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
