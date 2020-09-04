use File::Basename;

package StreamWrapper;
use Moose;

has 'name' => (is => 'rw');
has 'stream' => (is => 'rw');
has 'file_path' => (is => 'rw');

sub new
{
	my ($class, $name, $stream, $file_path) = @_;

	my $self;

	if(defined($file_path) && length($file_path) > 0)
	{
		$self =
		{
			name   => $file_path
		};
	}
	else
	{
		$self =
		{
			stream => $stream,
			name   => $name
		};
	}

	bless $self, $class;

	return $self;
}

sub get_name
{
	my ($self) = shift;
	return $self->{name};
}

sub get_stream
{
	my ($self) = shift;
	return $self->{stream};
}

=head1 NAME

com::zoho::crm::api::util::StreamWrapper - This class handles the file stream and name.

=head1 DESCRIPTION

=head2 METHODDS

=over 4

=item C<new>

Creates a StreamWrapper class instance with the specified parameters.

Param file_path : A String containing the absolute file path.

=item C<get_name>

This is a getter method to get the file name.

Returns A String representing the file name.

=item C<get_stream>

This is a getter method to get the file input stream.

Returns A InputStream representing the file input stream.

=back

=cut
1;
