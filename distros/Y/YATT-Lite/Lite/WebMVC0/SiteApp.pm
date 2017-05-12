package YATT::Lite::WebMVC0::SiteApp;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Breakpoint;
sub MY () {__PACKAGE__}

use 5.010; no if $] >= 5.017011, warnings => "experimental";

#========================================
# Dispatcher Layer: load and run corresponding DirApp for incoming request.
#========================================

use parent qw(YATT::Lite::Factory);
use YATT::Lite::MFields qw/cf_noheader
			   cf_is_psgi
			   cf_no_nested_query
			   allow_debug_from
			   cf_debug_cgi
			   cf_debug_psgi
			   cf_debug_connection
			   cf_debug_backend
			   cf_psgi_static
			   cf_psgi_fallback
			   cf_per_role_docroot
			   cf_per_role_docroot_key
			   cf_default_role
			   cf_backend
			   cf_site_config
			   cf_logfile
			   cf_debug_allowed_ip
			   cf_overwrite_status_code_for_errors_as
			   re_handled_ext
			 /;

use YATT::Lite::Util qw(cached_in split_path catch
			lookup_path nonempty try_invoke
			mk_http_status
			default ckrequire
			escape
			lexpand rootname extname untaint_any terse_dump);
use YATT::Lite::Util::CmdLine qw(parse_params);
use YATT::Lite qw/Entity *SYS *CON/;
use YATT::Lite::WebMVC0::DirApp ();
sub DirApp () {'YATT::Lite::WebMVC0::DirApp'}
sub default_default_app () {'YATT::Lite::WebMVC0::DirApp'}

use File::Basename;

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new();
  $self->{re_handled_ext} = qr{\.($self->{cf_ext_public}|ydo)$};
  $self->{cf_per_role_docroot_key} ||= $self->default_per_role_docroot_key;
  $self->{cf_default_role} ||= $self->default_default_role;
}

sub default_per_role_docroot_key { 'yatt.role' }
sub default_default_role { 'nobody' }

sub _cf_delegates {
  (shift->SUPER::_cf_delegates
   , qw(overwrite_status_code_for_errors_as));
}

#========================================
# runas($type, $fh, \%ENV, \@ARGV)  ... for CGI/FCGI support.
#========================================

sub runas {
  (my $this, my $type) = splice @_, 0, 2;
  my MY $self = ref $this ? $this : $this->new;
  my $sub = $self->can("runas_$type")
    or die "\n\nUnknown runas type: $type";
  $sub->($self, @_);
}

sub runas_cgi {
  require YATT::Lite::WebMVC0::SiteApp::CGI;
  shift->_runas_cgi(@_);
}
sub runas_fcgi {
  require YATT::Lite::WebMVC0::SiteApp::FCGI;
  shift->_runas_fcgi(@_);
}

#========================================

# Dispatcher::get_dirhandler
# -> Util::cached_in
# -> Factory::load
# -> Factory::buildspec

