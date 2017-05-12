#ABSTRACT: XML Sitemap protocol
use strict;
use warnings;
package WWW::Sitemap::XML;
BEGIN {
  $WWW::Sitemap::XML::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::VERSION = '2.02';
use Moose;

use WWW::Sitemap::XML::URL;
use XML::LibXML qw(XML_ELEMENT_NODE);
use Scalar::Util qw( blessed );

use WWW::Sitemap::XML::Types qw( SitemapURL );


has '_rootcontainer' => (
    is => 'ro',
    traits => [qw( Array )],
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        _add_entry => 'push',
        _count_entries => 'count',
        _entries => 'elements',
    }
);

has '_first_loc' => (
    is => 'rw',
);

has '_check_req_interface' => (
    is => 'ro',
    default => sub {
        sub {
            die 'object does not implement WWW::Sitemap::XML::URL::Interface'
                unless is_SitemapURL($_[0]);
        }
    }
);

has '_entry_class' => (
    is => 'ro',
    default => 'WWW::Sitemap::XML::URL'
);

has '_root_ns' => (
    is => 'ro',
    default => sub {
        {
            'xmlns' => "http://www.sitemaps.org/schemas/sitemap/0.9",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' => join(' ',
                'http://www.sitemaps.org/schemas/sitemap/0.9',
                'http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd'
            ),
            'xmlns:image' => "http://www.google.com/schemas/sitemap-image/1.1",
            'xmlns:video' => "http://www.google.com/schemas/sitemap-video/1.1",
            'xmlns:mobile' => "http://www.google.com/schemas/sitemap-mobile/1.0",
        }
    },
);

has '_root_elem' => (
    is => 'ro',
    default => 'urlset',
);

has '_entry_elem' => (
    is => 'ro',
    default => 'url',
);

sub _pre_check_add {
    my ($self, $entry) = @_;

    $self->_check_req_interface->($entry);

    die "Single file cannot contain more then 50 000 entries"
        if $self->_count_entries >= 50_000;

    my $loc = $entry->loc;

    die "URL cannot be longer then 2048 characters"
        unless length $loc < 2048;

    my($scheme, $authority) = $loc =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?|;
    my $new = "$scheme://$authority";
    if ( $self->_count_entries ) {
        my $first = $self->_first_loc;

        die "All URLs in same file should use the same protocol and reside on the "
            ."same host: $first, not $new" unless $first eq $new;
    } else {
        $self->_first_loc( $new );
    }
}


sub add {
    my $self = shift;

    my $class = $self->_entry_class;

    my $arg = @_ == 1 && blessed $_[0] ?
                shift @_ : $class->new(@_);

    $self->_pre_check_add($arg);

    $self->_add_entry( $arg );
}


sub urls { shift->_entries }


sub load {
    my $self = shift;

    $self->add($_) for $self->read(@_);
}


sub read {
    my ($self, %args) = @_;

    my @entries;
    my $class = $self->_entry_class;

    my $xml = XML::LibXML->load_xml( %args );
    my $doc = $xml->getDocumentElement;

    my @ns = $doc->getNamespaces();
    for my $ns ( @ns ) {
        my $name = $ns->localname;
        next unless $name;

        $self->_root_ns->{ $ns->nodeName } = $ns->href;
    }

    for my $url ( $doc->getChildrenByLocalName( $self->_entry_elem ) ) {
        my @childNodes = grep { $_->nodeType == XML_ELEMENT_NODE() } $url->nonBlankChildNodes;
        my %args;
        for my $n ( @childNodes ) {
            my $localname = $n->localname;

            if ( $localname eq 'image' ) {
                push @{ $args{images} }, {
                    map {
                        $_->localname => $_->textContent
                    }
                    grep { $_->nodeType == XML_ELEMENT_NODE() }
                    $n->nonBlankChildNodes
                };
            }
            elsif ( $localname eq 'video' ) {
                my $video = {};
                my @videoChildNodes = grep { $_->nodeType == XML_ELEMENT_NODE() } $n->nonBlankChildNodes;

                for my $cn ( @videoChildNodes ) {
                    my $vname = $cn->localname;

                    if ( $vname eq 'player_loc' ) {
                        $video->{player} = {
                            loc => $cn->textContent,
                            (
                                map {
                                    $_ => $cn->getAttribute($_)
                                }
                                grep {
                                    $cn->hasAttribute($_)
                                } qw( allow_embed autoplay )
                            )
                        };
                    }
                    else {
                        $video->{ $vname } = $cn->textContent;
                    }
                }

                push @{ $args{videos} }, $video;
            }
            elsif ( $localname eq 'mobile' ) {
                $args{mobile} = 1;
            }
            else {
                $args{ $n->localname } = $n->textContent;
            }
        }
        push @entries,
            $class->new( %args );
    }

    return @entries;
}


