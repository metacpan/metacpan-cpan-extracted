#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty::Schedules;
{
  $WebService::PagerDuty::Schedules::VERSION = '1.20131219.1627';
}
## use critic
use strict;
use warnings;

use base qw/ WebService::PagerDuty::Base /;
use URI;
use WebService::PagerDuty::Request;

__PACKAGE__->mk_ro_accessors(
    qw/
      url
      user
      password
      api_key
      /
);

sub entries {
    my ( $self, %params ) = @_;

    my $id = delete $params{id} || delete $params{schedule_id} || undef;

    die('WebService::PagerDuty::Schedules::entries(): id or schedule_id is required') unless defined $id;

    return WebService::PagerDuty::Request->new->get_data(
        url      => URI->new( $self->url . '/' . $id . '/entries' ),
        user     => $self->user,
        password => $self->password,
        api_key  => $self->api_key,
        params   => \%params,
    );
}
*list = \&entries;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty::Schedules

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

    my $pager_duty = WebService::PagerDuty->new;

    my $schedules = $pager_duty->schedules( ... );
    $schedules->entries();

=head1 DESCRIPTION

This class represents a basic schedules object, to get entries
of existing schedules.

=head1 NAME

WebService::PagerDuty::Schedules - A schedules object

=head1 SEE ALSO

L<http://PagerDuty.com>, L<oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 LICENSE

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=for Pod::Coverage     entries
    list

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
