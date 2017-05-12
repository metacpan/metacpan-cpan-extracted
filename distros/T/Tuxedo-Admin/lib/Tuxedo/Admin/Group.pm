package Tuxedo::Admin::Group;

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  closeinfo
                  curlmid
                  encryption_required
                  envfile
                  grpno
                  lmid
                  openinfo
                  sec_principal_location
                  sec_principal_name
                  sec_principal_passvar
                  signature_required
                  srvgrp
                  state
                  tmscount
                  tmsname
             ) ];

use Carp;
use strict;

sub init
{
  my $self        = shift || croak "init: Invalid parameters: expected self";
  $self->{admin}  = shift || croak "init: Invalid parameters: expected admin";
  $self->{srvgrp} = shift || croak "init: Invalid parameters: expected srvgrp";   

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_GROUP' ];
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

sub exists
{
  my $self = shift;
  $self->{exists} = $_[0] if (@_ != 0);
  return $self->{exists};
}

sub add
{
  my $self = shift;

  croak "srvgrp MUST be set"     unless $self->srvgrp();
  croak "grpno MUST be set"      unless $self->grpno();
  croak "lmid MUST be set"       unless $self->lmid();

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_GROUP' ];
  $input_buffer{'TA_STATE'}     = [ 'NEW' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  
  if ($error < 0)
  {
    carp($self->_status());
  }
  else
  {
    $self->exists(1);
  }
  
  return $error;
}

sub update
{
  my $self = shift;

  croak "Group does not exist!"  unless $self->exists();
  croak "srvgrp MUST be set"     unless $self->srvgrp();

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  
  # Constraints
  
  $input_buffer{'TA_CLASS'}     = [ 'T_GROUP' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub _set_state
{
  my ($self, $state) = @_;

  croak "Group does not exist!" unless $self->exists();
  croak "srvgrp MUST be set"    unless $self->srvgrp();

  my (%input_buffer, $error, %output_buffer);

  $input_buffer{'TA_CLASS'}   = [ 'T_GROUP' ];
  $input_buffer{'TA_STATE'}   = [ $state ];
  $input_buffer{'TA_SRVGRP'}  = [ $self->srvgrp() ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;
  my $error = $self->_set_state('INVALID');
  $self->exists(0) unless ($error < 0);
  return $error;
}

sub boot
{
  my $self = shift;
  croak "Group is already booted"
    if ($self->state() eq 'ACTIVE');
  return $self->_set_state('ACTIVE');
}

sub shutdown
{
  my $self = shift;
  croak "Group is already shut down"
    if ($self->state() eq 'INACTIVE');
  return $self->_set_state('INACTIVE');
}

sub suspend
{
  my $self = shift;
  croak "Group must be active"
    unless ($self->state() eq 'ACTIVE');
  return $self->_set_state('UNAVAILABLE');
}

sub resume
{
  my $self = shift;
  croak "Group must be active"
    unless ($self->state() eq 'ACTIVE');
  return $self->_set_state('AVAILABLE');
}

sub start
{
  my $self = shift;
  return $self->boot();
}

sub stop
{
  my $self = shift;
  return $self->shutdown();
}

sub servers
{
  my $self = shift;
  croak "Invalid arguments" unless (@_ == 0);
  return $self->{admin}->server_list( { 'srvgrp' => $self->srvgrp() } );
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

Tuxedo::Admin::Group

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $group = $admin->group('GW_GRP_3');

  $group->grpno('50');
  $group->lmid('master');
  $group->update();
  
  ...

  unless ($group->exists())
  {
    $rc = $group->add($group);
    $admin->print_status();
  }  

  foreach $group ($admin->group_list())
  {
    print "Group name: ", $group->srvgrp();
    print "Group number: ", $group->grpno();
  }

=head1 DESCRIPTION

Provides methods to query, add, remove and update a Tuxedo group.

=head1 INITIALISATION

Tuxedo::Admin::Group objects are not instantiated directly.  Instead they are
created via the group() method of a Tuxedo::Admin object.

Example:

  $group = $admin->group('GW_GRP_1');

This applies both for existing groups and for new groups that are being
created.

=head1 METHODS

=head2 exists()

Used to determine whether or not the group exists.

  if ($group->exists())
  {
    ...
  }

Returns true if the group exists.


=head2 add()

Adds the group to the current Tuxedo application.

  $rc = $group->add();

Croaks if the group already exists or if the required srvgrp, grpno and lmid
parameters are not set.  $rc is non-negative on success.

Example:

  $group = $admin->group('GW_GRP_1);
  die "group already exists\n" if $group->exists();
  
  $group->grpno('50');
  $group->lmid('yoda');
  
  $rc = $group->add($group);
  print "Welcome!" unless ($rc < 0);
  
  $admin->print_status();
  
=head2 remove()

Removes the group from the current Tuxedo application.

  $rc = $group->remove();

Croaks if the group is booted or if the required srvgrp parameter is not set.
$rc is non-negative on success.

Example:

  $group = $admin->group('GW_GRP_1');
  
  warn "Can't remove a group while it is booted.\n"
    unless ($group->state() eq 'INACTIVE');
  
  $rc = $group->remove()
    if ($group->exists() and ($group->state() eq 'INACTIVE'));

  print "hasta la vista baby!" unless ($rc < 0);
  
  $admin->print_status();
  
=head2 update()

Updates the group configuration with the values of the current object.

  $ok = $group->update();

Croaks if the group does not exist or the required srvgrp parameter is not
set.  $rc is non-negative on success.


=head2 boot()

Starts all servers in this group.

  $rc = $group->boot();

Croaks if the group is already booted.  $rc is non-negative on success.

Example:

  $group = $admin->group('GW_GRP_1');
  $rc = $group->boot()
    if ($group->exists() and ($group->state() ne 'ACTIVE'));

    
=head2 shutdown()

Stops all servers in this group.

  $rc = $group->shutdown();

Croaks if the group is not running.  $rc is non-negative on success.

Example:

  $group = $admin->group('GW_GRP_1');
  $rc = $group->shutdown() 
    if ($group->exists() and ($group->state() ne 'INACTIVE'));
  
  
=head2 suspend()

Suspends all services advertised by servers in this group.

  $rc = $group->suspend();

Croaks if the group is not active.  $rc is non-negative on success.

Example:

  $group = $admin->group('GW_GRP_1');
  $rc = $group->suspend()
    if ($group->exists() and ($group->state() eq 'ACTIVE'));

    
=head2 resume()

Unsuspends all services advertised by servers in this group.

  $rc = $group->resume();

Croaks if the group is not active.  $rc is non-negative on success.

Example:

  $group = $admin->group('GW_GRP_1');
  $rc = $group->resume() 
    if ($group->exists() and ($group->state() eq 'ACTIVE'));
  

=head2 servers()

Returns the list of servers in this group.

  @servers = $group->servers();

where @servers is an array of references to Tuxedo::Admin::Server objects.

Example:

  foreach $server ($group->servers())
  {
    print $server->servername(), "\t", $server->srvid(), "\n";
  }


=head2 get/set methods

The following methods are available to get and set the group parameters.  If
an argument is provided then the parameter value is set to be the argument
value.  The value of the parameter is returned.

Example:

  # Get the group number
  print $group->grpno(), "\n";

  # Set the group number
  $group->grpno('50');

=over

=item closeinfo()

=item curlmid()

=item encryption_required()

=item envfile()

=item grpno()

=item lmid()

=item openinfo()

=item sec_principal_location()

=item sec_principal_name()

=item sec_principal_passvar()

=item signature_required()

=item srvgrp()

=item state()

=item tmscount()

=item tmsname()

=back

=cut

1;
