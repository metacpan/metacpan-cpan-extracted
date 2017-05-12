#ABSTRACT: Abstract interface for sitemap indexes' Sitemap classes
use strict;
use warnings;
package WWW::SitemapIndex::XML::Sitemap::Interface;
BEGIN {
  $WWW::SitemapIndex::XML::Sitemap::Interface::AUTHORITY = 'cpan:AJGB';
}
$WWW::SitemapIndex::XML::Sitemap::Interface::VERSION = '2.02';
use Moose::Role;

requires qw(
    loc lastmod as_xml
);


no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::SitemapIndex::XML::Sitemap::Interface - Abstract interface for sitemap indexes' Sitemap classes

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    package My::SitemapIndex::Sitemap;
    use Moose;

    has [qw( loc lastmod as_xml )] => (
        is => 'rw',
        isa => 'Str',
    );

    with 'WWW::SitemapIndex::XML::Sitemap::Interface';

=head1 DESCRIPTION

Abstract interface for Sitemap elements added to sitemap index.

=head1 ABSTRACT METHODS

=head2 loc

URL of the sitemap.

=head2 lastmod

The date of last modification of the sitemap.

=head2 as_xml

XML representing the C<E<lt>sitemapE<gt>> entry in the sitemap index.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
