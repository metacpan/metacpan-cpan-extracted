package Venus::Os;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base';

# INHERITS

base 'Venus::Kind::Utility';

use Encode ();

our %TYPES;

# BUILDERS

sub build_arg {
  my ($self) = @_;

  return {};
}

# HOOKS

sub _exitcode {
  $? >> 8;
}

sub _open {
  CORE::open(shift, shift, shift);
}

sub _osname {
  $TYPES{$^O} || $^O
}

sub _system {
  local $SIG{__WARN__} = sub {};
  CORE::system(@_) or return 0;
}

# METHODS

sub call {
  my ($self, $name, @args) = @_;

  return if !$name;

  require Venus::Path;

  my $which = $self->which($name);

  return if !$which;

  my $path = Venus::Path->new($which);

  my $expr = join ' ', @args;

  return $path->try('mkcall')->maybe->result($expr || ());
}

sub find {
  my ($self, $name, @paths) = @_;

  return if !$name;

  require File::Spec;

  return [$name] if File::Spec->splitdir($name) > 1;

  my $result = [grep -f, map File::Spec->catfile($_, $name), @paths];

  return wantarray ? @{$result} : $result;
}

sub is_bsd {

  return true if lc(_osname()) eq 'freebsd';
  return true if lc(_osname()) eq 'openbsd';

  return false;
}

sub is_cyg {

  return true if lc(_osname()) eq 'cygwin';
  return true if lc(_osname()) eq 'msys';

  return false;
}

sub is_dos {

  return true if is_win();

  return false;
}

sub is_lin {

  return true if lc(_osname()) eq 'linux';

  return false;
}

sub is_mac {

  return true if lc(_osname()) eq 'macos';
  return true if lc(_osname()) eq 'darwin';

  return false;
}

sub is_non {

  return false if is_bsd();
  return false if is_cyg();
  return false if is_dos();
  return false if is_lin();
  return false if is_mac();
  return false if is_sun();
  return false if is_vms();
  return false if is_win();

  return true;
}

sub is_sun {

  return true if lc(_osname()) eq 'solaris';
  return true if lc(_osname()) eq 'sunos';

  return false;
}

sub is_vms {

  return true if lc(_osname()) eq 'vms';

  return false;
}

sub is_win {

  return true if lc(_osname()) eq 'mswin32';
  return true if lc(_osname()) eq 'dos';
  return true if lc(_osname()) eq 'os2';

  return false;
}

sub name {
  my ($self) = @_;

  my $name = _osname();

  return $name;
}

sub paths {
  my ($self) = @_;

  require File::Spec;

  my %seen;

  my $result = [grep !$seen{$_}++, File::Spec->path];

  return wantarray ? @{$result} : $result;
}

sub quote {
  my ($self, $data) = @_;

  if (!defined $data) {
    return '';
  }
  elsif ($self->is_win) {
    return ($data =~ /^"/ && $data =~ /"$/)
      ? $data
      : ('"' . (($data =~ s/"/\\"/gr) || "") . '"');
  }
  else {
    return ($data =~ /^'/ && $data =~ /'$/)
      ? $data
      : ("'" . (($data =~ s/'/'\\''/gr) || "") . "'");
  }
}

