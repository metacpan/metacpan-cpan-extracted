package Tuxedo::Admin::Service;

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  autotran
                  buftype
                  encryption_required
                  grpno
                  lmid
                  load
                  prio
                  routingname
                  rqaddr
                  servicename
                  signature_required
                  srvgrp
                  srvid
                  state
                  svcrnam
                  svctimeout
                  svctype
                  trantime
             ) ];

use Carp;
use strict;

sub init
{
  my $self             = shift
    || croak "init: Invalid parameters: expected self";
  $self->{admin}       = shift
    || croak "init: Invalid parameters: expected admin";
  $self->{servicename} = shift
    || croak "init: Invalid parameters: expected servicename";
  $self->{srvgrp}      = shift
    || croak "init: Invalid parameters: expected srvgrp";
  
  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_SVCGRP' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_get(\%input_buffer);
  carp($self->_status()) if ($error < 0);

  $self->exists($output_buffer{'TA_OCCURS'}[0] eq '1');
  
  delete $output_buffer{'TA_OCCURS'};
  delete $output_buffer{'TA_ERROR'};
  delete $output_buffer{'TA_MORE'};
  delete $output_buffer{'TA_CLASS'};
  delete $output_buffer{'TA_STATUS'};

  my ($field, $key);
  foreach $field (keys %output_buffer)
  {
    $key = $field;
    $key =~ s/^TA_//;
    $key =~ tr/A-Z/a-z/;
    if (defined $output_buffer{$field}[0])
    {
      $self->{$key} = $output_buffer{$field}[0];
    }
    else
    {
      $self->{$key} = undef;
    }
  }
}

#sub add
#{
#  my $self = shift;
#
#  croak "servicename MUST be set"  unless $self->servicename();
#  croak "srvgrp MUST be set"       unless $self->srvgrp();
#
#  my (%input_buffer, $error, %output_buffer);
#  %input_buffer = $self->_fields();
#  $input_buffer{'TA_CLASS'}     = [ 'T_SVCGRP' ];
#  $input_buffer{'TA_STATE'}     = [ 'NEW' ];
#  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
#  carp($self->_status()) if ($error < 0);
#  return $error;
#}

