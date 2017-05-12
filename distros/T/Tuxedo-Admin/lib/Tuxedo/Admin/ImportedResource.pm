package Tuxedo::Admin::ImportedResource;

use Class::MethodMaker
  new_with_init => 'new',
  get_set => [ qw(
                  dmapi
                  dmautotran
                  dmblocktime
                  dmcodepage
                  dmconv
                  dmfunction
                  dminbuftype
                  dmlaccesspoint
                  dmload
                  dmoutbuftype
                  dmprio
                  dmraccesspointlist
                  dmremotename
                  dmresourcename
                  dmresourcetype
                  dmroutingname
                  dmte_function
                  dmte_product
                  dmte_qualifier
                  dmte_rtqgroup
                  dmte_rtqname
                  dmte_target
                  dmtrantime
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
  $input_buffer{'TA_CLASS'}     = [ 'T_DM_IMPORT' ];
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

  $input_buffer{'TA_CLASS'}     = [ 'T_DM_IMPORT' ];
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

  croak "Does not exist!"                 unless $self->exists();
  croak "dmresourcename MUST be set"      unless $self->dmresourcename();
  croak "dmlaccesspoint MUST be set"      unless $self->dmlaccesspoint();
  croak "dmraccesspointlist MUST be set"  unless $self->dmraccesspointlist();

  my (%input_buffer, $error, %output_buffer);

  %input_buffer = $self->_fields();
  delete $input_buffer{'TA_STATE'};
  delete $input_buffer{'TA_DMROUTINGNAME'};
  delete $input_buffer{'TA_DMINBUFTYPE'};
  delete $input_buffer{'TA_DMOUTBUFTYPE'};
  delete $input_buffer{'TA_DMCODEPAGE'};
  delete $input_buffer{'TA_DMTE_PRODUCT'};
  delete $input_buffer{'TA_DMTE_FUNCTION'};
  delete $input_buffer{'TA_DMTE_TARGET'};
  delete $input_buffer{'TA_DMTE_QUALIFIER'};
  delete $input_buffer{'TA_DMTE_RTQGROUP'};
  delete $input_buffer{'TA_DMTE_RTQNAME'};
  delete $input_buffer{'TA_DMAUTOPREPARE'};
  delete $input_buffer{'TA_DMINRECTYPE'};
  delete $input_buffer{'TA_DMOUTRECTYPE'};
  delete $input_buffer{'TA_DMTPSUTTYPE'};
  delete $input_buffer{'TA_DMREMTPSUT'};

  delete $input_buffer{'TA_DMBLOCKTIME'}
    unless (($input_buffer{'TA_DMBLOCKTIME'} >= 0) and
            ($input_buffer{'TA_DMBLOCKTIME'} <= 32767)); 


  $input_buffer{'TA_CLASS'}     = [ 'T_DM_IMPORT' ];
  ($error, %output_buffer) = $self->{admin}->_tmib_set(\%input_buffer);
  carp($self->_status()) if ($error < 0);
  return $error;
}

sub remove
{
  my $self = shift;

  croak "dmresourcename MUST be set"      unless $self->dmresourcename();
  croak "dmlaccesspoint MUST be set"      unless $self->dmraccesspointlist();
  croak "dmraccesspointlist MUST be set"  unless $self->dmraccesspointlist();

  my (%input_buffer, $error, %output_buffer);

  $input_buffer{'TA_CLASS'}         = [ 'T_DM_IMPORT' ];
  $input_buffer{'TA_STATE'}         = [ 'INVALID' ];
  $input_buffer{'TA_DMRESOURCENAME'}     = [ $self->dmresourcename() ];
  $input_buffer{'TA_DMLACCESSPOINT'}     = [ $self->dmlaccesspoint() ];
  $input_buffer{'TA_DMRACCESSPOINTLIST'} = [ $self->dmraccesspointlist() ];
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

Tuxedo::Admin::ImportedResource

=head1 SYNOPSIS

  use Tuxedo::Admin;

  $admin = new Tuxedo::Admin;

  $imported_resource = $admin->imported_resource('BillingDetails'');

  $rc = $imported_resource->remove()
    if $imported_resource->exists();

  unless ($imported_resource->exists())
  {
    $rc = $imported_resource->add();
    die $admin->status() if ($rc < 0);
  }

=head1 DESCRIPTION

Provides methods to query, add, remove and update an imported resource.

=head1 INITIALISATION

Tuxedo::Admin::ImportedResource objects are not instantiated directly.  
Instead they are created via the imported_resource() method of a Tuxedo::Admin
object.

Example:

  $imported_resource = $admin->imported_resource('BillingDetails');

This applies both for existing imported resources and for new imported
resources that are being created.
 
=head1 METHODS

=head2 exists()

Used to determine whether or not the imported resource exists in the current
Tuxedo application.

  if ($imported_resource->exists())
  {
    ...
  }

Returns true if the imported resource exists.

=head2 add()

Adds the imported resource to the current Tuxedo application.

  $rc = $imported_resource->add();

Croaks if the imported resource already exists or if the required
dmresourcename parameter is not set.  If $rc is negative then an error
occurred.  If successful then the exists() method will return true.

Example:

  $imported_resource = $admin->imported_resource('BillingDetails');
  
  unless ($imported_resource->exists())
  {
    $imported_resource->dmlaccesspoint('LOCAL1');
    $imported_resource->dmraccesspointlist('*');
    $rc = $imported_resource->add();
    $admin->print_status();
  }

=head2 update()

Updates the imported resource configuration with the values of the current
object.

  $rc = $imported_resource->update();

Croaks if the imported resource does not exist or if the required
dmresourcename parameter is not set.  If $rc is negative then an error 
occurred.

=head2 remove()

Removes the imported resource from the current Tuxedo application.

  $rc = $imported_resource->remove();

Croaks if the imported resource does not exist or if the required
dmresourcename parameter is not set.  If $rc is negative then an error 
occurred.

Example:

  $imported_resource = $admin->imported_resource('BillingDetails');
  if ($imported_resource->exists())
  {
    $imported_resource->remove();
  }

=head2 get/set methods

The following methods are available to get and set the imported resource
parameters.  If an argument is provided then the parameter value is set to be 
the argument value.  The value of the parameter is returned.

Example:

  # Get the remote name
  print $imported_resource->dmremotename(), "\n";

  # Set the remote name
  $imported_resource->dmremotename('BillDetails');

=over

=item dmapi()

=item dmautotran()

=item dmblocktime()

=item dmcodepage()

=item dmconv()

=item dmfunction()

=item dminbuftype()

=item dmlaccesspoint()

=item dmload()

=item dmoutbuftype()

=item dmprio()

=item dmraccesspointlist()

=item dmremotename()

=item dmresourcename()

=item dmresourcetype()

=item dmroutingname()

=item dmte_function()

=item dmte_product()

=item dmte_qualifier()

=item dmte_rtqgroup()

=item dmte_rtqname()

=item dmte_target()

=item dmtrantime()

=item state()

=back

=cut

1;
