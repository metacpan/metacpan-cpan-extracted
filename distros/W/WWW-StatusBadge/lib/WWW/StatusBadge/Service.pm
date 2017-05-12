#!/usr/bin/perl
package WWW::StatusBadge::Service;
$WWW::StatusBadge::Service::VERSION = '0.0.2';
use strict;
use warnings;

use Carp ();
use Hash::Util::FieldHash ();
use Module::Pluggable::Object ();

Hash::Util::FieldHash::fieldhashes \my( %Img, %Txt, %Url, );

sub new {
    my $class = shift;
    my %arg   = @_;

    for my $key ( qw(img txt url) ) {
        Carp::croak( sprintf 'missing required parameter %s!', $key )
            unless $arg{ $key };
    }

    my $self = do {
        my $o; bless \( $o ), ref $class || $class || __PACKAGE__;
    };

    $Img{ $self } = $arg{'img'};
    $Txt{ $self } = $arg{'txt'};
    $Url{ $self } = $arg{'url'};

    return $self;
}

sub txt { return $Txt{ shift() }; }
sub img { return $Img{ shift() }; }
sub url { return $Url{ shift() }; }

my $package = __PACKAGE__;
my $finder  = Module::Pluggable::Object->new(
        'package' => 'WWW::StatusBadge::Render', 'require' => 1,
    );

{
    no strict 'refs';
    for my $plugin ( $finder->plugins ) {
        my $service = $plugin->can('render')
            || next;
        my $method = join( '_', ( split '::', lc $plugin )[4,] );
        *{ sprintf '%s::%s', $package, $method } = $service;
    }
}

1;
# ABSTRACT: Service agnostic Status Badge generator
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::StatusBadge::Service - Service agnostic Status Badge generator

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge::Service;

    my $service = WWW::StatusBadge::Service->new(
        'txt' => 'Build Status',
        'url' => 'https://travis-ci.org/ARivottiC/Sidekick-Accessor.pm',
        'img' => 'https://travis-ci.org/ARivottiC/Sidekick-Accessor.pm.svg',
    );

    my $markdown = $service->markdown;

=head1 DESCRIPTION

Generates Status Badges in several formats.

=head1 ATTRIBUTES

=head2 txt

Returns the status text.

=head2 url

Returns the URL.

=head2 img

Returns the image URL.

=head1 METHODS

=head2 new

    my $service = WWW::StatusBadge::Service->new(
        'txt' => 'Build Status',
        'url' => 'https://travis-ci.org/ARivottiC/Sidekick-Accessor.pm',
        'img' => 'https://travis-ci.org/ARivottiC/Sidekick-Accessor.pm.svg',
    );

=over 4

=item I<txt =E<gt> $text>

The status text. Required.

=item I<url =E<gt> $url>

The project/distribution URL. Required.

=item I<img =E<gt> $img_url>

The status image URL. Required.

=back

=for Pod::Coverage asciidoc html markdown pod rdoc rst textile

=head1 PLUGINS

    package WWW::StatusBadge::Render::Plugin::Markdown;

    sub render {
        my $self = shift;

        return sprintf('[![%s](%s)](%s)', $self->txt, $self->url, $self->img,)
    }

    1;

=head1 SEE ALSO

=over 4

=item *

L<WWW::StatusBadge>

=item *

L<WWW::StatusBadge::Service::TravisCI>

=item *

L<WWW::StatusBadge::Service::Coveralls>

=item *

L<WWW::StatusBadge::Service::BadgeFury>

=item *

L<WWW::StatusBadge::Render::Plugin::AsciiDoc>

=item *

L<WWW::StatusBadge::Render::Plugin::HTML>

=item *

L<WWW::StatusBadge::Render::Plugin::Markdown>

=item *

L<WWW::StatusBadge::Render::Plugin::Pod>

=item *

L<WWW::StatusBadge::Render::Plugin::RDoc>

=item *

L<WWW::StatusBadge::Render::Plugin::RST>

=item *

L<WWW::StatusBadge::Render::Plugin::Textile>

=back

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