sub write {
    my ($self, $fh, $format) = @_;

    $format ||= 0;

    my $writer = 'toFH';
    my $xml = $self->as_xml;

    unless ( ref $fh ) {
        $writer = 'toFile';
        if ( $fh =~ /\.gz$/i ) {
            $xml->setCompression(8);
        }
    }

    $xml->$writer( $fh, $format );
}


sub as_xml {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','UTF-8');
    my $root = $xml->createElement($self->_root_elem);

    while (my ($k, $v) = each %{ $self->_root_ns() } ) {
        $root->setAttribute($k, $v);
    };

    $root->appendChild($_) for
        map {
            my $xml = $_->as_xml;
            blessed $xml ? $xml : XML::LibXML->load_xml(string => $xml)->documentElement()
        } $self->_entries;

    $xml->setDocumentElement($root);

    return $xml;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML - XML Sitemap protocol

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    use WWW::Sitemap::XML;

    my $map = WWW::Sitemap::XML->new();

    # add new url
    $map->add( 'http://mywebsite.com/' );

    # or
    $map->add(
        loc => 'http://mywebsite.com/',
        lastmod => '2010-11-22',
        changefreq => 'monthly',
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
        videos => {
            content_loc => 'http://mywebsite.com/video1.flv',
            player => {
                loc => 'http://mywebsite.com/video_player.swf?video=1',
                allow_embed => "yes",
                autoplay => "ap=1",
            },
            thumbnail_loc => 'http://mywebsite.com/thumbs/1.jpg',
            title => 'Video Title 1',
            description => 'Video Description 1',
        }
    );

    # or
    $map->add(
        WWW::Sitemap::XML::URL->new(
            loc => 'http://mywebsite.com/',
            lastmod => '2010-11-22',
            changefreq => 'monthly',
            priority => 1.0,
            mobile => 1,
            images => [
                WWW::Sitemap::XML::Google::Image->new(
                    {
                        loc => 'http://mywebsite.com/image1.jpg',
                        caption => 'Caption 1',
                        title => 'Title 1',
                        license => 'http://www.mozilla.org/MPL/2.0/',
                        geo_location => 'Town, Region',
                    },
                ),
                WWW::Sitemap::XML::Google::Image->new(
                    {
                        loc => 'http://mywebsite.com/image2.jpg',
                        caption => 'Caption 2',
                        title => 'Title 2',
                        license => 'http://www.mozilla.org/MPL/2.0/',
                        geo_location => 'Town, Region',
                    }
                ),
            ],
            videos => [
                WWW::Sitemap::XML::Google::Video->new(
                    content_loc => 'http://mywebsite.com/video1.flv',
                    player => WWW::Sitemap::XML::Google::Video::Player->new(
                        {
                            loc => 'http://mywebsite.com/video_player.swf?video=1',
                            allow_embed => "yes",
                            autoplay => "ap=1",
                        }
                    ),
                    thumbnail_loc => 'http://mywebsite.com/thumbs/1.jpg',
                    title => 'Video Title 1',
                    description => 'Video Description 1',
                ),
            ],
        )
    );

    # read URLs from existing sitemap.xml file
    my @urls = $map->read( location => 'sitemap.xml' );

    # load urls from existing sitemap.xml file
    $map->load( location => 'sitemap.xml' );

    # get XML::LibXML object
    my $xml = $map->as_xml;

    print $xml->toString(1);

    # write to file
    $map->write( 'sitemap.xml', my $pretty_print = 1 );

    # write compressed
    $map->write( 'sitemap.xml.gz' );

=head1 DESCRIPTION

Read and write sitemap XML files as defined at L<http://www.sitemaps.org/> and
with support of Google video, image and mobile extensions described at L<https://support.google.com/webmasters/answer/183668>.

=head1 METHODS

=head2 add($url|%attrs)

    $map->add(
        WWW::Sitemap::XML::URL->new(
            loc => 'http://mywebsite.com/',
            lastmod => '2010-11-22',
            changefreq => 'monthly',
            priority => 1.0,
        )
    );

Add the C<$url> object representing single page in the sitemap.

Accepts blessed objects implementing L<WWW::Sitemap::XML::URL::Interface>.

Otherwise the arguments C<%attrs> are passed as-is to create new
L<WWW::Sitemap::XML::URL> object.

    $map->add(
        loc => 'http://mywebsite.com/',
        lastmod => '2010-11-22',
        changefreq => 'monthly',
        priority => 1.0,
    );

    # single url argument
    $map->add( 'http://mywebsite.com/' );

    # is same as
    $map->add( loc => 'http://mywebsite.com/' );

Performs basic validation of URLs added:

=over

=item * maximum of 50 000 URLs in single sitemap

=item * URL no longer then 2048 characters

=item * all URLs should use the same protocol and reside on same host

=back

=head2 urls

    my @urls = $map->urls;

Returns a list of all URL objects added to sitemap.

=head2 load(%sitemap_location)

    $map->load( location => $sitemap_file );

It is a shortcut for:

    $map->add($_) for $map->read( location => $sitemap_file );

Please see L<"read"> for details.

=head2 read(%sitemap_location)

    # file or url to sitemap
    my @urls = $map->read( location => $file_or_url );

    # file handle
    my @urls = $map->read( IO => $fh );

    # XML string
    my @urls = $map->read( string => $xml );

Read the sitemap from file, URL, open file handle or string and return the list of
L<WWW::Sitemap::XML::URL> objects representing C<E<lt>urlE<gt>> elements.

=head2 write($file, $format = 0)

    # write to file
    $map->write( 'sitemap.xml', my $pretty_print = 1);

    # or
    my $fh = IO::File->new();
    $fh->open('sitemap.xml', 'w');
    $map->write( $fh, my $pretty_print = 1);
    $cfh->close;

    # write compressed
    $map->write( 'sitemap.xml.gz' );

Write XML sitemap to C<$file> - a file name or L<IO::Handle> object.

If file names ends in C<.gz> then the output file will be compressed by
setting compression on XML object - please note that it requires I<libxml2> to
be compiled with I<zlib> support.

Optional C<$format> is passed to C<toFH> or C<toFile> methods
(depending on the type of C<$file>, respectively for file handle and file name)
as described in L<XML::LibXML>.

=head2 as_xml

    my $xml = $map->as_xml;

    # pretty print
    print $xml->toString(1);

    # write compressed
    $xml->setCompression(8);
    $xml->toFile( 'sitemap.xml.gz' );

Returns L<XML::LibXML::Document> object representing the sitemap in XML format.

The C<E<lt>urlE<gt>> elements are built by calling I<as_xml> on all URL objects
added into sitemap.

=head1 SEE ALSO

L<WWW::SitemapIndex::XML>

L<http://www.sitemaps.org/>

L<https://support.google.com/webmasters/answer/183668>

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