sub read {
  my ($self, $from) = @_;

  no warnings 'io';

  my $fh;
  my $is_handle = ref($from) eq 'GLOB' || UNIVERSAL::isa($from, 'IO::Handle');
  my $error;

  if ($is_handle) {
    $fh = $from;
    binmode($fh, ':raw') or $error = $!;
    if ($error) {
      $self->error_on_read_binmode({from => $from, error => $error, binmode => ':raw'})
      ->input($self, $from)
      ->output($error)
      ->throw;
    }
    seek($fh, 0, 0) or $error = $!;
    if ($error) {
      $self->error_on_read_seek({filehandle => $fh, error => $error})
      ->input($self, $from)
      ->output($error)
      ->throw;
    }
  }
  else {
    if (!defined $from || $from eq '-' || $from eq 'STDIN') {
      if (!defined(fileno(STDIN))) {
        _open(\*STDIN, '<&', 0) or $error = $!;
        if ($error) {
          $self->error_on_read_open_stdin({error => $error})
          ->input($self, $from)
          ->output($error)
          ->throw;
        }
      }
      $fh = *STDIN;
      binmode($fh, ':raw') or $error = $!;
      if ($error) {
        $self->error_on_read_binmode({from => 'STDIN', error => $error, binmode => ':raw'})
        ->input($self, $from)
        ->output($error)
        ->throw;
      }
    }
    else {
      _open($fh, '<:raw', $from) or $error = $!;
      if ($error) {
        $self->error_on_read_open_file({error => $error, file => $from})
        ->input($self, $from)
        ->output($error)
        ->throw;
      }
    }
  }

  read($fh, my $bom, 4);
  my $encoding;
  my $offset = 0;

  if ($bom =~ /^\xEF\xBB\xBF/) {
    $encoding = 'UTF-8';
    $offset = 3;
  }
  elsif ($bom =~ /^\xFF\xFE\x00\x00/) {
    $encoding = 'UTF-32LE';
    $offset = 4;
  }
  elsif ($bom =~ /^\x00\x00\xFE\xFF/) {
    $encoding = 'UTF-32BE';
    $offset = 4;
  }
  elsif ($bom =~ /^\xFF\xFE/) {
    $encoding = 'UTF-16LE';
    $offset = 2;
  }
  elsif ($bom =~ /^\xFE\xFF/) {
    $encoding = 'UTF-16BE';
    $offset = 2;
  }
  else {
    $encoding = 'UTF-8';
    seek($fh, 0, 0) or $error = $!;
    if ($error) {
      $self->error_on_read_seek_reset({error => $error})
      ->input($self, $from)
      ->output($error)
      ->throw;
    }
  }

  if ($offset > 0) {
    seek($fh, $offset, 0) or $error = $!;
    if ($error) {
      $self->error_on_read_seek({error => $error})
      ->input($self, $from)
      ->output($error)
      ->throw;
    }
  }

  my $raw_content = '';

  while (read($fh, my $chunk, 8192)) {
    $raw_content .= $chunk;
  }

  local $@;

  my $data = eval {
    Encode::decode($encoding, $raw_content, Encode::FB_CROAK);
  };
  if ($@) {
    $data = Encode::decode('ISO-8859-1', $raw_content);
  }

  close $fh if !$is_handle && fileno($fh) != fileno(STDIN);

  $data =~ s/\r\n?/\n/g;

  return $data;
}

sub syscall {
  my ($self, @args) = @_;

  (_system(@args) == 0) or do {
    my $error = $!;
    $self->error_on_system_call({args => [@args], error => $error || _exitcode(), exit_code => _exitcode()})
      ->input($self, @args)
      ->output($error)
      ->throw;
  };

  return $self;
}

sub type {
  my ($self) = @_;

  my @types = qw(
    is_lin
    is_mac
    is_win
    is_bsd
    is_cyg
    is_sun
    is_vms
  );

  my $result = [grep $self->$_, @types];

  return $result->[0] || 'is_non';
}

sub where {
  my ($self, $name) = @_;

  my $result = $self->find($name, $self->paths);

  return wantarray ? @{$result} : $result;
}

sub which {
  my ($self, $name) = @_;

  my $result = $self->where($name);

  return $result->[0];
}