sub update
{
  my $self = shift;

  croak "Does not exist!"          unless $self->exists();
  croak "servicename MUST be set"  unless $self->servicename();
  croak "srvgrp MUST be set"       unless $self->srvgrp();

  if (($self->state() eq 'ACTIVE') and 
      (!$self->srvid() or !$self->rqaddr()))
  {
    warn "srvid() and/or rqaddr() are not set, but may need to be to update() when the service is ACTIVE.\n";
  }

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_SVCGRP' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub _set_state
{
  my ($self, $state) = @_;

  croak "Does not exist!"          unless $self->exists();
  croak "servicename MUST be set"  unless $self->servicename();
  croak "srvgrp MUST be set"       unless $self->srvgrp();

  if (($self->state() eq 'ACTIVE') and 
      (!$self->srvid() or !$self->rqaddr()))
  {
    warn "srvid() and/or rqaddr() are not set, but may need to be for this to work when the service is ACTIVE.\n";
  }

  my (%input_buffer, $error, %output_buffer);

  $input_buffer{'TA_CLASS'}   = [ 'T_SVCGRP' ];
  $input_buffer{'TA_STATE'}   = [ $state ];
  $input_buffer{'TA_SRVGRP'}  = [ $self->srvgrp() ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;
  croak "Service must be INACTIVE"
    unless ($self->state() eq 'INACTIVE');
  return $self->_set_state('INVALID');
}

sub activate
{
  my $self = shift;
  croak "Service must be INACTIVE, SUSPENDED or INVALID"
    unless (($self->state() eq 'INACTIVE') or
            ($self->state() eq 'SUSPENDED') or
            ($self->state() eq 'INAVALID'));
  croak "No can do for service names starting with '.'"
    if ($self->servicename() =~ /^\./);
  return $self->_set_state('ACTIVE');
}

sub deactivate
{
  my $self = shift;
  croak "Service must be SUSPENDED"
    unless ($self->state() eq 'SUSPENDED');
  croak "No can do for service names starting with '_'"
    if ($self->servicename() =~ /^_/);
  return $self->_set_state('INACTIVE');
}

sub suspend
{
  my $self = shift;
  croak "Service must be ACTIVE"
    unless ($self->state() eq 'ACTIVE');
  croak "No can do for service names starting with '_'"
    if ($self->servicename() =~ /^_/);
  return $self->_set_state('INACTIVE');
}

sub _status
{
  my $self = shift;
  return $self->{admin}->status();
}

sub _fields
{
  my $self = shift;
  my ($key, $field, %data, %fields);
  %data = %{ $self };
  foreach $key (keys %data)
  {
    next if ($key eq 'admin');
    next if ($key eq 'exists');
    $field = "TA_$key";
    $field =~ tr/a-z/A-Z/;
    $fields{$field} = [ $data{$key} ];
  }
  return %fields;
}

sub hash
{
  my $self = shift;
  my (%data);
  %data = %{ $self };
  delete $data{admin};
  return %data;
}

=pod

Tuxedo::Admin::Service

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $service = $admin->service('TO_UPPER', 'APP_GRP_1');

  print $service->servicename(), "\t", 
        $service->srvgrp(), "\t",
        $service->rqaddr(), "\n";

  $rc = $service->suspend() if ($self->state() eq 'ACTIVE');
  $service->deactivate() unless ($rc < 0);
    
=head1 DESCRIPTION

Provides methods to query, remove and update a specific Tuxedo service.

=head1 INITIALISATION

Tuxedo::Admin::Service objects are not instantiated directly.  Instead they are
created via the service() method of a Tuxedo::Admin object.

Example:

  $service = $admin->service('TO_UPPER','APP_GRP_1');

This applies both for existing services and for new services that are being
created.

=head1 METHODS

=head2 remove()

Removes the service.

  $rc = $service->remove();

Croaks if the service is active or if the required servicename and srvgrp
parameters are not set.  $rc is non-negative on success.

Example:

  $service = $admin->service('TO_UPPER','APP_GRP_1');
  
  warn "Can't remove a service while it is active.\n"
    unless ($service->state() eq 'INACTIVE');
  
  $rc = $service->remove() if ($service->state() eq 'INACTIVE');

  print "hasta la vista baby!" unless ($rc < 0);
  
  $admin->print_status();
  
=head2 update()

Updates the service configuration with the values of the current object.

  $rc = $service->update();

Croaks if the required servicename and srvgrp parameters are not set.  When
the service is active it may also be necessary for the srvid and rqaddr
parameters to be set.  $rc is non-negative on success.

Example:

  $service = $admin->service('TO_UPPER', 'APP_GRP_1');

  $service->rqaddr('UPPER')
  
  $rc = $service->update();

  $admin->print_status(*STDERR);
  
=head2 activate()

Activates the service.

  $rc = $service->activate();

Croaks if the service is active or if the required servicename and srvgrp
parameters are not set.  $rc is non-negative on success.

Example:

  $service = $admin->service('TO_UPPER', 'APP_GRP_1');
  $rc = $service->active()
    if ($service->state() ne 'ACTIVE');
  
=head2 suspend()

Suspends the service.

  $rc = $service->suspend();

Croaks if the service is not active or if the required servicename and srvgrp
parameters are not set.  $rc is non-negative on success.

Example:

  $service = $admin->service('TO_UPPER', 'APP_GRP_1');
  $rc = $service->suspend() 
    if ($service->state() eq 'ACTIVE');
  
=head2 deactivate()

Deactivates the service.

  $rc = $service->deactivate();

Croaks if the service is not suspended or if the required servicename and
srvgrp parameters are not set.  $rc is non-negative on success.

=head2 get/set methods

The following methods are available to get and set the service parameters.  If
an argument is provided then the parameter value is set to be the argument
value.  The value of the parameter is returned.

Example:

  # Get the service request queue name
  print $service->rqaddr(), "\n";

  # Set the service request queue name
  $service->rqaddr('GWTDOMAIN');

=over

=item autotran()

=item buftype()

=item encryption_required()

=item grpno()

=item lmid()

=item load()

=item prio()

=item routingname()

=item rqaddr()

=item servicename()

=item signature_required()

=item srvgrp()

=item srvid()

=item state()

=item svcrnam()

=item svctimeout()

=item svctype()

=item trantime()

=back

=cut
1;
