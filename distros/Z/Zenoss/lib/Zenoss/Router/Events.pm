package Zenoss::Router::Events;
use strict;

use Moose::Role;
requires '_router_request', '_check_args';

#**************************************************************************
# Attributes
#**************************************************************************
has 'EVENTS_LOCATION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'zport/dmd/evconsole_router',
    init_arg    => undef,
);

has 'EVENTS_ACTION' => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'EventsRouter',
    init_arg    => undef,
);

#**************************************************************************
# Public Functions
#**************************************************************************
#======================================================================
# events_query
#======================================================================
sub events_query {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            limit       => 0,
            start       => 0,
            sort        => 'lastTime',
            dir         => 'DESC',
            history     => JSON::false,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'query',
            data        => [$args],
        }
    );
} # END events_query

#======================================================================
# events_queryHistory
#======================================================================
sub events_queryHistory {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            limit       => 0,
            start       => 0,
            sort        => 'lastTime',
            dir         => 'DESC',
            params      => JSON::null,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'queryHistory',
            data        => [$args],
        }
    );
} # END events_queryHistory

#======================================================================
# events_acknowledge
#======================================================================
sub events_acknowledge {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            direction   => 'DESC',
            history     => JSON::false,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'acknowledge',
            data        => [$args],
        }
    );
} # END events_acknowledge

#======================================================================
# events_unacknowledge
#======================================================================
sub events_unacknowledge {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            direction   => 'DESC',
            history     => JSON::false,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'unacknowledge',
            data        => [$args],
        }
    );
} # END events_unacknowledge

#======================================================================
# events_reopen
#======================================================================
sub events_reopen {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            direction   => 'DESC',
            history     => JSON::false,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'reopen',
            data        => [$args],
        }
    );
} # END events_reopen

#======================================================================
# events_close
#======================================================================
sub events_close {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            direction   => 'DESC',
            history     => JSON::false,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'close',
            data        => [$args],
        }
    );
} # END events_close

#======================================================================
# events_detail
#======================================================================
sub events_detail {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            history => JSON::false,
        },
        required    => ['evid']
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'detail',
            data        => [$args],
        }
    );
} # END events_detail

#======================================================================
# events_write_log
#======================================================================
sub events_write_log {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            history => JSON::false,
        },
        required    => ['evid', 'message'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'write_log',
            data        => [$args],
        }
    );
} # END events_write_log

#======================================================================
# events_classify
#======================================================================
sub events_classify {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            history => JSON::false,
        },
        required    => ['evids', 'evclass'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'classify',
            data        => [$args],
        }
    );
} # END events_classify

#======================================================================
# events_add_event
#======================================================================
sub events_add_event {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        required    => ['summary', 'device', 'component', 'severity', 'evclasskey', 'evclass'],
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'add_event',
            data        => [$args],
        }
    );
} # END events_add_event

#======================================================================
# events_column_config
#======================================================================
sub events_column_config {
    my ($self, $args) = @_;
    $args = {} if !$args;

    # Argument definition
    my $definition = {
        defaults    => {
            history => JSON::false,
        },
    };

    # Check the args
    $self->_check_args($args, $definition);

    # Route the request
    $self->_router_request(
        {
            location    => $self->EVENTS_LOCATION,
            action      => $self->EVENTS_ACTION,
            method      => 'column_config',
            data        => [$args],
        }
    );
} # END events_column_config 

#**************************************************************************
# Package end
#**************************************************************************
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router::Events - A JSON/ExtDirect interface to operations on events

=head1 SYNOPSIS

    use Zenoss;
    my $api = Zenoss->connect(
        {
            username    => 'zenoss username',
            password    => 'zenoss password',
            url         => 'http://zenossinstance:8080',
        }
    );

    # Replace SOMEMETHOD with one of the available methods provided by this module
    my $response = $api->events_SOMEMETHOD(
        {
            parameter1 => 'value',
            parameter2 => 'value',
        }
    );

=head1 DESCRIPTION

This module is NOT instantiated directly.  To call methods from this module create an
instance of L<Zenoss>.  This document serves as a resource of available Zenoss API
calls to L<Zenoss>.

=head1 METHODS

The following is a list of available methods available for interaction with the Zenoss API.
Please take note of the argument requirements, defaults and return content.

The documentation for this module was mostly taken from the Zenoss JSON API docs.  Keep in mind
that their (Zenoss Monitoring System) programming is based around python, so descriptions such as 
dictionaries will be represented as hashes in Perl.

=head2 $obj->events_query()

Query for events.

=over

=item ARGUMENTS

limit (integer) - Max index of events to retrieve

start (integer) - Min index of events to retrieve

sort (string) - Key on which to sort the return results

dir (string) - Sort order; can be either 'ASC' or 'DESC'

params (dictionary) - Key-value pair of filters for this search.

history (boolean) - True to search the event history table instead of active events

uid (string) - Context for the query

criteria ([dictionary]) - A list of key-value pairs to to build query's where clause

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{limit => 0, start => 0, sort => 'lastTime', dir => 'DESC', history => JSON::false}

=back

=over

=item RETURNS

events: ([dictionary]) List of objects representing events

totalCount: (integer) Total count of events returned

asof: (float) Current time

=back

=head2 $obj->events_queryHistory()

Query history table for events.

=over

=item ARGUMENTS

limit (integer) - Max index of events to retrieve

start (integer) - Min index of events to retrieve

sort (string) - Key on which to sort the return results

dir (string) - Sort order; can be either 'ASC' or 'DESC'

params (dictionary) - Key-value pair of filters for this search

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{limit => 0, start => 0, sort => 'lastTime', dir => 'DESC', params => JSON::null}

