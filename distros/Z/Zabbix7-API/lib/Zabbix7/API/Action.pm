package Zabbix7::API::Action;
use strict;
use warnings;
use 5.010;
use Carp;
use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;
use Log::Any; # Added for debugging

use constant {
    ACTION_EVENTSOURCE_TRIGGERS => 0,
    ACTION_EVENTSOURCE_DISCOVERY => 1,
    ACTION_EVENTSOURCE_AUTOREGISTRATION => 2,
    ACTION_EVENTSOURCE_INTERNAL => 3, # Added for Zabbix 7.0

    ACTION_CONDITION_TYPE_HOST_GROUP => 0,
    ACTION_CONDITION_TYPE_HOST => 1,
    ACTION_CONDITION_TYPE_TRIGGER => 2,
    ACTION_CONDITION_TYPE_TRIGGER_NAME => 3,
    ACTION_CONDITION_TYPE_TRIGGER_SEVERITY => 4,
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
    ACTION_CONDITION_TYPE_PROXY => 20,
    ACTION_CONDITION_TYPE_DOBJECT => 21,
    ACTION_CONDITION_TYPE_HOST_NAME => 22,
    ACTION_CONDITION_TYPE_EVENT_TYPE => 23, # Added for Zabbix 7.0
    ACTION_CONDITION_TYPE_TAG => 25, # Added for Zabbix 7.0
    ACTION_CONDITION_TYPE_TAG_VALUE => 26, # Added for Zabbix 7.0

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
    ACTION_OPERATION_TYPE_HOST_INVENTORY => 10, # Added for Zabbix 7.0
    ACTION_OPERATION_TYPE_HOST_LINK_TEMPLATE => 11, # Added for Zabbix 7.0
    ACTION_OPERATION_TYPE_HOST_UNLINK_TEMPLATE => 12, # Added for Zabbix 7.0

    ACTION_EVAL_TYPE_AND_OR => 0,
    ACTION_EVAL_TYPE_AND => 1,
    ACTION_EVAL_TYPE_OR => 2,
};

our @EXPORT_OK = qw/
    ACTION_EVENTSOURCE_TRIGGERS
    ACTION_EVENTSOURCE_DISCOVERY
    ACTION_EVENTSOURCE_AUTOREGISTRATION
    ACTION_EVENTSOURCE_INTERNAL
    ACTION_CONDITION_TYPE_HOST_GROUP
    ACTION_CONDITION_TYPE_HOST
    ACTION_CONDITION_TYPE_TRIGGER
    ACTION_CONDITION_TYPE_TRIGGER_NAME
    ACTION_CONDITION_TYPE_TRIGGER_SEVERITY
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
    ACTION_CONDITION_TYPE_PROXY
    ACTION_CONDITION_TYPE_DOBJECT
    ACTION_CONDITION_TYPE_HOST_NAME
    ACTION_CONDITION_TYPE_EVENT_TYPE
    ACTION_CONDITION_TYPE_TAG
    ACTION_CONDITION_TYPE_TAG_VALUE
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
    ACTION_OPERATION_TYPE_HOST_INVENTORY
    ACTION_OPERATION_TYPE_HOST_LINK_TEMPLATE
    ACTION_OPERATION_TYPE_HOST_UNLINK_TEMPLATE
    ACTION_EVAL_TYPE_AND_OR
    ACTION_EVAL_TYPE_AND
    ACTION_EVAL_TYPE_OR
/;

