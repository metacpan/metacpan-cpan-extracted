#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty::Incidents;
{
  $WebService::PagerDuty::Incidents::VERSION = '1.20131219.1627';
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

sub count {
    my ( $self, %params ) = @_;

    return WebService::PagerDuty::Request->new->get_data(
        url      => URI->new( $self->url . '/count' ),
        user     => $self->user,
        password => $self->password,
        api_key  => $self->api_key,
        params   => \%params,
    );
}

sub query {
    my ( $self, %params ) = @_;

    return WebService::PagerDuty::Request->new->get_data(
        url      => $self->url,
        user     => $self->user,
        password => $self->password,
        api_key  => $self->api_key,
        params   => \%params,
    );
}
*list = \&query;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty::Incidents

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

    my $pager_duty = WebService::PagerDuty->new;

    my $incidents = $pager_duty->incidents( ... );
    $incidents->count();
    $incidents->query();
    $incidents->list(); # same as above, synonym

=head1 DESCRIPTION

This class represents a basic incidents object, to get access
to count and list of existing incidents.

=head1 NAME

WebService::PagerDuty::Incidents - A incidents object

=head1 SEE ALSO

L<WebService::PagerDuty>, L<http://PagerDuty.com>, L<oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 LICENSE

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=for Pod::Coverage     count
    list
    query

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
