#ABSTRACT: Abstract interface for Google extension video player class
use strict;
use warnings;
package WWW::Sitemap::XML::Google::Video::Player::Interface;
BEGIN {
  $WWW::Sitemap::XML::Google::Video::Player::Interface::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::Google::Video::Player::Interface::VERSION = '2.02';
use Moose::Role;

requires qw(
    loc allow_embed autoplay as_xml
);


no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::Google::Video::Player::Interface - Abstract interface for Google extension video player class

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    package My::Sitemap::Google::Video::Player;
    use Moose;

    has [qw( loc allow_embed autoplay as_xml )] => (
        is => 'rw',
        isa => 'Str',
    );

    with 'WWW::Sitemap::XML::Google::Video::Player::Interface';

=head1 DESCRIPTION

Abstract interface for video player elements added to sitemap.

See L<WWW::Sitemap::XML::Google::Video::Player> for details.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
