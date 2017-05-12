package Tuxedo::Admin::RemoteAccessPoint;

# TODO: Check limitations.

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  dmaccesspoint
                  dmaccesspointid
                  dmaclpolicy
                  dmcodepage
                  dmconnprincipalname
                  dmcredentialpolicy
                  dminpriority
                  dmlocalprincipalname
                  dmpriority_type
                  dmtype
                  state
             ) ];

use Tuxedo::Admin::TDomain;
use Carp;
use strict;
use Data::Dumper;

sub init
{
  my $self = shift
    || croak "init: Invalid parameters: expected self";
  $self->{admin} = shift
    || croak "init: Invalid parameters: expected admin";
  $self->{dmaccesspoint} = shift
    || croak "init: Invalid parameters: expected dmaccesspoint";

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_DM_REMOTE' ];
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

  croak "dmaccesspoint MUST be set"     unless $self->dmaccesspoint();
  croak "dmaccesspointid MUST be set"   unless $self->dmaccesspointid();

  my (%input_buffer, $error, %output_buffer, $tdomain);

  %input_buffer = $self->_fields();

  $input_buffer{'TA_CLASS'}     = [ 'T_DM_REMOTE' ];
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

  croak "Remote Access Point does not exist!" unless $self->exists();
  croak "dmaccesspoint MUST be set"           unless $self->dmaccesspoint();

  my (%input_buffer, $error, %output_buffer, $tdomain);

  %input_buffer = $self->_fields();
  # Constraints

  $input_buffer{'TA_CLASS'}     = [ 'T_DM_REMOTE' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;

  croak "Remote Access Point does not exist!" unless $self->exists();
  croak "dmaccesspoint MUST be set"           unless $self->dmaccesspoint();

  my (%input_buffer, $error, %output_buffer, $tdomain);

  foreach $tdomain ($self->tdomains())
  {
    next unless defined $tdomain;
    $error = $tdomain->remove();
    return $error if ($error < 0);
  }

  $input_buffer{'TA_CLASS'}         = [ 'T_DM_REMOTE' ];
  $input_buffer{'TA_STATE'}         = [ 'INVALID' ];
  $input_buffer{'TA_DMACCESSPOINT'} = [ $self->dmaccesspoint() ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);

  if ($error < 0)
  {
    carp($self->_status());
  }
  else
  {
    $self->exists(0);
  }
  
  return $error;
}

sub tdomains
{
  my $self = shift;
  croak "Invalid arguments" if (@_ != 0);
  croak "Remote Access Point does not exist" unless $self->exists();
  my @tdomains =
    $self->{admin}->tdomain_list( { 'dmaccesspoint' => $self->dmaccesspoint() } );
  return @tdomains;
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
    next if ($key eq 'tdomains');
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
  delete $data{tdomains};
  return %data;
}

=pod

Tuxedo::Admin::RemoteAccessPoint

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $remote_access_point = $admin->remote_access_point('ACCESS_POINT_NAME');

  $rc = $remote_access_point->remove()
    if $remote_access_point->exists();
  
  unless ($remote_access_point->exists())
  {
    $remote_access_point->dmaccesspointid('ACCESS_POINT_ID');
    $remote_access_point->dmsrvgroup('GW_GRP');
    $rc = $remote_access_point->add();
    die $admin->status() if ($rc < 0);
  }

=head1 DESCRIPTION

Provides methods to query, add, remove and update a remote access point.

=head1 INITIALISATION

Tuxedo::Admin::RemoteAccessPoint objects are not instantiated directly.  Instead
they are created via the remote_access_point() method of a Tuxedo::Admin object.

Example:

  $remote_access_point =
    $admin->remote_access_point('ACCESS_POINT_NAME');

This applies both for existing access points and for new access points that 
are being created.

=head1 METHODS

=head2 exists()

Used to determine whether or not the remote access point exists in the current
Tuxedo application.

  if ($remote_access_point->exists())
  {
    ...
  }

Returns true if the remote access point exists.


=head2 add()

Adds the remote access point to the current Tuxedo application.

  $rc = $remote_access_point->add();

Croaks if the remote access point already exists or if the required
dmaccesspoint and dmaccesspointid are not set.  If $rc is negative then an 
error occurred.  If successful then the exists() method will return true.

Example:

  $remote_access_point = $admin->remote_access_point('REMOTE');
  unless ($remote_access_point->exists())
  {
    $remote_access_point->dmaccesspointid('REMOTE_ID');
    $rc = $remote_access_point->add();
    $admin->print_status();
    die if ($rc < 0);


    $tdomain1 = $admin->tdomain('REMOTE', 'hostname:8765');
    $rc = $tdomain1->add();
    $admin->print_status();
    die if ($rc < 0);
    

    $tdomain2 = $admin->tdomain('REMOTE', 'hostname:8766');
    $rc = $tdomain2->add();
    $admin->print_status();
    die if ($rc < 0);
  }
  else
  {
    print STDERR "Already exists!\n";
  }

=head2 update()

Updates the remote access point configuration with the values of the current
object.

  $rc = $remote_access_point->update();

Croaks if the remote access point does not exist or if the required
dmaccesspoint parameter is not set.  If $rc is negative then an error
occurred.

=head2 remove()

Removes the remote access point from the current Tuxedo application.

  $rc = $remote_access_point->remove();

Croaks if the remote access point does not exist or if the required
dmaccesspoint parameter is not set.  If $rc is negative then an error
occurred.

Example:

  $remote_access_point = $admin->remote_access_point('REMOTE');
  if ($remote_access_point->exists())
  {
    $remote_access_point->remove();
  }

=head2 get/set methods

The following methods are available to get and set the remote access point
parameters.  If an argument is provided then the parameter value is set to be
the argument value.  The value of the parameter is returned.

Example:

  # Get the access point id
  print $remote_access_point->dmaccesspointid(), "\n";

  # Set the access point id
  $remote_access_point->dmaccesspointid('REMOTE_ID');

=over

=item dmaccesspoint()

=item dmaccesspointid()

=item dmaclpolicy()

=item dmcodepage()

=item dmconnprincipalname()

=item dmcredentialpolicy()

=item dminpriority()

=item dmlocalprincipalname()

=item dmpriority_type()

=item dmtype()

=item state()

=back

=cut

1;
