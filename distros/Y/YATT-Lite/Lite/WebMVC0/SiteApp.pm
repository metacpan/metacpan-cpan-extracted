package YATT::Lite::WebMVC0::SiteApp;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Breakpoint;
sub MY () {__PACKAGE__}

use mro 'c3';

use 5.010; no if $] >= 5.017011, warnings => "experimental";

use constant DEBUG_ERROR => $ENV{DEBUG_YATT_ERROR};

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
                           _site_config_cache_entry
                           cf_site_config_as_entity

			   cf_logfile
			   cf_overwrite_status_code_for_errors_as
			   re_handled_ext
                           handled_ext_list

                           cf_^progname

                           cf_no_trim_script_name

                           cf_ext_public_action

                           cf_^config_dir
                           dirapp_config
                           cf_use_sibling_config_dir
			 /;

use YATT::Lite::Util qw(cached_in split_path catch
			lookup_path nonempty try_invoke
			mk_http_status
			default ckrequire
			escape
                        trim_common_suffix_from
                        is_done
			lexpand rootname extname untaint_any terse_dump
                        add_entity_into
                     );
use YATT::Lite::Util::CmdLine qw(parse_params);
use YATT::Lite qw/Entity *SYS *CON/;
our @EXPORT_OK = qw/*CON/;

use YATT::Lite::WebMVC0::DirApp ();
sub DirApp () {'YATT::Lite::WebMVC0::DirApp'}
sub default_default_app () {'YATT::Lite::WebMVC0::DirApp'}
sub default_ext_public_action {'ydo'}

use File::Basename;

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new();
  $self->{cf_ext_public_action} //= $self->default_ext_public_action;
  $self->{handled_ext_list} = [
    $self->{cf_ext_public}, $self->{cf_ext_public_action}
  ];
  $self->{re_handled_ext} = do {
    my $str = join("|", @{$self->{handled_ext_list}});
    qr{\.($str)$};
  };
  $self->{cf_per_role_docroot_key} ||= $self->default_per_role_docroot_key;
  $self->{cf_default_role} ||= $self->default_default_role;
  $self->{cf_config_dir} //= do {
    if (not $self->{cf_app_root}) {
      undef;
    } elsif ($self->{cf_use_sibling_config_dir}) {
      "$self->{cf_app_root}.config.d"
    } else {
      "$self->{cf_app_root}/config"
    }
  };

  $self->{dirapp_config} = +{};
  $self->{cf_site_config_as_entity} //= $self->default_site_config_as_entity;
}

sub default_per_role_docroot_key { 'yatt.role' }
sub default_default_role { 'nobody' }

sub default_site_config_as_entity {1}

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

# callas($type, $app, $fh, \%ENV, \@ARGV, %opts)

sub callas {
  (my $this, my $type) = splice @_, 0, 2;
  my MY $self = ref $this ? $this : $this->new;
  my $sub = $self->can("callas_$type")
    or die "\n\nUnknown callas type: $type";
  $sub->($self, @_);
}

sub callas_cgi {
  require YATT::Lite::WebMVC0::SiteApp::CGI;
  shift->_callas_cgi(@_);
}
sub callas_fcgi {
  require YATT::Lite::WebMVC0::SiteApp::FCGI;
  shift->_callas_fcgi(@_);
}


#========================================

# Dispatcher::get_dirhandler
# -> Util::cached_in
# -> Factory::load
# -> Factory::buildspec

sub get_lochandler {
  (my MY $self, my ($location, $tmpldir)) = @_;
  if ($self->{cf_per_role_docroot}) {
    # When per_role_docroot is on, $tmpldir already points
    # $per_role_docroot/$role. So just append $location.

    # Unfortunately, $self->error_response calls get_lochandler without $tmpldir
    $tmpldir //= "$self->{cf_per_role_docroot}/$self->{cf_default_role}";

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
use YATT::Lite::PSGIEnv qw/SCRIPT_URL/;

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

  $self->next::method;

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
      and my ($path_prefix, $psgi_app)
      = $self->lookup_psgi_mount($env->{PATH_INFO})) {
    require Plack::Util;
    local $env->{PATH_INFO} = $self->trimleft_length($env->{PATH_INFO}, $path_prefix);
    local $env->{SCRIPT_NAME} = $self->trimleft_length($env->{SCRIPT_NAME}, $path_prefix);
    return Plack::Util::run_app($psgi_app, $env);
  }

  # XXX: user_dir?
  my ($tmpldir, $loc, $file, $trailer, $is_index)
    = my @pi = $self->split_path_info($env);

  if (@pi and $loc =~ m{/\.\./}) {
    return $self->psgi_error(403, "Bad location: $loc");
  }

  # Set $env->{yatt.script_name}
  $self->set_yatt_script_name($env);

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
		, is_psgi => 1);

  local $CON = my $con = $self->make_connection(undef, @params, yatt => $dh, noheader => 1);

  my $error = catch {
    $CON->configure(cgi => $req);

    $self->run_dirhandler($dh, $con, $file);
  };

  try_invoke($con, 'flush_headers');

  if ($self->has_htdebug("response")) {
    return [200, [], [terse_dump(["caught exception" => $error])
                      , "\n", terse_dump(["diag(inner to outer)" => $CON->diag_list])
                      , "\n", terse_dump(["buffers(inner to outer)" => $CON->oldbuf, $CON->buffer])
                    ]
          ];
  }

  if ($con->is_error) {
    print STDERR "# EARLY ERROR\n" if DEBUG_ERROR;
    my $error_list = $con->error_list;
    return $self->error_response($error_list->[0], $env, $con);
  }
  elsif (not $error or is_done($error)) {
    print STDERR "# NORMAL\n" if DEBUG_ERROR;

    return $self->psgi_response_of_connection($con, $env);

  } elsif (ref $error eq 'ARRAY' or ref $error eq 'CODE') {
    print STDERR "# SPECIAL\n" if DEBUG_ERROR;

    # redirect
    if ($self->{cf_debug_psgi}) {
      if (my $errfh = fileno(STDERR) ? \*STDERR : $env->{'psgi.errors'}) {
	print $errfh "PSGI Response: ", terse_dump($error), "\n";
      }
    }
    return Plack::Util::response_cb($error, sub {
      my $res = shift;
      $self->finalize_response($env, $res);
      $res;
    });

  } elsif (UNIVERSAL::isa($error, 'YATT::Lite::Error')) {
    print STDERR "# ERROR\n" if DEBUG_ERROR;

    return $self->error_response($error, $env, $con);

  } else {
    print STDERR "# from raw die\n" if DEBUG_ERROR;
    # system_error. Should be treated by PSGI Server.
    die $error;
  }
}

sub error_response {
  (my MY $self, my $err, my Env $env, my $orig_con) = @_;
  my $error_status = $self->{cf_overwrite_status_code_for_errors_as}
    // $err->{cf_http_status_code}
    // $orig_con->cget('status')
    // 500;

  my $root = $self->get_lochandler('/');

  if (my ($sub, $pkg) = $root->find_renderer(error => ignore_error => 1)) {
    my $errcon = $orig_con->as_error;
    {
      local ($SYS, $CON) = ($self, $errcon);
      $sub->($pkg, $errcon, $err);
    }
    $self->psgi_response_of_connection($errcon, $env);
  } else {
    return $self->psgi_text($err->cget('http_status_code') // 500
                            , $err->byte_message);
  }
}

sub psgi_response_of_connection {
  (my MY $self, my $con, my Env $env) = @_;
  $env //= $con->cget('env');
  my $code = $con->cget('status') // $env->{REDIRECT_STATUS} // 200;
  my $res = Plack::Response->new($code);
  $res->content_type("text/html"
                     . ($self->{cf_header_charset}
                        ? qq{; charset="$self->{cf_header_charset}"}
                        : ""));
  if (my @h = $con->list_header) {
    $res->headers->header(@h);
  }
  $res->body($con->buffer);

  my $tuple = $res->finalize;
  $self->finalize_response($env, $tuple);
  return $tuple;
}

sub before_dirhandler {
  (my MY $self, my ($dh, $con, $file)) = @_;
  if ($self->{cf_site_config_as_entity}) {
    $self->examine_site_config($con);
  }
  &maybe::next::method;
}

sub make_debug_params {
  (my MY $self, my ($reqrec, $args)) = @_;

  my ($path_info, @rest) = ref $reqrec ? @$reqrec : $reqrec;

  my Env $env = Env->psgi_simple_env;
  $env->{PATH_INFO} = $path_info;
  $env->{REQUEST_URI} = $path_info;

  my @params = ($self->SUPER::make_debug_params($reqrec, $args)
		, env => $env);
  {
    require Plack::Request;
    push @params, cgi => Plack::Request->new($env)
      , parameters => YATT::Lite::Util::ixhash(lexpand($args))
      , is_psgi => 1
      ;
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

#========================================

sub set_yatt_script_name {
  (my MY $self, my Env $env) = @_;

  $env->{'yatt.script_name'} = do {
    if (not $self->{cf_no_trim_script_name}
        and $env->{REDIRECT_HANDLER}
        and ($env->{REDIRECT_STATUS} // 0) == 200
        and $env->{SCRIPT_FILENAME}
      ) {
      #
      # For Apache Action+AddHandler mapping.
      #
      trim_common_suffix_from($env->{SCRIPT_NAME}
                              , $env->{SCRIPT_FILENAME});
    } else {
      #
      # Normal case.
      #
      $env->{SCRIPT_NAME};
    }
  };
}

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
    my ($tmpldir, $loc, $file, $trailer, $is_index)
      = split_path($env->{PATH_TRANSLATED}, $self->{cf_app_root}
                   , $self->{cf_use_subpath}
                   , $self->{cf_ext_public}
                 );

    # This is a workaround for $is_index. Determining $is_index only from
    # PATH_TRANSLATED was just wrong.
    #
    # So instead turn on it when "$env->{REQUEST_URI}$file" eq $env->{REDIRECT_URL};
    #
    $is_index ||= do {
      if ($env->{REQUEST_URI} and $env->{REDIRECT_URL}) {
        my $path = URI->new($env->{REQUEST_URI})->path;
        "$path$file" eq $env->{REDIRECT_URL};
      }
    };

    ($tmpldir, $loc, $file, $trailer, $is_index);

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
		, $self->{cf_index_name}
                , $self->{handled_ext_list}
		, $self->{cf_use_subpath});
  } else {
    # or die
    return;
  }
}

sub has_forbidden_path {
  (my MY $self, my $path) = @_;
  if (not defined $path) {
    return undef;
  }
  elsif ($path =~ m{\.lib(?: / | $ )}x) {
    return ".lib: $path";
  }
  elsif ($path =~ m{(?:^|/)\.ht|\.ytmpl$ }x) {
    # XXX: basename() is just to ease testing.
    return "filetype: " . basename($path);
  }
  else {
    undef;
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
  $self->is_debug_allowed_ip($ip);
}

sub is_debug_allowed_ip {
  (my MY $self, my $ip) = @_;
  $self->configure_allow_debug_from unless $self->{allow_debug_from};
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

*configure_debug_allowed_ip = *configure_allow_debug_from;
*configure_debug_allowed_ip = *configure_allow_debug_from;

sub configure_allow_debug_from {
  (my MY $self, my $data) = @_;
  my $pat = join "|", map { quotemeta($_) } lexpand($data // ['127.0.0.1']);
  $self->{allow_debug_from} = qr{^(?:$pat)};
}

sub has_htdebug {
  (my MY $self, my $name) = @_;
  defined $self->{cf_app_root}
    and -e "$self->{cf_app_root}/.htdebug_$name"
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
   , $self->cf_delegate_defined(qw(is_psgi
                                   no_unicode_params
                                   no_nested_query))
   , @args);
}

sub finalize_response {
  shift->next::method(@_);
}

# This will be called back from $CON->flush_heades.
sub finalize_connection {
  my MY $self = shift;
  my ConnProp $prop = (my $glob = shift)->prop;
  $self->session_flush($glob) if $prop->{session};
}

#========================================
# misc.
#========================================

sub header_charset {
  (my MY $self) = @_;
  $self->{cf_header_charset} || $self->{cf_output_encoding};
}

#========================================

#
# Alternative dir_config under $app_root/config/$app_name.{yml,xhf}
# Note: $app_name may contain '/'.
#
sub dirapp_config_for {
  (my MY $self, my $yatt_or_app_name) = @_;

  unless ($self->{cf_config_dir}) {
    Carp::croak "config_dir is empty!";
  }

  my $app_name = do {
    if (not ref $yatt_or_app_name) {
      $yatt_or_app_name;
    } elsif ($self->{cf_use_sibling_config_dir}) {
      $yatt_or_app_name->rel_app_name;
    } else {
      $yatt_or_app_name->app_name
    }
  };

  my $base_path = "$self->{cf_config_dir}/$app_name";

  my $has_latest_entry = sub {
    my ($dict, $key) = @_;

    defined (my $prev_entry = $dict->{$key})
      or return undef;

    my ($age, $path, $obj) = @$prev_entry;
    my $new_age = -M $path or do {
      delete $dict->{$key};
      return undef;
    };

    $new_age == $age
      or return undef;

    $prev_entry;
  };

  if (my $prev_entry = $has_latest_entry->($self->{dirapp_config}, $base_path)) {

    $prev_entry->[-1];

  } elsif (my $cf = $self->find_unique_config_file($base_path)) {
    my $obj = $self->read_file($cf);
    $self->{dirapp_config}{$base_path} = [-M $cf, $cf, $obj];
    $obj;
  } else {
    undef;
  }
}

sub site_config {
  (my MY $self) = @_;
  $self->{cf_site_config} // do {
    $self->examine_site_config;
    $self->{cf_site_config};
  };
}

sub examine_site_config {
  (my MY $self, my $con) = @_;

  if ($con) {
    # Cache should be examined at most once for each request.
    my ConnProp $prop = $con->prop;
    return if $prop->{_site_config_is_examined}++;
  }

  if (my $cache_entry = $self->{_site_config_cache_entry}) {
    my ($age, $fn) = @$cache_entry;
    my $cur_age = -M $fn;
    if (not defined $cur_age) {
      # Cached file is deleted, so cache should be deleted too.
      delete $self->{_site_config_cache_entry};

    } elsif ($age == $cur_age) {
      # Cache is valid.
      return;
    }
  }

  # Examine app.site_config.{yml,xhf} and site_config.{yml,xhf}.
  my ($cf) = (
    ($self->{cf_use_sibling_config_dir}
       ? $self->find_unique_config_file($self->{cf_config_dir}, "/site_config")
       : ()),
    # Note: $self->{cf_app_rootname} and $self->{cf_app_root} can be undef
    # but find_unique_config_file() can safely ignore undef.
    $self->find_unique_config_file($self->{cf_app_rootname}, ".site_config"),
    $self->find_unique_config_file($self->{cf_app_root}, "/site_config"),
  );

  if ($cf) {

    $self->{cf_site_config} = $self->read_file($cf);

    $self->{_site_config_cache_entry} = [-M $cf, $cf];

    $self->site_config_load_hook;
  } else {

    $self->{cf_site_config} = {};
  }
}

sub site_config_load_hook {
  (my MY $self) = @_;

  if ($self->{cf_site_config_as_entity}) {
    my $entns = $self->EntNS;

    foreach my $name (keys %{$self->{cf_site_config}}) {

      next if $name =~ /\W/;

      $self->add_entity_into($entns, $name, sub {
        my MY $actual = $SYS; # To avoid directly capturing $self.
        $actual->{cf_site_config}{$name};
      }, 1); # Just ignore if already defined.
    }
  }
}

#========================================

Entity site_config => sub {
  my ($this, $name, $default) = @_;
  my MY $self = $SYS;
  $SYS->examine_site_config($CON);
  return $self->{cf_site_config} unless defined $name;
  $self->{cf_site_config}{$name} // $default;
};

Entity is_debug_allowed_ip => sub {
  my ($this, $remote_addr) = @_;
  my MY $self = $SYS;

  $remote_addr //= do {
    my Env $env = $CON->env;
    $self->guess_client_ip($env);
  };

  $remote_addr && $self->is_debug_allowed_ip($remote_addr)
};

foreach my $name (qw/
		      file_location
		      dir_location
		      is_current_file
		      is_current_page
		    /
		) {
  my $method = $name;
  Entity $method => sub {
    shift;
    $CON->$method(@_);
  };
}

foreach my $item (map([$_ => uc($_)]
		      , qw/path_info
			   request_uri

			   script_filename

                           SCRIPT_NAME
                           SCRIPT_URI
			   SCRIPT_URL
			   /)) {
  my ($method, $env_name) = @$item;
  Entity $method => sub {
    my Env $env = $CON->env;
    $env->{$env_name};
  };
}

# &yatt:SCRIPT_NAME(); is original $env->{SCRIPT_NAME}
# &yatt:script_name(); is $env->{'yatt.script_name'}

Entity script_name => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $env->{'yatt.script_name'};
};


# GH-205
# &yatt:SCRIPT_URI(); is original $env->{SCRIPT_URI}
# &yatt:script_uri(); cares HTTP_X_FORWARDED_PROTO

Entity script_uri => sub {
  my ($this) = @_;
  $CON->mkprefix . $this->entity_script_url;
};

Entity script_url => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $env->{SCRIPT_URL} // $this->entity_file_location;
};

#
# :abspath() - location + file
#
Entity abspath => sub {
  my ($this) = @_;
  my ConnProp $prop = $CON->prop;
  ($prop->{cf_location} // '').($prop->{cf_file} // '');
};

Entity abspath_in_siteapp => sub {shift->entity_abspath};

# :absrequest() - REQUEST_URI - yatt.script_name
# Note: since this value is derived from REQUEST_URI, which do not contain
# index.yatt typically, this is not suitable to get physical filename.
Entity absrequest => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  my $url = substr($env->{REQUEST_URI}, length $env->{'yatt.script_name'});
  $url =~ s{\?.*}{};
  $url;
};


#========================================

YATT::Lite::Breakpoint::break_load_dispatcher();

1;
