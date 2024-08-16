package YATT::Lite::WebMVC0::SiteApp::CGI;
# -*- coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Lite::WebMVC0::SiteApp; # To make lint happy, this is required.

package YATT::Lite::WebMVC0::SiteApp;

#
# For debugging only (at least for now).
#
sub _callas_cgi {
  (my MY $self, my $app, my $fh, my Env $init_env, my ($args, %opts)) = @_;

  my Env $env = $self->psgi_cgi_newenv($init_env, $fh);

  my $res;
  if ($self->{cf_noheader}) {
    require Cwd;
    local $env->{GATEWAY_INTERFACE} = 'CGI/YATT';
    local $env->{REQUEST_METHOD} //= 'GET';
    local @{$env}{qw(PATH_TRANSLATED REDIRECT_STATUS)}
      = (Cwd::abs_path(shift @$args), 200)
      if @_;

    if (my $err = catch { $res = $app->($env) }) {
      # XXX: Should I do error specific things?
      $res = $err;
    }

  } elsif ($env->{GATEWAY_INTERFACE}) {
    if (my $err = catch { $res = $app->($env) }) {
      $res = $err;
    }
  } else {
    $res = $app->($env);
    print terse_dump($res);
  }

  print terse_dump($res);
}

sub _runas_cgi {
  (my MY $self, my $fh, my Env $env, my ($args, %opts)) = @_;

  if ($self->has_htdebug("env")) {
    $self->printenv($fh, $env);
    return;
  }

  # This flag is useful to debug "malformed header from script" case.
  if ($self->has_htdebug("dumb_header")) {
    print $fh "\n\n";
  }

  $self->init_by_env($env);

  if ($self->{cf_noheader}) {
    # コマンド行起動時
    require Cwd;
    local $env->{GATEWAY_INTERFACE} = 'CGI/YATT';
    local $env->{REQUEST_METHOD} //= 'GET';
    local @{$env}{qw(PATH_TRANSLATED REDIRECT_STATUS)}
      = (Cwd::abs_path(shift @$args), 200)
	if @_;

    my @params = $self->make_cgi($env, $args, \%opts);
    my $con = $self->make_connection($fh, @params);
    $self->cgi_dirhandler($con, @params);

  } elsif ($env->{GATEWAY_INTERFACE}) {
    # Normal CGI
    if (defined $fh and fileno($fh) >= 0) {
      open STDERR, '>&', $fh or die "can't redirect STDERR: $!";
    }

    my $con;
    my $error = catch {
      my @params = $self->make_cgi($env, $args, \%opts);
      $con = $self->make_connection($fh, @params);
      $self->cgi_dirhandler($con, @params);
    };

    $self->cgi_process_error($error, $con, $fh, $env);
    $con->header_was_sent if $con;

  } else {
    # dispatch without catch.
    my @params = $self->make_cgi($env, $args, \%opts);
    my $con = $self->make_connection($fh, @params, no_auto_flush_headers => 1);
    $self->cgi_dirhandler($con, @params);
  }
}

#========================================

sub cgi_dirhandler {
  (my MY $self, my ($con, %params)) = @_;
  # dirhandler は必ず load することにする。 *.yatt だけでなくて *.ydo でも。
  # 結局は機能集約モジュールが欲しくなるから。
  # そのために、 dirhandler は死重を減らすよう、部分毎に delayed load する

  my $dh = $self->get_dirhandler(untaint_any($params{dir}))
    or die "Unknown directory: $params{dir}";
  # XXX: cache のキーは相対パスか、絶対パスか?

  $con->configure(yatt => $dh);

  $self->run_dirhandler($dh, $con, $params{file});

  try_invoke($con, 'flush_headers');

  wantarray ? ($dh, $con) : $con;
}

#========================================
# XXX: $env 渡し中心に変更する. 現状では...
# [1] $fh, $cgi を外から渡すケース... そもそも、これを止めるべき. $env でええやん、と。
# [2] $fh, $file, []/{}
# [3] $fh, $file, k=v, k=v... のケース

