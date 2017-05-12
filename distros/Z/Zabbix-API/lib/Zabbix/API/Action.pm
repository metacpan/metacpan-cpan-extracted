package Zabbix::API::Action;

use strict;
use warnings;
use 5.010;
use Carp;

use parent qw/Exporter Zabbix::API::CRUDE/;

use constant {
    ACTION_EVENTSOURCE_TRIGGERS => 0,
    ACTION_EVENTSOURCE_DISCOVERY => 1,
    ACTION_EVENTSOURCE_AUTOREGISTRATION => 2,

    ACTION_CONDITION_TYPE_HOST_GROUP => 0,
    ACTION_CONDITION_TYPE_HOST => 1,
    ACTION_CONDITION_TYPE_TRIGGER => 2,
    ACTION_CONDITION_TYPE_TRIGGER_NAME => 3,
    ACTION_CONDITION_TYPE_TRIGGER_SEVERITY => 4,
    ACTION_CONDITION_TYPE_TRIGGER_VALUE => 5,
    ACTION_CONDITION_TYPE_TIME_PERIOD => 6,
    ACTION_CONDITION_TYPE_DHOST_IP => 7,
    ACTION_CONDITION_TYPE_DSERVICE_TYPE => 8,
    ACTION_CONDITION_TYPE_DSERVICE_PORT => 9,
    ACTION_CONDITION_TYPE_DSTATUS => 10,
    ACTION_CONDITION_TYPE_DUPTIME => 11,
    ACTION_CONDITION_TYPE_DVALUE => 12,
    ACTION_CONDITION_TYPE_HOST_TEMPLATE => 13,
    ACTION_CONDITION_TYPE_EVENT_ACKNOWLEDGED => 14,
    ACTION_CONDITION_TYPE_APPLICATION => 15,
    ACTION_CONDITION_TYPE_MAINTENANCE => 16,
    ACTION_CONDITION_TYPE_NODE => 17,
    ACTION_CONDITION_TYPE_DRULE => 18,
    ACTION_CONDITION_TYPE_DCHECK => 19,
    ACTION_CONDITION_TYPE_PROXY => 20,
    ACTION_CONDITION_TYPE_DOBJECT => 21,
    ACTION_CONDITION_TYPE_HOST_NAME => 22,

    ACTION_CONDITION_OPERATOR_EQUAL => 0,
    ACTION_CONDITION_OPERATOR_NOT_EQUAL => 1,
    ACTION_CONDITION_OPERATOR_LIKE => 2,
    ACTION_CONDITION_OPERATOR_NOT_LIKE => 3,
    ACTION_CONDITION_OPERATOR_IN => 4,
    ACTION_CONDITION_OPERATOR_MORE_EQUAL => 5,
    ACTION_CONDITION_OPERATOR_LESS_EQUAL => 6,
    ACTION_CONDITION_OPERATOR_NOT_IN => 7,

    ACTION_OPERATION_TYPE_MESSAGE => 0,
    ACTION_OPERATION_TYPE_COMMAND => 1,
    ACTION_OPERATION_TYPE_HOST_ADD => 2,
    ACTION_OPERATION_TYPE_HOST_REMOVE => 3,
    ACTION_OPERATION_TYPE_GROUP_ADD => 4,
    ACTION_OPERATION_TYPE_GROUP_REMOVE => 5,
    ACTION_OPERATION_TYPE_TEMPLATE_ADD => 6,
    ACTION_OPERATION_TYPE_TEMPLATE_REMOVE => 7,
    ACTION_OPERATION_TYPE_HOST_ENABLE => 8,
    ACTION_OPERATION_TYPE_HOST_DISABLE => 9,

    ACTION_EVAL_TYPE_AND_OR => 0,
    ACTION_EVAL_TYPE_AND => 1,
    ACTION_EVAL_TYPE_OR => 2,
};