sub write {
  my ($self, $into, $data, $encoding) = @_;

  no warnings 'io';

  $encoding ||= Encode::is_utf8($data) ? 'UTF-8' : 'ISO-8859-1';

  my $fh;
  my $is_handle = ref($into) eq 'GLOB' || UNIVERSAL::isa($into, 'IO::Handle');
  my $error;

  if ($is_handle) {
    $fh = $into;
  }
  else {
    if (!defined $into || $into eq '-' || $into eq 'STDOUT') {
      if (!defined(fileno(STDOUT))) {
        _open(\*STDOUT, '>&', 1) or $error = $!;
        if ($error) {
          $self->error_on_write_open_stdout({error => $error})
          ->input($self, $into, $data, $encoding)
          ->output($error)
          ->throw;
        }
      }
      $fh = \*STDOUT; select($fh); $| = 1;
    }
    elsif ($into eq 'STDERR') {
      if (!defined(fileno(STDERR))) {
        _open(\*STDERR, '>&', 2) or $error = $!;
        if ($error) {
          $self->error_on_write_open_stderr({error => $error})
          ->input($self, $into, $data, $encoding)
          ->output($error)
          ->throw;
        }
      }
      $fh = \*STDERR; select($fh); $| = 1;
    }
    else {
      _open($fh, '>:raw', $into) or $error = $!;
      if ($error) {
        $self->error_on_write_open_file({error => $error, file => $into})
        ->input($self, $into, $data, $encoding)
        ->output($error)
        ->throw;
      }
    }
  }

  if (fileno($fh) == fileno(STDOUT) || fileno($fh) == fileno(STDERR)) {
    binmode($fh, ":raw") or $error = $!;
    if ($error) {
      $self->error_on_write_binmode({from => 'STOUT', error => $error, binmode => ':raw'})
      ->input($self, $into, $data, $encoding)
      ->output($error)
      ->throw;
    }
  }
  else {
    binmode($fh, ':raw') or $error = $!;
    if ($error) {
      $self->error_on_write_binmode({from => $fh, error => $error, binmode => ':raw'})
      ->input($self, $into, $data, $encoding)
      ->output($error)
      ->throw;
    }

    if ($encoding eq 'UTF-8') {
      print $fh "\xEF\xBB\xBF";
    }
    elsif ($encoding eq 'UTF-16LE') {
      print $fh "\xFF\xFE";
    }
    elsif ($encoding eq 'UTF-16BE') {
      print $fh "\xFE\xFF";
    }
    elsif ($encoding eq 'UTF-32LE') {
      print $fh "\xFF\xFE\x00\x00";
    }
    elsif ($encoding eq 'UTF-32BE') {
      print $fh "\x00\x00\xFE\xFF";
    }
  }

  $data = "" if !defined $data;

  if ($self->is_vms || $self->is_win) {
    $data =~ s/(?<!\r)\n/\r\n/g;
  }

  if (fileno($fh) == fileno(STDOUT) || fileno($fh) == fileno(STDERR)) {
    my $encoded_content = Encode::is_utf8($data)
      ? "$data"
      : Encode::encode('UTF-8', $data, Encode::FB_CROAK);
    print $fh $encoded_content;
  }
  else {
    my $encoded_content = Encode::encode($encoding, $data, Encode::FB_CROAK);
    my $chunk_size = 8192;
    my $offset = 0;
    my $length = length($encoded_content);

    while ($offset < $length) {
      my $chunk = substr($encoded_content, $offset, $chunk_size);
      print $fh $chunk;
      $offset += $chunk_size;
    }
  }

  close $fh
    if !$is_handle
    && (fileno($fh) != fileno(STDOUT) && fileno($fh) != fileno(STDERR));

  return $self;
}

# ERRORS

