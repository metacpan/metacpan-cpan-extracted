#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty;
{
  $WebService::PagerDuty::VERSION = '1.20131219.1627';
}
## use critic
use strict;
use warnings;

use base qw/ WebService::PagerDuty::Base /;
use URI;
use WebService::PagerDuty::Event;
use WebService::PagerDuty::Incidents;
use WebService::PagerDuty::Schedules;

__PACKAGE__->mk_ro_accessors(
    qw/
      user
      password
      api_key
      subdomain
      use_ssl
      event_url
      incidents_url
      schedules_url
      /
);

sub new {
    my $self = shift;
    $self->SUPER::new(
        _defaults => {
            use_ssl   => sub { 1 },
            event_url => sub {
                my $self = shift;
                URI->new( ( $self->use_ssl ? 'https' : 'http' ) . '://events.pagerduty.com/generic/2010-04-15/create_event.json' );
            },
            incidents_url => sub {
                my $self = shift;
                URI->new( 'https://' . $self->subdomain . '.pagerduty.com/api/v1/incidents' );
            },
            schedules_url => sub {
                my $self = shift;
                URI->new( 'https://' . $self->subdomain . '.pagerduty.com/api/v1/schedules' );
            },
        },
        @_
    );
}

sub event {
    my $self = shift;
    return WebService::PagerDuty::Event->new(
        url => $self->event_url,
        @_
    );
}

sub incidents {
    my $self = shift;
    return WebService::PagerDuty::Incidents->new(
        url      => $self->incidents_url,
        user     => $self->user,
        password => $self->password,
        api_key  => $self->api_key,
        @_
    );
}

sub schedules {
    my $self = shift;
    return WebService::PagerDuty::Schedules->new(
        url      => $self->schedules_url,
        user     => $self->user,
        password => $self->password,
        api_key  => $self->api_key,
        @_
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

    # for Events API, all parameters are optional
    my $pager_duty = WebService::PagerDuty->new();


    # for Incidents API and Schedules API, these are mandatory
    my $pager_duty2 = WebService::PagerDuty->new(
        user        => 'test_user',
        password    => 'test_password',
        subdomain   => 'test-sub-domain',
        # always optional, true by default
        use_ssl     => 1,
    );

    # if you want to get access to all three APIs via
    # same $pager_duty variable, then use second form


    #
    # Events API
    #
    my $event = $pager_duty->event(
         service_key  => ... , # required
         incident_key => ... , # optional
         %extra_params,
    );
    $event->trigger( %extra_params );
    $event->acknowledge( %extra_params );
    $event->resolve( %extra_params );

    #
    # Incidents API
    #
    my $incidents = $pager_duty->incidents();
    $incidents->count( %extra_params );
    $incidents->list( %extra_params );

    #
    # Schedules API
    #
    my $schedules = $pager_duty->schedules();
    $schedules->list(
        schedule_id => ... ,            # required
        since       => 'ISO8601date',   # required
        until       => 'ISO8601date',   # required
        %extra_params,
    );

=head1 DESCRIPTION

WebService::PagerDuty - is a client library for http://PagerDuty.com

For detailed description of B<%extra_params> (including which of them are
required or optional), see PagerDuty site:

=over 4

=item L<Events API|http://www.pagerduty.com/docs/integration-api/integration-api-documentation>

=item L<Incidents API|http://www.pagerduty.com/docs/rest-api/incidents>

=item L<Schedules API|http://www.pagerduty.com/docs/rest-api/schedules>

=back

Also, you could explore tests in t/ directory of distribution archive.

=head1 NAME

WebService::PagerDuty - Module to interface with the http://PagerDuty.com service

=head1 SEE ALSO

L<http://PagerDuty.com>, L<http://oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 CONTRIBUTORS

Ryan Olson (Gimpson), C<< <gimpson@cpan.org> >> - support for B<api_key>

=head1 LICENSE

Same as Perl.

=head1 COPYRIGHT

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=head1 NO WARRANTY

This software is provided "as-is," without any express or implied warranty.
In no event shall the author or sponsor be held liable for any damages
arising from the use of the software.

=for Pod::Coverage     event
    incidents
    schedules

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