our @EXPORT_OK = qw/
ACTION_EVENTSOURCE_TRIGGERS
ACTION_EVENTSOURCE_DISCOVERY
ACTION_EVENTSOURCE_AUTOREGISTRATION
ACTION_CONDITION_TYPE_HOST_GROUP
ACTION_CONDITION_TYPE_HOST
ACTION_CONDITION_TYPE_TRIGGER
ACTION_CONDITION_TYPE_TRIGGER_NAME
ACTION_CONDITION_TYPE_TRIGGER_SEVERITY
ACTION_CONDITION_TYPE_TRIGGER_VALUE
ACTION_CONDITION_TYPE_TIME_PERIOD
ACTION_CONDITION_TYPE_DHOST_IP
ACTION_CONDITION_TYPE_DSERVICE_TYPE
ACTION_CONDITION_TYPE_DSERVICE_PORT
ACTION_CONDITION_TYPE_DSTATUS
ACTION_CONDITION_TYPE_DUPTIME
ACTION_CONDITION_TYPE_DVALUE
ACTION_CONDITION_TYPE_HOST_TEMPLATE
ACTION_CONDITION_TYPE_EVENT_ACKNOWLEDGED
ACTION_CONDITION_TYPE_APPLICATION
ACTION_CONDITION_TYPE_MAINTENANCE
ACTION_CONDITION_TYPE_NODE
ACTION_CONDITION_TYPE_DRULE
ACTION_CONDITION_TYPE_DCHECK
ACTION_CONDITION_TYPE_PROXY
ACTION_CONDITION_TYPE_DOBJECT
ACTION_CONDITION_TYPE_HOST_NAME
ACTION_CONDITION_OPERATOR_EQUAL
ACTION_CONDITION_OPERATOR_NOT_EQUAL
ACTION_CONDITION_OPERATOR_LIKE
ACTION_CONDITION_OPERATOR_NOT_LIKE
ACTION_CONDITION_OPERATOR_IN
ACTION_CONDITION_OPERATOR_MORE_EQUAL
ACTION_CONDITION_OPERATOR_LESS_EQUAL
ACTION_CONDITION_OPERATOR_NOT_IN
ACTION_OPERATION_TYPE_MESSAGE
ACTION_OPERATION_TYPE_COMMAND
ACTION_OPERATION_TYPE_HOST_ADD
ACTION_OPERATION_TYPE_HOST_REMOVE
ACTION_OPERATION_TYPE_GROUP_ADD
ACTION_OPERATION_TYPE_GROUP_REMOVE
ACTION_OPERATION_TYPE_TEMPLATE_ADD
ACTION_OPERATION_TYPE_TEMPLATE_REMOVE
ACTION_OPERATION_TYPE_HOST_ENABLE
ACTION_OPERATION_TYPE_HOST_DISABLE
ACTION_EVAL_TYPE_AND_OR
ACTION_EVAL_TYPE_AND
ACTION_EVAL_TYPE_OR/;

our %EXPORT_TAGS = (
    eventsources => [
        qw/ACTION_EVENTSOURCE_TRIGGERS
        ACTION_EVENTSOURCE_DISCOVERY
        ACTION_EVENTSOURCE_AUTOREGISTRATION/
    ],
    condition_types => [
        qw/ACTION_CONDITION_TYPE_HOST_GROUP
        ACTION_CONDITION_TYPE_HOST
        ACTION_CONDITION_TYPE_TRIGGER
        ACTION_CONDITION_TYPE_TRIGGER_NAME
        ACTION_CONDITION_TYPE_TRIGGER_SEVERITY
        ACTION_CONDITION_TYPE_TRIGGER_VALUE
        ACTION_CONDITION_TYPE_TIME_PERIOD
        ACTION_CONDITION_TYPE_DHOST_IP
        ACTION_CONDITION_TYPE_DSERVICE_TYPE
        ACTION_CONDITION_TYPE_DSERVICE_PORT
        ACTION_CONDITION_TYPE_DSTATUS
        ACTION_CONDITION_TYPE_DUPTIME
        ACTION_CONDITION_TYPE_DVALUE
        ACTION_CONDITION_TYPE_HOST_TEMPLATE
        ACTION_CONDITION_TYPE_EVENT_ACKNOWLEDGED
        ACTION_CONDITION_TYPE_APPLICATION
        ACTION_CONDITION_TYPE_MAINTENANCE
        ACTION_CONDITION_TYPE_NODE
        ACTION_CONDITION_TYPE_DRULE
        ACTION_CONDITION_TYPE_DCHECK
        ACTION_CONDITION_TYPE_PROXY
        ACTION_CONDITION_TYPE_DOBJECT
        ACTION_CONDITION_TYPE_HOST_NAME/
    ],
    condition_operators => [
        qw/ACTION_CONDITION_OPERATOR_EQUAL
        ACTION_CONDITION_OPERATOR_NOT_EQUAL
        ACTION_CONDITION_OPERATOR_LIKE
        ACTION_CONDITION_OPERATOR_NOT_LIKE
        ACTION_CONDITION_OPERATOR_IN
        ACTION_CONDITION_OPERATOR_MORE_EQUAL
        ACTION_CONDITION_OPERATOR_LESS_EQUAL
        ACTION_CONDITION_OPERATOR_NOT_IN/
    ],
    operation_types => [
        qw/ACTION_OPERATION_TYPE_MESSAGE
        ACTION_OPERATION_TYPE_COMMAND
        ACTION_OPERATION_TYPE_HOST_ADD
        ACTION_OPERATION_TYPE_HOST_REMOVE
        ACTION_OPERATION_TYPE_GROUP_ADD
        ACTION_OPERATION_TYPE_GROUP_REMOVE
        ACTION_OPERATION_TYPE_TEMPLATE_ADD
        ACTION_OPERATION_TYPE_TEMPLATE_REMOVE
        ACTION_OPERATION_TYPE_HOST_ENABLE
        ACTION_OPERATION_TYPE_HOST_DISABLE/
    ],
    eval_types => [
        qw/ACTION_EVAL_TYPE_AND_OR
        ACTION_EVAL_TYPE_AND
        ACTION_EVAL_TYPE_OR/
    ],
);