sub error_on_read_binmode {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t binmode on read: {{error}}';

  $error->name('on.read.binmode');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_read_open_file {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t open "{{file}}" for reading: {{error}}';

  $error->name('on.read.open.file');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_read_open_stdin {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t open STDIN for reading: {{error}}';

  $error->name('on.read.open.stdin');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_read_seek {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t seek in filehandle: {{error}}';

  $error->name('on.read.seek');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_read_seek_reset {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t reset seek in filehandle: {{error}}';

  $error->name('on.read.seek.reset');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_system_call {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t make system call "{{command}}": {{error}}';

  $data->{command} = join ' ', @{$data->{args}};

  $error->name('on.system.call');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_write_binmode {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t binmode on write: {{error}}';

  $error->name('on.write.binmode');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_write_open_file {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t open "{{file}}" for writing: {{error}}';

  $error->name('on.write.open.file');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_write_open_stderr {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t open STDERR for writing: {{error}}';

  $error->name('on.write.open.stderr');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

sub error_on_write_open_stdout {
  my ($self, $data) = @_;

  my $error = $self->error->sysinfo;

  my $message = 'Can\'t open STDOUT for writing: {{error}}';

  $error->name('on.write.open.stdout');
  $error->message($message);
  $error->offset(1);
  $error->stash($data);
  $error->reset;

  return $error;
}

1;



=encoding UTF8

=cut

=head1 NAME

Venus::Os - OS Class

=cut

=head1 ABSTRACT

OS Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Os;

  my $os = Venus::Os->new;

  # bless({...}, 'Venus::Os')

  # my $name = $os->name;

  # "linux"

=cut

=head1 DESCRIPTION

This package provides methods for determining the current operating system, as
well as finding and executing files.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 call

  call(string $name, string @args) (any)

The call method attempts to find the path to the program specified via
L</which> and dispatches to L<Venus::Path/mkcall> and returns the result. Any
exception throw is supressed and will return undefined if encountered.

I<Since C<2.80>>

=over 4

=item call example 1

  # given: synopsis

  package main;

  my $app = $os->is_win ? 'perl.exe' : 'perl';

  my $call = $os->call($app, '-V:osname');

  # "osname='linux';"

=back

=over 4

=item call example 2

  # given: synopsis

  package main;

  my $app = $os->is_win ? 'perl.exe' : 'perl';

  my @call = $os->call($app, '-V:osname');

  # ("osname='linux';", 0)

=back

=over 4

=item call example 3

  # given: synopsis

  package main;

  my $call = $os->call('nowhere');

  # undef

=back

=over 4

=item call example 4

  # given: synopsis

  package main;

  my @call = $os->call($^X, '-V:osname');

  # ("osname='linux';", 0)

=back

=over 4

=item call example 5

  # given: synopsis

  package main;

  my @call = $os->call($^X, 't/data/sun');

  # ("", 1)

=back

=cut

=head2 find

  find(string $name, string @paths) (arrayref)

The find method searches the paths provided for a file matching the name
provided and returns all the files found as an arrayref. Returns a list in list
context.

I<Since C<2.80>>

=over 4

=item find example 1

  # given: synopsis

  package main;

  my $find = $os->find('cmd', 't/path/user/bin');

  # ["t/path/user/bin/cmd"]

=back

=over 4

=item find example 2

  # given: synopsis

  package main;

  my $find = $os->find('cmd', 't/path/user/bin', 't/path/usr/bin');

  # ["t/path/user/bin/cmd", "t/path/usr/bin/cmd"]

=back

=over 4

=item find example 3

  # given: synopsis

  package main;

  my $find = $os->find('zzz', 't/path/user/bin', 't/path/usr/bin');

  # []

=back

=cut

=head2 is_bsd

  is_bsd() (boolean)

The is_bsd method returns true if the OS is either C<"freebsd"> or
C<"openbsd">, and otherwise returns false.

I<Since C<2.80>>

=over 4

=item is_bsd example 1

  # given: synopsis

  package main;

  # on linux

  my $is_bsd = $os->is_bsd;

  # false

=back

=over 4

=item is_bsd example 2

  # given: synopsis

  package main;

  # on freebsd

  my $is_bsd = $os->is_bsd;

  # true

=back

=over 4

=item is_bsd example 3

  # given: synopsis

  package main;

  # on openbsd

  my $is_bsd = $os->is_bsd;

  # true

=back

=cut

=head2 is_cyg

  is_cyg() (boolean)

The is_cyg method returns true if the OS is either C<"cygwin"> or C<"msys">,
and otherwise returns false.

I<Since C<2.80>>

=over 4

=item is_cyg example 1

  # given: synopsis

  package main;

  # on linux

  my $is_cyg = $os->is_cyg;

  # false

=back

=over 4

=item is_cyg example 2

  # given: synopsis

  package main;

  # on cygwin

  my $is_cyg = $os->is_cyg;

  # true

=back

=over 4

=item is_cyg example 3

  # given: synopsis

  package main;

  # on msys

  my $is_cyg = $os->is_cyg;

  # true

=back

=cut

=head2 is_dos

  is_dos() (boolean)

The is_dos method returns true if the OS is either C<"mswin32"> or C<"dos"> or
C<"os2">, and otherwise returns false.

I<Since C<2.80>>

=over 4

=item is_dos example 1

  # given: synopsis

  package main;

  # on linux

  my $is_dos = $os->is_dos;

  # false

=back

=over 4

=item is_dos example 2

  # given: synopsis

  package main;

  # on mswin32

  my $is_dos = $os->is_dos;

  # true

=back

=over 4

=item is_dos example 3

  # given: synopsis

  package main;

  # on dos

  my $is_dos = $os->is_dos;

  # true

=back

=over 4

=item is_dos example 4

  # given: synopsis

  package main;

  # on os2

  my $is_dos = $os->is_dos;

  # true

=back

=cut

=head2 is_lin

  is_lin() (boolean)

The is_lin method returns true if the OS is C<"linux">, and otherwise returns
false.

I<Since C<2.80>>

=over 4

=item is_lin example 1

  # given: synopsis

  package main;

  # on linux

  my $is_lin = $os->is_lin;

  # true

=back

=over 4

=item is_lin example 2

  # given: synopsis

  package main;

  # on macos

  my $is_lin = $os->is_lin;

  # false

=back

=over 4

=item is_lin example 3

  # given: synopsis

  package main;

  # on mswin32

  my $is_lin = $os->is_lin;

  # false

=back

=cut

=head2 is_mac

  is_mac() (boolean)

The is_mac method returns true if the OS is either C<"macos"> or C<"darwin">,
and otherwise returns false.

I<Since C<2.80>>

=over 4

=item is_mac example 1

  # given: synopsis

  package main;

  # on linux

  my $is_mac = $os->is_mac;

  # false

=back

=over 4

=item is_mac example 2

  # given: synopsis

  package main;

  # on macos

  my $is_mac = $os->is_mac;

  # true

=back

=over 4

=item is_mac example 3

  # given: synopsis

  package main;

  # on darwin

  my $is_mac = $os->is_mac;

  # true

=back

=cut

=head2 is_non

  is_non() (boolean)

The is_non method returns true if the OS is not recognized, and if recognized
returns false.

I<Since C<2.80>>

=over 4

=item is_non example 1

  # given: synopsis

  package main;

  # on linux

  my $is_non = $os->is_non;

  # false

=back

=over 4

=item is_non example 2

  # given: synopsis

  package main;

  # on aix

  my $is_non = $os->is_non;

  # true

=back

=cut

=head2 is_sun

  is_sun() (boolean)

The is_sun method returns true if the OS is either C<"solaris"> or C<"sunos">,
and otherwise returns false.

I<Since C<2.80>>

=over 4

=item is_sun example 1

  # given: synopsis

  package main;

  # on linux

  my $is_sun = $os->is_sun;

  # false

=back

=over 4

=item is_sun example 2

  # given: synopsis

  package main;

  # on solaris

  my $is_sun = $os->is_sun;

  # true

=back

=over 4

=item is_sun example 3

  # given: synopsis

  package main;

  # on sunos

  my $is_sun = $os->is_sun;

  # true

=back

=cut

=head2 is_vms

  is_vms() (boolean)

The is_vms method returns true if the OS is C<"vms">, and otherwise returns
false.

I<Since C<2.80>>

=over 4

=item is_vms example 1

  # given: synopsis

  package main;

  # on linux

  my $is_vms = $os->is_vms;

  # false

=back

=over 4

=item is_vms example 2

  # given: synopsis

  package main;

  # on vms

  my $is_vms = $os->is_vms;

  # true

=back

=cut

=head2 is_win

  is_win() (boolean)

The is_win method returns true if the OS is either C<"mswin32"> or C<"dos"> or
C<"os2">, and otherwise returns false.

I<Since C<2.80>>

=over 4

=item is_win example 1

  # given: synopsis

  package main;

  # on linux

  my $is_win = $os->is_win;

  # false

=back

=over 4

=item is_win example 2

  # given: synopsis

  package main;

  # on mswin32

  my $is_win = $os->is_win;

  # true

=back

=over 4

=item is_win example 3

  # given: synopsis

  package main;

  # on dos

  my $is_win = $os->is_win;

  # true

=back

=over 4

=item is_win example 4

  # given: synopsis

  package main;

  # on os2

  my $is_win = $os->is_win;

  # true

=back

=cut

=head2 name

  name() (string)

The name method returns the OS name.

I<Since C<2.80>>

=over 4

=item name example 1

  # given: synopsis

  package main;

  # on linux

  my $name = $os->name;

  # "linux"

  # same as $^O

=back

=cut

=head2 new

  new(any @args) (Venus::Os)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Os;

  my $new = Venus::Os->new;

  # bless(..., "Venus::Os")

=back

=cut

=head2 paths

  paths() (arrayref)

The paths method returns the paths specified by the C<"PATH"> environment
variable as an arrayref of unique paths. Returns a list in list context.

I<Since C<2.80>>

=over 4

=item paths example 1

  # given: synopsis

  package main;

  my $paths = $os->paths;

  # [
  #   "/root/local/bin",
  #   "/root/bin",
  #   "/usr/local/sbin",
  #   "/usr/local/bin",
  #   "/usr/sbin:/usr/bin",
  # ]

=back

=cut

=head2 quote

  quote(string $data) (string)

The quote method accepts a string and returns the OS-specific quoted version of
the string.

I<Since C<2.91>>

=over 4

=item quote example 1

  # given: synopsis

  package main;

  # on linux

  my $quote = $os->quote("hello \"world\"");

  # "'hello \"world\"'"

=back

=over 4

=item quote example 2

  # given: synopsis

  package main;

  # on linux

  my $quote = $os->quote('hello \'world\'');

  # "'hello '\\''world'\\'''"

=back

=over 4

=item quote example 3

  # given: synopsis

  package main;

  # on mswin32

  my $quote = $os->quote("hello \"world\"");

  # "\"hello \\"world\\"\""

=back

=over 4

=item quote example 4

  # given: synopsis

  package main;

  # on mswin32

  my $quote = $os->quote('hello "world"');

  # '"hello \"world\""'

=back

=cut

=head2 read

  read(any $from) (string)

The read method reads from a file, filehandle, or STDIN, and returns the data.
To read from STDIN provide the string C<"STDIN">. The method defaults to reading from STDIN.

I<Since C<4.15>>

=over 4

=item read example 1

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read;

  # from STDIN

  # "..."

=back

=over 4

=item read example 2

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('STDIN');

  # from STDIN

  # "..."

=back

=over 4

=item read example 3

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/iso-8859-1.txt');

  # from file

  # "Hello, world! This is ISO-8859-1."

=back

=over 4

=item read example 4

  # given: synopsis

  package main;

  # on linux

  open my $fh, '<', 't/data/texts/iso-8859-1.txt';

  my $read = $os->read($fh);

  # from filehandle

  # "Hello, world! This is ISO-8859-1."

=back

=over 4

=item read example 5

  # given: synopsis

  package main;

  # on linux

  use IO::File;

  my $fh = IO::File->new('t/data/texts/iso-8859-1.txt', 'r');

  my $read = $os->read($fh);

  # from filehandle

  # "Hello, world! This is ISO-8859-1."

=back

=over 4

=item read example 6

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-16be.txt');

  # from UTF-16BE encoded file

  # "Hello, world! こんにちは世界！"

=back

=over 4

=item read example 7

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-16le.txt');

  # from UTF-16LE encoded file

  # "Hello, world! こんにちは世界！"

=back

=over 4

=item read example 8

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-32be.txt');

  # from UTF-32BE encoded file

  # "Hello, world! こんにちは世界！"

=back

=over 4

=item read example 9

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-32le.txt');

  # from UTF-32LE encoded file

  # "Hello, world! こんにちは世界！"

=back

=over 4

=item read example 10

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-8.txt');

  # from UTF-8 encoded file

  # "Hello, world! こんにちは世界！"

=back

=over 4

=item B<may raise> L<Venus::Os::Error> C<on.read.open.file>

  # given: synopsis;

  $os->read('/path/to/nowhere');

  # Error! (on.read.open.file)

=back

=cut

=head2 syscall

  syscall(any @data) (Venus::Os)

The syscall method executes the command and arguments provided, via
L<perlfunc/system>, and returns the invocant.

I<Since C<4.15>>

=over 4

=item syscall example 1

  package main;

  use Venus::Os;

  my $os = Venus::Os->new;

  $os->syscall($^X, '--help');

  # bless(..., "Venus::Os")

=back

=over 4

=item syscall example 2

  package main;

  use Venus::Os;

  my $os = Venus::Os->new;

  $os->syscall('.help');

  # Exception! (isa Venus::Os::Error) (see error_on_system_call)

=back

=cut

=head2 type

  type() (string)

The type method returns a string representing the "test" method, which
identifies the OS, that would return true if called, based on the name of the
OS.

I<Since C<2.80>>

=over 4

=item type example 1

  # given: synopsis

  package main;

  # on linux

  my $type = $os->type;

  # "is_lin"

=back

=over 4

=item type example 2

  # given: synopsis

  package main;

  # on macos

  my $type = $os->type;

  # "is_mac"

=back

=over 4

=item type example 3

  # given: synopsis

  package main;

  # on mswin32

  my $type = $os->type;

  # "is_win"

=back

=over 4

=item type example 4

  # given: synopsis

  package main;

  # on openbsd

  my $type = $os->type;

  # "is_bsd"

=back

=over 4

=item type example 5

  # given: synopsis

  package main;

  # on cygwin

  my $type = $os->type;

  # "is_cyg"

=back

=over 4

=item type example 6

  # given: synopsis

  package main;

  # on dos

  my $type = $os->type;

  # "is_win"

=back

=over 4

=item type example 7

  # given: synopsis

  package main;

  # on solaris

  my $type = $os->type;

  # "is_sun"

=back

=over 4

=item type example 8

  # given: synopsis

  package main;

  # on vms

  my $type = $os->type;

  # "is_vms"

=back

=cut

=head2 where

  where(string $file) (arrayref)

The where method searches the paths defined by the C<PATH> environment variable
for a file matching the name provided and returns all the files found as an
arrayref. Returns a list in list context. This method doesn't check (or care)
if the files found are actually executable.

I<Since C<2.80>>

=over 4

=item where example 1

  # given: synopsis

  package main;

  my $where = $os->where('cmd');

  # [
  #   "t/path/user/local/bin/cmd",
  #   "t/path/user/bin/cmd",
  #   "t/path/usr/bin/cmd",
  #   "t/path/usr/local/bin/cmd",
  #   "t/path/usr/local/sbin/cmd",
  #   "t/path/usr/sbin/cmd"
  # ]

=back

=over 4

=item where example 2

  # given: synopsis

  package main;

  my $where = $os->where('app1');

  # [
  #   "t/path/user/local/bin/app1",
  #   "t/path/usr/bin/app1",
  #   "t/path/usr/sbin/app1"
  # ]

=back

=over 4

=item where example 3

  # given: synopsis

  package main;

  my $where = $os->where('app2');

  # [
  #   "t/path/user/local/bin/app2",
  #   "t/path/usr/bin/app2",
  # ]

=back

=over 4

=item where example 4

  # given: synopsis

  package main;

  my $where = $os->where('app3');

  # [
  #   "t/path/user/bin/app3",
  #   "t/path/usr/sbin/app3"
  # ]

=back

=over 4

=item where example 5

  # given: synopsis

  package main;

  my $where = $os->where('app4');

  # [
  #   "t/path/user/local/bin/app4",
  #   "t/path/usr/local/bin/app4",
  #   "t/path/usr/local/sbin/app4",
  # ]

=back

=over 4

=item where example 6

  # given: synopsis

  package main;

  my $where = $os->where('app5');

  # []

=back

=cut

=head2 which

  which(string $file) (string)

The which method returns the first match from the result of calling the
L</where> method with the arguments provided.

I<Since C<2.80>>

=over 4

=item which example 1

  # given: synopsis

  package main;

  my $which = $os->which('cmd');

  # "t/path/user/local/bin/cmd",

=back

=over 4

=item which example 2

  # given: synopsis

  package main;

  my $which = $os->which('app1');

  # "t/path/user/local/bin/app1"

=back

=over 4

=item which example 3

  # given: synopsis

  package main;

  my $which = $os->which('app2');

  # "t/path/user/local/bin/app2"

=back

=over 4

=item which example 4

  # given: synopsis

  package main;

  my $which = $os->which('app3');

  # "t/path/user/bin/app3"

=back

=over 4

=item which example 5

  # given: synopsis

  package main;

  my $which = $os->which('app4');

  # "t/path/user/local/bin/app4"

=back

=over 4

=item which example 6

  # given: synopsis

  package main;

  my $which = $os->which('app5');

  # undef

=back

=cut

=head2 write

  write(any $into, string $data, string $encoding) (Venus::Os)

The write method writes to a file, filehandle, STDOUT, or STDERR, and returns
the invocant. To write to STDOUT provide the string C<"STDOUT">. To write to
STDERR provide the string C<"STDERR">. The method defaults to writing to
STDOUT.

I<Since C<4.15>>

=over 4

=item write example 1

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write;

  # to STDOUT

  # ''

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 2

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write(undef, '');

  # to STDOUT

  # ''

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 3

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDOUT');

  # to STDOUT

  # ''

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 4

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDOUT', '...');

  # to STDOUT

  # '...'

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 5

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDERR');

  # to STDERR

  # ''

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 6

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDERR', '...');

  # to STDERR

  # '...'

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 7

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/iso-8859-1.txt';

  my $write = $os->write($file, 'Hello, world! This is ISO-8859-1.');

  # to file

  # "Hello, world! This is ISO-8859-1."

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 8

  # given: synopsis

  package main;

  # on linux

  open my $fh, '<', 't/data/texts/iso-8859-1.txt';

  my $write = $os->write($fh, 'Hello, world! This is ISO-8859-1.');

  # to file

  # "Hello, world! This is ISO-8859-1."

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 9

  # given: synopsis

  package main;

  # on linux

  use IO::File;

  my $fh = IO::File->new('t/data/texts/iso-8859-1.txt', 'w');

  my $write = $os->write($fh, 'Hello, world! This is ISO-8859-1.');

  # to ISO-8859-1 encoded file

  # "Hello, world! This is ISO-8859-1."

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 10

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-16be.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-16BE');

  # to UTF-16BE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 11

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-16le.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-16LE');

  # to UTF-16LE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 12

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-32be.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-32BE');

  # to UTF-32BE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 13

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-32le.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-32LE');

  # to UTF-32LE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=back

=over 4

=item write example 14

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-8.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-8');

  # to UTF-8 encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=back

=over 4

=item B<may raise> L<Venus::Os::Error> C<on.write.open.file>

  # given: synopsis;

  $os->write('/path/to/nowhere/file.txt', 'content');

  # Error! (on.write.open.file)

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut