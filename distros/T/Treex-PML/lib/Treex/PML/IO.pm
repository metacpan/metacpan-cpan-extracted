# -*- cperl -*-

=head1 NAME

Treex::PML::IO - I/O support functions used by Treex::PML

=head1 DESCRIPTION

This module implements various I/O and filesystem related functions
used by L<Treex::PML>.

The current implementation supports the following protocols for
reading:

  http, https, ftp, gopher, news - reading (POSIX and Windows)

  ssh, fish, sftp - reading/writing on POSIX systems via secure shell copy
                    or the kioclient from KDE.

The module attempts to handle GNU Zip-compressed files (suffix .gz)
transparently.

=head1 FUNCTIONS

=cut

package Treex::PML::IO;
use Exporter;
use File::Temp 0.14 qw();
use IO::File;
use IO::Pipe;
use strict;
use URI;
use URI::file;
use URI::Escape;
use Scalar::Util qw(blessed);
use UNIVERSAL::DOES;
use Carp;
use LWP::UserAgent;
use File::Spec;
use Fcntl qw(SEEK_SET);

use Cwd qw(getcwd);

use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK
            %UNLINK_ON_CLOSE
            $Debug
            $kioclient $kioclient_opts
            $ssh $ssh_opts
            $curl $curl_opts
            $gzip $gzip_opts
            $zcat $zcat_opts
            $reject_proto
            $lwp_user_agent
           );

sub DOES {
  my ($self,$role)=@_;
  if ($role eq 'IO' or $role eq __PACKAGE__) { # backward compatibility
    return 1;
  } else {
    return $self->SUPER::DOES($role);
  }
}

{
  package Treex::PML::IO::UserAgent;
  use base qw(LWP::UserAgent);
}

#$Debug=0;
my %input_protocol_handler;

BEGIN {
  *_find_exe = eval {
      require File::Which;
      \&File::Which::which
  } || sub {};

  $VERSION = '2.28'; # version template
  @ISA=qw(Exporter);
  @EXPORT_OK = qw($kioclient $kioclient_opts
                  $ssh $ssh_opts
                  $curl $curl_opts
                  $gzip $gzip_opts
                  $zcat $zcat_opts
                  &set_encoding
                  &open_backend &open_uri &close_backend &close_uri
                  &get_protocol &quote_filename
                  &rename_uri);

  $zcat         ||= _find_exe('zcat');
  $gzip         ||= _find_exe('gzip');
  $kioclient    ||= _find_exe('kioclient');
  $ssh          ||= _find_exe('ssh');
  $curl         ||= _find_exe('curl');
  $ssh_opts     ||= '-C';
  $reject_proto ||= '^(pop3?s?|imaps?)\$';
  $lwp_user_agent = Treex::PML::IO::UserAgent->new(keep_alive=>1);
  $lwp_user_agent->agent("Treex::PML_IO/$VERSION");
};


=over 4

=item C<DirPart($path)>

Returns directory part of a given path (including volume).

=cut

sub DirPart {
  return File::Spec->catpath(
    (File::Spec->splitpath($_[0]))[0,1],''
   );
}

=item C<CallerDir($rel_path?)>

If called without an argument, returns the directory of the perl
module or macro-file that invoked this macro.

If a relative path is given as an argument, a respective absolute path
is computed based on the caller's directory and returned.

=cut

sub CallerDir {
  return
    @_>0
      ? File::Spec->rel2abs($_[0], DirPart( (caller)[1] ))
      : DirPart( (caller)[1] );
}

=item C<register_input_protocol_handler($scheme,$callback)>

Register a callback to fetch URIs of a given protocol. C<$scheme> is
the URI scheme of the protocol (i.e. the first part of an URI
preceding the comma, e.g. 'ftp' or 'https'). <$callback> is either a
CODE reference or an ARRAY reference whose first element is a CODE
reference and the other elements are additional arguments to be passed
to the callback prior to the standard arguments.

When the library attempts to fetch a resource from an URI matching
given scheme, the callback is invoked with the (optional) user
parameters followed by the URI.

