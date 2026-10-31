#!/usr/bin/env perl
package YATT::Lite::LanguageServer::Generic;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     , qw/_buffer _out_semaphore _log_fh/
     , [read_fd => default => 0]
     , [write_fd => default => 1]
     , [read_length => default => 8192]
     , [jsonrpc_version => default => '2.0']
     , [dump_request => default => 0]
     , [logfile => doc => "append protocol trace to this file (default: \$YATT_LANGSERVER_LOG). Works even with --quiet"]
     , qw/_is_shutting_down/
   ];

use JSON::MaybeXS;

use MOP4Import::Types
  (Header => [[fields => qw/Content-Length/]]);

use YATT::Lite::LanguageServer::Protocol
  qw/Message Request Response Notification Error/, qr/^ErrorCodes__/;

# Most logics are shamelessly stolen from Perl::LanguageServer

use Coro ;
use Coro::AIO ;
use AnyEvent;

use Scope::Guard qw/guard/;
use Try::Tiny;
use Errno qw(EINTR);
use Time::HiRes ();

use IO::Handle;

use URI;

#========================================

sub cli_encode_json {
  (my MY $self, my $obj) = @_;
  my ($encoded, $err);
  try {
    $encoded = $self->SUPER::cli_encode_json($obj);
  } catch {
    $err = $_;
  };

  unless (defined $encoded) {
    Carp::croak (($err // 'json encode error')
                 .": ".MOP4Import::Util::terse_dump($obj));
  }

  $encoded;
}

sub after_configure_default {
  (my MY $self) = @_;
  $self->{_out_semaphore} = Coro::Semaphore->new;
  $self->{logfile} //= $ENV{YATT_LANGSERVER_LOG};
  if (defined $self->{logfile} and $self->{logfile} ne '') {
    open $self->{_log_fh}, '>>', $self->{logfile}
      or die "Can't open logfile $self->{logfile}: $!";
    $self->{_log_fh}->autoflush(1);
  }
}

#========================================
# Logging.
#
# Goes to STDERR unless --quiet, and to --logfile (or $YATT_LANGSERVER_LOG)
# regardless of --quiet. Arguments may be CODE refs, which are only
# evaluated when something is actually logged (JSON encoding of a whole
# didOpen/didChange is not free).
#
sub is_logging {
  (my MY $self) = @_;
  $self->{_log_fh} || !$self->{quiet};
}

sub logmsg {
  (my MY $self, my @msg) = @_;
  return unless $self->is_logging;
  my $line = sprintf("# %.3f ", Time::HiRes::time())
    . join("", map {ref $_ eq 'CODE' ? $_->() : $_} @msg) . "\n";
  print {$self->{_log_fh}} $line if $self->{_log_fh};
  print STDERR $line unless $self->{quiet};
}

sub json_for_log {
  (my MY $self, my ($obj, $limit)) = @_;
  my $str = eval { $self->cli_encode_json($obj) };
  $str = "(unencodable: $@)" unless defined $str;
  $self->truncate_for_log($str, $limit);
}

sub truncate_for_log {
  (my MY $self, my ($str, $limit)) = @_;
  if ($limit and length($str) > $limit) {
    substr($str, 0, $limit) . "...(" . length($str) . " bytes)";
  } else {
    $str;
  }
}

#========================================

sub call_method {
  (my MY $self, my Request $request) = @_;
  my $method = $self->translate_method_name($request->{method});
  if (my $sub = $self->can($method)) {
    my $params = $request->{params};
    $self->logmsg("call_method: $method '", sub {$self->json_for_log($params, 200)}, "'");
    $sub->($self, $params);
  } else {
    $self->logmsg("Not implemented: ", sub {$self->json_for_log($request, 200)});
    undef;
  }
}

sub translate_method_name {
  (my MY $self, my $method) = @_;
  $method =~ s,/,__,g;
  $method =~ s,^\$,__ext,;
  'lspcall__'.$method;
}

sub cmd_server {
  (my MY $self, my @args) = @_;

  autoflush STDERR 1;
  # A client which went away turns into a write error (handled) instead of
  # SIGPIPE killing the server in the middle of a response.
  local $SIG{PIPE} = 'IGNORE';
  $self->logmsg("server started");

  my $cv = AnyEvent::CondVar->new;

  async {
    $self->mainloop(@args);
    $cv->send;
  };

  $cv->recv;
  $self->logmsg("server finished");
  "";
}

sub mainloop {
  (my MY $self) = @_;
  my (%request, %notification); # XXX: should this be an instance member?
  my $notificationNo;
  while (1) {
    my $reqRaw = $self->read_raw_request;
    unless (defined $reqRaw) {
      $self->logmsg("input closed, leaving mainloop");
      return;
    }
    my Request $request = eval { decode_json($reqRaw) };
    unless (ref $request eq 'HASH') {
      # A broken frame must not kill the reader (which would leave the
      # server deaf forever). Report and continue with the next frame.
      my $err = $@ || "not a JSON object";
      $self->logmsg("json parse error, frame dropped: $err");
      $self->emit_error_response(undef, ErrorCodes__ParseError, "Parse error: $err");
      next;
    }
    if (defined (my $id = $request->{id})) {
      $self->logmsg("processing request: ", sub {$self->json_for_log($request, 500)});
      $request{$id} = async {
        my $guard = guard {
          delete $request{$id};
        };
        $self->process_request($request);
      };
    } else {
      $self->logmsg("got notification: ", sub {$self->json_for_log($request, 500)});
      my $no = ++$notificationNo;
      $notification{$no} = async {
        my $guard = guard {
          delete $notification{$no};
        };
        $self->process_request($request);
      };
    }

    cede;
  }
}

#========================================

sub lspcall__shutdown {
  (my MY $self, my $nullParam) = @_;
  $self->{_is_shutting_down} = 1;
  undef;
}

sub lspcall__exit {
  (my MY $self, my $nullParam) = @_;
  my $code = $self->{_is_shutting_down} ? 0 : 1;
  $self->logmsg("exit with code $code");
  close $self->{_log_fh} if $self->{_log_fh};
  exit $code;
}

#========================================

sub send_notification {
  (my MY $self, my ($methodName, $params)) = @_;
  my Notification $notif = {};
  $notif->{method} = $methodName;
  $notif->{params} = $params;
  $notif->{jsonrpc} = $self->{jsonrpc_version};

  my $wdata = eval { $self->format_message($notif) };
  unless (defined $wdata) {
    $self->logmsg("notification encode failed ($methodName): ", $@ // 'unknown error');
    return;
  }

  $self->logmsg("sending notification: ", sub {$self->truncate_for_log($wdata, 300)});

  $self->emit_outdata($wdata);
}

sub process_request {
  (my MY $self, my Request $request) = @_;
  my $isRequest = defined $request->{id};
  my Response $outdata;
  my $result = eval { $self->call_method($request) };
  if (my $msg = $@) {
    # Expect $msg is an object which supports stringification, or a string.
    my $text = ref $msg ? "$msg" : $msg;
    if ($isRequest) {
      $outdata->{error} = my Error $error = {};
      $error->{code} = ErrorCodes__UnknownErrorCode;
      $error->{message} = $text;
    } else {
      # JSON-RPC forbids responses to notifications.
      $self->logmsg("error in notification handler ($request->{method}): $text");
      return;
    }
  } elsif ($isRequest) {
    $outdata->{result} = $result;
  } else {
    return;
  }

  eval { $self->emit_response($outdata, $request->{id}) };
  if ($@) {
    $self->logmsg("failed to emit response for id=$request->{id}: $@");
  }
}

sub emit_error_response {
  (my MY $self, my ($id, $code, $message)) = @_;
  my Response $res = {};
  $res->{error} = my Error $error = {};
  $error->{code} = $code;
  $error->{message} = $message;
  eval { $self->emit_response($res, $id) };
  if ($@) {
    $self->logmsg("failed to emit error response: $@");
  }
}

sub emit_response {
  (my MY $self, my Response $response, my $id) = @_;

  my $wdata = eval { $self->format_message($self->make_response($response, $id)) };
  unless (defined $wdata) {
    # Never let an unencodable result kill the coro (and the server).
    my $err = $@ // 'unknown error';
    $self->logmsg("response encode failed for id=", $id // 'null', ": $err");
    my Response $fallback = {};
    $fallback->{error} = my Error $error = {};
    $error->{code} = ErrorCodes__InternalError;
    $error->{message} = "response encode failed: $err";
    $wdata = $self->format_message($self->make_response($fallback, $id));
  }

  $self->logmsg("sending response: ", sub {$self->truncate_for_log($wdata, 300)});

  $self->emit_outdata($wdata);
}

sub emit_outdata {
  (my MY $self, my $wdata) = @_;
  my $guard = $self->{_out_semaphore}->guard;
  my $sum = 0;
  use bytes;
  while ((my $diff = length($wdata) - $sum) > 0) {
    my $cnt = aio_write $self->{write_fd}, undef, $diff, $wdata, $sum;
    die "write_error ($!)" if $cnt <= 0;
    $sum += $cnt;
  }

  $self->logmsg("sent $sum bytes");
}

sub make_response {
  (my MY $self, my Response $response, my $id) = @_;
  $response->{id} = $id; # null for errors without id (ParseError).
  $response->{jsonrpc} = $self->{jsonrpc_version};
  $response;
}

sub format_message {
  (my MY $self, my Message $message) = @_;
  my $outdata = $self->cli_encode_json($message);
  if (Encode::is_utf8($outdata)) {
    Encode::_utf8_off($outdata);
  }
  use bytes;
  my $len = length $outdata;
  my @out = ("Content-Length: $len"
               , "Content-Type: application/vscode-jsonrpc; charset=utf-8"
               , ""
               , $outdata);
  wantarray ? @out : join("\r\n", @out);
}

#========================================
# Reading frames.
#
# Both loops below check what is already in _buffer BEFORE blocking in
# aio_read, so that several frames arriving in one read (eglot writes
# didChange and definition back to back) are all served without waiting
# for further input. GH-275
#
# Returns the body of the next frame, or undef at EOF / read error.
sub read_raw_request {
  (my MY $self) = @_;
  while (1) {
    my Header $header = $self->read_header
      or return undef;
    my $len = $header->{'Content-Length'};
    if (defined $len and $len =~ /^\d+\z/) {
      while ((my $diff = $len - length $self->{_buffer}) > 0) {
        my $cnt = aio_read $self->{read_fd}, undef, $diff
          , $self->{_buffer}, length $self->{_buffer};
        if (not defined $cnt or $cnt < 0) {
          next if $! == EINTR;
          $self->logmsg("read error (body): $!");
          return undef;
        }
        if ($cnt == 0) {
          $self->logmsg("EOF while reading body (wanted $diff more bytes)");
          return undef;
        }
      }
      my $data = substr($self->{_buffer}, 0, $len, '');
      return wantarray ? ($data, $header) : $data;
    }
    # A header block without (valid) Content-Length: skip it and resync
    # at the next header instead of terminating the server.
    $self->logmsg("no valid Content-Length, header skipped: "
                  , sub {$self->json_for_log($header)});
  }
}

# Returns the parsed header of the next frame (consumed from _buffer),
# or undef at EOF / read error.
sub read_header {
  (my MY $self) = @_;
  $self->{_buffer} //= "";
  my $sepPos;
  while (($sepPos = index($self->{_buffer}, "\r\n\r\n")) < 0) {
    my $cnt = aio_read $self->{read_fd}, undef, $self->{read_length}
      , $self->{_buffer}, length $self->{_buffer};
    $self->logmsg("aio read header: cnt=", $cnt // 'undef'
                  , ($self->{dump_request} ? ("\n", sub {$self->dump_buffer}) : ()));
    if (not defined $cnt or $cnt < 0) {
      next if $! == EINTR;
      $self->logmsg("read error (header): $!");
      return undef;
    }
    if ($cnt == 0) {
      $self->logmsg("EOF with unparsed input: ", sub {$self->truncate_for_log($self->{_buffer}, 200)})
        if length $self->{_buffer};
      return undef;
    }
  }
  my Header $header = {};
  foreach my $line (split /\r\n/, substr($self->{_buffer}, 0, $sepPos)) {
    my ($k, $v) = split /:\s*/, $line, 2;
    next unless defined $k and defined $v;
    $k = 'Content-Length' if lc($k) eq 'content-length';
    $header->{$k} = $v;
  }
  substr($self->{_buffer}, 0, $sepPos+4, '');
  $self->logmsg("got header: ", sub {$self->json_for_log($header)});
  $header;
}

sub dump_buffer {
  (my MY $self) = @_;
  require Data::HexDump::XXD;

  join("\n", Data::HexDump::XXD::xxd($self->{_buffer}));
}

#----------------------------------------

# file:// uri => local path (percent-decoded octets, no symlink
# resolution: the server keys templates by the path form the client
# sends). Symmetric with Inspector::filename2uri (URI::file->new_abs).
sub uri2localpath {
  (my MY $self, my $uri) = @_;
  return undef unless defined $uri;
  return undef unless $uri =~ m{^file://};
  URI->new($uri)->file;
}

MY->run(\@ARGV) unless caller;
