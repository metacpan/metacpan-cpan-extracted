package Tuxedo::Admin::Server;

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  basesrvid
                  clopt
                  cltlmid
                  cltpid
                  cltreply
                  cmtret
                  conv
                  curconv
                  curdispatchthreads
                  curinterface
                  curobjects
                  curreq
                  currservice
                  curtime
                  ejbcache_flush
                  envfile
                  generation
                  grace
                  grpno
                  hwdispatchthreads
                  lastgrp
                  lmid
                  max
                  maxdispatchthreads
                  maxejbcache
                  maxgen
                  maxqueuelen
                  min
                  mindispatchthreads
                  numconv
                  numdequeue
                  numdispatchthreads
                  numenqueue
                  numpost
                  numreq
                  numsubscribe
                  numtran
                  numtranabt
                  numtrancmt
                  pid
                  rcmd
                  replyq
                  restart
                  rpid
                  rpperm
                  rqaddr
                  rqid
                  rqperm
                  sec_principal_location
                  sec_principal_name
                  sec_principal_passvar
                  sequence
                  servername
                  sicacheentriesmax
                  srvgrp
                  srvid
                  srvtype
                  state
                  svctimeout
                  system_access
                  threadstacksize
                  timeleft
                  timerestart
                  timestart
                  totreqc
                  totworkl
                  tranlev
             ) ];

use Carp;
use strict;
use Data::Dumper;

sub init
{
  my $self        = shift || croak "init: Invalid parameters: expected self";
  $self->{admin}  = shift || croak "init: Invalid parameters: expected admin";
  $self->{srvgrp} = shift || croak "init: Invalid parameters: expected srvgrp";
  $self->{srvid}  = shift || croak "init: Invalid parameters: expected srvid"; 

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];
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
  croak "srvid MUST be set"      unless $self->srvid();
  croak "servername MUST be set" unless $self->servername();

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  
  # Constraints
  
  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];
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

  croak "Server does not exist!" unless $self->exists();
  croak "srvgrp MUST be set"     unless $self->srvgrp();
  croak "srvid MUST be set"      unless $self->srvid();

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  
  # Constraints
  
  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub _set_state
{
  my ($self, $state) = @_;

  croak "Server does not exist!" unless $self->exists();
  croak "srvgrp MUST be set"     unless $self->srvgrp();
  croak "srvid MUST be set"      unless $self->srvid();

  my (%input_buffer, $error, %output_buffer);

  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];
  $input_buffer{'TA_STATE'}     = [ $state ];
  $input_buffer{'TA_SRVGRP'}    = [ $self->srvgrp() ];
  $input_buffer{'TA_SRVID'}     = [ $self->srvid() ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;
  croak "Can't remove server while it is booted"
    if ($self->state() eq 'ACTIVE');
  my $error = $self->_set_state('INVALID');
  $self->exists(0);
  return $error;
}

sub boot
{
  my $self = shift;
  croak "Server is already booted"
    if ($self->state() eq 'ACTIVE');
  return $self->_set_state('ACTIVE');
}

sub shutdown
{
  my $self = shift;
  croak "Server is already shut down"
    if ($self->state() eq 'INACTIVE');
  return $self->_set_state('INACTIVE');
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

sub services
{
  my $self = shift;
  croak "Invalid arguments" unless (@_ == 0);
  return $self->{admin}->service_list( { 'srvgrp' => $self->srvgrp(),
                                         'srvid'  => $self->srvid() } );
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

Tuxedo::Admin::Server

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $server = $admin->server('GW_GRP_1','30');

  print $server->servername(), "\t", 
        $server->srvgrp(), "\t",
        $server->numreq(), "\n";

  $rc = $server->shutdown() 
    if ($server->exists() and ($server->state() ne 'INACTIVE'));
  unless ($rc < 0)
  {
    $server->max('10');
    $server->update();
    $server->boot();
  }

=head1 DESCRIPTION

Provides methods to query, add, remove and update a specific Tuxedo server
instance.

=head1 INITIALISATION

Tuxedo::Admin::Server objects are not instantiated directly.  Instead they are
created via the server() method of a Tuxedo::Admin object.

Example:

  $server = $admin->server('GW_GRP_1','30');

This applies both for existing servers and for new servers that are being
created.

=head1 METHODS

=head2 exists()

Used to determine whether or not the server exists in the current Tuxedo
application.

  if ($server->exists())
  {
    ...
  }

Returns true if the server exists.


=head2 add()

Adds the server to the current Tuxedo application.

  $rc = $server->add();

Croaks if the server already exists or if the required srvid, srvgrp and
servername parameters are not set.  $rc is non-negative on success.

Example:

  $server = $admin->server('GW_GRP_1','30');
  die "Server already exists\n" if $server->exists();
  
  $server->servername('GWTDOMAIN');
  $server->min('1');
  $server->max('1');
  $server->grace('0');
  $server->maxgen('5');
  $server->restart('Y');
  
  $rc = $server->add($server);
  print "Welcome!" unless ($rc < 0);
  
  $admin->print_status();
  
=head2 remove()

Removes the server from the current Tuxedo application.

  $rc = $server->remove();

Croaks if the server is booted or if the required srvid, srvgrp and servername
parameters are not set.  $rc is non-negative on success.

Example:

  $server = $admin->server('GW_GRP_1','30');
  
  warn "Can't remove a server while it is booted.\n"
    unless ($server->state() eq 'INACTIVE');
  
  $rc = $server->remove()
    if ($server->exists() and ($server->state() eq 'INACTIVE'));

  print "hasta la vista baby!" unless ($rc < 0);
  
  $admin->print_status();
  
=head2 update()

Updates the server configuration in the current Tuxedo application with the
values of the current object.

  $rc = $server->update();

Croaks if the server does not exist or the required srvid and srvgrp
parameters are not set.  $rc is non-negative on success.

Example:

  $server = $admin->server('GW_GRP_1', '30');
  die "Can't find server\n" unless $server->exists();

  $server->grace('0')
  $server->restart('Y');
  
  $rc = $server->update();

  $admin->print_status(*STDERR);
  
=head2 boot()

Starts the server.

  $rc = $server->boot();

Croaks if the server is already booted.  $rc is non-negative on success.

Example:

  $server = $admin->server('GW_GRP_1','30');
  $rc = $server->boot()
    if ($server->exists() and ($server->state() ne 'ACTIVE'));
  
=head2 shutdown()

Stops the server.

  $rc = $server->shutdown();

Croaks if the server is not running.  $rc is non-negative on success.

Example:

  $server = $admin->server('GW_GRP_1','30');
  $rc = $server->shutdown() 
    if ($server->exists() and ($server->state() ne 'INACTIVE'));
  
=head2 services()

Returns the list of services advertised by this server.

  @services = $server->services();

where @services is an array of references to Tuxedo::Admin::Service objects.

Example:

  print "Server: ", $server->servername(), " advertises:\n";
  foreach $service ($server->services())
  {
    print "\t", $service->servicename(), "\n";
  }

=head2 get/set methods

The following methods are available to get and set the server parameters.  If
an argument is provided then the parameter value is set to be the argument
value.  The value of the parameter is returned.

Example:

  # Get the server name
  print $server->servername(), "\n";

  # Set the server name
  $server->servername('GWTDOMAIN');

=over

=item basesrvid()

=item clopt()

=item cltlmid()

=item cltpid()

=item cltreply()

=item cmtret()

=item conv()

=item curconv()

=item curdispatchthreads()

=item curinterface()

=item curobjects()

=item curreq()

=item currservice()

=item curtime()

=item ejbcache_flush()

=item envfile()

=item generation()

=item grace()

=item grpno()

=item hwdispatchthreads()

=item lastgrp()

=item lmid()

=item max()

=item maxdispatchthreads()

=item maxejbcache()

=item maxgen()

=item maxqueuelen()

=item min()

=item mindispatchthreads()

=item numconv()

=item numdequeue()

=item numdispatchthreads()

=item numenqueue()

=item numpost()

=item numreq()

=item numsubscribe()

=item numtran()

=item numtranabt()

=item numtrancmt()

=item pid()

=item rcmd()

=item replyq()

=item restart()

=item rpid()

=item rpperm()

=item rqaddr()

=item rqid()

=item rqperm()

=item sec_principal_location()

=item sec_principal_name()

=item sec_principal_passvar()

=item sequence()

=item servername()

=item sicacheentriesmax()

=item srvgrp()

=item srvid()

=item srvtype()

=item state()

=item svctimeout()

=item system_access()

=item threadstacksize()

=item timeleft()

=item timerestart()

=item timestart()

=item totreqc()

=item totworkl()

=item tranlev()

=back

=cut

1;
