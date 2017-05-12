package Tuxedo::Admin::TDomain;

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  dmaccesspoint
                  dmcmplimit
                  dmfailoverseq
                  dmmaxencryptbits
                  dmminencryptbits
                  dmnwaddr
                  dmnwdevice
                  state
             ) ];

use Carp;
use strict;

sub init
{
  my $self               = shift
    || croak "init: Invalid parameters: expected self";
  $self->{admin}         = shift
    || croak "init: Invalid parameters: expected admin";
  $self->{dmaccesspoint} = shift
    || croak "init: Invalid parameters: expected dmaccesspoint";
  $self->{dmnwaddr}      = shift
    || croak "init: Invalid parameters: expected dmnwaddr";
    
  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_DM_TDOMAIN' ];
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
  croak "dmnwaddr MUST be set"          unless $self->dmnwaddr();

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_DM_TDOMAIN' ];
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

  croak "TDomain does not exist!"    unless $self->exists();
  croak "dmaccesspoint MUST be set"  unless $self->dmaccesspoint();
  croak "dmnwaddr MUST be set"       unless $self->dmnwaddr();

  my (%input_buffer, $error, %output_buffer);

  %input_buffer = $self->_fields();

  # Constraints
  delete $input_buffer{'TA_STATE'};
  delete $input_buffer{'TA_DMFAILOVERSEQ'}; # FIXME
  delete $input_buffer{'TA_DMNWDEVICE'};    # FIXME

  $input_buffer{'TA_CLASS'}     = [ 'T_DM_TDOMAIN' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;

  croak "TDomain does not exist!"    unless $self->exists();
  croak "dmaccesspoint MUST be set"  unless $self->dmaccesspoint();
  croak "dmnwaddr MUST be set"       unless $self->dmnwaddr();

  my (%input_buffer, $error, %output_buffer);
  #%input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}         = [ 'T_DM_TDOMAIN' ];
  $input_buffer{'TA_STATE'}         = [ 'INVALID' ];
  $input_buffer{'TA_DMACCESSPOINT'} = [ $self->dmaccesspoint() ];
  $input_buffer{'TA_DMNWADDR'}      = [ $self->dmnwaddr() ];
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

Tuxedo::Admin::TDomain

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $tdomain = $admin->tdomain('ACCESS_POINT_NAME', 'hostname:port');

  $rc = $tdomain->remove()
    if $tdomain->exists();

  unless ($tdomain->exists())
  {
    $rc = $tdomain->add();
    die $admin->status() if ($rc < 0);
  }

=head1 DESCRIPTION

Provides methods to query, add, remove and update a tdomain.

=head1 INITIALISATION

Tuxedo::Admin::TDomain objects are not instantiated directly.  Instead
they are created via the tdomain() method of a Tuxedo::Admin object.

Example:

  $tdomain = $admin->tdomain('ACCESS_POINT_NAME', 'hostname:port');

This applies both for existing tdomains and for new tdomains that are being
created.

=head1 METHODS

=head2 exists()

Used to determine whether or not the tdomain exists in the current
Tuxedo application.

  if ($tdomain->exists())
  {
    ...
  }

Returns true if the tdomain exists.


=head2 add()

Adds the tdomain to the current Tuxedo application.

  $rc = $tdomain->add();

Croaks if the tdomain already exists or if the required
dmaccesspoint and dmnwaddr are not set.  If $rc is negative then an error 
occurred.  If successful then the exists() method will return true.
Example:

  $tdomain = $admin->tdomain('REMOTE', 'hostname:port');
  unless ($tdomain->exists())
  {
    $rc = $tdomain->add();
    $admin->print_status();
  }

=head2 update()

Updates the tdomain configuration with the values of the current
object.

  $rc = $tdomain->update();

Croaks if the tdomain does not exist or if the required
dmaccesspoint and dmnwaddr parameters are not set.  If $rc is negative then an 
error occurred.

=head2 remove()

Removes the tdomain from the current Tuxedo application.

  $rc = $tdomain->remove();

Croaks if the tdomain does not exist or if the required dmaccesspoint and 
dmnwaddr parameters are not set.  If $rc is negative then an error occurred.

Example:

  $tdomain = $admin->tdomain('REMOTE', 'hostname:port');
  if ($tdomain->exists())
  {
    $tdomain->remove();
  }

=head2 get/set methods

The following methods are available to get and set the tdomain parameters.  If 
an argument is provided then the parameter value is set to be the argument
value.  The value of the parameter is returned.

Example:

  # Get the access point name
  print $tdomain->dmaccesspoint(), "\n";

  # Set the access point name
  $tdomain->dmaccesspoint('ACCESS_POINT_NAME');

=over

=item dmaccesspoint()

=item dmcmplimit()

=item dmfailoverseq()

=item dmmaxencryptbits()

item dmminencryptbits()

=item dmnwaddr()

=item dmnwdevice()

=item state()

=back

=cut

1;
