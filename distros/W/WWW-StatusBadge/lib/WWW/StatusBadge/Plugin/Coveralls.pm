#!/usr/bin/perl
package WWW::StatusBadge::Plugin::Coveralls;
$WWW::StatusBadge::Plugin::Coveralls::VERSION = '0.0.2';
use strict;
use warnings;

use WWW::StatusBadge::Service::Coveralls;

sub service {
    return WWW::StatusBadge::Service::Coveralls->new( shift->args, @_ );
}

1;
# ABSTRACT: StatusBadge plugin for Coveralls
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::StatusBadge::Plugin::Coveralls - StatusBadge plugin for Coveralls

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge;

    my $badge = WWW::StatusBadge->new(
        'repo'   => 'WWW-StatusBadge.pm',
        'user'   => 'ARivottiC',
        'branch' => 'develop',
    );

    my $service = $badge->coveralls;

=for Pod::Coverage service

=head1 SEE ALSO

=over 4

=item *

L<WWW::StatusBadge>

=item *

L<WWW::StatusBadge::Service::Coveralls>

=back

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
