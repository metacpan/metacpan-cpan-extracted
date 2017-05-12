#ABSTRACT: XML Sitemap Google extension video player entry
use strict;
use warnings;
package WWW::Sitemap::XML::Google::Video::Player;
BEGIN {
  $WWW::Sitemap::XML::Google::Video::Player::AUTHORITY = 'cpan:AJGB';
}
$WWW::Sitemap::XML::Google::Video::Player::VERSION = '2.02';
use Moose;
use WWW::Sitemap::XML::Types qw( Location StrBool );



has 'loc' => (
    is => 'rw',
    isa => Location,
    required => 1,
    coerce => 1,
    predicate => 'has_loc',
);


has 'allow_embed' => (
    is => 'rw',
    isa => StrBool,
    required => 0,
    coerce => 1,
    predicate => 'has_allow_embed',
);


has 'autoplay' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    predicate => 'has_autoplay',
);


sub as_xml {
    my $self = shift;

    my $player = XML::LibXML::Element->new('video:player_loc');

    $player->appendText( $self->loc );

    do {
        my $name = $_;

        $player->setAttribute( $name, $self->$name() );

    } for grep {
            eval('$self->has_'.$_) || defined $self->$_()
        } qw( allow_embed autoplay );

    return $player;
}

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return $class->$next(loc => $_[0]);
    }
    return $class->$next( @_ );
};

with 'WWW::Sitemap::XML::Google::Video::Player::Interface';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Sitemap::XML::Google::Video::Player - XML Sitemap Google extension video player entry

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    my $player => WWW::Sitemap::XML::Google::Video::Player->new(
        {
            loc => 'http://mywebsite.com/video_player.swf?video=1',
            allow_embed => "yes",
            autoplay => "ap=1",
        }
    );

XML output:

    <?xml version="1.0" encoding="UTF-8"?>
    <video:player_loc allow_embed="yes" autoplay="ap=1">http://example.com/video_player.swf?video=2</video:player_loc>

=head1 DESCRIPTION

WWW::Sitemap::XML::Google::Video::Player represents single video player for
video entry in sitemap file.

Class implements L<WWW::Sitemap::XML::Google::Video::Player::Interface>.

=head1 ATTRIBUTES

=head2 loc

URL of the player.

isa: L<WWW::Sitemap::XML::Types/"Location">

Required.

=head2 allow_embed

Whether Google can embed the video in search results. Allowed values are
I<yes> or I<no>. The default value is I<yes>.

isa: L<WWW::Sitemap::XML::Types/"StrBool">

Optional.

=head2 autoplay

User-defined string that Google may append (if appropriate) to the flashvars
parameter to enable autoplay of the video.

isa: C<Str>

Optional.

=head1 METHODS

=head2 as_xml

Returns L<XML::LibXML::Element> object representing the C<E<lt>video:player_locE<gt>> entry.

=head1 SEE ALSO

L<WWW::Sitemap::XML::Google::Video>

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
