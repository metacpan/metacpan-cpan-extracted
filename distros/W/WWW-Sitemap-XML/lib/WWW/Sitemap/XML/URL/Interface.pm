#ABSTRACT: Abstract interface for sitemap's URL classes
use strict;
use warnings;
package WWW::Sitemap::XML::URL::Interface;
BEGIN {
  $WWW::Sitemap::XML::URL::Interface::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::URL::Interface::VERSION = '2.02';
use Moose::Role;

requires qw(
    loc lastmod changefreq priority images videos mobile as_xml
);


no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::URL::Interface - Abstract interface for sitemap's URL classes

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    package My::Sitemap::URL;
    use Moose;

    has [qw( loc lastmod changefreq priority as_xml )] => (
        is => 'rw',
        isa => 'Str',
    );

    has [qw( images videos )] => (
        is => 'rw',
        isa => 'ArrayRef',
    );

    has [qw( mobile )] => (
        is => 'rw',
        isa => 'Bool',
    );

    with 'WWW::Sitemap::XML::URL::Interface';

=head1 DESCRIPTION

Abstract interface for URL elements added to sitemap.

See L<WWW::Sitemap::XML::URL> for details.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
