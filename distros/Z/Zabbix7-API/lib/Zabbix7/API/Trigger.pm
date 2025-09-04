package Zabbix7::API::Trigger;

use strict;
use warnings;
use 5.010;
use Carp;
use autodie;
use utf8;

use Moo;
extends qw/Exporter Zabbix7::API::CRUDE/;

use constant {
    TRIGGER_PRIORITY_NOT_CLASSIFIED => 0,
    TRIGGER_PRIORITY_INFO => 1,
    TRIGGER_PRIORITY_WARN => 2,
    TRIGGER_PRIORITY_AVG  => 3,
    TRIGGER_PRIORITY_HIGH => 4,
    TRIGGER_PRIORITY_DISASTER => 5,
    TRIGGER_STATUS_ACTIVE => 0,
    TRIGGER_STATUS_DISABLED => 1,
    TRIGGER_VALUE_OK => 0,
    TRIGGER_VALUE_PROBLEM => 1,
    TRIGGER_VALUE_UNKNOWN => 2,
    TRIGGER_TYPE_NORMAL => 0,
    TRIGGER_TYPE_MULTIPLE => 1,
};

our @EXPORT_OK = qw/
    TRIGGER_PRIORITY_NOT_CLASSIFIED
    TRIGGER_PRIORITY_INFO
    TRIGGER_PRIORITY_WARN
    TRIGGER_PRIORITY_AVG
    TRIGGER_PRIORITY_HIGH
    TRIGGER_PRIORITY_DISASTER
    TRIGGER_STATUS_ACTIVE
    TRIGGER_STATUS_DISABLED
    TRIGGER_VALUE_OK
    TRIGGER_VALUE_PROBLEM
    TRIGGER_VALUE_UNKNOWN
    TRIGGER_TYPE_NORMAL
    TRIGGER_TYPE_MULTIPLE
/;

our %EXPORT_TAGS = (
    trigger_types => [
        qw/TRIGGER_TYPE_NORMAL
           TRIGGER_TYPE_MULTIPLE/
    ],
    priority_types => [
        qw/TRIGGER_PRIORITY_NOT_CLASSIFIED
           TRIGGER_PRIORITY_INFO
           TRIGGER_PRIORITY_WARN
           TRIGGER_PRIORITY_AVG
           TRIGGER_PRIORITY_HIGH
           TRIGGER_PRIORITY_DISASTER/
    ],
    value_types => [
        qw/TRIGGER_VALUE_OK
           TRIGGER_VALUE_PROBLEM
           TRIGGER_VALUE_UNKNOWN/
    ],
    status_types => [
        qw/TRIGGER_STATUS_ACTIVE
           TRIGGER_STATUS_DISABLED/
    ],
);

sub _readonly_properties {
    return {
        triggerid => 1,
        error => 1,
        flags => 1,
        lastchange => 1,
        state => 1,
        templateid => 1,
        value => 1,
    };
}

sub id {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->data->{triggerid} = $value;
        Log::Any->get_logger->debug("Set triggerid: $value for trigger");
        return $self->data->{triggerid};
    }
    my $id = $self->data->{triggerid};
    Log::Any->get_logger->debug("Retrieved triggerid for trigger: " . ($id // 'none'));
    return $id;
}

sub _prefix {
    my (undef, $suffix) = @_;
    return 'trigger' . ($suffix // '');
}

sub _extension {
    return (
        output => 'extend',
        selectHosts => ['hostid', 'host'], # Updated for Zabbix 7.0
        selectItems => ['itemid', 'key_', 'name'], # Updated for Zabbix 7.0
        selectFunctions => 'extend',
        selectDependencies => ['triggerid'],
        selectTags => 'extend', # Added for Zabbix 7.0
    );
}

sub name {
    my $self = shift;
    my $name = $self->data->{description} || '???';
    Log::Any->get_logger->debug("Retrieved name for trigger ID: " . ($self->id // 'new') . ": $name");
    return $name;
}

before 'create' => sub {
    my ($self) = @_;
    delete $self->data->{triggerid}; # Ensure triggerid is not sent
    delete $self->data->{flags};    # flags is read-only
    delete $self->data->{value};    # value is read-only
    delete $self->data->{state};    # state is read-only
    Log::Any->get_logger->debug("Preparing to create trigger: " . ($self->data->{description} // 'unknown'));
};

before 'update' => sub {
    my ($self) = @_;
    delete $self->data->{flags}; # flags is read-only
    delete $self->data->{value}; # value is read-only
    delete $self->data->{state}; # state is read-only
    Log::Any->get_logger->debug("Preparing to update trigger ID: " . ($self->id // 'new'));
};

1;
__END__
=pod

=head1 NAME

Zabbix7::API::Trigger -- Zabbix trigger objects

=head1 SYNOPSIS

  use Zabbix7::API::Trigger;
  
  # fetch a single trigger...
  my $trigger = $zabbix->fetch_single('Trigger', params => { triggerids => [ 22379 ] });
  
  # manipulate its properties: make it "average" severity
  $trigger->data->{priority} = 3;
  
  # and update the properties on the server.
  $trigger->update;
  
  # create a new trigger
  my $new_trigger = Zabbix7::API::Trigger->new(
      root => $zabbix,
      data => {
          description => 'some trigger',
          expression => '{Zabbix server:system.uptime.last(0)}<600',
      });
  $new_trigger->create;
  
  # get the triggers that have been triggered and not acked yet, and
  # their parent hosts' IDs in the "hosts" property
  my $triggers = $zabbix->fetch(
      'Trigger',
      params => {
          filter => { value => 1 },
          withLastEventUnacknowledged => 1,
          selectHosts => ['hostid'],
      });

=head1 DESCRIPTION

Handles CRUD for Zabbix trigger objects.

This is a subclass of C<Zabbix7::API::CRUDE>; see there for inherited
methods.

=head1 BUGS AND LIMITATIONS

L<Zabbix::API::Trigger> used to have rudimentary dependency support;
this version doesn't, because I don't need it right now.  Patches
welcome.

=head1 SEE ALSO

L<Zabbix7::API::CRUDE>.

=head1 AUTHOR

SCOTTH

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