sub id {

    ## mutator for id

    my ($self, $value) = @_;

    if (defined $value) {

        $self->data->{actionid} = $value;
        return $self->data->{actionid};

    } else {

        return $self->data->{actionid};

    }

}

sub prefix {

    my (undef, $suffix) = @_;

    if ($suffix) {

        return 'action'.$suffix;

    } else {

        return 'action';

    }

}

sub extension {

    return ( output => 'extend',
             select_conditions => 'extend',
             select_operations => 'extend' );

}

sub collides {

    my $self = shift;

    return @{$self->{root}->query(method => $self->prefix('.get'),
                                  params => { filter => { name => [ $self->data->{name} ] },
                                              $self->extension })};

}

sub name {

    my $self = shift;

    return $self->data->{name};

}

1;
__END__
=pod

=head1 NAME

Zabbix::API::Action -- Zabbix action objects

=head1 SYNOPSIS

  use Zabbix::API::Action qw/ACTION_EVENTSOURCE_TRIGGERS
      ACTION_EVAL_TYPE_AND
      ACTION_CONDITION_TYPE_TRIGGER_NAME
      ACTION_CONDITION_OPERATOR_LIKE
      ACTION_OPERATION_TYPE_MESSAGE/;

  # Create a new action: every time the trigger 'Another Trigger' toggles (from OK
  # to PROBLEM or from PROBLEM to OK), send a message to the user with a short
  # subject line and a slightly less short body

  my $new_action = Zabbix::API::Action->new(root => $zabber,
                                            data => {
                                                name => 'Another Action',
                                                eventsource => ACTION_EVENTSOURCE_TRIGGERS,
                                                evaltype => ACTION_EVAL_TYPE_AND,
                                                conditions => [ {
                                                    conditiontype => ACTION_CONDITION_TYPE_TRIGGER_NAME,
                                                    operator => ACTION_CONDITION_OPERATOR_LIKE,
                                                    value => 'Another Trigger' } ],
                                                operations => [ {
                                                    operationtype => ACTION_OPERATION_TYPE_MESSAGE,
                                                    shortdata => '{TRIGGER.NAME}: {STATUS}',
                                                    longdata => 'Hey, look: {TRIGGER.NAME} is now {STATUS}' } ]
                                            });

  $new_action->push;

=head1 DESCRIPTION

Handles CRUD for Zabbix action objects.

This is a subclass of C<Zabbix::API::CRUDE>; see there for inherited methods.

=head1 METHODS

=over 4

=item collides()

Returns true if an action exists with this name, false otherwise.

=back

=head1 EXPORTS

Many many constants that don't seem to be documented anywhere; see source for a
complete list.

Nothing is exported by default; you can use the tags C<:eventsources>,
C<:condition_types>, C<:condition_operators>, C<operation_types> and
C<eval_types> (or import by name).

=head1 BUGS AND ODDITIES

The code in the SYNOPSIS works for creating actions, B<but not fetching them>.
I don't know if this is because of the specific data I'm sending; I can't see
any obvious reason to be able to fetch B<some> actions but not all, except
possibly if the API user has no permissions on the triggers or other objects
involved in the conditions.  (Further experimentation reveals that even if I can
pull the trigger set as a condition, I can't pull the action.)

Obviously this is problematic; in C<CRUDE> we assume that if we can create an
object we can also fetch it.  This means we can't fetch back the action's ID,
which in turns borks up the rest of the API.

As a very ugly workaround, you can set your API user as Super Admin (just Admin
doesn't seem to work); apparently this issue then goes away.  Without the
workaround, this class B<will> die with a meaningless exception in certain
cases.  Further input on what these cases are and why this happens is welcome.

Confirmed in 1.8.10.

=head1 SEE ALSO

L<Zabbix::API::CRUDE>.

L<http://www.zabbix.com/documentation/1.8/complete#actions>

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Devoteam

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
