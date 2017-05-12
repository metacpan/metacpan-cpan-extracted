package Tuxedo::Admin::ExportedResource;

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  dmaclname
                  dmapi
                  dmcodepage
                  dmconv
                  dminbuftype
                  dmlaccesspoint
                  dmoutbuftype
                  dmremotename
                  dmresourcename
                  dmresourcetype
                  dmte_function
                  dmte_product
                  dmte_qualifier
                  dmte_rtqgroup
                  dmte_rtqname
                  dmte_target
                  state
             ) ];

use Carp;
use strict;
use Data::Dumper;

sub init
{
  my $self                = shift
    || croak "init: Invalid parameters: expected self";
  $self->{admin}          = shift
    || croak "init: Invalid parameters: expected admin";
  $self->{dmresourcename} = shift
    || croak "init: Invalid parameters: expected dmresourcename";

  my (%input_buffer, $error, %output_buffer);
  %input_buffer = $self->_fields();
  $input_buffer{'TA_CLASS'}     = [ 'T_DM_EXPORT' ];
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

  croak "dmresourcename MUST be set"   unless $self->dmresourcename();

  my (%input_buffer, $error, %output_buffer);

  %input_buffer = $self->_fields();

  $input_buffer{'TA_CLASS'}     = [ 'T_DM_EXPORT' ];
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

  croak "dmresourcename MUST be set"  unless $self->dmresourcename();
  #croak "dmlaccesspoint MUST be set"  unless $self->dmlaccesspoint();

  my (%input_buffer, $error, %output_buffer, $tdomain);

  %input_buffer = $self->_fields();

  $input_buffer{'TA_CLASS'}     = [ 'T_DM_EXPORT' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;

  croak "dmresourcename MUST be set"  unless $self->dmresourcename();
  #croak "dmlaccesspoint MUST be set"  unless $self->dmlaccesspoint();

  my (%input_buffer, $error, %output_buffer);

  $input_buffer{'TA_CLASS'}         = [ 'T_DM_EXPORT' ];
  $input_buffer{'TA_STATE'}         = [ 'INVALID' ];
  $input_buffer{'TA_DMRESOURCENAME'} = [ $self->dmresourcename() ];
  $input_buffer{'TA_DMLACCESSPOINT'} = [ $self->dmlaccesspoint() ];
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

Tuxedo::Admin::ExportedResource

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $exported_resource = $admin->exported_resource('BillingDetails'');

  $rc = $exported_resource->remove()
    if $exported_resource->exists();

  unless ($exported_resource->exists())
  {
    $rc = $exported_resource->add();
    die $admin->status() if ($rc < 0);
  }

=head1 DESCRIPTION

Provides methods to query, add, remove and update an exported resource.

=head1 INITIALISATION

Tuxedo::Admin::ExportedResource objects are not instantiated directly.
Instead they are created via the exported_resource() method of a Tuxedo::Admin
object.

Example:

  $exported_resource = $admin->exported_resource('BillingDetails');

This applies both for existing exported resources and for new exported
resources that are being created.

=head1 METHODS

=head2 exists()

Used to determine whether or not the exported resource exists in the current
Tuxedo application.

  if ($exported_resource->exists())
  {
    ...
  }

Returns true if the exported resource exists.

=head2 add()

Adds the exported resource to the current Tuxedo application.

  $rc = $exported_resource->add();

Croaks if the exported resource already exists or if the required
dmresourcename parameter is not set.  If $rc is negative then an error
occurred.  If successful then the exists() method will return true.

Example:

  $exported_resource = $admin->exported_resource('BillingDetails');

  unless ($exported_resource->exists())
  {
    $exported_resource->dmlaccesspoint('LOCAL1');
    $rc = $exported_resource->add();
    $admin->print_status();
  }

=head2 update()

Updates the exported resource configuration with the values of the current
object.

  $rc = $exported_resource->update();

Croaks if the exported resource does not exist or if the required
dmresourcename parameter is not set.  If $rc is negative then an error
occurred.

Example:

  $exported_resource = $admin->exported_resource('BillingDetails');

  if ($exported_resource->exists())
  {
    $exported_resource->dmremotename('BillDetails');
    $rc = $exported_resource->update();
    $admin->print_status();
  }

=head2 remove()

Removes the exported resource from the current Tuxedo application.

  $rc = $exported_resource->remove();

Croaks if the exported resource does not exist or if the required
dmresourcename parameter is not set.  If $rc is negative then an error
occurred.

Example:

  $exported_resource = $admin->exported_resource('BillingDetails');
  if ($exported_resource->exists())
  {
    $exported_resource->remove();
  }

=head2 get/set methods

The following methods are available to get and set the exported resource
parameters.  If an argument is provided then the parameter value is set to be
the argument value.  The value of the parameter is returned.

Example:

  # Get the remote name
  print $exported_resource->dmremotename(), "\n";

  # Set the remote name
  $exported_resource->dmremotename('BillDetails');

=over

=item dmaclname()

=item dmapi()

=item dmcodepage()

=item dmconv()

=item dminbuftype()

=item dmlaccesspoint()

=item dmoutbuftype()

=item dmremotename()

=item dmresourcename()

=item dmresourcetype()

=item dmte_function()

=item dmte_product()

=item dmte_qualifier()

=item dmte_rtqgroup()

=item dmte_rtqname()

=item dmte_target()

=item state()

=back

=cut

1;
