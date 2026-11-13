package Twilio::Http::File;

use 5.016;
use warnings;

use Carp           qw(croak);
use File::Basename qw(basename);
use Scalar::Util   qw(openhandle);

our $VERSION = '2.001';

sub new {
  my ($class, $file_name, $contents, $content_type) = @_;

  croak 'A file needs a name'                     if !defined $file_name || !length $file_name;
  croak 'A content type cannot hold a line break' if ($content_type // q{}) =~ /[\r\n]/;
  croak 'File contents must be a string or an open filehandle'
    if ref $contents && !openhandle($contents);

  return bless { file_name => $file_name, contents => $contents, content_type => $content_type },
    $class;
}

sub get_file_name    { return $_[0]{file_name} }
sub get_contents     { return $_[0]{contents} }
sub get_content_type { return $_[0]{content_type} }

# A file read from disk is sent under its own name, without the folders it was in.
sub upload_name {
  my ($self) = @_;
  return defined $self->{contents} ? $self->{file_name} : basename($self->{file_name});
}

# Read once and kept: a request is built again for each retry after a 429, and a filehandle
# would be empty by the second one.
sub bytes {
  my ($self) = @_;
  $self->{bytes} //= $self->_read;
  return $self->{bytes};
}

sub _read {
  my ($self) = @_;

  my $contents = $self->{contents};
  my $bytes =
     !defined $contents ? _slurp_path($self->{file_name})
    : ref $contents     ? _slurp_handle($contents)
    :                     $contents;

  # Guessing an encoding for text would change what the caller meant to send.
  utf8::downgrade($bytes, 1) or croak 'File contents must be bytes: encode text before sending it';
  return $bytes;
}

sub _slurp_path {
  my ($path) = @_;
  open my $handle, '<:raw', $path or croak "Cannot read '$path': $!";
  my $bytes = _slurp_handle($handle);
  close $handle or croak "Cannot read '$path': $!";
  return $bytes;
}

sub _slurp_handle {
  my ($handle) = @_;
  local $/ = undef;
  my $bytes = readline $handle;
  return $bytes // q{};
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::Http::File - A file to upload in a form

=head1 SYNOPSIS

  use Twilio::Http::File;

  my $inquiry = $client->trusthub->v1->compliance_registration_inquiries->create(
    $end_user_type, $phone_number_type,
    {
      file      => Twilio::Http::File->new('/path/to/license.pdf', undef, 'application/pdf'),
      file_name => 'license.pdf',
    }
  );

=head1 DESCRIPTION

A form value that is a C<Twilio::Http::File> sends the whole request body as
C<multipart/form-data>, with the file as one part and every other value as a
part of its own. See L<Twilio::Http::Client/request>.

Twilio's API descriptions don't say which values take a file, so the generated
documentation describes them as text. Trusthub's
C<compliance_registration_inquiries> is the one that twilio-php uploads.

=head1 METHODS

=head2 new

  my $file = Twilio::Http::File->new($file_name);
  my $file = Twilio::Http::File->new($file_name, $contents, $content_type);

With only a name, the file is read from that path when the request is sent, and
only its base name is sent. With C<$contents>, a string of bytes or an open
filehandle, C<$file_name> is the name sent as it is. The contents are read once
and kept, so a retried request sends the same file.

C<$content_type> is optional. Without it, the part is sent as
C<application/octet-stream>.

=head2 get_file_name

Returns the name given to L</new>.

=head2 get_contents

Returns the contents given to L</new>, or nothing for a file read from a path.

=head2 get_content_type

Returns the content type given to L</new>, if any.

=head2 upload_name

Returns the name sent with the file.

=head2 bytes

Returns the bytes sent. Text with characters above 255 dies: encode it first,
for example with C<Encode::encode('UTF-8', $text)>.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
