package ZMQ::Declare::ZDCF;
{
  $ZMQ::Declare::ZDCF::VERSION = '0.03';
}
use 5.008001;
use Moose;

use ZMQ::Declare;
use ZMQ::Declare::ZDCF::Validator;
use ZMQ::Declare::ZDCF::Encoder;
use ZMQ::Declare::ZDCF::Encoder::JSON;

use ZeroMQ qw(:all);

use ZMQ::Declare::Constants qw(:all);
use ZMQ::Declare::Types;
use Carp ();
use Clone ();

has 'validator' => (
  is => 'rw',
  isa => 'ZMQ::Declare::ZDCF::Validator',
  default => sub {ZMQ::Declare::ZDCF::Validator->new},
);

has 'encoder' => (
  is => 'rw',
  isa => 'ZMQ::Declare::ZDCF::Encoder',
  default => sub {ZMQ::Declare::ZDCF::Encoder::JSON->new},
);

has 'tree' => (
  is => 'rw',
  required => 1,
);

sub BUILD {
  my $self = shift;
  my $tree = $self->tree;

  # needs decoding
  if (not ref($tree) eq 'HASH') {
    my $sref;
    if (ref($tree) eq 'SCALAR') { # content as scalar ref
      $sref = $tree;
    }
    elsif (not ref $tree) { # slurp from file
      use autodie;
      open my $fh, "<", $tree;
      local $/;
      my $zdcf_content = <$fh>;
      $sref = \$zdcf_content;
    }

    $tree = $self->encoder->decode($sref);
    Carp::croak("Failed to decode input ZDCF")
      if not defined $tree;

    $self->tree($tree);
  }

  $tree = $self->validator->validate_and_upgrade($tree);
  Carp::croak("Failed to validate decoded ZDCF")
    if not defined $tree;
  $self->tree($tree);
}

sub application_names {
  my $self = shift;
  return keys %{ $self->tree->{apps} || {} };
}

sub application {
  my $self = shift;
  my $name = shift;
  $name = "" if not defined $name; # more-or-less compat with pre v1 ZDCF spec

  my $apps = $self->tree->{apps} || {};
  Carp::croak("Invalid application '$name'")
    if not exists $apps->{$name};

  my $app_spec = $apps->{$name};
  my $typename = $app_spec->{type};
  $typename = '' if not defined $typename;

  return ZMQ::Declare::Application->new(
    name => $name,
    spec => $self,
  );
}

sub encode {
  my ($self) = @_;
  return $self->encoder->encode($self->tree);
}

sub write_to_file {
  my ($self, $filename) = @_;
  open my $fh, ">", $filename or die $!;
  print $fh ${ $self->encode };
  close $fh;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

ZMQ::Declare::ZDCF - Object representing ZeroMQ Device Configuration (File)

=head1 SYNOPSIS

  use ZMQ::Declare;
  
  my $zdcf = ZMQ::Declare::ZDCF->new(tree => $json_zdcf_filename);
  # Alternatively
  my $zdcf = ZMQ::Declare::ZDCF->new(
    encoder => ZMQ::Declare::ZDCF::Encoder::YourFormat->new,
    tree => $zdcf_file_with_different_encoding
  );
  
  my $app = $zdcf->application("event_broker");
  # ...

=head1 DESCRIPTION

This class represents the content of a single ZDCF. That means,
it covers a single 0MQ threading context and an arbitrary
number of devices and sockets.

=head1 METHODS

=head2 new

Constructor taking named arguments. Any parameters listed under
I<METHOD-ACCESSIBLE INSTANCE PROPERTIES> can be supplied, but
a C<tree> is the main input and thus required.

You can provide the C<tree> property as any one of the following:

=over 2

=item *

A hash reference that represents the underlying ZDCF data structure.
It will be validated using the ZDCF validator but otherwise won't
be touched (or cloned).

=item *

A reference to a scalar. The scalar is assumed to contain valid input
for the decoder (by default: JSON-encoded ZDCF). The thusly decoded
Perl data structure will be validated like if you provided a hash
reference.

=item *

A string, which is interpreted as a file name to read from. The data
read from the file will be decoded and validated as per the above.

=back

=head2 application

Given an application name, creates a L<ZMQ::Declare::Application>
object from the information stored in the ZDCF tree and returns that object.

This C<ZMQ::Declare::Application> object contains one 0MQ threading
context and one or many 0MQ device objects. Those devise are what you can
use to actually implement 0MQ devices that are configured through ZDCF.
Note that creating a C<ZMQ::Declare::Application> object does B<not>
create any 0MQ contexts, sockets, or connections yet.

=head2 application_names

Returns a list (not a reference) of application names that are known to
the ZDCF tree.

=head2 encode

Encodes the ZDCF data structure using the object's encoder and
returns a scalar reference to the result.

=head2 write_to_file

Writes the ZDCF content to the given file name.

=head1 SEE ALSO

The ZDCF RFC L<http://rfc.zeromq.org/spec:5>

L<ZMQ::Declare>, L<ZMQ::Declare::Application>, C<ZMQ::Declare::Device>

L<ZeroMQ>

=head1 METHOD-ACCESSIBLE INSTANCE PROPERTIES

=head2 validator

Get/set the validator object that can check a Perl-datastructure ZDCF tree
for structural correctness. Must be a L<ZMQ::Declare::ZDCF::Validator>
object or an object of a derived class. Defaults to a new
C<ZMQ::Declare::ZDCF::Validator> object.

=head2 encoder

Get/set the encoder (decoder) object for turning a text file into a
ZDCF tree in memory and vice versa. Needs to be an object of a class
derived from L<ZMQ::Declare::ZDCF::Encoder>. Defaults to a
L<ZMQ::Declare::ZDCF::Encoder::JSON> object for reading/writing JSON-encoded
ZDCF.

=head2 tree

The actual nested (and untyped) Perl data structure that represents the ZDCF
information. See the documentation for the constructor for details on what
data is valid to supply to the constructor for this property.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
