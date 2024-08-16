package YATT::Lite::WebMVC0::SiteApp::FCGI;
# -*- coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);

use FCGI;

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

sub _prepare_config_for_fcgi {
  (my MY $self, my ($opts)) = @_;

  $self->{cf_is_psgi} = 1;

  # In suexec fcgi, $0 will not be absolute path.
  $self->{cf_progname} //= do {
    if (-r (my $fn = delete $opts->{progname} || $0)) {
      $self->rel2abs($fn);
    } else {
      croak "progname is empty!";
    }
  };

  if ((my $dn = $self->{cf_progname}) =~ s{/html/cgi-bin/[^/]+$}{}) {
    $self->{cf_app_root} //= $dn;
    $self->{cf_doc_root} //= "$dn/html";
    push @{$self->{tmpldirs}}, $self->{cf_doc_root}
      unless $self->{tmpldirs} and @{$self->{tmpldirs}};
    #print STDERR "Now:", terse_dump($self->{cf_app_root}, $self->{cf_doc_root}
    #				    , $self->{tmpldirs}), "\n";
  }
}

# callas_fcgi() and runas_fcgi() is designed for single process app.
# If you want psgi.multiprocess, use Plack's own FCGI instead.

#
# Check timestamp for $self->{cf_progname} and exit when modified.
# (Outer processmanager is responsible to restart).
#
sub _callas_fcgi {
  (my MY $self, my $app, my $fhset, my Env $init_env, my ($args, %opts)) = @_;
  # $fhset is either stdout or [\*STDIN, \*STDOUT, \*STDERR].
  # $init_env is just discarded.
  # $args = \@ARGV
  # %opts is fcgi specific options.

  $self->_prepare_config_for_fcgi(\%opts);

  my $dir = dirname($self->{cf_progname});
  my $age = -M $self->{cf_progname};

  my ($stdin, $stdout, $stderr) = ref $fhset eq 'ARRAY' ? @$fhset
    : (\*STDIN, $fhset
       , ((delete $opts{isolate_stderr}) // 1) ? \*STDERR : $fhset);

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
    if (my $err = catch { $res = $app->($env) }) {
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
    last if -e $self->{cf_progname} and -M $self->{cf_progname} < $age;
  }
}

sub _runas_fcgi {
  (my MY $self, my $fhset, my Env $init_env, my ($args, %opts)) = @_;

  # This will be called again in _callas_fcgi, but it will not harm.
  $self->_prepare_config_for_fcgi(\%opts);

  $self->prepare_app;

  $self->_callas_fcgi($self->to_app, $fhset, $init_env, $args, %opts);
}

*psgi_fcgi_newenv = *psgi_cgi_newenv;
*psgi_fcgi_newenv = *psgi_cgi_newenv;

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