The callback function must either return a new URI (typically a
file:// URI pointing to a temporary file) and a boolean flag
indicating whether the library should attempt to delete the
returned file after it finished reading.

If the callback returns the same or another URI with the C<$scheme>,
the callback is not reinvoked, but passed on to further processing
(i.e. by Treex::PML I/O backends).

=cut

sub register_input_protocol_handler {
  my ($proto,$handler)=@_;
  if (ref($handler) eq 'CODE' or ref($handler) eq 'ARRAY') {
    if (exists($input_protocol_handler{$proto})) {
      carp(__PACKAGE__."::register_input_protocol_handler: WARNING: redefining protocol handler for '$proto'");
    }
    $input_protocol_handler{$proto}=$handler;
  } else {
    croak("Wrong arguments. Usage: Treex::PML::IO::register_input_protocol_handler(protocol=>callback)");
  }
}

=item unregister_input_protocol_handler($scheme)

Unregister a handler for a given URI scheme.

=cut

sub unregister_input_protocol_handler {
  my ($proto)=@_;
  return delete $input_protocol_handler{$proto};
}

=item get_input_protocol_handler($scheme)

Returns the user-defined handler registered for a given URI scheme; if
none, undef is returned.

=cut

sub get_input_protocol_handler {
  my ($proto)=@_;
  return $input_protocol_handler{$proto};
}

=item set_encoding($filehandle, $encoding)

Safely resets Perl I/O-layer on a given filehandle to decode or encode
from/to a given encoding. This is equivalent to:

   binmode($filehandle,":raw:perlio:encoding($encoding)");

except that errors are turned into warnings.

=cut

sub set_encoding {
  my ($fh,$encoding) = @_;
  no integer;
  if (defined($fh) and defined($encoding) and ($]>=5.008)) {
    eval {
      binmode($fh,":raw:perlio:encoding($encoding)");
    };
    warn $@ if $@;
  }
  return $fh;
}

=item get_protocol($filename_or_URI)

If the argument is a filename, returns 'file'; if the argument is an
URI, returns the URI's scheme. Note: unless the argument is an URI
object, a heuristic is used to determine the scheme. To avoid
reporting Windows drive names as URI schemes, only URI schemes
consisting of at least two characters are supported, i.e. C:foo is
considered a file name wheres CC:foo would be an URI with the scheme
'CC'.

=cut

# to avoid collision with Win32 drive-names, we only support protocols
# with at least two letters
sub get_protocol {
  my ($uri) = @_;
  if (blessed($uri) and $uri->isa('URI')) {
    return $uri->scheme || 'file';
  }
  if ($uri =~ m{^\s*([[:alnum:]][[:alnum:]]+):}) {
    return $1;
  } else {
    return 'file';
  }
}

=item quote_filename($string)

