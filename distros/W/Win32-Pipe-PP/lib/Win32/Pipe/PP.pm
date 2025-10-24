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
our $VERSION = 'v0.2.2';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'cpan:JDB';
our $AUTHORITY = 'cpan:BRICKPOOL';

# ------------
# Used Modules
# ------------

require bytes;
use Carp qw( croak );
use Win32;
use Win32::API;
use Win32::Event;
use Win32::IPC qw( INFINITE );
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
my $PeekNamedPipe;
my $GetNamedPipeInfo;
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

  $PeekNamedPipe = Win32::API::More->new('Kernel32',
    'BOOL PeekNamedPipe(
      HANDLE  hNamedPipe,
      LPVOID  lpBuffer,
      DWORD   nBufferSize,
      LPDWORD lpBytesRead,
      LPDWORD lpTotalBytesAvail,
      LPDWORD lpBytesLeftThisMessage
    )'
  ) or die "Import PeekNamedPipe: $^E";

  $GetNamedPipeInfo = Win32::API::More->new('Kernel32',
    'BOOL GetNamedPipeInfo(
      HANDLE  hNamedPipe,
      LPDWORD lpFlags,
      LPDWORD lpOutBufferSize,
      LPDWORD lpInBufferSize,
      LPDWORD lpMaxInstances
    )'
  ) or die "Import GetNamedPipeInfo: $^E";
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
  # DEFAULT_WAIT_TIME => INFINITE,
  DEFAULT_WAIT_TIME => 10000,
};

# Windows system error codes
use constant {
  ERROR_INVALID_FUNCTION   => 1,
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
  ERROR_IO_PENDING         => 997,
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
  my ($class, $name, $timeout) = @_;
  croak qq(usage: new(\$class, \$name [, \$timeout]);\n) 
    unless @_ >= 2 && @_ <= 3 && $class;

  $timeout = DEFAULT_WAIT_TIME unless defined $timeout;

  # Reset error state
  _fail(0, '');

  if (length $name >= PIPE_NAME_SIZE) {
    return _fail(ERROR_INVALID_PARAMETER, "Pipe Name is too long");
  }

  my $self = {
    hPipe      => 0,
    bufferSize => BUFFER_SIZE,
    pipeType   => '',
    errorNum   => 0,
    errorText  => '',
    blocking   => 0,
    event      => \0,
  };

  if ($name =~ /^\\\\/) {
    if (length $name <= length PIPE_NAME_PREFIX) {
      return _fail(ERROR_INVALID_PARAMETER, "Pipe Name is too short");
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
        # FILE_FLAG_WRITE_THROUGH on the client: This is not usually necessary 
        # for named pipes; it only reduces throughput and does not help against 
        # blockages. We will omit this flag.
        FILE_ATTRIBUTE_NORMAL,
        []
      );

      # Exit loop on success
      if ($hPipe && $hPipe != INVALID_HANDLE_VALUE) {
        $self->{hPipe} = 0+$hPipe;
        last;
      }

      my $err = Win32::GetLastError();
      
      # Wait/retry when all instances are busy
      if ($err == ERROR_PIPE_BUSY) {
        next if $WaitNamedPipeA->Call($name, $timeout);    # retry
      }

      # Return on error
      return _fail($err, "CreateFile failed");
    }
  }
  else {
    unless (length $name) {
      return _fail(ERROR_INVALID_PARAMETER, "Pipe Name cannot be empty");
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
      $timeout, 
      undef
    );

    unless ($hPipe && $hPipe != INVALID_HANDLE_VALUE) {
      return _fail(Win32::GetLastError(), "CreateNamedPipe failed");
    }

    $self->{hPipe} = $hPipe;
  }

  my $event = Win32::Event->new();
  unless ($event && $$event && $$event != INVALID_HANDLE_VALUE) {
    return _fail(Win32::GetLastError(), "CreateEvent failed");
  }
  $self->{event} = $event;

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
  $self->_fail(0, '');

  # Treat undef or empty string as a successful no-op (like WriteFile)
  return 1 unless defined $data && length($data);

  my $bufsize = $self->{bufferSize} || BUFFER_SIZE;
  my $len     = length($data);
  my $total   = 0;

  while ($total < $len) {
    # Send at most bufferSize per call to avoid blocking on small pipe buffers
    my $to_send = $len - $total;
    $to_send = $bufsize if $to_send > $bufsize;

    my $chunk   = bytes::substr($data, $total, $to_send);
    my $written = 0;

    Win32::SetLastError(0);
    my $r = WriteFile($self->{hPipe}, $chunk, $to_send, $written, []);

    if (!$r) {
      my $err = Win32::GetLastError();

      # Common "peer closed" / "not connected" cases -> report clearly
      if ( $err == ERROR_BROKEN_PIPE
        || $err == ERROR_NO_DATA
        || $err == ERROR_PIPE_NOT_CONNECTED
      ) {
        return $self->_fail($err, "Write failed: peer closed/not connected");
      }
      return $self->_fail($err, "Write failed");
    }

    # Safety: successful call should advance unless zero-length write
    if ($written == 0 && $to_send > 0) {
      return $self->_fail(ERROR_WRITE_FAULT, 
        "WriteFile wrote 0 bytes unexpectedly");
    }

    $total += $written;
  }

  return 1;
}

