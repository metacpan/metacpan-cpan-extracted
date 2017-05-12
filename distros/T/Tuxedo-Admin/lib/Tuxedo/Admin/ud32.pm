package Tuxedo::Admin::ud32;

use Carp;
use IPC::Open2;
use strict;
use Data::Dumper;

sub new
{
	my $pkg = shift;
  my $self = { @_ };

	croak("Missing TUXDIR parameter!")    unless exists $self->{'TUXDIR'};
	croak("Missing TUXCONFIG parameter!") unless exists $self->{'TUXCONFIG'};
	croak("Missing BDMCONFIG parameter!") unless exists $self->{'BDMCONFIG'};

  return bless($self, $pkg);
}

sub tpcall
{
  # TODO: Need to make this Windows/Mac friendly
  my ($self, $service_name, $input_buffer) = @_;

  croak "input_buffer parameter is not a reference to a hash"
	  unless (ref($input_buffer) eq 'HASH');

  my ($field, @occurrences, $occurrence, $value, $error_code, $status, %output_buffer);

  $ENV{'TUXDIR'}          = $self->{'TUXDIR'};
  $ENV{'TUXCONFIG'}       = $self->{'TUXCONFIG'};
  $ENV{'BDMCONFIG'}       = $self->{'BDMCONFIG'};
  $ENV{'APP_PW'}          = $self->{'APP_PW'};
  $ENV{'FLDTBLDIR32'}     = $self->{'TUXDIR'} . '/udataobj';
  $ENV{'FIELDTBLS32'}     = 'Usysfl32,tpadm';
  $ENV{'LD_LIBRARY_PATH'} = $self->{'TUXDIR'} . '/lib';
  $ENV{'SHLIB_PATH'}      = $self->{'TUXDIR'} . '/lib';
  $ENV{'LANG'}            = 'C';

  # Damn! This bit me hard!
  my $oldors = $\;
  $\ = '';

  open2(\*READER,
        \*WRITER, 
        $self->{'TUXDIR'} .  '/bin/ud32 -e 1 -C tpsysadm 2>/dev/null')
    or croak "Can't run $self->{'tuxdir'}/bin/ud32\n";

  print "Input Buffer: ", Dumper($input_buffer), "\n" if $self->debug();
  print WRITER "SRVCNM\t$service_name\n";
  foreach $field (keys %{ $input_buffer })
  {
    croak "field value is not an array" unless (ref($input_buffer->{$field}) eq 'ARRAY');
    @occurrences = @{ $input_buffer->{$field} };
    foreach $occurrence (@occurrences)
    {
      print WRITER "$field\t", $occurrence, "\n";
    }
  }
  print WRITER "\n";
  close(WRITER);

  while(<READER>)
  {
    last if /^$/;
  }

  while(<READER>)
  {
    next if /^RTN pkt/;
    chomp;
    ($field,$value) = split(/\s+/,$_,2);
    next unless $field;
    if (exists $output_buffer{$field})
    {
      push @{ $output_buffer{$field} }, $value;
    }
    else
    {
      $output_buffer{$field}[0] = $value;
    }
  }
  close(READER);
  print "Output Buffer: ", Dumper(\%output_buffer), "\n" if $self->debug();

  $error_code = $output_buffer{TA_ERROR}[0];
  if (exists $output_buffer{TA_STATUS})
  {
    $status = $output_buffer{TA_STATUS}[0];
    $self->status($error_code, $status);
  }
  else
  {
    $self->status($error_code);
  }

  $\ = $oldors;

	return ($error_code, %output_buffer);
}

sub error_code_text
{
  my ($self, $error_code) = @_;
  return "UNKNOWN" if ($error_code eq '');
  return "TAEAPP - Application component error during MIB processing"
    if ($error_code == -1);
  return "TAECONFIG - Operating system error"
    if ($error_code == -2);
  return "TAEINVAL - Invalid argument"
    if ($error_code == -3);
  return "TAEOS - Operating system error"
    if ($error_code == -4);
  return "TAEPERM - Permission error"
    if ($error_code == -5);
  return "TAEPREIMAGE - Preimage does not match current image"
    if ($error_code == -6);
  return "TAEPROTO - MIB specific protocol error"
    if ($error_code == -7);
  return "TAEREQUIRED - Field value required but not present"
    if ($error_code == -8);
  return "TAESUPPORT - Documented but unsupported feature"
    if ($error_code == -9);
  return "TAESYSTEM - Internal System/T error"
    if ($error_code == -10);
  return "TAEUNIQ - SET did not specify unique class instance"
    if ($error_code == -11);
  return "TAOK - Succeeded"
    if ($error_code == 0);
  return "TAUPDATED - Succeeded and updated a record"
    if ($error_code == 1);
  return "TAPARTIAL - Succeeded at master; failed elsewhere"
    if ($error_code == 2);
  return "UNKNOWN";
}

