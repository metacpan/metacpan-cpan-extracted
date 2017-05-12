#!/usr/bin/perl
package WWW::StatusBadge;
$WWW::StatusBadge::VERSION = '0.0.2';
use strict;
use warnings;

use Carp ();
use Hash::Util::FieldHash ();
use Module::Pluggable::Object ();

Hash::Util::FieldHash::fieldhash my %Arg;

sub new {
    my $class = shift;
    my %arg   = @_;

    my $self = do {
        my $o; bless \( $o ), ref $class || $class || __PACKAGE__
    };

    $Arg{ $self } = { %arg };

    return $self;
}

sub args { return %{ $Arg{ shift() } }; }

my $package = __PACKAGE__;
my $finder = Module::Pluggable::Object->new(
        'package' => $package, 'require' => 1,
    );

{
    no strict 'refs';
    for my $plugin ( $finder->plugins ) {
        my $service = $plugin->can('service')
            || next;
        my $method = join( '_', ( split '::', lc $plugin )[3,] );
        *{ sprintf '%s::%s', $package, $method } = $service;
    }
}

1;
# ABSTRACT: Plugin based Status Badge generator
# vim:ts=4:sw=4:syn=perl

__END__

=pod

=encoding UTF-8

=for markdown
[![Build Status](https://travis-ci.org/ARivottiC/WWW-StatusBadge.pm.svg)](https://travis-ci.org/ARivottiC/WWW-StatusBadge.pm)
[![Coverage Status](https://img.shields.io/coveralls/ARivottiC/WWW-StatusBadge.pm.svg)](https://coveralls.io/r/ARivottiC/WWW-StatusBadge.pm?branch=master)
[![CPAN version](https://badge.fury.io/pl/WWW-StatusBadge.svg)](http://badge.fury.io/pl/WWW-StatusBadge)

=head1 NAME

WWW::StatusBadge - Plugin based Status Badge generator

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use WWW::StatusBadge;

    my $badge = WWW::StatusBadge->new(
        'repo'   => 'WWW-StatusBadge.pm',
        'dist'   => 'WWW-StatusBadge',
        'user'   => 'ARivottiC',
        'branch' => 'develop',
    );

    my $travis_markdown   = $badge->travis->markdown;
    my $coveralls_textile = $badge->coveralls->textile;
    my $cpan_rst          = $badge->badgefury( 'for' => 'perl' )->rst;

=head1 DESCRIPTION

A Status Badge is dynamically generated image that provide different
information relating to a project, such as coverage, test, build, and can be
found in many GitHub repositories.

This module generates the markup necessary to include this badges in any
documentation.

For more information see
L<Project status badges|http://bahmutov.calepin.co/project-status-badges.html>,
L<badges/shields on GitHub|https://github.com/badges/shields> and
L<Travis CI: Status Images|http://docs.travis-ci.com/user/status-images/>.

=head1 ATTRIBUTES

=head2 args

Returns the original args used in the constructor.

=head1 METHODS

=head2 new

    my $badge = WWW::StatusBadge->new(
        'repo'   => 'WWW-StatusBadge.pm',
        'dist'   => 'WWW-StatusBadge',
        'user'   => 'ARivottiC',
        'branch' => 'develop',
    );

None of the following are required and may vary depending on the plugin used.

=over 4

=item I<repo =E<gt> $repo_name>

The repository name.

=item I<dist =E<gt> $dist_name>

The distribution name.

=item I<user =E<gt> $user_name>

The user name.

=item I<branch =E<gt> $branch_name>

The branch name.

=item I<private =E<gt> 0|1>

Declare the repository as private.

=back

See L<WWW::StatusBadge::Service> for more info.

=for Pod::Coverage travis coveralls badgefury cpan github

=head1 PLUGINS

    package WWW::StatusBadge::Plugin::Travis;

    use WWW::StatusBadge::Service::TravisCI;

    sub service {
        return WWW::StatusBadge::Service::TravisCI->new( shift->args, @_ );
    }

    1;

=head1 SEE ALSO

=over 4

=item *

L<WWW::StatusBadge::Plugin::Travis>

=item *

L<WWW::StatusBadge::Plugin::Coveralls>

=item *

L<WWW::StatusBadge::Plugin::BadgeFury>

=item *

L<WWW::StatusBadge::Plugin::CPAN>

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
