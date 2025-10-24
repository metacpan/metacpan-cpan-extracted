use strict;
use warnings;

use Test::More 'no_plan';

use Config;

BEGIN {
  use_ok 'Win32::Pipe::PP';
  use_ok 'threads';
}

sub _push {
  my ( $out, $seq, $ok, $txt ) = @_;
  push @$out, [ $seq, $ok ? 1 : 0, $txt ];
}

# --- SERVER: Sync (blocking) ---
sub server_thread_sync {
  my ($pipename, $bufsize, $message) = @_;
  my @res;

  my $server = Win32::Pipe->new($pipename);
  if ($server) {
    $server->{overlapped} = 0;    # Force sync (only for testing)
    $server->blocking(1);
    $server->ResizeBuffer($bufsize);
    _push(\@res, 1, 1, "Server(S) created (bufsize=".$server->BufferSize().")");
  }
  else {
    diag "Server created failed: ".Win32::Pipe->Error();
    _push(\@res, 1, 0, "Server(S) created");
    return \@res;
  }

  my $r = $server->Connect();
  if (!$r) {
    my ($err, $msg) = Win32::Pipe->Error();
    diag "Server connected failed: [$err] \"$msg\"";
    _push(\@res, 3, 0, "Server(S) connected");
    $server->Close(); 
    return \@res;
  }
  _push(\@res, 3, 1, "Server(S) connected");

  my $data = $server->Read();
  my $got  = defined $data ? 1 : 0;
  my ($err, $msg) = Win32::Pipe->Error();
  _push(\@res, 5, $got, "Server(S) read returned data");

  my $ok_match = $got && $data eq $message;
  _push(\@res, 6, $ok_match, "Server(S) read matches");

  $server->Disconnect();
  $server->Close();
  return \@res;
}

# --- SERVER: Non-Blocking (wait) ---
sub server_thread_nb {
  my ($pipename, $bufsize, $message) = @_;
  my @res;

  my $server = Win32::Pipe->new($pipename);
  if ($server) {
    # NB-Path: Overlapped Default (1), non-blocking read
    $server->blocking(0);
    $server->ResizeBuffer($bufsize);
    _push(\@res, 1, 1, "Server(NB) created (bufsize=".
      $server->BufferSize().")");
  }
  else {
    diag "Server created failed: ". Win32::Pipe->Error();
    _push(\@res, 1, 0, "Server(NB) created");
    return \@res;
  }

  my $r = $server->Connect();
  if (!$r) {
    my ($err, $msg) = Win32::Pipe->Error();
    if ($err == 535) { 
      _push(\@res, 3, 1, "Server(NB) connect: peer already connected"); 
    }
    else { 
      diag "Server connect failed: [$err] \"$msg\"";
      _push(\@res, 3, 0, "Server(NB) connect"); 
      $server->Close(); 
      return \@res; 
    }
  } else {
    _push(\@res, 3, 1, "Server(NB) connected");
  }

  # Poll wait (max ~2 s), then Read (non-blocking)
  my $can = $server->wait(2000);
  _push(\@res, 5, $can, "Server(NB) wait OK");

  my $data = $server->Read();
  my $ok_match = $can && defined $data && $data eq $message;
  _push(\@res, 6, $ok_match, "Server(NB) read matches");

  $server->Disconnect();
  $server->Close();
  return \@res;
}

# --- CLIENT ---
sub client_thread {
  my ($full_name, $bufsize, $message, $label) = @_;
  my @res;

  # Minimal Stagger (create server first/call Connect)
  select(undef, undef, undef, 50/1000);

  # Retry auf CreateFile: 2=FILE_NOT_FOUND, 231=PIPE_BUSY
  my $client; 
  my ($err, $msg) = (0, '');
  for ( 1 .. 500 ) {    # ~5 s
    $client = Win32::Pipe->new($full_name) and last;
    ($err, $msg) = Win32::Pipe->Error();
    last if $err && $err != 2 && $err != 231;
    select(undef, undef, undef, 10/1000);
  }
  unless ($client) {
    diag "Client created failed: [$err] \"$msg\"";
    _push(\@res, 2, 0, "Client($label) created");
    return \@res;
  }

  $client->ResizeBuffer($bufsize);
  _push(\@res, 2, 1, "Client($label) created (bufsize=".
    $client->BufferSize().")");

  my $r = $client->Write($message) ? 1 : 0;
  if (!$r) {
    my ($err, $msg) = Win32::Pipe->Error();
    diag "Client write failed: [$err] \"$msg\"";
    _push(\@res, 4, 0, "Client($label) wrote");
    $client->Close(); return \@res;
  }
  _push(\@res, 4, 1, "Client($label) wrote");

  $client->Close();
  return \@res;
}

SKIP: {
  # 12 checks per bufsize (Sync + NB)
  skip "ithreads not available; skipping tests", 3 * 12 
    unless $Config{useithreads};

  for my $bufsize (128, 512, 256) {
    note "start bufsize=$bufsize";
    my $name = 'testpipe-' . $$ . '-' . int(rand(1_000_000));
    my $full = "\\\\.\\pipe\\$name";
    my $msg  = "X" x ($bufsize - 10) . "Y";

    note 'Sync Subtest';
    {
      my $t_srv = threads->create(\&server_thread_sync, $name, $bufsize, $msg);
      my $t_cli = threads->create(\&client_thread, $full, $bufsize, $msg, 'S');

      my $server = $t_srv->join();
      my $client = $t_cli->join();

      my @all = sort { $a->[0] <=> $b->[0] } (@$server, @$client);
      for my $r (@all) {
        my ( $seq, $ok, $text ) = @$r;
        ok( $ok, "$text (bufsize=$bufsize)" );
      }
    }

    note 'Non-Blocking Subtest';
    TODO: {
      local $TODO = 'Race condition';
      my $t_srv = threads->create(\&server_thread_nb, $name, $bufsize, $msg);
      my $t_cli = threads->create(\&client_thread, $full, $bufsize, $msg, 'NB');

      my $server = $t_srv->join();
      my $client = $t_cli->join();

      my @all = sort { $a->[0] <=> $b->[0] } (@$server, @$client);
      for my $r (@all) {
        my ( $seq, $ok, $text ) = @$r;
        ok( $ok, "$text (bufsize=$bufsize)" );
      }
    }
  }
}

done_testing;