our %EXPORT_TAGS = (
    eventsources => [
        qw/ACTION_EVENTSOURCE_TRIGGERS
           ACTION_EVENTSOURCE_DISCOVERY
           ACTION_EVENTSOURCE_AUTOREGISTRATION
           ACTION_EVENTSOURCE_INTERNAL/
    ],
    condition_types => [
        qw/ACTION_CONDITION_TYPE_HOST_GROUP
           ACTION_CONDITION_TYPE_HOST
           ACTION_CONDITION_TYPE_TRIGGER
           ACTION_CONDITION_TYPE_TRIGGER_NAME
           ACTION_CONDITION_TYPE_TRIGGER_SEVERITY
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
           ACTION_CONDITION_TYPE_PROXY
           ACTION_CONDITION_TYPE_DOBJECT
           ACTION_CONDITION_TYPE_HOST_NAME
           ACTION_CONDITION_TYPE_EVENT_TYPE
           ACTION_CONDITION_TYPE_TAG
           ACTION_CONDITION_TYPE_TAG_VALUE/
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
           ACTION_OPERATION_TYPE_HOST_DISABLE
           ACTION_OPERATION_TYPE_HOST_INVENTORY
           ACTION_OPERATION_TYPE_HOST_LINK_TEMPLATE
           ACTION_OPERATION_TYPE_HOST_UNLINK_TEMPLATE/
    ],
    eval_types => [
        qw/ACTION_EVAL_TYPE_AND_OR
           ACTION_EVAL_TYPE_AND
           ACTION_EVAL_TYPE_OR/
    ],
);

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{actionid} = $value;
        return $self->data->{actionid};
    }
    return $self->data->{actionid};
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'action' . ($suffix // '');
}

sub _readonly_properties {
    return {
        actionid => 1,
        status => 1, # Added for Zabbix 7.0 (read-only field)
    };
}

sub _extension {
    return (
        output => 'extend',
        selectFilter => 'extend', # Updated for Zabbix 7.0
        selectOperations => 'extend',
        selectRecoveryOperations => 'extend', # Added for Zabbix 7.0
        selectUpdateOperations => 'extend', # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    return $self->data->{name} || '???';
}

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Action -- Zabbix action objects

=head1 SYNOPSIS

  use Zabbix7::API::Action qw/ACTION_EVENTSOURCE_TRIGGERS
      ACTION_EVAL_TYPE_AND
      ACTION_CONDITION_TYPE_TRIGGER_NAME
      ACTION_CONDITION_OPERATOR_LIKE
      ACTION_OPERATION_TYPE_MESSAGE/;
  
  # Create a trigger for demonstration purposes.
  my $new_trigger = Zabbix7::API::Trigger->new(
      root => $zabber,
      data => { description => 'Some Trigger',
                expression => '{Zabbix server:system.uptime.last(0)}<600', });
  
  # Get a random media type and user, also for demonstration purposes.
  my $any_media_type = $zabber->fetch_single('MediaType', params => { limit => 1 });
  my $any_user = $zabber->fetch_single('User', params => { limit => 1 });
  
  # Create a new action: every time the trigger 'Some Trigger' toggles
  # (from OK to PROBLEM or from PROBLEM to OK), send a message to the
  # user.  The message's contents will be determined from the action
  # data (default_msg => 1) and the message itself will be delivered,
  # over some media type that we previously picked randomly, to a random
  # user (id.).  Escalates every 2 minutes.
  
  my $new_action = Zabbix7::API::Action->new(
      root => $zabber,
      data => { name => 'Another Action',
                esc_period => 120,
                eventsource => ACTION_EVENTSOURCE_TRIGGERS,
                evaltype => ACTION_EVAL_TYPE_AND,
                conditions => [ { conditiontype => ACTION_CONDITION_TYPE_TRIGGER_NAME,
                                  operator => ACTION_CONDITION_OPERATOR_LIKE,
                                  value => 'Some Trigger' } ],
                operations => [ { operationtype => ACTION_OPERATION_TYPE_MESSAGE,
                                  opmessage => { default_msg => 1,
                                                 mediatypeid => $any_media_type->id },
                                  opmessage_usr => [ { userid => $any_user->id } ] } ]
      });
  
  $new_action->create;

=head1 DESCRIPTION

Handles CRUD for Zabbix action objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

=head1 EXPORTS

Many many constants that don't seem to be documented anywhere; see source for a
complete list.

Nothing is exported by default; you can use the tags C<:eventsources>,
C<:condition_types>, C<:condition_operators>, C<operation_types> and
C<eval_types> (or import by name).

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

L<https://www.zabbix.com/documentation/current/en/manual/api/reference/action>

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