sub make_cgi {
  (my MY $self, my Env $env, my ($args, $opts)) = @_;
  my ($cgi, $root, $loc, $file, $trailer, $is_index);
  unless ($self->{cf_noheader}) {
    $cgi = do {
      if (ref $args and UNIVERSAL::can($args, 'param')) {
	$args;
      } else {
	$self->new_cgi(@$args);
      }
    };

    ($root, $loc, $file, $trailer, $is_index) = my @pi = $self->split_path_info($env);

    unless (@pi) {
      # XXX: This is too early for fatal to browser. mmm
      $self->error("Can't parse request. env='%s'", terse_dump($env));
    }

    # XXX: /~user_dir の場合は $dir ne $root$loc じゃんか orz...

  } else {
    my $path = shift @$args;
    unless (defined $path) {
      die "Usage: $0 tmplfile args...\n";
    }
    unless ($path =~ m{^/}) {
      unless (-e $path) {
	 die "No such file: $path\n";
      }
      # XXX: $path が相対パスだったら?この時点で abs 変換よね？
      require Cwd;		# でも、これで 10ms 遅くなるのよね。
      $path = Cwd::abs_path($path) // die "No such file: $path\n";
    }
    # XXX: widget 直接呼び出しは？ cgi じゃなしに、直接パラメータ渡しは？ =>
    ($root, $loc, $file, $trailer, $is_index) = split_path($path, $self->{cf_app_root});
    $cgi = $self->new_cgi(@$args);
  }

  if ($self->has_htdebug("path_info")) {
    $self->raise_psgi_dump([loc     => $loc]
                           , [file    => $file]
                           , [trailer => $trailer]
                           , [is_index => $is_index]
                         );
  }

  (env => $env, $self->connection_quad(["$root$loc", $loc, $file, $trailer])
   , cgi => $cgi, root => $root, is_psgi => 0);
}

sub init_by_env {
  (my MY $self, my Env $env) = @_;
  $self->{cf_noheader} //= 0 if $env->{GATEWAY_INTERFACE};
  $self->{cf_doc_root} //= $env->{DOCUMENT_ROOT} if $env->{DOCUMENT_ROOT};
  $self;
}

sub new_cgi {
  my MY $self = shift;
  my (@params) = do {
    unless (@_) {
      ()
    } elsif (@_ == 1 and defined $_[0] and not ref $_[0] and $_[0] =~ /[&;]/) {
      $_[0]; # Raw query string
    } elsif (@_ > 1 or defined $_[0] and not ref $_[0]) {
      # k=v list
      $self->parse_params(\@_, {})
    } elsif (not defined $_[0]) {
      ();
    } elsif (ref $_[0] eq 'ARRAY') {
      my %hash = @{$_[0]};
      \%hash;
    } else {
      $_[0];
    }
  };
  require CGI; CGI->new(@params);
  # shift; require CGI::Simple; CGI::Simple->new(@_);
}

sub cgi_process_error {
  (my MY $self, my ($error, $con, $fh, $env)) = @_;
  if (not $error or is_done($error)) {
    if (not tell($fh) and (my $len = length($con->buffer))) {
      # We have buffered content but not yet delivered!
      # Possible misuse of Connection API.
      $self->cgi_response($fh, $env
			  , 200
			  , ["Content-type", $con->_mk_content_type]
			  # XXX: We should add API usage suggestion here.
			  , [$con->buffer]);
    } else {
      # Already delivered.
    }
  } elsif (ref $error eq 'ARRAY') {
    # Non local exit with PSGI response triplet.
    $self->cgi_response($fh, $env, @{$error});

  } elsif (defined $con and UNIVERSAL::isa($error, $self->Error)) {
    # To erase premature output.
    $con->rewind;

    # Known error. Header (may be) already printed.
    (undef, my $ct, my @rest) = $self->secure_text_plain;
    $con->set_content_type($ct);
    $con->set_header_list(@rest) if @rest;
    $con->flush_headers;
    print $fh $error->message;

  } else {
    # Unknown error.
    $self->show_error($fh, $error, $env);
  }
}

sub cgi_response {
  (my MY $self, my ($fh, $env, $code, $headers, $body)) = @_;
  my $header = mk_http_status($code);
  while (my ($k, $v) = splice @$headers, 0, 2) {
    $header .= "$k: $v\015\012";
  }
  $header .= "\015\012";

  print {*$fh} $header;
  print {*$fh} @$body;
}

sub printenv {
  (my MY $self, my ($fh, $env)) = @_;
  $self->dump_pairs($fh, map {$_ => $env->{$_}} sort keys %$env);
}

sub dump_pairs {
  (my MY $self, my ($fh)) = splice @_, 0, 2;
  $self->show_error($fh);
  while (my ($name, $value) = splice @_, 0, 2) {
    print $fh $name, "\t", terse_dump($value), "\n";
  }
}

sub show_error {
  (my MY $self, my ($fh, $error, $env)) = @_;
  if (my @kv = $self->secure_text_plain) {
    while (my ($k, $v) = splice @kv, 0, 2) {
      print $fh "$k: $v\n";
    }
  } else {
    print $fh "\n";
  }
  print $fh "\n". ($error // "");
}

sub psgi_cgi_newenv {
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

&YATT::Lite::Breakpoint::break_load_dispatcher_cgi;

1;
