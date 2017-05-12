#ABSTRACT: Abstract interface for Google extension video class
use strict;
use warnings;
package WWW::Sitemap::XML::Google::Video::Interface;
BEGIN {
  $WWW::Sitemap::XML::Google::Video::Interface::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::Google::Video::Interface::VERSION = '2.02';
use Moose::Role;

requires qw(
    content_loc title description thumbnail_loc player as_xml
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::Google::Video::Interface - Abstract interface for Google extension video class

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    package My::Sitemap::Google::Video;
    use Moose;

    has [qw( content_loc title description thumbnail_loc player as_xml )] => (
        is => 'rw',
        isa => 'Str',
    );

    with 'WWW::Sitemap::XML::Google::Video::Interface';

=head1 DESCRIPTION

Abstract interface for video elements added to sitemap.

See L<WWW::Sitemap::XML::Google::Video> for details.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
