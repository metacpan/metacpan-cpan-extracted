#!/usr/bin/env perl
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(File::Spec);
sub MY () {__PACKAGE__}

use IO::Socket::UNIX;
use Fcntl;
# use POSIX qw(:sys_wait_h);

use FindBin;
use lib "$FindBin::Bin/../";
use YATT::Util::Finalizer;

use Getopt::Long;

GetOptions("s|server!" => \ my $is_server
	   , "c|client!" => \ my $is_client
	   , 'v|verbose!' => \ my $verbose
	   , 'n=i' => \ (my $GOAL = 100)
	  )
  or exit 1;

{
  package test_delta;
  use Test::Builder ();
  my $Test = Test::Builder->new;
  sub is_delta_ok {
    my ($delta, $got, $expect, $desc) = @_;
    if (not defined $got and not defined $expect) {
      $Test->ok(1, $desc);
    } elsif (not defined $got) {
      $Test->ok(0, $desc);
      $Test->diag("got undef");
    } elsif (not defined $expect) {
      $Test->ok(0, $desc);
      $Test->diag("got defined");
    } elsif (abs(my $diff = $got - $expect) <= $delta) {
      $Test->ok(1, $desc);
    } else {
      $Test->ok(0, $desc);
      $Test->diag("expect $expect +- $delta, got $got");
    }
  }
}

if ($is_server and $is_client) {
  die "$0: -server and -client is exclusive\n";
}

sub do_skip_all ($) {
  my ($reason) = @_;
  require Test::More;
  Test::More::plan(skip_all => $reason);
}

unless (-r "/proc/$$/status") {
  do_skip_all '/proc/$pid/status is not available for your system';
}

unless (MY->which('cgi-fcgi')) {
  do_skip_all "cgi-fcgi is not installed";
}

my $sessdir  = MY->tmpdir . "/fcgitest$$";
my $sockfile = "$sessdir/socket";

unless (mkdir $sessdir, 0700) {
  die "Can't mkdir $sessdir: $!";
}

unless (eval {require FCGI}) {
  do_skip_all 'FCGI.pm is not installed';
}
unless (eval {require CGI::Fast}) {
  do_skip_all 'CGI::Fast is not installed';
}

if ($is_server or (defined $is_client and not $is_client)
    or my $kid = fork) {
  # parent

  my $scope = finally {
    kill TERM => $kid;
    waitpid($kid, 0);

    unlink $sockfile if -e $sockfile;
    rmdir $sessdir;
    exit 0;
  };

  require Test::More;
  import Test::More;

  plan(tests => 2);

  ok(my $fcgi = MY->which('cgi-fcgi'), "cgi-fcgi is available");

  unless (-w $sockfile) {
    print "# waiting for socketfile $sockfile\n" if $verbose;
    sleep 1;
  }

  # First request.
  my @res = MY->send_request($fcgi, $sockfile, GET => '/');
  print "# ", join("|", @res), "\n" if $verbose;

  # Memory size after processing of first request.
  my $at_start = MY->memsize($kid);

  for (my $cnt = 1; $cnt < $GOAL; $cnt++) {
    my @res = MY->send_request($fcgi, $sockfile, GET => '/');
    print "# ", join("|", @res), "\n" if $verbose;
  }

  test_delta::is_delta_ok(4, MY->memsize($kid), $at_start
			  , "memsize after $GOAL calls");
} else {
  die "Can't fork: $!" if not defined $is_client and not defined $kid;

  require FCGI;

  my $sock = FCGI::OpenSocket($sockfile, 100)
    or die "Can't open socket '$sockfile': $!";

  my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV
			      , $sock, &FCGI::FAIL_ACCEPT_ON_INTR);

  my $count = 0;
  while ($request->Accept() >= 0) {
    print ++$count; # Plaintext is enough because this is not talking to httpd.
    {
      # To avoid "Use of uninitialized value in numeric eq (==) at /usr/lib64/perl5/FCGI.pm line 59."
      local $SIG{__DIE__} = sub {}; local $SIG{__WARN__} = sub {};

      $request->Finish();
    }
    # last if $count >= $GOAL;
  }
  # exit;
}

#========================================

sub send_request {
  my ($pack, $fcgi, $sock, $method, $path, @query) = @_;
  local $ENV{SERVER_SOFTWARE} = 'PERL_FCGI_LEAKTEST';
  local $ENV{REQUEST_METHOD} = uc($method);
  local $ENV{REQUEST_URI} = $path;
  local $ENV{QUERY_STRING} = @query ? join("&", @query) : undef;

  open my $pipe, "-|", $fcgi, qw(-bind -connect) => $sock
    or die "Can't invoke $fcgi: $!";
  local $/ = "\r\n";
  my @result; chomp(@result = <$pipe>);
  @result;
}

#========================================
sub fgrep (&@);

sub which {
  my ($pack, $exe) = @_;
  foreach my $path ($pack->path) {
    if (-x (my $fn = $pack->join($path, $exe))) {
      return $fn;
    }
  }
}

sub procfile {
  my ($pack, $pid) = @_;
  my $proc = "/proc/$pid/status";
  return unless -r $proc;
  $proc;
}

sub memsize {
  my ($pack, $pid) = @_;
  scalar fgrep {s/^VmRSS:\s+(\d+)\D+$/$1/} $pack->procfile($pid);
}

#========================================

sub fgrep (&@) {
  my ($sub, @files) = @_;
  local @ARGV = @files;
  local $_;
  my (@result);
  while (<>) {
    next unless $sub->();
    push @result, $_;
  }
  wantarray ? @result : $result[0];
}
