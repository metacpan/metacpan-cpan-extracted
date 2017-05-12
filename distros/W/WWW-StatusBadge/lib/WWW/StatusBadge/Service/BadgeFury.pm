#!/usr/bin/perl
package WWW::StatusBadge::Service::BadgeFury;
$WWW::StatusBadge::Service::BadgeFury::VERSION = '0.0.2';
use strict;
use warnings;

use parent 'WWW::StatusBadge::Service';

# for internal functions
my ($croak_missing, $require, $user_and_repo_to_dist);

my %for_to_text = (
    'bo' => 'Bower version',
    'co' => 'Pod version',
    'gh' => 'GitHub version',
    'js' => 'npn version',
    'nu' => 'NuGet version',
    'pl' => 'CPAN version',
    'py' => 'PyPI version',
    'rb' => 'Gem version',
);

sub new {
    my $class = shift;
    my %arg   = @_;

    $user_and_repo_to_dist->( \%arg );

    for my $key ( qw(for dist) ) {
        $key->$croak_missing
            unless $arg{ $key };
    }

    my ($for, $dist) = @arg{ qw(for dist) };
    my $txt = $for_to_text{ $for };

    Carp::croak( sprintf 'not suported: %s', $for )
        unless $txt;

    my $url = sprintf 'http://badge.fury.io/%s/%s', $for, $dist;
    my $img = sprintf 'https://badge.fury.io/%s/%s.svg', $for, $dist;

    return $class->SUPER::new(
        'txt' => $txt,
        'url' => $url,
        'img' => $img,
    );
}

# Internal Functions
$croak_missing = sub {
    Carp::croak( sprintf 'missing required parameter %s!', shift );
};

$require = sub { $_[0]{ $_[1] } || $croak_missing->( $_[1] ); };

$user_and_repo_to_dist = sub {
    my %arg = %{ $_[0] };
    my ($user, $repo) = $arg{ qw(user repo) };

    if ( $user || $repo ) {
        $require->( \%arg, 'user' );
        $require->( \%arg, 'repo' );

        $_[0]{'dist'} = join '/', $user, $repo;
    }
};

1;
# ABSTRACT: Badge Fury Status Badge generator
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::StatusBadge::Service::BadgeFury - Badge Fury Status Badge generator

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge::Service::BadgeFury;

    my $service = WWW::StatusBadge::Service::BadgeFury->new(
        'dist' => 'Sidekick-Accessor',
        'for'  => 'pl',
    );

    my $markdown = $service->markdown;

=head1 DESCRIPTION

Generates Badge Fury Status Badges in several formats.

=head1 METHODS

=head2 new

    my $service = WWW::StatusBadge::Service::BadgeFury->new(
        'dist' => 'Sidekick-Accessor',
        'for'  => 'pl',
    );

=over 4

=item I<dist =E<gt> $dist_name>

The distribution name. Required.

=item I<for =E<gt> $language_extension>

Allowed extensions:

=over 4

=item *

I<bo =E<gt> Bower>

=item *

I<co =E<gt> Pod>

=item *

I<gh =E<gt> GitHub>

=item *

I<js =E<gt> npn>

=item *

I<nu =E<gt> NuGet>

=item *

I<pl =E<gt> CPAN>

=item *

I<py =E<gt> PyPI>

=item *

I<rb =E<gt> Gem>

=back

Required.

=item I<repo =E<gt> $repo_name>
=item I<user =E<gt> $user_name>

If both are set, I<dist> will be override with "$user_name/$repo_name".
Optional unless one of them is defined.

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
