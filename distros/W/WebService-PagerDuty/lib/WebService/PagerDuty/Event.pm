#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty::Event;
{
  $WebService::PagerDuty::Event::VERSION = '1.20131219.1627';
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
      service_key
      incident_key
      description
      /
);

my @__method_definitions = (
    ## method_name => required_arg  ],
    [ trigger     => 'description' ],
    [ acknowledge => 'incident_key' ],
    [ resolve     => 'incident_key' ],
);

__construct_method(@$_) for @__method_definitions;
*ack = \&acknowledge;

sub __construct_method {
    my ( $method_name, $required_arg ) = @_;

    no strict 'refs';    ## no critic

    my $method = 'sub {
        my ( $self, %details ) = @_;

        my $incident_key = delete $details{incident_key} || $self->incident_key || undef;
        my $description  = delete $details{description}  || $self->description  || undef;

        die("WebService::PagerDuty::Event::' . $method_name . '(): ' . $required_arg . ' is required")
            unless defined \$' . $required_arg . ';

        return WebService::PagerDuty::Request->new->post_data(
            url         => $self->url,
            event_type  => "' . $method_name . '",
            service_key => $self->service_key,
            ( $description  ? ( description  => $description )  : () ),
            ( $incident_key ? ( incident_key => $incident_key ) : () ),
            ( %details      ? ( details      => \%details )     : () ),
        );
    }';

    *$method_name = eval $method;    ## no critic
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty::Event

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

    my $pager_duty = WebService::PagerDuty->new;

    my $event = $pager_duty->event( ... );
    $event->trigger( ... );
    $event->acknowledge( ... );
    $event->ack( ... ); # same as above, synonym
    $event->resolve( ... );

=head1 DESCRIPTION

This class represents a basic event object, which could be triggered,
acknowledged or resolved.

=head1 NAME

WebService::PagerDuty::Event - A event object

=head1 SEE ALSO

L<WebService::PagerDuty>, L<http://PagerDuty.com>, L<oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 LICENSE

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=for Pod::Coverage     trigger
    acknowledge
    ack
    resolve

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
