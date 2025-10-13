# SPDX-License-Identifier: MIT

package Win32::Pipe::PP;

# ABSTRACT: Pure Perl Win32::Pipe drop-in replacement using Win32::API

# -----------
# Boilerplate
# -----------

use strict;
use warnings;

# version '...'
our $version = '0.026';
our $VERSION = 'v0.1.1';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'cpan:JDB';
our $AUTHORITY = 'cpan:BRICKPOOL';

# ------------
# Used Modules
# ------------

use Carp qw( croak );
use Win32;
use Win32::API;
use Win32API::File qw(
  :FILE_ATTRIBUTE_
  :FILE_FLAG_
  :FILE_SHARE_
  :Func
  :GENERIC_
  :Misc
);

# -------
# Imports
# -------

my $ConnectNamedPipe;
my $CreateNamedPipeA;
my $DisconnectNamedPipe;
my $FlushFileBuffers;
my $WaitNamedPipeA;
BEGIN {
  $ConnectNamedPipe = Win32::API::More->new('Kernel32',
    'BOOL ConnectNamedPipe(
      HANDLE hNamedPipe,
      LPVOID lpOverlapped
    )'
  ) or die "Import ConnectNamedPipe: $^E";

  $CreateNamedPipeA = Win32::API::More->new('Kernel32',
    'HANDLE CreateNamedPipeA(
      LPCSTR lpName,
      DWORD  dwOpenMode,
      DWORD  dwPipeMode,
      DWORD  nMaxInstances,
      DWORD  nOutBufferSize,
      DWORD  nInBufferSize,
      DWORD  nDefaultTimeOut,
      LPVOID lpSecurityAttributes
    )'
  ) or die "Import CreateNamedPipeA: $^E";

  $DisconnectNamedPipe = Win32::API::More->new('Kernel32',
    'BOOL DisconnectNamedPipe(
      HANDLE hNamedPipe
    )'
  ) or die "Import DisconnectNamedPipe: $^E";

  $FlushFileBuffers = Win32::API::More->new('Kernel32',
    'BOOL FlushFileBuffers(
      HANDLE hFile
    )'
  ) or die "Import FlushFileBuffers: $^E";

  $WaitNamedPipeA = Win32::API::More->new('Kernel32',
    'BOOL WaitNamedPipeA(
      LPCSTR lpNamedPipeName,
      DWORD  nTimeOut
    )'
  ) or die "Import WaitNamedPipeA: $^E";
}

# -------
# Exports
# -------

use Exporter qw( import );

our @EXPORT = qw(
  DEFAULT_WAIT_TIME
);

# ---------
# Constants
# ---------

# Exportable constants
use constant {
  DEFAULT_WAIT_TIME => 10000,
};

# Windows system error codes
use constant {
  ERROR_INVALID_HANDLE     => 6,
  ERROR_WRITE_FAULT        => 29,
  ERROR_NOT_SUPPORTED      => 50,
  ERROR_INVALID_PARAMETER  => 87,
  ERROR_BROKEN_PIPE        => 109,
  ERROR_PIPE_BUSY          => 231,
  ERROR_NO_DATA            => 232,
  ERROR_PIPE_NOT_CONNECTED => 233,
  ERROR_MORE_DATA          => 234,
  ERROR_PIPE_CONNECTED     => 535,
};

# Windows pipe constants
use constant {
  PIPE_UNLIMITED_INSTANCES => 255,
  PIPE_ACCESS_DUPLEX       => 0x00000003,
  PIPE_TYPE_BYTE           => 0x00000000,
  PIPE_READMODE_BYTE       => 0x00000000,
  PIPE_WAIT                => 0x00000000,
};

# Internal pipe constants
use constant {
  PIPE_NAME_PREFIX => '\\\\.\\pipe\\',
  PIPE_NAME_SIZE   => 256,
  BUFFER_SIZE      => 512,
};

# ---------
# Variables
#----------

# Internal error state
our $ErrorNum  = 0;
our $ErrorText = '';

# ----------------------
# Constructor/Destructor
# ----------------------

sub new {
  my ($class, $name, $wait) = @_;
  croak qq(usage: new(\$class, \$name, \$wait);\n) 
    unless @_ >= 2 && @_ <= 3 && $class;

  $wait = DEFAULT_WAIT_TIME unless defined $wait;

  if (length $name >= PIPE_NAME_SIZE) {
    ($ErrorNum, $ErrorText) = (ERROR_INVALID_PARAMETER, 
      "Pipe Name is too long");
    return;
  }


  my $self = {
    hPipe       => 0,
    bufferSize  => BUFFER_SIZE,
    pipeType    => '',
    errorNum    => 0,
    errorText   => '',
  };

  ($ErrorNum, $ErrorText) = (0, '');
  if ($name =~ /^\\\\/) {
    if (length $name <= length PIPE_NAME_PREFIX) {
      ($ErrorNum, $ErrorText) 
        = (ERROR_INVALID_PARAMETER, "Pipe Name is too short");
      return;
    }

    # CLIENT: full path like \\.\pipe\ -> use CreateFile
    $self->{pipeType} = 'CLIENT';

    while (1) {
      my $hPipe = CreateFile(
        $name,
        GENERIC_READ | GENERIC_WRITE, 
        FILE_SHARE_READ	| FILE_SHARE_WRITE,
        [],
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH,
        []
      );

      # Success -> break
      if ($hPipe && $hPipe != INVALID_HANDLE_VALUE) {
        $self->{hPipe} = $hPipe;
        last;
      }

      my $err = Win32::GetLastError();
      
      # Wait/retry when all instances are busy
      if ($err == ERROR_PIPE_BUSY) {
        next if $WaitNamedPipeA->Call($name, $wait);    # retry
      }

      # Error -> return
      ($ErrorNum, $ErrorText) = ($err, "CreateFile failed");
      return;
    }
  }
  else {
    unless (length $name) {
      ($ErrorNum, $ErrorText)
        = (ERROR_INVALID_PARAMETER, "Pipe Name cannot be empty");
      return;
    }

    # SERVER: logical name without \\.\pipe\ -> prefix and CreateNamedPipe
    $self->{pipeType} = 'SERVER';

    my $full = PIPE_NAME_PREFIX . $name;

    my $hPipe = $CreateNamedPipeA->Call(
      $full,
      PIPE_ACCESS_DUPLEX,
      PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
      PIPE_UNLIMITED_INSTANCES,
      $self->{bufferSize},
      $self->{bufferSize},
      $wait, 
      undef
    );

    unless ($hPipe && $hPipe != INVALID_HANDLE_VALUE) {
      ($ErrorNum, $ErrorText)
        = (Win32::GetLastError(), "CreateNamedPipe failed");
      return;
    }

    $self->{hPipe} = $hPipe;
  }

  bless $self, $class;
}

sub DESTROY {
  my ($self) = @_;
  $self->Close();
  return;
}

# -------------------
# Subroutines/Methods
#--------------------

# Read and Write methods
sub Write {
  my ($self, $data) = @_;
  croak "usage: Write(\$pipe, \$data);\n" unless @_ == 2 && ref $self;

  # Reset last error state for this call
  ($self->{errorNum}, $self->{errorText}) = (0, '');

  # Validate handle
  my $hPipe = $self->{hPipe} || 0;
  unless ($hPipe && $hPipe != INVALID_HANDLE_VALUE) {
    ($self->{errorNum}, $self->{errorText}) 
      = (ERROR_INVALID_HANDLE, "Write failed: invalid handle");
    return;
  }

  # Treat undef or empty string as a successful no-op (like WriteFile)
  return 1 unless defined $data && length($data);

  my $bufsize = $self->{bufferSize} || BUFFER_SIZE;
  my $len     = length($data);
  my $total   = 0;

  while ($total < $len) {
    # Send at most bufferSize per call to avoid blocking on small pipe buffers
    my $to_send = $len - $total;
    $to_send = $bufsize if $to_send > $bufsize;

    my $chunk   = substr($data, $total, $to_send);
    my $written = 0;

    my $r = WriteFile($hPipe, $chunk, $to_send, $written, []);

    if (!$r) {
      my $err = Win32::GetLastError();

      # Common "peer closed" / "not connected" cases -> report clearly
      if ( $err == ERROR_BROKEN_PIPE
        || $err == ERROR_NO_DATA
        || $err == ERROR_PIPE_NOT_CONNECTED
      ) {
        ($self->{errorNum}, $self->{errorText}) 
          = ($err, "Write failed: peer closed/not connected");
      } else {
        ($self->{errorNum}, $self->{errorText}) 
          = ($err, "Write failed");
      }
      return;
    }

    # Safety: successful call should advance unless zero-length write
    if ($written == 0 && $to_send > 0) {
      ($self->{errorNum}, $self->{errorText}) 
        = (ERROR_WRITE_FAULT, "WriteFile wrote 0 bytes unexpectedly");
      return;
    }

    $total += $written;
  }

  return 1;
}

sub Read {
  my ($self) = @_;
  croak "usage: Read(\$pipe)\n" unless @_ == 1 && ref $self;

  # Reset last error state for this call
  ($self->{errorNum}, $self->{errorText}) = (0, '');

  # Validate handle
  my $hPipe = $self->{hPipe} || 0;
  unless ($hPipe && $hPipe != INVALID_HANDLE_VALUE) {
    ($self->{errorNum}, $self->{errorText}) 
      = (ERROR_INVALID_HANDLE, "Write failed");
    return;
  }

  my $bufsize = $self->{bufferSize} || BUFFER_SIZE;

  my $data   = '';
  my $chunk  = "\0" x $bufsize;  # pre-allocate buffer
  my $read   = 0;

  while (1) {
    my $r = ReadFile($self->{hPipe}, $chunk, $bufsize, $read, []);

    if ($r) {
      # Successful read; $read may be 0 (EOF/peer closed).
      if ($read == 0) {
        # No more data; return what we have
        return $data;
      }
      # Append only the bytes actually read
      $data .= substr($chunk, 0, $read);
      last;
    }
    else {
      my $err = Win32::GetLastError();

      if ($err == ERROR_MORE_DATA) {
        # Partial message: append what we got and continue reading the rest
        $data .= substr($chunk, 0, $read) if $read;
        next;
      }
      elsif ($err == ERROR_BROKEN_PIPE || $err == ERROR_PIPE_NOT_CONNECTED) {
        # Peer closed while reading: return data collected so far
        last;
      }
      else {
        # Genuine error
        ($self->{errorNum}, $self->{errorText}) = ($err, "Read failed");
        return;
      }
    }
  }

  return $data;
}

# Internal error handling
sub Error {
  my ($self) = @_;
  croak "usage: Error([\$pipe]);\n" if @_ > 1;

  my ($no, $msg);
  if (ref $self) {
    ($no, $msg) = ($self->{errorNum}, $self->{errorText});
  } else {
    ($no, $msg) = ($ErrorNum, $ErrorText);
  }
  return wantarray ? ($no, $msg) : qq([$no] "$msg");
}

# Connect, Disconnect and Close methods
sub Close {
  my ($self) = @_;
  croak "usage: Close(\$pipe);\n" unless @_ == 1 && ref $self;

  # Reset last error state for this call
  ($self->{errorNum}, $self->{errorText}) = (0, '');

  # already closed -> success (no-op)
  return 1 unless $self->{hPipe} && $self->{hPipe} != INVALID_HANDLE_VALUE;

  $self->Disconnect(1);
  # We don't abort on disconnect failure; 
  # we'll still attempt to close the handle if it remains valid.

  # If a handle is still present (SERVER case), close it now.
  if ($self->{hPipe} && $self->{hPipe} != INVALID_HANDLE_VALUE) {
    my $r = CloseHandle($self->{hPipe});
    if (!$r) {
      my $err = Win32::GetLastError();

      # Treat "already closed" as success; otherwise record and fail
      if ($err != ERROR_INVALID_HANDLE) {
        ($ErrorNum, $ErrorText) = ($err, "CloseHandle failed");
        # Prevent accidental reuse
        $self->{hPipe} = 0;
        return;
      }
    }
    $self->{hPipe} = 0;
  }

  # If we get here, the handle is closed
  return 1;
}

sub Connect {
  my ($self) = @_;
  croak "usage: Connect(\$pipe);\n" unless @_ == 1 && ref $self;

  my $r = $ConnectNamedPipe->Call($self->{hPipe}, undef);
	if (!$r) {
    my $err = Win32::GetLastError();
    # Treat "already connected" as success
    unless ($err == ERROR_PIPE_CONNECTED) {
      ($self->{errorNum}, $self->{errorText}) = ($err, "Connect failed");
      return;
    }
	}
  return 1;
}

sub Disconnect {
  my ($self, $purge) = @_;
  croak "usage: Disconnect(\$pipe [, \$purge]);\n"
    unless @_ >= 1 && @_ <= 2 && ref $self;

  # Clear last error for this operation
  ($self->{errorNum}, $self->{errorText}) = (0, '');

  my $hPipe = $self->{hPipe} || 0;

  # already closed/disconnected handle -> success (no-op)
  return 1 if !$hPipe || $hPipe == INVALID_HANDLE_VALUE;

  # Optional flush before disconnect.
  if ($purge) {
    my $r = $FlushFileBuffers->Call($hPipe);
    if (!$r) {
      my $err = Win32::GetLastError();
      # Tolerate common benign cases; still proceed to disconnect/close.
      if ($err != ERROR_INVALID_HANDLE
        && $err != ERROR_BROKEN_PIPE
        && $err != ERROR_NOT_SUPPORTED
      ) {
        # Record the error but do not abort the disconnect step.
        ($self->{errorNum}, $self->{errorText}) 
          = ($err, "FlushFileBuffers failed");
      }
    }
  }

  SWITCH: for ($self->{pipeType} || '') {
    /SERVER/ and do {
      # Disconnect instance but keep the handle for future Connect()
      my $r = $DisconnectNamedPipe->Call($hPipe);
      if (!$r) {
        my $err = Win32::GetLastError();
        # Treat "already disconnected" as success
        unless ($err == ERROR_PIPE_NOT_CONNECTED) {
          ($self->{errorNum}, $self->{errorText}) 
            = ($err, "DisconnectNamedPipe failed");
          return;
        }
      }
      last;
    };

    /CLIENT/ and do {
      # Close the handle and clear it
      my $r = CloseHandle($hPipe);
      if (!$r) {
        my $err = Win32::GetLastError();
        # Treat "already closed" as success
        unless ($err == ERROR_INVALID_HANDLE) {
          ($self->{errorNum}, $self->{errorText})
            = ($err, "CloseHandle failed");
          return;
        }
      }
      $self->{hPipe} = 0;
      last;
    };

    DEFAULT: {
      ($self->{errorNum}, $self->{errorText}) 
        = (ERROR_NOT_SUPPORTED, "Disconnect failed");
      return;
    }
  }

  return 1;
}

# Buffer management
sub BufferSize {
  my ($self, $size) = @_;
  croak "usage: BufferSize(\$pipe);\n" unless @_ == 1 && ref $self;

  return 0+$self->{bufferSize};
}

sub ResizeBuffer {
  my ($self, $size) = @_;
  croak "usage: ResizeBuffer(\$pipe, \$size);\n" unless @_ == 2 && ref $self;

  $self->{bufferSize} = 0+$size;
  return 1;
}

# Meta methods
sub Info {
  return (
    'Win32::Pipe::PP', 
    $VERSION, 
    '2025',
    $AUTHORITY,
    '',
    '', 
    'Dave Roth <rothd@roth.net>'
  );
}
sub Credit { ... }
sub Center { ... }

# Win32::IPC support
sub get_Win32_IPC_HANDLE {
  my ($self) = @_;
  return INVALID_HANDLE_VALUE unless ref $self && defined $self->{handle};
  return $self->{handle};
}

{
  package    # hide from CPAN
    Win32::Pipe;
  no strict 'refs';
  no warnings 'redefine';
  *new          = \&Win32::Pipe::PP::new;
  *DESTROY      = \&Win32::Pipe::PP::DESTROY;
  *Write        = \&Win32::Pipe::PP::Write;
  *Read         = \&Win32::Pipe::PP::Read;
  *Error        = \&Win32::Pipe::PP::Error;
  *Close        = \&Win32::Pipe::PP::Close;
  *Connect      = \&Win32::Pipe::PP::Connect;
  *Disconnect   = \&Win32::Pipe::PP::Disconnect;
  *BufferSize   = \&Win32::Pipe::PP::BufferSize;
  *ResizeBuffer = \&Win32::Pipe::PP::ResizeBuffer;
  *Info         = \&Win32::Pipe::PP::Info;
  *Credit       = \&Win32::Pipe::PP::Credit
                    unless defined \&Win32::Pipe::Credit;
  *Center       = \&Win32::Pipe::PP::Center
                    unless defined \&Win32::Pipe::Center;
  *get_Win32_IPC_HANDLE = \&Win32::Pipe::PP::get_Win32_IPC_HANDLE;
}

1;

__END__

=head1 NAME

Win32::Pipe::PP - Pure Perl replacement for Win32::Pipe using Win32::API

=head1 SYNOPSIS

  use Win32::Pipe::PP;
  my $server = Win32::Pipe->new($name) or die ''.Win32::Pipe::Error();
  $server->Connect() or die ''.Win32::Pipe->Error();
  ...
  $client->Write("Hello");
  my $data = $server->Read();
  $server->Disconnect;

=head1 DESCRIPTION

This module provides a pure Perl implementation of L<Win32::Pipe> using 
L<Win32::API>. It is designed as a drop-in replacement for the XS-based version, 
with API compatibility. Please use the documentation of L<Win32::Pipe>.

=head1 METHODS

=over

=item new

Creates a new pipe object.

=item Read

Reads data from the pipe.

=item Write

Writes data to the pipe.

=item Error

Returns the last error code.

=item Close

Closes the named pipe.

=item Connect

Create the instance and connects the named pipe.

=item Disconnect

Disconnects the instance of the named pipe.

=item BufferSize

Returns the current buffer size.

=item ResizeBuffer

Resizes the internal buffer.

=item Info

Returns a array with internal metadata.

=item get_Win32_IPC_HANDLE

Returns the raw handle for IPC integration.

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 LICENSE

MIT License - see LICENSE file for full text. However, this library distributes 
and references code from other open source projects that have their own 
licenses.

=head1 CREDITS

Special thanks go to David Roth for creating L<Win32::Pipe>

=cut
