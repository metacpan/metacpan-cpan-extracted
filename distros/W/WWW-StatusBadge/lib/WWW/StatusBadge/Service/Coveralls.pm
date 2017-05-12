#!/usr/bin/perl
package WWW::StatusBadge::Service::Coveralls;
$WWW::StatusBadge::Service::Coveralls::VERSION = '0.0.2';
use strict;
use warnings;

use parent 'WWW::StatusBadge::Service';

sub new {
    my $class = shift;
    my %arg   = (
        'private' => 0,
        @_
    );

    for my $key ( qw(user repo branch) ) {
        Carp::croak( sprintf 'missing required parameter %s!', $key )
            unless $arg{ $key };
    }

    my @values = @arg{ qw(user repo branch) };

    my $url =
        sprintf 'https://coveralls.io/r/%s/%s?branch=%s', @values;

    my $format = $arg{'private'}
               ? 'https://coveralls.io/repos/%s/%s/badge.png?branch=%s'
               : 'https://img.shields.io/coveralls/%s/%s.svg';

    return $class->SUPER::new(
        'txt' => 'Coverage Status',
        'url' => $url,
        'img' => sprintf( $format, @values ),
    );
}

1;
# ABSTRACT: Coveralls Status Badge generator
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::StatusBadge::Service::Coveralls - Coveralls Status Badge generator

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge::Service::Coveralls;

    my $service = WWW::StatusBadge::Service::Coveralls->new(
        'repo'   => 'Sidekick-Accessor.pm',
        'user'   => 'ARivottiC',
        'branch' => 'master',
    );

    my $markdown = $service->markdown;

=head1 DESCRIPTION

Generates Coveralls Status Badges in several formats.

=head1 METHODS

=head2 new

    my $service = WWW::StatusBadge::Service::Coveralls->new(
        'repo'   => 'Sidekick-Accessor.pm',
        'user'   => 'ARivottiC',
        'branch' => 'master',
    );

=over 4

=item I<repo =E<gt> $repo_name>

The repository name. Required.

=item I<user =E<gt> $user_name>

The user name. Required.

=item I<branch =E<gt> $branch_name>

The branch name. Required.

=item I<private =E<gt> 0|1>

Declare the repository as private. Optional, default is 0.

=back

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
