#!/usr/bin/perl
package WWW::StatusBadge::Render::Plugin::RST;
$WWW::StatusBadge::Render::Plugin::RST::VERSION = '0.0.2';
use strict;
use warnings;

sub render {
    my $self = shift;

    return sprintf('.. image:: %s :target: %s', $self->img, $self->url, );
}

1;
# ABSTRACT: ReStructuredText Status Badge renderer
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::StatusBadge::Render::Plugin::RST - ReStructuredText Status Badge renderer

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge::Service;

    my $service = WWW::StatusBadge::Service->new(
        'txt' => 'Build Status',
        'url' => 'https://travis-ci.org/ARivottiC/WWW-StatusBadge.pm',
        'img' => 'https://travis-ci.org/ARivottiC/WWW-StatusBadge.pm.svg',
    );

    my $badge = $service->rst;

=for Pod::Coverage render

=head1 SEE ALSO

=over 4

=item *

L<WWW::StatusBadge>

=item *

L<WWW::StatusBadge::Service>

=back

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