Returns given string in shell-quotes with special characters (\, $, ")
escaped.

=cut

sub quote_filename {
  my ($uri)=@_;
  $uri =~ s{\\}{\\\\}g;
  $uri =~ s{\$}{\\\$}g;
  $uri =~ s{"}{\\"}g;
  return '"'.$uri.'"';
}

=item get_filename($URI_or_filename)

Upgrades given string to an URI and if the resulting URI is in the
'file' scheme (e.g. file:///bar/baz), returns the file-name portion of
the URI (e.g. /bar/baz). Otherwise returns nothing.

=cut

sub get_filename {
  my ($uri)=@_;
  $uri=make_URI($uri); # cast to URI or make a copy
  $uri->scheme('file') if !$uri->scheme;
  if ($uri->scheme eq 'file') {
    return $uri->file;
  }
  return;
}

=item make_abs_URI($URL_or_filename)

Upgrades a given string (URL or filename) into an URI object with
absolute path (relative URIs are resolved using the current working
directory obtained via Cwd::getcwd())

=cut

sub make_abs_URI {
  my ($url)=@_;
  my $uri = make_URI($url);
  my $cwd = getcwd();
  $cwd = VMS::Filespec::unixpath($cwd) if $^O eq 'VMS';
  $cwd = URI::file->new($cwd);
  $cwd .= "/" unless substr($cwd, -1, 1) eq "/";
  return $uri->abs($cwd);
}

=item make_URI($URL_or_filename)

Upgrades a given string (URL or filename) into an URI object.

=cut

sub make_URI {
  my ($url)=@_;
  my $uri = URI->new($url);
  return $uri if blessed($url) and $url->isa('URI'); # return a copy if was URI already
  if (($uri eq $url or URI::Escape::uri_unescape($uri) eq $url)
        and $url =~ m(^\s*[[:alnum:]]+://)) { # looks like it is URL already
    return $uri;
  } else {
    return URI::file->new($url);
  }
}

=item make_relative_URI($URL,$baseURI)

Returns a relative URI based in a given base URI. The arguments
are automatically upgraded using make_URI() if necessary.

=cut

sub make_relative_URI {
  my ($href,$base)=@_;
#  if (Treex::PML::_is_url($href)) {
  $href = URI->new(make_URI($href)) unless blessed($href) and $href->isa('URI');
  $base = make_URI($base);
  ###  $href = $href->abs($base)->rel($base);
  $href = $href->rel($base);
}

=item strip_protocol($URI)

Returns the scheme-specific part of the URI (everything between the
scheme and the fragment). If the scheme of the URI was 'file', returns
the URI as a file name.

=cut

sub strip_protocol {
  my ($uri)=@_;
  $uri=make_URI($uri); # make a copy
  $uri->scheme('file') if !$uri->scheme;
  if ($uri->scheme eq 'file') {
    return $uri->file;
  }
  return $uri->opaque;
}

# =item is_gzip($filename)

# Auxiliary:
# Returns true if the filename ends with the suffix .gz or .gz~.

# =cut

sub _is_gzip {
  ($_[0] =~/.gz~?$/) ? 1 : 0;
}

=item is_same_filename($URI_1,$URI_2)

Checks if $URI_1 and $URI_2 point to the same resource.  For filenames
and URIs in the 'file' scheme checks that the referred files (if
exist) are the same using is_same_file(); for other schemes simply
checks for string equality on canonical versions of the URIs (see
URI->canonical).

=cut

sub is_same_filename {
  my ($f1,$f2)=@_;
  return 1 if $f1 eq $f2;
  my $u1 = (blessed($f1) and $f1->isa('URI')) ? $f1 : make_URI($f1);
  my $u2 = (blessed($f2) and $f2->isa('URI')) ? $f2 : make_URI($f2);
  return 1 if $u1 eq $u2;
  return 1 if $u1->canonical eq $u2->canonical;
  if (!ref($f1) and !ref($f2) and $^O ne 'MSWin32' and -f $f1 and -f $f2) {
    return is_same_file($f1,$f2);
  }
  return 0;
}

=item is_same_file($filename_1,$filename_2)

Uses device and i-node numbers (reported by stat()) to check if the
two filenames point to the same file on the filesystem. Returns 1 if
yes, 0 otherwise.

=cut

sub is_same_file {
  my ($f1,$f2) = @_;
  return 1 if $f1 eq $f2;
  my ($d1,$i1)=stat($f1);
  my ($d2,$i2)=stat($f2);
  return ($d1==$d2 and $i1!=0 and $i1==$i2) ? 1 : 0;
}

=item open_pipe($filename,$mode,$command)

Returns a filehandle of a newly open pipe in a given mode.

In write mode ($mode = 'w'), opens a writing pipe to a given
command redirecting the standard output of the command to a given
file. Moreover, if the last suffix of the $filename is '.gz' or
'.gz~', the output of the command is gzipped before saving to
$filename.

In read mode ($mode = 'r'), opens a reading pipe to a given
command redirecting the content of the given file to the standard
input of the command. Moreover, if the last suffix of the $filename is
'.gz' or '.gz~', the output of the command is un-gzipped before it is passed
to the command.

=cut

sub open_pipe {
  my ($file,$rw,$pipe) = @_;
  my $fh;
  if (_is_gzip($file)) {
    if (-x $gzip && -x $zcat) {
      if ($rw eq 'w') {
        open $fh, "| $pipe | $gzip $gzip_opts > ".quote_filename($file) || undef $fh;
      } else {
        open $fh, "$zcat $zcat_opts < ".quote_filename($file)." | $pipe |" || undef $fh;
      }
    } else {
      warn "Need a functional gzip and zcat to open this file\n";
    }
  } else {
    if ($rw eq 'w') {
      open $fh, "| $pipe > ".quote_filename($file) || undef $fh;
    } else {
      open $fh, "$pipe < ".quote_filename($file)." |" || undef $fh;
    }
  }
  return $fh;
}

# _open_file_zcat:
#
# Note: This function represents the original strategy used on POSIX
# systems. It turns out, however, that the calls to zcat/gzip cause
# serious penalty on btred when loading large amount of files and also
# cause the process' priority to lessen. It also turns out that we
# cannot use IO::Zlib filehandles directly with some backends, such as
# StorableBackend.
#
# I'm leaving the function here, but it is not used anymore.

sub _open_file_zcat {
  my ($file,$rw) = @_;
  my $fh;
  if (_is_gzip($file)) {
   if (-x $gzip) {
      $fh = new IO::Pipe();
      if ($rw eq 'w') {
        $fh->writer("$gzip $gzip_opts > ".quote_filename($file)) || undef $fh;
      } else {
        $fh->reader("$zcat $zcat_opts < ".quote_filename($file)) || undef $fh;
      }
   }
   unless ($fh) {
     eval {
       require IO::Zlib;
       $fh = new IO::Zlib;
     } || return;
     $fh->open($file,$rw."b") || undef $fh;
   }
  } else {
    $fh = new IO::File();
    $fh->open($file,$rw) || undef $fh;
  }
  return $fh;
}

=item open_file($filename,$mode)

Opens a given file for reading ($mode = 'r') or writing ($mode =
'w'). If the last suffix of the filename is '.gz' or '.gz~', the data
are transparently un-gzipped (when reading) or gzipped (when writing).

=cut

sub open_file {
  my ($file,$rw) = @_;
  my $fh;
  if (_is_gzip($file)) {
    eval {
      $fh = File::Temp->new(UNLINK => 1);
    };
    die if $@;
    return unless $fh;
    if ($rw eq 'w') {
      print STDERR __PACKAGE__.": Storing ZIPTOFILE: $rw\n" if $Debug;
      ${*$fh}{'ZIPTOFILE'}=$file;
    } else {
      my $tmp;
      eval {
        require IO::Zlib;
        $tmp = new IO::Zlib();
      } && $tmp || return;
      $tmp->open($file,"rb") || return;
      my $buffer;
      my $length = 1024*1024;
      while (read($tmp,$buffer,$length)) {
        $fh->print($buffer);
      }
      $tmp->close();
      seek($fh,0,SEEK_SET);
    }
    return $fh;
  } else {
    $fh = new IO::File();
    $fh->open($file,$rw) || return;
  }
  return $fh;
}

sub _callback {
  my $callback = shift;
  if (ref($callback) eq 'CODE') {
    return $callback->(@_);
  } elsif (ref($callback) eq 'ARRAY') {
    my ($cb,@args)=@{$callback};
    $cb->(@args,@_);
  }
}

sub _fetch_file {
  my ($uri) = @_;
  my $proto = get_protocol($uri);
  if ($proto eq 'file') {
    my $file = get_filename($uri);
    print STDERR __PACKAGE__.": _fetch_file: $file\n" if $Debug;
    die("File does not exist: $file\n") unless -e $file;
    die("File is not readable: $file\n") unless -r $file;
    die("File is empty: $file\n") if -z $file;
    return ($file,0);
  } elsif ($proto eq 'ntred' or $proto =~ /$reject_proto/) {
    return ($uri,0);
  } elsif (exists($input_protocol_handler{$proto})) {
    my ($new_uri,$unlink) = _callback($input_protocol_handler{$proto},$uri);
    my $new_proto = get_protocol($new_uri);
    if ($new_proto ne $proto) {
      return _fetch_file($new_uri);
    } else {
      return ($new_uri,$unlink);
    }
  } else {
    if ($^O eq 'MSWin32') {
      return _fetch_file_win32($uri,$proto);
    } else {
      return _fetch_file_posix($uri,$proto);
    }
  }
}


=item fetch_file($uri)

Fetches a resource from a given URI and returns a path to a local file
with the content of the resource and a boolean unlink flag. If the
unlink flag is true, the caller is responsible for removing the local
file when finished using it. Otherwise, the caller should not remove
the file (usually when it points to the original resource).  The
caller may assume that the resource is already un-gzipped if the URI
had the '.gz' or '.gz~' suffix.

=cut

sub fetch_file {
  my ($uri) = @_;
  my ($file,$unlink) = &_fetch_file;
  if (get_protocol($file) eq 'file' and _is_gzip($uri)) {
    my ($fh,$ungzfile) = File::Temp::tempfile("tredgzioXXXXXX",
                                              DIR => File::Spec->tmpdir(),
                                              UNLINK => 0,
                                             );
    die "Cannot create temporary file: $!" unless $fh;
    my $tmp;
    eval {
      require IO::Zlib;
      $tmp = new IO::Zlib();
    } && $tmp || die "Cannot load IO::Zlib: $@";
    $tmp->open($file,"rb") || die "Cannot read $uri ($file)";
    my $buffer;
    my $length = 1024*1024;
    while (read($tmp,$buffer,$length)) {
      $fh->print($buffer);
    }
    $tmp->close();
    $fh->close;
    unlink $file if $unlink;
    return ($ungzfile,1);
  } else {
    return ($file,$unlink);
  }
}


sub _fetch_cmd {
  my ($cmd, $filename)=@_;
  print STDERR __PACKAGE__.": _fetch_cmd: $cmd\n" if $Debug;
  if (system($cmd." > ".$filename)==0) {
    return ($filename,1);
  } else {
    warn "$cmd > $filename failed (code $?): $!\n";
    return $filename,0;
  }
}

sub _fetch_with_lwp {
  my ($uri,$fh,$filename)=@_;
  my $status = $lwp_user_agent->get($uri, ':content_file' => $filename);
  if ($status and $status->is_error and $status->code == 401) {
    # unauthorized
    # Got authorization error 401, maybe the nonce is stale, let's try again...
    $status = $lwp_user_agent->get($uri, ':content_file' => $filename);
  }
  if ($status->is_success()) {
    close $fh;
    return ($filename,1);
  } else {
    unlink $fh;
    close $fh;
    die "Error occured while fetching URL $uri $@\n".
      $status->status_line()."\n";
  }
}

sub _fetch_file_win32 {
  my ($uri,$proto)=@_;
  my ($fh,$filename) = File::Temp::tempfile("tredioXXXXXX",
                                            DIR => File::Spec->tmpdir(),
                                            SUFFIX => (_is_gzip($uri) ? ".gz" : ""),
                                            UNLINK => 0,
                                           );
  print STDERR __PACKAGE__.": fetching URI $uri as proto $proto to $filename\n" if $Debug;
  if ($proto=~m(^https?|ftp|gopher|news)) {
    return _fetch_with_lwp($uri,$fh,$filename);
  }
  return($uri,0);
}

sub _fetch_file_posix {
  my ($uri,$proto)=@_;
  print STDERR __PACKAGE__.": fetching file using protocol $proto ($uri)\n" if $Debug;
  my ($fh,$tempfile) = File::Temp::tempfile("tredioXXXXXX",
                                            DIR => File::Spec->tmpdir(),
                                            SUFFIX => (_is_gzip($uri) ? ".gz" : ""),
                                            UNLINK => 0,
                                           );
  print STDERR __PACKAGE__.": tempfile: $tempfile\n" if $Debug;
  if ($proto=~m(^https?|ftp|gopher|news)) {
    return _fetch_with_lwp($uri,$fh,$tempfile);
  }
  close($fh);
  if ($ssh and -x $ssh and $proto =~ /^(ssh|fish|sftp)$/) {
    print STDERR __PACKAGE__.": using plain ssh\n" if $Debug;
    if ($uri =~ m{^\s*(?:ssh|sftp|fish):(?://)?([^-/][^/]*)(/.*)$}) {
      my ($host,$file) = ($1,$2);
      print STDERR __PACKAGE__.": tempfile: $tempfile\n" if $Debug;
      return
        _fetch_cmd($ssh." ".$ssh_opts." ".quote_filename($host).
        " /bin/cat ".quote_filename(quote_filename($file)),$tempfile);
    } else {
      die "failed to parse URI for ssh $uri\n";
    }
  }
  if ($kioclient and -x $kioclient) {
    print STDERR __PACKAGE__.": using kioclient\n" if $Debug;
    # translate ssh protocol to fish protocol
    if ($proto eq 'ssh') {
      ($uri =~ s{^\s*ssh:(?://)?([/:]*)[:/]}{fish://$1/});
    }
    return _fetch_cmd($kioclient." ".$kioclient_opts.
                     " cat ".quote_filename($uri),$tempfile);
  }
  if ($curl and -x $curl and $proto =~ /^(?:https?|ftps?|gopher)$/) {
    return _fetch_cmd($curl." ".$curl_opts." ".quote_filename($uri),$tempfile);
  }
  warn "No handlers for protocol $proto\n";
  return ($uri,0);
}

sub _open_upload_pipe {
  my ($need_gzip,$user_pipe,$upload_pipe)=@_;
  my $fh;
  $user_pipe="| ".$user_pipe if defined($user_pipe) and $user_pipe !~ /^\|/;
  $user_pipe.=" ";
  my $cmd;
  if ($need_gzip) {
    if (-x $gzip) {
      $cmd = $user_pipe."| $gzip $gzip_opts | $upload_pipe ";
    } else {
      die "Need a functional gzip and zcat to open this file\n";
    }
  } else {
    $cmd = $user_pipe."| $upload_pipe ";
  }
  print STDERR __PACKAGE__.": upload: $cmd\n" if $Debug;
  open $fh, $cmd || undef $fh;
  return $fh;
}

sub _get_upload_fh_win32 {
  my ($uri,$proto,$userpipe)=@_;
  die "Can't save files using protocol $proto on Windows\n";
}

sub _get_upload_fh_posix {
  my ($uri,$proto,$userpipe)=@_;
  print STDERR __PACKAGE__.": uploading file using protocol $proto ($uri)\n" if $Debug;
  return if $proto eq 'http' or $proto eq 'https';
  if ($ssh and -x $ssh and $proto =~ /^(ssh|fish|sftp)$/) {
    print STDERR __PACKAGE__.": using plain ssh\n" if $Debug;
    if ($uri =~ m{^\s*(?:ssh|sftp|fish):(?://)?([^-/][^/]*)(/.*)$}) {
      my ($host,$file) = ($1,$2);
      return _open_upload_pipe(_is_gzip($uri), $userpipe, "$ssh $ssh_opts ".
                       quote_filename($host)." /bin/cat \\> ".
                              quote_filename(quote_filename($file)));
    } else {
      die "failed to parse URI for ssh $uri\n";
    }
  }
  if ($kioclient and -x $kioclient) {
    print STDERR __PACKAGE__.": using kioclient\n" if $Debug;
    # translate ssh protocol to fish protocol
    if ($proto eq 'ssh') {
      $uri =~ s{^\s*ssh:(?://)?([/:]*)[:/]}{fish://$1/};
    }
    return _open_upload_pipe(_is_gzip($uri),$userpipe,
                     "$kioclient $kioclient_opts put ".quote_filename($uri));
  }
  if ($curl and -x $curl and $proto =~ /^(?:ftps?)$/) {
    return _open_upload_pipe("$curl --upload-file - $curl_opts ".quote_filename($uri));
  }
  die "No handlers for protocol $proto\n";
}

=item get_store_fh ($uri, $command?)

If $command is provided, returns a writable filehandle for a pipe to a given
command whose output is redirected to an uploader to the given $URI
(for file $URIs this simply redirects the output of the command to the
given file (gzipping the data first if the $URI ends with the '.gz' or
'.gz~' suffix).

If $command is not given, simly retuns a writable file handle to a
given file (possibly performing gzip if the file name ends with the
'.gz' or '.gz~' suffix).

=cut

sub get_store_fh {
  my ($uri,$user_pipe) = @_;
  my $proto = get_protocol($uri);
  if ($proto eq 'file') {
    $uri = get_filename($uri);
    if ($user_pipe) {
      return open_pipe($uri,'w',$user_pipe);
    } else {
      return open_file($uri,'w');
    }
  } elsif ($proto eq 'ntred' or $proto =~ /$reject_proto/) {
    return $uri;
  } else {
    if ($^O eq 'MSWin32') {
      return _get_upload_fh_win32($uri,$proto,$user_pipe);
    } else {
      return _get_upload_fh_posix($uri,$proto,$user_pipe);
    }
  }
}

=item unlink_uri($URI)

Delete the resource point to by a given URI (if supported by the
corresponding protocol handler).

=cut

sub unlink_uri {
  ($^O eq 'MSWin32') ? &_unlink_uri_win32 : &_unlink_uri_posix;
}

sub _unlink_uri_win32 {
  my ($uri) = @_;
  my $proto = get_protocol($uri);
  if ($proto eq 'file') {
    unlink get_filename($uri);
  } else {
    die "Can't unlink file $uri\n";
  }
}

sub _unlink_uri_posix {
  my ($uri)=@_;
  my $proto = get_protocol($uri);
  if ($proto eq 'file') {
    return unlink get_filename($uri);
  }
  print STDERR __PACKAGE__.": unlinking file $uri using protocol $proto\n" if $Debug;
  if ($ssh and -x $ssh and $proto =~ /^(ssh|fish|sftp)$/) {
    print STDERR __PACKAGE__.": using plain ssh\n" if $Debug;
    if ($uri =~ m{^\s*(?:ssh|sftp|fish):(?://)?([^-/][^/]*)(/.*)$}) {
      my ($host,$file) = ($1,$2);
      return (system("$ssh $ssh_opts ".quote_filename($host)." /bin/rm ".
                     quote_filename(quote_filename($file)))==0) ? 1 : 0;
    } else {
      die "failed to parse URI for ssh $uri\n";
    }
  }
  if ($kioclient and -x $kioclient) {
    # translate ssh protocol to fish protocol
    if ($proto eq 'ssh') {
      $uri =~ s{^\s*ssh:(?://)?([/:]*)[:/]}{fish://$1/};
    }
    return (system("$kioclient $kioclient_opts rm ".quote_filename($uri))==0 ? 1 : 0);
  }
  die "No handlers for protocol $proto\n";
}

=item rename_uri($URI_1,$URI_2)

Rename the resource point to by $URI_1 to $URI_2 (if supported by the
corresponding protocol handlers). The URIs must point to the same
physical storage.

=cut

sub rename_uri {
  print STDERR __PACKAGE__.": rename @_\n" if $Debug;
  ($^O eq 'MSWin32') ? &_rename_uri_win32 : &_rename_uri_posix;
}


sub _rename_uri_win32 {
  my ($uri1,$uri2) = @_;
  my $proto1 = get_protocol($uri1);
  my $proto2 = get_protocol($uri2);
  if ($proto1 eq 'file' and $proto2 eq 'file') {
    my $uri1 = get_filename($uri1);
    return unless -f $uri1;
    rename $uri1, get_filename($uri2);
  } else {
    die "Can't rename file $uri1 to $uri2\n";
  }
}

sub _rename_uri_posix {
  my ($uri1,$uri2) = @_;
  my $proto = get_protocol($uri1);
  my $proto2 = get_protocol($uri2);
  if ($proto ne $proto2) {
    die "Can't rename file $uri1 to $uri2\n";
  }
  if ($proto eq 'file') {
    my $uri1 = get_filename($uri1);
    return unless -f $uri1;
    return rename $uri1, get_filename($uri2);
  }
  print STDERR __PACKAGE__.": rename file $uri1 to $uri2 using protocol $proto\n" if $Debug;
  if ($ssh and -x $ssh and $proto =~ /^(ssh|fish|sftp)$/) {
    print STDERR __PACKAGE__.": using plain ssh\n" if $Debug;
    if ($uri1 =~ m{^\s*(?:ssh|sftp|fish):(?://)?([^-/][^/]*)(/.*)$}) {
      my ($host,$file) = ($1,$2);
      if ($uri2 =~ m{^\s*(?:ssh|sftp|fish):(?://)?([^-/][^/]*)(/.*)$} and $1 eq $host) {
        my $file2 = $2;
        return (system("$ssh $ssh_opts ".quote_filename($host)." /bin/mv ".
                       quote_filename(quote_filename($file))." ".
                       quote_filename(quote_filename($file2)))==0) ? 1 : 0;
      } else {
        die "failed to parse URI for ssh $uri2\n";
      }
    } else {
      die "failed to parse URI for ssh $uri1\n";
    }
  }
  if ($kioclient and -x $kioclient) {
    # translate ssh protocol to fish protocol
    if ($proto eq 'ssh') {
      $uri1 =~ s{^\s*ssh:(?://)?([/:]*)[:/]}{fish://$1/};
      $uri2 =~ s{^\s*ssh:(?://)?([/:]*)[:/]}{fish://$1/};
    }
    return (system("$kioclient $kioclient_opts mv ".quote_filename($uri1).
                     " ".quote_filename($uri2))==0 ? 1 : 0);
  }
  die "No handlers for protocol $proto\n";
}



=item open_backend (filename,mode,encoding?)

Open given file for reading or writing (depending on mode which may be
one of "r" or "w"); Return the corresponding object based on
File::Handle class. Only files the filename of which ends with '.gz'
are considered to be gz-commpressed. All other files are opened using
IO::File.

Optionally, in perl ver. >= 5.8, you may also specify file character
encoding.

=cut


sub open_backend {
  my ($filename, $rw,$encoding)=@_;
  $filename =~ s/^\s*|\s*$//g;
  if ($rw eq 'r') {
    return set_encoding(open_file($filename,$rw)||undef,$encoding);
  } elsif ($rw eq 'w') {
    return set_encoding(get_store_fh($filename)||undef,$encoding);
  } else {
    croak "2nd argument to open_backend must be 'r' or 'w'!";
  }
  return;
}

=pod

=item close_backend (filehandle)

Close given filehandle opened by previous call to C<open_backend>

=cut

sub close_backend {
  my ($fh)=@_;
  # Win32 hack:
  if (ref($fh) eq 'File::Temp') {
    my $filename = ${*$fh}{'ZIPTOFILE'};
    if ($filename ne "") {
      print STDERR __PACKAGE__.": Doing the real save to $filename\n" if $Debug;
      seek($fh,0,SEEK_SET);
      require IO::Zlib;
      my $tmp = new IO::Zlib();
      $tmp->open($filename,"wb") || die "Cannot write to $filename: $!\n";
      # probably bug in Perl 5.8.9? - using just :raw here is not enough
      binmode $fh, ':raw:perlio:bytes';
      local $/;
      $tmp->print(<$fh>);
      $tmp->close;
    }
  }
  my $ret;
  if ((blessed($fh) and $fh->isa('IO::Zlib'))) {
    $ret = 1;
  } else {
    $ret = ref($fh) && $fh->close();
  }
  my $unlink = delete $UNLINK_ON_CLOSE{ $fh };
  if ($unlink) {
    unlink $unlink;
  }
  return $ret;
}


=item open_uri (URI,encoding?)

Open given URL for reading, returning an object based on File::Handle
class. Since for some types of URLs this function first copies the
data into a temporary file, use close_uri($fh) on the resulting
filehandle to close it and clean up the temporary file.

Optionally, in perl ver. >= 5.8, you may also specify file character
encoding.

=cut

sub open_uri {
  my ($uri,$encoding) = @_;
  my ($local_file, $is_temporary) = fetch_file( $uri );
  my $fh = open_backend($local_file,'r') || return;
  if ($is_temporary and $local_file ne $uri ) {
    if (!unlink($local_file)) {
      $UNLINK_ON_CLOSE{ $fh } = $local_file;
    }
  }
  return set_encoding($fh,$encoding);
}

*close_uri = \&close_backend;

=item close_uri (filehandle)

Close given filehandle opened by previous call to C<open_uri>.

=cut


=item copy_uri ($URI_1,$URI_2)

Copy the resource pointed to by the URI $URI_1 to $URI_2. The type of
$URI_2 must be writable.

=cut

sub copy_uri {
  my ($src_uri,$target_uri)=@_;
  my $in = open_uri($src_uri)
    or die "Cannot open source $src_uri: $!\n";
  my $out = open_backend($target_uri,'w')
    or die "Cannot open target $target_uri: $!\n";
  my $L=1024*100;
  my $buffer;
  while(read($in,$buffer,$L)>0) {
    print $out ($buffer);
  }
  close_backend($in);
  close_backend($out);
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Petr Pajas, 2010-2024 Jan Stepanek

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