sub Read {
  my ($self) = @_;
  croak "usage: Read(\$pipe)\n" unless @_ == 1 && ref $self;

  # Reset last error state for this call
  $self->_fail(0, '');

  my $bufsize = $self->{bufferSize} || BUFFER_SIZE;

  my $data  = '';
  my $read  = 0;

  unless ($self->{blocking}) {
    # Mode: non-blocking
    if ($self->get_Win32_IPC_HANDLE() == INVALID_HANDLE_VALUE) {
      return $self->_fail(ERROR_INVALID_HANDLE, "ResetEvent failed");
    }

    my $avail = 0;
    my $r = $PeekNamedPipe->Call($self->{hPipe}, undef, 0, undef, $avail, 
      undef);
    if (!$r) {
      return $self->_fail(Win32::GetLastError(), "PeekNamedPipe failed");
    }

    if ($avail == 0) {
      # Valid, but zero bytes: fast return
      return '';
    } 
    elsif ($avail < $bufsize) {
      # If necessary, adjust the buffer size to the expected message size
      $bufsize = $avail;
    }
    $self->{event}->set();
  }

  while (length($data) < $bufsize) {
    my $remaining  = $bufsize - length($data);
    my $chunk_size = $remaining > $bufsize ? $bufsize : $remaining;
    my $chunk = "\0" x $chunk_size;    # pre-allocate buffer

    Win32::SetLastError(0);
    my $r = ReadFile($self->{hPipe}, $chunk, $chunk_size, $read, []);
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

    my $err = Win32::GetLastError();
    if ($err == ERROR_MORE_DATA) {
      # Partial message: append what was received and read the rest, 
      # or leave the loop immediately in non-blocking mode
      $data .= bytes::substr($chunk, 0, $read) if $read;
      $self->{blocking} ? next : last;
    }

    # Error
    if ( $err == ERROR_BROKEN_PIPE
      || $err == ERROR_NO_DATA
      || $err == ERROR_PIPE_NOT_CONNECTED
    ) {
      # Peer closed while reading: return data collected so far
      return $self->_fail($err, "Read failed: peer closed/not connected");
    } 
    # Genuine error
    return $self->_fail($err, "Read failed");
  }

  unless ($self->{blocking}) {
    # After reading: check whether data is still there
    my $avail = 0;
    my $r = $PeekNamedPipe->Call($self->{hPipe}, undef, 0, undef, $avail, 
      undef);
    if (!$r) {
      return $self->_fail(Win32::GetLastError(), "PeekNamedPipe failed");
    }
    # Data still available: Set event
    $self->{event}->set() if $avail > 0;
  }

  return $data;
}

# Internal error handling
sub Error {
  my ($self) = @_;
  croak "usage: Error([\$class | \$pipe]);\n" if @_ > 1;

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
  $self->_fail(0, '');

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
    # Success scenarios (asynchronous/timing):
    return 1 if $err == ERROR_PIPE_CONNECTED;  # Client was faster
    return 1 if $err == ERROR_IO_PENDING;      # Overlapped pending
    return $self->_fail($err, "Connect failed");
	}
  return 1;
}

