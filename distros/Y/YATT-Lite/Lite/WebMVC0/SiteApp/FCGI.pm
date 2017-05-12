package YATT::Lite::WebMVC0::SiteApp::FCGI;
# -*- coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Lite::WebMVC0::SiteApp; # To make lint happy, this is required.
use YATT::Lite::WebMVC0::SiteApp::CGI;

package YATT::Lite::WebMVC0::SiteApp;


########################################
#
# FastCGI support with auto_exit, based on PSGI mode.
#
# Many parts are stolen from Plack::Handler::FCGI.
#
########################################

# runas_fcgi() is designed for single process app.
# If you want psgi.multiprocess, use Plack's own FCGI instead.

sub _runas_fcgi {
  (my MY $self, my $fhset, my Env $init_env, my ($args, %opts)) = @_;
  # $fhset is either stdout or [\*STDIN, \*STDOUT, \*STDERR].
  # $init_env is just discarded.
  # $args = \@ARGV
  # %opts is fcgi specific options.

  local $self->{cf_is_psgi} = 1;

  # In suexec fcgi, $0 will not be absolute path.
  my $progname = do {
    if (-r (my $fn = delete $opts{progname} || $0)) {
      $self->rel2abs($fn);
    } else {
      croak "progname is empty!";
    }
  };

  if ((my $dn = $progname) =~ s{/html/cgi-bin/[^/]+$}{}) {
    $self->{cf_app_root} //= $dn;
    $self->{cf_doc_root} //= "$dn/html";
    push @{$self->{tmpldirs}}, $self->{cf_doc_root}
      unless $self->{tmpldirs} and @{$self->{tmpldirs}};
    #print STDERR "Now:", terse_dump($self->{cf_app_root}, $self->{cf_doc_root}
    #				    , $self->{tmpldirs}), "\n";
  }

  $self->prepare_app;

  my $dir = dirname($progname);
  my $age = -M $progname;

  my ($stdin, $stdout, $stderr) = ref $fhset eq 'ARRAY' ? @$fhset
    : (\*STDIN, $fhset
       , ((delete $opts{isolate_stderr}) // 1) ? \*STDERR : $fhset);

  require FCGI;
  my $sock = do {
    if (my $sockfile = delete $opts{listen}) {
      unless (-e (my $d = dirname($sockfile))) {
	require File::Path;
	File::Path::make_path($d)
	    or die "Can't mkdir $d: $!";
      }
      FCGI::OpenSocket($sockfile, 100)
	  or die "Can't open FCGI socket '$sockfile': $!";
    } else {
      0;
    }
  };

  my %env;
  my $request = FCGI::Request
    ($stdin, $stdout, $stderr
     , \%env, $sock, $opts{nointr} ? 0 :&FCGI::FAIL_ACCEPT_ON_INTR);

  if (keys %opts) {
    croak "Unknown options: ".join(", ", sort keys %opts);
  }

  local $self->{cf_at_done} = sub {die \"DONE"};
  local $SIG{PIPE} = 'IGNORE';
  while ($request->Accept >= 0) {
    my Env $env = $self->psgi_fcgi_newenv(\%env, $stdin, $stderr);

    if (-e "$dir/.htdebug_env") {
      $self->printenv($stdout, $env);
      next;
    }

    my $res;
    if (my $err = catch { $res = $self->call($env) }) {
      # XXX: Should I do error specific things?
      $res = $err;
    }

    unless (defined $res) {
      die "Empty response";
    }
    elsif (ref $res eq 'ARRAY') {
      $self->fcgi_handle_response($res);
    }
    elsif (ref $res eq 'CODE') {
      $res->(sub {
	       $self->fcgi_handle_response($_[0]);
	     });
    }
    elsif (not ref $res or UNIVERSAL::can($res, 'message')) {
      print $stderr $res if $$stderr ne $stdout;
      if ($self->is_debug_allowed($env)) {
	$self->cgi_process_error($res, undef, $stdout, $env);
      } else {
	$self->cgi_process_error("Application error", undef, $stdout, $env);
      }
    }
    else {
      die "Bad response $res";
    }

    $request->Finish;

    # Exit if bootscript is modified.
    last if -e $progname and -M $progname < $age;
  }
}

sub psgi_fcgi_newenv {
  (my MY $self, my Env $init_env, my ($stdin, $stderr)) = @_;
  require Plack::Util;
  require Plack::Request;
  my Env $env = +{ %$init_env };
  $env->{'psgi.version'} = [1,1];
  $env->{'psgi.url_scheme'}
    = ($init_env->{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http';
  $env->{'psgi.input'}        = $stdin  || *STDIN;
  $env->{'psgi.errors'}       = $stderr || *STDERR;
  $env->{'psgi.multithread'}  = &Plack::Util::FALSE;
  $env->{'psgi.multiprocess'} = &Plack::Util::FALSE; # XXX:
  $env->{'psgi.run_once'}     = &Plack::Util::FALSE;
  $env->{'psgi.streaming'}    = &Plack::Util::FALSE; # XXX: Todo.
  $env->{'psgi.nonblocking'}  = &Plack::Util::FALSE;
  # delete $env->{HTTP_CONTENT_TYPE};
  # delete $env->{HTTP_CONTENT_LENGTH};
  $env;
}

sub fcgi_handle_response {
    my ($self, $res) = @_;

    require HTTP::Status;

    *STDOUT->autoflush(1);
    binmode STDOUT;

    my $hdrs;
    my $message = HTTP::Status::status_message($res->[0]);
    $hdrs = "Status: $res->[0] $message\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    print STDOUT $hdrs;

    my $cb = sub { print STDOUT $_[0] };
    my $body = $res->[2];
    if (defined $body) {
        Plack::Util::foreach($body, $cb);
    }
    else {
        return Plack::Util::inline_object
            write => $cb,
            close => sub { };
    }
}

&YATT::Lite::Breakpoint::break_load_dispatcher_fcgi;

1;
