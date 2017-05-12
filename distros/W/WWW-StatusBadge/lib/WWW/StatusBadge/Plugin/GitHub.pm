#!/usr/bin/perl
package WWW::StatusBadge::Plugin::GitHub;
$WWW::StatusBadge::Plugin::GitHub::VERSION = '0.0.2';
use strict;
use warnings;

sub service {
    return shift->badgefury( @_, 'for' => 'gh' );
}

1;
# ABSTRACT: StatusBadge plugin for CPAN
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::StatusBadge::Plugin::GitHub - StatusBadge plugin for CPAN

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge;

    my $badge = WWW::StatusBadge->new(
        'dist'   => 'WWW-StatusBadge',
        'branch' => 'develop',
    );

    my $service = $badge->cpan;

=for Pod::Coverage service

=head1 SEE ALSO

=over 4

=item *

L<WWW::StatusBadge>

=item *

L<WWW::StatusBadge::Service::BadgeFury>

=back

=head1 AUTHOR

André Rivotti Casimiro <rivotti@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by André Rivotti Casimiro.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