sub get_dirhandler {
  (my MY $self, my $dirPath) = @_;
  $dirPath =~ s,/*$,,;
  $self->{path2yatt}{$dirPath} ||= $self->load_yatt($dirPath);
}

sub get_lochandler {
  (my MY $self, my ($location, $tmpldir)) = @_;
  if ($self->{cf_per_role_docroot}) {
    # When per_role_docroot is on, $tmpldir already points
    # $per_role_docroot/$role. So just append $location.
    $self->get_dirhandler($tmpldir.$location);
  } else {
    $self->SUPER::get_lochandler($location, $tmpldir);
  }
}

#----------------------------------------
# preload_handlers

sub preload_apps {
  (my MY $self, my (@dir)) = @_;
  push @dir, $self->{cf_doc_root} unless @dir;

  my @apps;
  foreach my $dir ($self->find_apps(@dir)) {
    push @apps, my $app = $self->get_dirhandler($dir);
  }
  @apps;
}

sub find_apps {
  (my MY $self, my @dir) = @_;
  require File::Find;
  my @apps;
  my $handler = sub {
    push @apps, $_ if -d;
  };
  File::Find::find({wanted => $handler
		    , no_chdir => 1
		    , follow_skip => 2}
		   , @dir
		  );
  @apps;
}

#========================================
# PSGI Adaptor
#========================================
use YATT::Lite::PSGIEnv;

sub to_app {
  my MY $self = shift;
#  XXX: Should check it.
#  unless (defined $self->{cf_app_root}) {
#    croak "app_root is undef!";
#  }
  unless (defined $self->{cf_doc_root}
	  or defined $self->{cf_per_role_docroot}) {
    croak "document_root is undef!";
  }
  return $self->SUPER::to_app(@_);
}

sub prepare_app {
  (my MY $self) = @_;
  $self->{cf_is_psgi} = 1;
  require Plack::Request;
  require Plack::Response;
  my $backend;
  if ($backend = $self->{cf_backend}
      and my $sub = $backend->can('startup')) {
    $sub->($backend, $self, $self->preload_apps);
  }
}

sub call {
  (my MY $self, my Env $env) = @_;

  YATT::Lite::Breakpoint::break_psgi_call();

  if ($self->has_htdebug("env")) {
    return $self->psgi_dump(map {"$_\t".($env->{$_}//"(undef)")."\n"}
			    sort keys %$env);
  }

  if (my $deny = $self->has_forbidden_path($env->{PATH_INFO})
      // $self->has_forbidden_path($env->{PATH_TRANSLATED})) {
    return $self->psgi_error(403, "Forbidden $deny");
  }

  if (not $self->{cf_no_unicode_params}
      and $self->{cf_output_encoding}) {
    $env->{PATH_INFO} = Encode::decode($self->{cf_output_encoding}
				       , $env->{PATH_INFO});
  }

  if ($self->{loc2psgi_dict}
      and my $psgi_app = $self->lookup_psgi_mount($env->{PATH_INFO})) {
    require Plack::Util;
    return Plack::Util::run_app($psgi_app, $env);
  }

  # XXX: user_dir?
  my ($tmpldir, $loc, $file, $trailer, $is_index)
    = my @pi = $self->split_path_info($env);

  my ($realdir, $virtdir);
  if (@pi) {
    $realdir = "$tmpldir$loc";
    $virtdir = defined $self->{cf_doc_root}
      ? "$self->{cf_doc_root}$loc" : $realdir;
  }

  if ($self->has_htdebug("path_info")) {
    return $self->psgi_dump([tmpldir   => $tmpldir]
			    , [loc     => $loc]
			    , [file    => $file]
			    , [trailer => $trailer]
			    , [virtdir => $virtdir, realdir => $realdir]
			  );
  }

  if ($self->{cf_debug_psgi}) {
    # XXX: should be configurable.
    if (my $errfh = fileno(STDERR) ? \*STDERR : $env->{'psgi.errors'}) {
      print $errfh join("\t"
			, "# REQ: "
			, terse_dump([tmpldir   => $tmpldir]
				     , [loc     => $loc]
				     , [file    => $file]
				     , [trailer => $trailer]
				     , ['all templdirs', $self->{tmpldirs}]
				     , map {[$_ => $env->{$_}]} sort keys %$env)
		       ), "\n";
    }
  }

  unless (@pi) {
    return $self->psgi_handle_fallback($env);
  }

  unless (-d $realdir) {
    return $self->psgi_error(404, "Not found: $loc");
  }

  # Default index file.
  # Note: Files may placed under (one of) tmpldirs instead of docroot.
  if ($file eq '') {
    $file = "$self->{cf_index_name}.$self->{cf_ext_public}";
  } elsif ($file eq $self->{cf_index_name}) { #XXX: $is_index
    $file .= ".$self->{cf_ext_public}";
  }

  if ($file !~ $self->{re_handled_ext}) {
    if ($self->{cf_debug_psgi} and $self->has_htdebug("static")) {
      return $self->psgi_dump("Not handled since extension doesn't match"
			      , $file, $self->{re_handled_ext});
    }
    return $self->psgi_handle_static($env);
  }

  my $dh = $self->get_lochandler(map {untaint_any($_)} $loc, $tmpldir) or do {
    return $self->psgi_error(404, "No such directory: $loc");
  };

  # To support $con->param and other cgi compat methods.
  my $req = Plack::Request->new($env);

  my @params = (env => $env
		, path_info => $env->{PATH_INFO}
		, $self->connection_quad([$virtdir, $loc, $file, $trailer])
		, $is_index ? (is_index => 1) : ()
		, is_psgi => 1, cgi => $req);

  my $con = $self->make_connection(undef, @params, yatt => $dh, noheader => 1);

  my $error = catch {
    $self->run_dirhandler($dh, $con, $file);
  };

  try_invoke($con, 'flush_headers');

  if (not $error or is_done($error)) {
    my $res = Plack::Response->new(200);
    $res->content_type("text/html"
		       . ($self->{cf_header_charset}
			  ? qq{; charset="$self->{cf_header_charset}"}
			  : ""));
    if (my @h = $con->list_header) {
      $res->headers->header(@h);
    }
    $res->body($con->buffer);
    return $res->finalize;
  } elsif (ref $error eq 'ARRAY') {
    # redirect
    if ($self->{cf_debug_psgi}) {
      if (my $errfh = fileno(STDERR) ? \*STDERR : $env->{'psgi.errors'}) {
	print $errfh "PSGI Tuple: ", terse_dump($error), "\n";
      }
    }
    return $error;
  } else {
    # system_error. Should be treated by PSGI Server.
    die $error;
  }
}

sub make_debug_params {
  (my MY $self, my ($reqrec, $args)) = @_;

  my ($path_info, @rest) = ref $reqrec ? @$reqrec : $reqrec;

  my Env $env = Env->psgi_simple_env;
  $env->{PATH_INFO} = $path_info;
  $env->{REQUEST_URI} = $path_info;

  my @params = ($self->SUPER::make_debug_params($reqrec, $args)
		, env => $env);

  #
  # Only for debugging aid. See YATT/samples/db_backed/1/t/t_signup.pm
  #
  if (@rest == 2 and defined $rest[-1] and ref $args eq 'HASH') {
    require Hash::MultiValue;
    push @params, hmv => Hash::MultiValue->from_mixed($args);
  }

  @params;
}

#========================================

sub psgi_handle_static {
  (my MY $self, my Env $env) = @_;
  my $app = $self->{cf_psgi_static}
    || $self->psgi_file_app($self->{cf_doc_root});

  # When PATH_INFO contains virtual path prefix (like /~$user/),
  # we need to strip them (for Plack::App::File).
  local $env->{PATH_INFO} = $self->trim_site_prefix($env->{PATH_INFO});

  $app->($env);
}

sub psgi_handle_fallback {
  (my MY $self, my Env $env) = @_;
  (my $app = $self->{cf_psgi_fallback}
   ||= $self->psgi_file_app($self->{cf_doc_root}))
    or return [404, [], ["Cannot understand: ", $env->{PATH_INFO}]];

  local $env->{PATH_INFO} = $self->trim_site_prefix($env->{PATH_INFO});

  $app->($env);
}

sub trim_site_prefix {
  (my MY $self, my $path) = @_;
  if (my $pfx = $self->{cf_site_prefix}) {
    substr($path, length($pfx));
  } else {
    $path;
  }
}

# XXX: Do we need to care about following headers too?:
# * X-Content-Security-Policy
# * X-Request-With
# * X-Frame-Options
# * Strict-Transport-Security

sub is_done {
  defined $_[0] and ref $_[0] eq 'SCALAR' and not ref ${$_[0]}
    and ${$_[0]} eq 'DONE';
}

#========================================

sub split_path_info {
  (my MY $self, my Env $env) = @_;

  if (! $self->{cf_per_role_docroot}
      && nonempty($env->{PATH_TRANSLATED})
      && $self->is_path_translated_mode($env)) {
    #
    # [1] PATH_TRANSLATED mode.
    #
    # If REDIRECT_STATUS == 200 and PATH_TRANSLATED is not empty,
    # use it as a template path. It must be located under app_root.
    #
    # In this case, PATH_TRANSLATED should be valid physical path
    # + optionally trailing sub path_info.
    #
    # XXX: What should be done when app_root is empty?
    # XXX: Is userdir ok? like /~$USER/dir?
    # XXX: should have cut_depth option.
    #
    split_path($env->{PATH_TRANSLATED}, $self->{cf_app_root}
	       , $self->{cf_use_subpath}
	       , $self->{cf_ext_public}
	     );
    # or die.

  } elsif (nonempty($env->{PATH_INFO})) {
    #
    # [2] Template lookup mode.
    #

    my $tmpldirs = do {
      if ($self->{cf_per_role_docroot}) {
        my $user = $env->{$self->{cf_per_role_docroot_key}};
        $user ||= $self->{cf_default_role};
        ["$self->{cf_per_role_docroot}/$user"]
      } else {
        $self->{tmpldirs}
      }
    };

    lookup_path($env->{PATH_INFO}
		, $tmpldirs
		, $self->{cf_index_name}, ".$self->{cf_ext_public}"
		, $self->{cf_use_subpath});
  } else {
    # or die
    return;
  }
}

sub has_forbidden_path {
  (my MY $self, my $path) = @_;
  given ($path) {
    when (undef) {
      return undef;
    }
    when (m{\.lib(?:/|$)}) {
      return ".lib: $path";
    }
    when (m{(?:^|/)\.ht|\.ytmpl$}) {
      # XXX: basename() is just to ease testing.
      return "filetype: " . basename($path);
    }
  }
}

sub is_path_translated_mode {
  (my MY $self, my Env $env) = @_;
  ($env->{REDIRECT_STATUS} // 0) == 200
}

# XXX: kludge! redundant!
sub split_path_url {
  (my MY $self, my ($path_translated, $path_info, $document_root)) = @_;

  my @info = do {
    if ($path_info =~ s{^(/~[^/]+)(?=/)}{}) {
      my $user = $1;
      my ($root, $loc, $file, $trailer)
	= split_path($path_translated
		     , substr($path_translated, 0
			      , length($path_translated) - length($path_info))
		     , 0
		    );
      (dir => "$root$loc", file => $file, subpath => $trailer
       , root => $root, location => "$user$loc");
    } else {
      my ($root, $loc, $file, $trailer)
	= split_path($path_translated, $document_root, 0);
      (dir => "$root$loc", file => $file, subpath => $trailer
       , root => $root, location => $loc);
    }
  };

  if (wantarray) {
    @info
  } else {
    my %info = @info;
    \%info;
  }
}

# どこを起点に split_path するか。UserDir の場合は '' を返す。
sub document_dir {
  (my MY $self, my $cgi) = @_;
  my $path_info = $cgi->path_info;
  if (my ($user) = $path_info =~ m{^/~([^/]+)/}) {
    '';
  } else {
    $self->{cf_doc_root} // '';
  }
}

#========================================
sub is_debug_allowed {
  (my MY $self, my Env $env) = @_;
  return unless $self->{allow_debug_from};
  return unless defined(my $ip = $self->guess_client_ip($env));
  $ip =~ $self->{allow_debug_from};
}

sub guess_client_ip {
  (my MY $self, my Env $env) = @_;
  $env->{HTTP_X_REAL_IP} // $env->{HTTP_X_CLIENT_IP} // do {
    if (defined(my $forward = $env->{HTTP_X_FORWARDED_FOR})) {
      [split /(?:\s*,\s*|\s+)/, $forward]->[0];
    } else {
      $env->{REMOTE_ADDR}
    }
  }
}

sub configure_allow_debug_from {
  (my MY $self, my $data) = @_;
  my $pat = join "|", map { quotemeta($_) } lexpand($data);
  $self->{allow_debug_from} = qr{^(?:$pat)};
}

sub has_htdebug {
  (my MY $self, my $name) = @_;
  defined $self->{cf_app_root}
    and -e "$self->{cf_app_root}/.htdebug_$name"
}

sub psgi_dump {
  my MY $self = shift;
  [200
   , [$self->secure_text_plain]
   , [map {escape(terse_dump($_))} @_]];
}

#========================================

#========================================

use YATT::Lite::WebMVC0::Connection;
sub Connection () {'YATT::Lite::WebMVC0::Connection'}
sub ConnProp () {Connection}

sub make_connection {
  (my MY $self, my ($fh, @args)) = @_;
  my @opts = do {
    if ($self->{cf_noheader}) {
      # direct mode.
      ($fh, noheader => 1);
    } else {
      # buffered mode.
      (undef, parent_fh => $fh);
    }
  };

  push @opts, site_prefix => $self->{cf_site_prefix};

  if (my $fn = $self->{cf_logfile}) {
    my $dir = $self->app_path_ensure_existing(dirname($fn));
    my $real = "$dir/" . basename($fn);
    open my $fh, '>>', $real or die "Can't open logfile: fn=$real: $!";
    push @opts, logfh => $fh;
  }

  push @opts, debug => $self->{cf_debug_connection}
    if $self->{cf_debug_connection};

  if (my $back = $self->{cf_backend}) {
    push @opts, (backend => try_invoke($back, 'clone') // $back);
  }

  if (my $enc = $$self{cf_output_encoding}) {
    push @opts, encoding => $enc;
  }
  $self->SUPER::make_connection
  (@opts
   , $self->cf_delegate_defined(qw(is_psgi no_nested_query))
   , @args);
}

sub finalize_connection {
  my MY $self = shift;
  my ConnProp $prop = (my $glob = shift)->prop;
  $self->session_flush($glob) if $prop->{session};
}

use YATT::Lite::WebMVC0::Partial::Session;

#========================================
# misc.
#========================================

sub header_charset {
  (my MY $self) = @_;
  $self->{cf_header_charset} || $self->{cf_output_encoding};
}

#========================================

Entity site_config => sub {
  my ($this, $name, $default) = @_;
  my MY $self = $SYS;
  return $self->{cf_site_config} unless defined $name;
  $self->{cf_site_config}{$name} // $default;
};

Entity is_debug_allowed_ip => sub {
  my ($this, $remote_addr) = @_;
  my MY $self = $SYS;

  $remote_addr //= do {
    my Env $env = $CON->env;
    $env->{HTTP_X_REAL_IP}
      // $env->{HTTP_X_CLIENT_IP}
	// $env->{HTTP_X_FORWARDED_FOR}
	  // $env->{REMOTE_ADDR};
  };

  unless (defined $remote_addr and $remote_addr ne '') {
    return 0;
  }

  grep {$remote_addr ~~ $_} lexpand($self->{cf_debug_allowed_ip}
				    // ['127.0.0.1']);
};

foreach my $item (map([lc($_) => uc($_)]
		      , qw/SCRIPT_NAME
			   PATH_INFO
			   REQUEST_URI

			   SCRIPT_URI
			   SCRIPT_URL
			   SCRIPT_FILENAME
			   /)) {
  my ($method, $env_name) = @$item;
  Entity $method => sub {
    my Env $env = $CON->env;
    $env->{$env_name};
  };
}

#========================================

YATT::Lite::Breakpoint::break_load_dispatcher();

1;