=back

=over

=item RETURNS

events: ([dictionary]) List of objects representing events

totalCount: (integer) Total count of events returned

asof: (float) Current time

=back

=head2 $obj->events_acknowledge()

Acknowledge event(s).

=over

=item ARGUMENTS

evids ([string]) - List of event IDs to acknowledge

excludeIds ([string]) - List of event IDs to exclude from acknowledgment

selectState (string) - Select event ids based on select state. Available values are: All, New, Acknowledged, and Suppressed

field (string) - Field key to filter gathered events

direction (string) - Sort order; can be either 'ASC' or 'DESC'

params (dictionary) - Key-value pair of filters for this search

history (boolean) - True to use the event history table instead of active events

uid (string) - Context for the query

asof (float) - Only acknowledge if there has been no state change since this time

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{direction => 'DESC', history => JSON::false}

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->events_unacknowledge()

Unacknowledge event(s).

=over

=item ARGUMENTS

evids ([string]) - List of event IDs to unacknowledge 

excludeIds ([string]) - List of event IDs to exclude from unacknowledgment 

selectState (string) - Select event ids based on select state. Available values are: All, New, Acknowledged, and Suppressed 

field (string) - Field key to filter gathered events 

direction (string) - Sort order; can be either 'ASC' or 'DESC' 

params (dictionary) - Key-value pair of filters for this search. 

history (boolean) - True to use the event history table instead of active events 

uid (string) - Context for the query 

asof (float) - Only unacknowledge if there has been no state change since this time 

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{direction => 'DESC', history => JSON::false}

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->events_reopen()

Reopen event(s).

=over

=item ARGUMENTS

evids ([string]) - List of event IDs to reopen 

excludeIds ([string]) - List of event IDs to exclude from reopen 

selectState (string) - Select event ids based on select state. Available values are: All, New, Acknowledged, and Suppressed 

field (string) - Field key to filter gathered events 

direction (string) - Sort order; can be either 'ASC' or 'DESC' 

params (dictionary) - Key-value pair of filters for this search. 

history (boolean) - True to use the event history table instead of active events 

uid (string) - Context for the query 

asof (float) - Only reopen if there has been no state change since this time 

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{direction => 'DESC', history => JSON::false}

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->events_close()

Close event(s).

=over

=item ARGUMENTS

evids ([string]) - List of event IDs to close 

excludeIds ([string]) - List of event IDs to exclude from close 

selectState (string) - Select event ids based on select state. Available values are: All, New, Acknowledged, and Suppressed 

field (string) - Field key to filter gathered events 

direction (string) - Sort order; can be either 'ASC' or 'DESC' 

params (dictionary) - Key-value pair of filters for this search. 

history (boolean) - True to use the event history table instead of active events 

uid (string) - Context for the query 

asof (float) - Only close if there has been no state change since this time 

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{direction => 'DESC', history => JSON::false}

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->events_detail()

Get event details.

=over

=item ARGUMENTS

evid (string) - Event ID to get details

history (boolean) - True to search the event history table instead of active events

=back

=over

=item REQUIRED ARGUMENTS

evid

=back

=over

=item DEFAULT ARGUMENTS

{history => JSON::false}

=back

=over

=item RETURNS

event: ([dictionary]) List containing a dictionary representing event details

=back

=head2 $obj->events_write_log()

Write a message to an event's log.

=over

=item ARGUMENTS

evid (string) - Event ID to log to

message (string) - Message to log

history (boolean) - True to use the event history table instead of active events

=back

=over

=item REQUIRED ARGUMENTS

evid

message

=back

=over

=item DEFAULT ARGUMENTS

{history => JSON::false}

=back

=over

=item RETURNS

Success message

=back

=head2 $obj->events_classify()

Associate event(s) with an event class.

=over

=item ARGUMENTS

evids ([string]) - List of event ID's to classify

evclass (string) - Event class to associate events to

history (boolean) - True to use the event history table instead of active events

=back

=over

=item REQUIRED ARGUMENTS

evids

evclass

message

=back

=over

=item DEFAULT ARGUMENTS

{history => JSON::false}

=back

=over

=item RETURNS

msg: (string) Success/failure message

success: (boolean) True if class update successful

=back

=head2 $obj->events_add_event()

Create a new event.

=over

=item ARGUMENTS

summary (string) - New event's summary

device (string) - Device uid to use for new event

component (string) - Component uid to use for new event

severity (string) - Severity of new event. Can be one of the following: Critical, Error, Warning, Info, Debug, or Clear

evclasskey (string) - The Event Class Key to assign to this event

evclass (string) - Event class for the new event

=back

=over

=item REQUIRED ARGUMENTS

summary

device

component

severity

evclasskey

evclass

=back

=over

=item DEFAULT ARGUMENTS

N/A

=back

=over

=item RETURNS

evid: (string) The id of the created event

=back

=head2 $obj->events_column_config()

Get the current event console field column configuration.

=over

=item ARGUMENTS

uid (string) - UID context to use

history (boolean) - True to use the event history table instead of active events

=back

=over

=item REQUIRED ARGUMENTS

N/A

=back

=over

=item DEFAULT ARGUMENTS

{history => JSON::false}

=back

=over

=item RETURNS

A list of objects representing field columns

=back

=head1 SEE ALSO

=over

=item *

L<Zenoss>

=item *

L<Zenoss::Response>

=back

=head1 AUTHOR

Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

This module is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You can obtain the Artistic License 2.0 by either viewing the
LICENSE file provided with this distribution or by navigating
to L<http://opensource.org/licenses/artistic-license-2.0.php>.

=cut