#ABSTRACT: XML Sitemap index protocol
use strict;
use warnings;
package WWW::SitemapIndex::XML;
BEGIN {
  $WWW::SitemapIndex::XML::AUTHORITY = 'cpan:AJGB';
}
$WWW::SitemapIndex::XML::VERSION = '2.02';
use Moose;
extends qw( WWW::Sitemap::XML );

use WWW::SitemapIndex::XML::Sitemap;
use XML::LibXML;
use Scalar::Util qw( blessed );

use WWW::Sitemap::XML::Types qw( SitemapIndexSitemap );


has '+_check_req_interface' => (
    is => 'ro',
    default => sub {
        sub {
            die 'object does not implement WWW::SitemapIndex::XML::Sitemap::Interface'
                unless is_SitemapIndexSitemap($_[0]);
        }
    }
);

has '+_entry_class' => (
    is => 'ro',
    default => 'WWW::SitemapIndex::XML::Sitemap'
);

has '+_root_ns' => (
    is => 'ro',
    default => sub {
        {
            'xmlns' => "http://www.sitemaps.org/schemas/sitemap/0.9",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' => join(' ',
                'http://www.sitemaps.org/schemas/sitemap/0.9',
                'http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd'
            ),
        }
    },
);

has '+_root_elem' => (
    is => 'ro',
    default => 'sitemapindex',
);

has '+_entry_elem' => (
    is => 'ro',
    default => 'sitemap',
);


sub sitemaps { shift->_entries }


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::SitemapIndex::XML - XML Sitemap index protocol

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    use WWW::SitemapIndex::XML;

    my $index = WWW::SitemapIndex::XML->new();

    # add new sitemaps
    $index->add( 'http://mywebsite.com/sitemap1.xml.gz' );

    # or
    $index->add(
        loc => 'http://mywebsite.com/sitemap1.xml.gz',
        lastmod => '2010-11-26',
    );

    # or
    $index->add(
        WWW::SitemapIndex::XML::Sitemap->new(
            loc => 'http://mywebsite.com/sitemap1.xml.gz',
            lastmod => '2010-11-26',
        )
    );

    # read sitemaps from existing sitemap_index.xml file
    my @sitemaps = $index->read( 'sitemap_index.xml' );

    # load sitemaps from existing sitemap_index.xml file
    $index->load( 'sitemap_index.xml' );

    # get XML::LibXML object
    my $xml = $index->as_xml;

    print $xml->toString(1);

    # write to file
    $index->write( 'sitemap_index.xml', my $pretty_print = 1 );

    # write compressed
    $index->write( 'sitemap_index.xml.gz' );

=head1 DESCRIPTION

Read and write sitemap index xml files as defined at L<http://www.sitemaps.org/>.

=head1 METHODS

=head2 add($sitemap|%attrs)

    $index->add(
        WWW::SitemapIndex::XML::Sitemap->new(
            loc => 'http://mywebsite.com/sitemap1.xml.gz',
            lastmod => '2010-11-26',
        )
    );

Add the C<$sitemap> object representing single sitemap in the sitemap index.

Accepts blessed objects implementing L<WWW::SitemapIndex::XML::Sitemap::Interface>.

Otherwise the arguments C<%attrs> are passed as-is to create new
L<WWW::SitemapIndex::XML::Sitemap> object.

    $index->add(
        loc => 'http://mywebsite.com/sitemap1.xml.gz',
        lastmod => '2010-11-26',
    );

    # single url argument
    $index->add( 'http://mywebsite.com/' );

    # is same as
    $index->add( loc => 'http://mywebsite.com/sitemap1.xml.gz' );

Performs basic validation of sitemaps added:

=over

=item * maximum of 50 000 sitemaps in single sitemap

=item * URL no longer then 2048 characters

=item * all URLs should use the same protocol and reside on same host

=back

=head2 sitemaps

    my @sitemaps = $index->sitemaps;

Returns a list of all Sitemap objects added to sitemap index.

=head2 load(%sitemap_index_location)

    $index->load( location => $sitemap_index_file );

It is a shortcut for:

    $index->add($_) for $index->read( location => $sitemap_index_file );

Please see L<"read"> for details.

=head2 read(%sitemap_index_location)

    # file or url to sitemap index
    my @sitemaps = $index->read( location => $file_or_url );

    # file handle
    my @sitemaps = $index->read( IO => $fh );

    # xml string
    my @sitemaps = $index->read( string => $xml );

Read the sitemap index from file, URL, open file handle or string and return
the list of L<WWW::SitemapIndex::XML::Sitemap> objects representing
C<E<lt>sitemapE<gt>> elements.

=head2 write($file, $format = 0)

    # write to file
    $index->write( 'sitemap_index.xml', my $pretty_print = 1);

    # or
    my $fh = IO::File->new();
    $fh->open('sitemap_index.xml', 'w');
    $index->write( $fh, my $pretty_print = 1);
    $cfh->close;

    # write compressed
    $index->write( 'sitemap_index.xml.gz' );

Write XML sitemap index to C<$file> - a file name or L<IO::Handle> object.

If file names ends in C<.gz> then the output file will be compressed by
setting compression on xml object - please note that it requires I<libxml2> to
be compiled with I<zlib> support.

Optional C<$format> is passed to C<toFH> or C<toFile> methods
(depending on the type of C<$file>, respectively for file handle and file name)
as described in L<XML::LibXML>.

=head2 as_xml

    my $xml = $index->as_xml;

    # pretty print
    print $xml->toString(1);

    # write compressed
    $xml->setCompression(8);
    $xml->toFile( "sitemap_index.xml.gz" );

Returns L<XML::LibXML::Document> object representing the sitemap index in XML
format.

The C<E<lt>sitemapE<gt>> elements are built by calling I<as_xml> on all Sitemap
objects added into sitemap index.

=head1 SEE ALSO

L<http://www.sitemaps.org/>

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
