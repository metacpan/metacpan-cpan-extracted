#ABSTRACT: XML Sitemap Google extension image entry
use strict;
use warnings;
package WWW::Sitemap::XML::Google::Image;
BEGIN {
  $WWW::Sitemap::XML::Google::Image::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::Google::Image::VERSION = '2.02';
use Moose;
use WWW::Sitemap::XML::Types qw( Location );
use XML::LibXML;



has 'loc' => (
    is => 'rw',
    isa => Location,
    required => 1,
    coerce => 1,
    predicate => 'has_loc',
);


has 'caption' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    predicate => 'has_caption',
);


has 'title' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    predicate => 'has_title',
);


has 'geo_location' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    predicate => 'has_geo_location',
);


has 'license' => (
    is => 'rw',
    isa => Location,
    required => 0,
    coerce => 1,
    predicate => 'has_license',
);


sub as_xml {
    my $self = shift;

    my $image = XML::LibXML::Element->new('image:image');

    do {
        my $name = $_;
        my $e = XML::LibXML::Element->new("image:$name");

        $e->appendText( $self->$name );

        $image->appendChild( $e );

    } for 'loc',grep {
            eval('$self->has_'.$_) || defined $self->$_()
        } qw( caption title license geo_location );

    return $image;
}

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->$next(loc => $_[0]);
    }
    return $class->$next( @_ );
};

with 'WWW::Sitemap::XML::Google::Image::Interface';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::Google::Image - XML Sitemap Google extension image entry

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    my $image = WWW::Sitemap::XML::Google::Image->new(
        {
            loc => 'http://mywebsite.com/image1.jpg',
            caption => 'Caption 1',
            title => 'Title 1',
            license => 'http://www.mozilla.org/MPL/2.0/',
            geo_location => 'Town, Region',
        },
    );

XML output:

    <?xml version="1.0" encoding="UTF-8"?>
    <image:image>
      <image:loc>http://mywebsite.com/image1.jpg</image:loc>
      <image:caption>Caption 1</image:caption>
      <image:title>Title 1</image:title>
      <image:license>http://www.mozilla.org/MPL/2.0/</image:license>
      <image:geo_location>Town, Region</image:geo_location>
    </image:image>

=head1 DESCRIPTION

WWW::Sitemap::XML::Google::Image represents single image entry in sitemap file.

Class implements L<WWW::Sitemap::XML::Google::Image::Interface>.

=head1 ATTRIBUTES

=head2 loc

The URL of the image.

isa: L<WWW::Sitemap::XML::Types/"Location">

Required.

=head2 caption

The caption of the image.

isa: C<Str>

Optional.

=head2 title

The title of the image.

isa: C<Str>

Optional.

=head2 geo_location

The geographic location of the image.

isa: C<Str>

Optional.

=head2 license

A URL to the license of the image.

isa: L<WWW::Sitemap::XML::Types/"Location">

Optional.

=head1 METHODS

=head2 as_xml

Returns L<XML::LibXML::Element> object representing the C<E<lt>image:imageE<gt>> entry in the sitemap.

=head1 SEE ALSO

L<https://support.google.com/webmasters/answer/183668>

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