sub status
{
  my $self = shift;
  if (@_ == 0)
  {
    return $self->{status};
  }
  elsif (@_ == 1)
  {
    $self->{status} = $self->error_code_text($_[0]);
  }
  elsif (@_ == 2)
  {
    $self->{status} = $self->error_code_text($_[0]) . ': ' . $_[1];
  }
  else
  {
    croak("Invalid arguments\n");
  }
}

sub debug
{
  my $self = shift;
  $self->{debug} = $_[0] if (@_ == 1);
  return $self->{debug};
}

=pod

Tuxedo::Admin::ud32 - a Tuxedo client implemented using the ud32 utility

=head1 SYNOPSIS

  $client = new Tuxedo::Admin::ud32
              (
                'TUXDIR'    => $self->{'TUXDIR'},
                'TUXCONFIG' => $self->{'TUXCONFIG'},
                'BDMCONFIG' => $self->{'BDMCONFIG'},
                'APP_PW'    => $self->{'APP_PW'}
              );

  $input_buffer{'TA_OPERATION'} = [ 'GET' ];
  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];

  ($error, %output_buffer) = $client->tpcall('.TMIB', \%input_buffer);

  die($client->status() . "\n") if ($error < 0);

=head1 DESCRIPTION

Provides a Tuxedo client based on the ud32 utility that comes with Tuxedo.
ud32 is a command-line native client that sends and receives FML32 buffers.

FML32 buffers are represented as a hash of arrays.  Each hash entry is the
name of an FML32 field and each hash value is an array where each element is
an occurrence of that field.

=head1 INITIALISATION

The 'new' method is the object constructor.  The following parameters must be
provided:

=over 4

=item TUXDIR

The directory where the Tuxedo installation is located.

=item TUXCONFIG

The full path to the binary application configuration file (as generated by
tmloadcf).

=item BDMCONFIG

The full path to the binary domains configuration file (as generated by
dmloadcf).

=back

In addition the APP_PW parameter may need to be specified if the Tuxedo
application requires that an application password be used.

=head1 METHODS

=head2 tpcall()

The 'tpcall' method is used to make synchronous calls.  It takes as input the
name of a service and a reference to a hash of arrays that represents the
input FML32 buffer.  It returns an indication of whether or not the call
succeeded and the output FML buffer (again represented as a hash of arrays):

  $input_buffer{'TA_OPERATION'} = [ 'GET' ];
  $input_buffer{'TA_CLASS'}     = [ 'T_SERVER' ];

  ($error, %output_buffer) = $client->tpcall('.TMIB', \%input_buffer);

If $error is negative this indicates that an error has occurred.  The status()
method may be used to obtain a description of the error that occurred.

=head2 status()

Returns a description of the result of the most recent tpcall() method call.

=head2 error_code_text()

Given an error code as input, returns a description of the error.

Below are the error codes with their corresponsing descriptions:

=over

=item -1 "TAEAPP - Application component error during MIB processing"

=item -2 "TAECONFIG - Operating system error"

=item -3 "TAEINVAL - Invalid argument"

=item -4 "TAEOS - Operating system error"

=item -5 "TAEPERM - Permission error"

=item -6 "TAEPREIMAGE - Preimage does not match current image"

=item -7 "TAEPROTO - MIB specific protocol error"

=item -8 "TAEREQUIRED - Field value required but not present"

=item -9 "TAESUPPORT - Documented but unsupported feature"

=item -10 "TAESYSTEM - Internal System /T error"

=item -11 "TAEUNIQ - SET did not specify unique class instance"

=item 0 "TAOK - Succeeded"

=item 1 "TAUPDATED - Succeeded and updated a record"

=item 2 "TAPARTIAL - Succeeded at master; failed elsewhere"

=back

=head1 AUTHOR

Keith Burdis <keith@rucus.ru.ac.za>

=cut

1;