sub Disconnect {
  my ($self, $purge) = @_;
  croak "usage: Disconnect(\$pipe [, \$purge]);\n"
    unless @_ >= 1 && @_ <= 2 && ref $self;

  # Clear last error for this operation
  $self->_fail(0, '');

  my $hPipe = $self->{hPipe} || 0;

  # already closed/disconnected handle -> success (no-op)
  return 1 if !$hPipe || $hPipe == INVALID_HANDLE_VALUE;

  # Optional flush before disconnect.
  if ($purge) {
    my $r = $FlushFileBuffers->Call($hPipe);
    if (!$r) {
      my $err = Win32::GetLastError();
      # Tolerate common benign cases; still proceed to disconnect/close.
      if ( $err != ERROR_INVALID_HANDLE
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
  return $self->{bufferSize};
}

sub ResizeBuffer {
  my ($self, $size) = @_;
  croak "usage: ResizeBuffer(\$pipe, \$size);\n" unless @_ == 2 && ref $self;
  $size += 0;

  # Buffer sizes are only advisory values in CreateNamedPipe anyway and are 
  # specified during creation.
  my ($in, $out) = (0, 0);
  unless ($GetNamedPipeInfo->Call($self->{hPipe}, undef, $out, $in, undef)) {
    return _fail(Win32::GetLastError(), "GetNamedPipeInfo failed");
  }

  # TODO: ResizeBuffer() is only implemented correctly if you re-instantiate 
  # when necessary (e.g., if the kernel buffer is too small) – because the 
  # kernel buffer size cannot be changed dynamically. 
  $size = $out if $size > $out;
  $size = $in  if $size > $in;
  $self->{bufferSize} = $size;
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

# Extensions

sub blocking {
  my ($self, $value) = @_;
  croak "usage: blocking(\$pipe [, \$value]);\n" 
    unless @_ >= 1 && @_ <= 2 && ref $self;
  if (@_ == 2) {
    $self->{blocking} = $value ? 1 : 0;
  }
  return $self->{blocking};
}

# Wait for Win32::Event to be signalled. See Win32::IPC.
sub wait {
  my ($self, $timeout) = @_;
  croak "usage: wait(\$pipe [, \$timeout]);\n" 
    unless @_ >= 1 && @_ <= 2 && ref $self;

  $timeout = INFINITE unless defined $timeout;

  # Reset last error state for this call
  $self->_fail(0, '');

  if ($self->{blocking}) {
    return $self->_fail(ERROR_INVALID_FUNCTION, "SetEvent failed");
  }
  if ($self->get_Win32_IPC_HANDLE() == INVALID_HANDLE_VALUE) {
    return $self->_fail(ERROR_INVALID_HANDLE, "WaitForSingleObject failed");
  }

  my $start = Win32::GetTickCount();
  my $wait = 50;
  while (1) {
    my $avail = 0;
    my $r = $PeekNamedPipe->Call($self->{hPipe}, undef, 0, undef, $avail, 
      undef);
    if (!$r) {
      # An error occurred
      return $self->_fail(Win32::GetLastError(), "PeekNamedPipe failed");
    }
    if ($avail > 0) {
      # Signal external listeners und exit
      $self->{event}->set();
      return 1;
    }

    unless ($timeout == INFINITE) {
      # Exit the loop when the time is elapsed
      my $elapsed = Win32::GetTickCount() - $start;
      last if $elapsed >= $timeout;

      # Adjust wait time if less than 50 ms remain
      my $remaining = $timeout - $elapsed;
      $wait = $remaining if $remaining < 50;
    }

    # Waiting for external signal (max 50ms)
    last if $self->{event}->wait($wait);
  }

  return 0;
}

# Win32::IPC support
sub get_Win32_IPC_HANDLE {
  my ($self) = @_;
  my $hEvent = ${$self->{event}} if ref $self && $self->{event};
  return INVALID_HANDLE_VALUE unless defined $hEvent;
  return $hEvent;
}

# Private Methods
sub _fail {
  if (@_ == 3 && ref $_[0]) {
    my $self = shift;
    ($self->{errorNum}, $self->{errorText}) = @_;
    Win32::SetLastError($^E = $self->{errorNum});
  } 
  elsif (@_ == 2) {
    ($ErrorNum, $ErrorText) = @_;
    Win32::SetLastError($^E = $ErrorNum);
  }
  return;
}

{
  package    # hide from CPAN
    Win32::Pipe;
  no warnings;
  if ($ENV{WIN32_PIPE_IMPLEMENTATION} ne 'XS') {
    our @ISA = qw( Win32::Pipe::PP );
    no strict 'refs';
    *Error       = \&Win32::Pipe::PP::Error;
    *BUFFER_SIZE = \&Win32::Pipe::PP::BUFFER_SIZE;
  }
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

=item wait

Wait for Read to be signalled. See L<Win32::IPC>.

=item get_Win32_IPC_HANDLE

Returns the raw handle for L<Win32::IPC> integration.

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
