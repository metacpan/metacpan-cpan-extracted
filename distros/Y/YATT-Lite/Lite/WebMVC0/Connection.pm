package YATT::Lite::WebMVC0::Connection; sub PROP () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use base qw(YATT::Lite::Connection);
use YATT::Lite::MFields
(qw/cgi
    is_psgi hmv
    parameters

    site_prefix

    no_nested_query

    mkquery_with_body_params

    no_unicode_params

    _dir_config_cache
    _site_config_is_examined

    _sigil_type_item

    _current_user

    _htdebug_cache
   /);
use YATT::Lite::Util qw(globref url_encode nonempty empty rootname lexpand);
use YATT::Lite::PSGIEnv;

use YATT::Lite::Util::CGICompat;

#----------------------------------------

BEGIN {
  # print STDERR join("\n", sort(keys our %FIELDS)), "\n";

  foreach my $name (qw(raw_body uploads upload)) {
    *{globref(PROP, $name)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      unless ($prop->{is_psgi}) {
	croak "Connection method $name is PSGI mode only!"
      }
      $prop->{cgi}->$name(@_);
    };
  }

  foreach my $name (qw(url_param)) {
    *{globref(PROP, $name)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      $prop->{cgi}->$name(@_);
    };
  }

  foreach my $item ([referer => 'HTTP_REFERER']
		    , map([lc($_) => uc($_)]
			  , qw/REMOTE_ADDR
			       REQUEST_METHOD
			       SCRIPT_NAME
			       PATH_INFO
			       QUERY_STRING
			       SERVER_NAME
			       SERVER_PORT
			       SERVER_PROTOCOL
			       CONTENT_LENGTH
			       CONTENT_TYPE
			      /)
		   ) {
    my ($method, $env) = @$item;
    *{globref(PROP, $method)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      my ($default) = @_;
      if ($prop->{env}) {
	$prop->{env}->{$env} // $default;
      } elsif ($prop->{cgi} and my $sub = $prop->{cgi}->can($method)) {
	$sub->($prop->{cgi}) // $default;
      } else {
	$default;
      }
    };
  }

  foreach my $name (qw(file subpath parameters request_file)) {
    *{globref(PROP, $name)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      $prop->{$name};
    };
  }
}

#========================================

sub param {
  my PROP $prop = (my $glob = shift)->prop;
  if (my $ixh = $prop->{parameters}) {
    return keys %$ixh unless @_;
    defined (my $key = shift)
      or croak "undefined key!";
    $key =~ s/\[\]\z// if not $prop->{no_nested_query};
    if (@_) {
      if (@_ >= 2) {
	$ixh->{$key} = [@_]
      } else {
	$ixh->{$key} = shift;
      }
    } else {
      # If parameters is enabled, value is returned AS-IS.
      $ixh->{$key};
    }
  } elsif (my $hmv = $prop->{hmv}) {
    return $hmv->keys unless @_;
    if (@_ == 1) {
      return wantarray ? $hmv->get_all($_[0]) : $hmv->get($_[0]);
    } else {
      $hmv->add(@_);
      return $glob;
    }
  } elsif (my $cgi = $prop->{cgi}) {
    return $cgi->param(@_);
  } else {
    croak "Neither Hash::MultiValue nor CGI is found in connection!";
  }
}

# Annoying multi_param support.
sub multi_param {
  my PROP $prop = (my $glob = shift)->prop;
  if (my $ixh = $prop->{parameters}) {
    return keys %$ixh unless @_;
    defined (my $key = shift)
      or croak "undefined key!";
    # If parameters is enabled, value is returned AS-IS.
    $ixh->{$key};

  } elsif (my $hmv = ($prop->{hmv} // do {
    $prop->{is_psgi} && $prop->{cgi}->parameters
  })) {
    return $hmv->keys unless @_;
    return wantarray ? $hmv->get_all($_[0]) : $hmv->get($_[0]);
  } elsif (my $cgi = $prop->{cgi}) {
    return $cgi->multi_param(@_);
  } else {
    croak "Neither Hash::MultiValue nor CGI is found in connection!";
  }
}

#========================================

sub sigil_type_item {
  my PROP $prop = (my $glob = shift)->prop;

  @{$prop->{_sigil_type_item} // []};
}

sub collect_request_sigil_by {
  my ($glob, $cutter, @list) = @_;
  my %dict;
  foreach my $name (grep {defined} @list) {
    my ($sigil, $word) = $name =~ /^([~!])(\1|\w*)$/
      or next;
    defined (my $value = $cutter->($name))
      or next;
    push @{$dict{$sigil}}, do {
      if ($sigil eq $word) {
        $value;
      } else {
        $word;
      }
    };
  };
  \%dict;
}

sub has_content {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{env}
    or return 0;
  ($env->{CONTENT_TYPE} and defined $env->{CONTENT_LENGTH}) ? 1 : 0;
}

sub parse_request_sigil_psgi {
  my PROP $prop = (my $glob = shift)->prop;
  my ($req) = @_;

  if ($glob->has_content) {
    $prop->{_sigil_type_item} = do {
      my @bodyParams = $glob->extract_sigil_from_hmv($req->body_parameters);
      my @queryParams = $glob->extract_sigil_from_hmv($req->query_parameters);
      if (@bodyParams) {
        \@bodyParams
      } else {
        \@queryParams
      }
    };
  } else {
    $glob->parse_request_sigil_hmv($req->parameters);
  }
}

sub parse_request_sigil_hmv {
  my PROP $prop = (my $glob = shift)->prop;
  my ($hmvOrRawHash) = @_;
  my $hmv = ref $hmvOrRawHash eq 'HASH' ? Hash::MultiValue->new(%$hmvOrRawHash)
    : $hmvOrRawHash;
  $prop->{_sigil_type_item} = [$glob->extract_sigil_from_hmv($hmv)];
}

sub extract_sigil_from_hmv {
  my ($glob, $hmv) = @_;

  my $sigilsDict = $glob->collect_request_sigil_by(
    sub {
      my $value = $hmv->{$_[0]};
      $hmv->remove($_[0]);
      $value;
    }, $hmv->keys);
  $glob->validate_request_sigils_dict($sigilsDict);
}

sub parse_request_sigil_cgi {
  my PROP $prop = (my $glob = shift)->prop;
  my ($cgi) = @_;
  my $sigilsDict = $glob->collect_request_sigil_by(
    sub {
      my $value = $cgi->param($_[0]);
      $cgi->delete($_[0]);
      $value;
    }, $cgi->param());
  $prop->{_sigil_type_item}
    = [$glob->validate_request_sigils_dict($sigilsDict)];
}

sub validate_request_sigils_dict {
  my PROP $prop = (my $glob = shift)->prop;
  my ($sigilsDict) = @_;

  my ($subpage, $action);
  if (my $names = $sigilsDict->{'~'}) {
    if (@$names >= 2) {
      $glob->error("Multiple subpage sigils in request!: %s"
                     , join(", ", @$names));
    }
    $subpage = $names->[0];
  }
  if (my $names = $sigilsDict->{'!'}) {
    if (@$names >= 2) {
      $glob->error("Multiple action sigils in request!: %s"
                     , join(", ", @$names));
    }
    $action = $names->[0];
  }
  if (defined $subpage and defined $action) {
    # XXX: Reserved for future use.
    $glob->error("Can't use subpage and action at one time: %s vs %s"
                 , $subpage, $action);
  } elsif (defined $subpage) {
    unless ($subpage =~ m{^\w*\z}a) {
      $glob->error(+{http_status_code => 400}, "Invalid subpage: %s",
                   YATT::Lite::Util::escape($subpage));
    }
    (page => $subpage);
  } elsif (defined $action) {
    unless ($action =~ m{^\w*\z}a) {
      $glob->error(+{http_status_code => 400}, "Invalid action: %s",
                   YATT::Lite::Util::escape($action));
    }
    (action => $action);
  } else {
    ();
  }
}

#========================================

sub queryobj {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{parameters} || $prop->{hmv} || $prop->{cgi};
}

# GH-259: For url reproduction (mkquery($CON), current_path($CON)...),
# requests with a body should reproduce QUERY_STRING-derived params only.
# Note: query_parameters below is the sigil-stripped, request-cached
# Hash::MultiValue (see extract_sigil_from_hmv).
# Set mkquery_with_body_params to restore the old merged behavior.
sub queryobj_for_mkquery {
  my PROP $prop = (my $glob = shift)->prop;
  if (not $prop->{mkquery_with_body_params}
      and not $prop->{hmv}
      and $prop->{is_psgi} and $prop->{cgi}
      and $glob->has_content) {
    $prop->{cgi}->query_parameters;
  } else {
    $glob->queryobj;
  }
}

sub param_exists {
  my ($glob, $name) = @_;
  exists $glob->as_hash->{$name};
}

sub as_hash {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{parameters} // $prop->{hmv} // do {
    if ($prop->{is_psgi}) {
      $prop->{cgi}->parameters
    } else {
      $prop->{cgi}->Vars
    }
  };
}

*remove_param = *delete_param; *remove_param = *delete_param;
sub delete_param {
  my PROP $prop = (my $glob = shift)->prop;
  my ($key) = @_;
  unless (defined $key) {
    croak "Undefined key!";
  }
  if (my $dict = $prop->{parameters}) {
    # For nested_query (array_param)
    delete $dict->{$key};
  } elsif ($dict = $prop->{hmv}) {
    # For direct Hash::MultiValue.
    $dict->remove($key);
  } elsif (($dict = $prop->{cgi})->can("parameters")) {
    # For Plack::Request
    $dict->parameters->remove($key);
  } elsif ($dict->can("delete")) {
    # For CGI family.
    $dict->delete($key);
  } else {
    croak "No queryobj found!";
  }
}

#========================================

sub after_create {
  my PROP $prop = (my $glob = shift)->prop;
  $glob->SUPER::after_create();

  # If cgi is empty and parameters is given,
  # request sigils are collected via parse_request_sigil_hmv.
  #
  if (not $prop->{cgi} and $prop->{parameters}) {
    $glob->parse_request_sigil_hmv($prop->{parameters});
  }
}

sub configure_cgi {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cgi} = my $cgi = shift;
  return unless $glob->is_form_content_type($cgi->content_type);
  return if $prop->{parameters};

  #
  # parse_request_sigil should be called before parse_nested_query.
  #
  if ($prop->{is_psgi}) {
    $glob->parse_request_sigil_psgi($cgi);
  } else {
    $glob->parse_request_sigil_cgi($cgi);
  }

  unless ($prop->{no_nested_query}) {
    if ($prop->{is_psgi}) {
      $glob->convert_array_param_psgi($cgi);
    } else {
      $glob->convert_array_param_cgi($cgi);
    }
  }
}

sub is_form_content_type {
  my ($self, $real_ct) = @_;
  return 1 if ($real_ct // '') eq '';
  foreach my $check_ct ($self->form_content_types) {
    return 1 if $real_ct =~ $check_ct;
  }
  return 0;
}

sub form_content_types {
  (qr(^multipart/form-data\s*(?:;|$))i
   , qr(^application/x-www-form-urlencoded$)i);
}

sub parse_nested_query {
  my PROP $prop = (my $glob = shift)->prop;
  my ($obj_or_string) = @_;
  YATT::Lite::Util::parse_nested_query
    ($obj_or_string
     , (!$prop->{no_unicode_params} && $prop->{encoding})
   );
}

sub convert_array_param_psgi {
  my PROP $prop = (my $glob = shift)->prop;
  my ($req) = @_;
  $prop->{parameters} = do {
    if ($glob->has_content) {
      my $body = $glob->parse_nested_query([$req->body_parameters->flatten]);
      my $qs = $glob->parse_nested_query([$req->query_parameters->flatten]);
      foreach my $key (keys %$qs) {
	if (exists $body->{$key}) {
	  die $glob->error("Attempt to overwrite a POST parameter '%s'"
                           . " by the same one in QUERY_STRING"
			   , $key);
	}
	$body->{$key} = $qs->{$key};
      }
      $body;
    } else {
      $glob->parse_nested_query([$req->query_parameters->flatten]);
    }
  };
}

sub convert_array_param_cgi {
  my PROP $prop = (my $glob = shift)->prop;
  my ($cgi) = @_;
  return if ($cgi->content_type // "") eq "application/json";
  $prop->{parameters}
    = $glob->parse_nested_query($cgi->query_string);
}

# Location(path part of url) of overall SiteApp.
sub site_location {
  shift->site_prefix . '/';
}
*site_loc = *site_location; *site_loc = *site_location;
sub site_prefix {
  my PROP $prop = (my $glob = shift)->prop;
  # Note: This is safe because site_prefix 0 is meaningless(I hope).
  $prop->{site_prefix} || do {
    my Env $env = $prop->{env};
    $env->{'yatt.script_name'} // ''
  }
}

# Location of DirApp
sub location {
  my PROP $prop = (my $glob = shift)->prop;
  (my $loc = ($prop->{location} // '')) =~ s,/*$,/,;
  $loc;
}

sub _invoke_or {
  my ($default, $obj, $method, @args) = @_;
  if (defined $obj and my $sub = $obj->can($method)) {
    $sub->($obj, @args)
  } else {
    $default;
  }
}

# XXX: parameter の加減算も？
# XXX: 絶対 path/相対 path の選択?
# scheme
# authority
# path
# query
# fragment
sub mkurl {
  my PROP $prop = (my $glob = shift)->prop;
  my ($file, $param, %opts) = @_;

  my $path = $glob->mkpath($file, $opts{mapped_path});

  # XXX: /../ truncation
  # XXX: If sep is '&', scalar ref quoting is required.
  # XXX: connection should have default separator.
  my $url = '';
  $url .= $glob->mkprefix unless $opts{local};
  $url .= $path . $glob->mkquery($param, $opts{separator});
  $url;
}

sub mkpath {
  my PROP $prop = (my $glob = shift)->prop;
  my ($file, $used_mapped_path) = @_;

  my $req = do {
    if ($used_mapped_path) {
      # GH-251: mapped_path reproduces the url path of the request
      # (mount prefix included, request_file based).
      scalar $glob->mapped_path;
    } else {
      $glob->request_path;
    }
  };

  if (defined $file and $file =~ m!^/!) {
    $glob->site_prefix.$file;
  } else {
    my ($orig, $dir) = ('');
    if (($dir = $req) =~ s{([^/]+)$ }{}x) {
      $orig = $1;
    }
    if (not defined $file or $file eq '') {
      $dir . $orig;
    } elsif ($file eq '.') {
      $dir
    } else {
      $dir . $file;
    }
  }
}

sub mkprefix {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{env};
  my $scheme
    = $env->{HTTP_X_FORWARDED_PROTO}
    || $env->{'psgi.url_scheme'} || $prop->{cgi}->protocol;
  my $host = $glob->mkhost($scheme);
  $scheme . '://' . $host . join("", @_);
}

#
# $CON->has_htdebug($name): per-request cache of
# $SYS->has_htdebug($name) (YATT::Lite::WebMVC0::SiteApp), which does an
# %ENV lookup and a stat() of $app_root/.htdebug_$name every time.
# escape() consults this for every reference it is asked to print, so
# the answer is computed at most once per connection and name.
#
sub has_htdebug {
  my PROP $prop = (my $glob = shift)->prop;
  my ($name) = @_;
  my $cache = $prop->{_htdebug_cache} //= {};
  return $cache->{$name} if exists $cache->{$name};
  $cache->{$name} = do {
    my $sys = $prop->{system};
    ($sys and $sys->can('has_htdebug')) ? ($sys->has_htdebug($name) // 0) : 0;
  };
}

# True if this request came over TLS (see YATT::Lite::PSGIEnv::is_https).
sub is_https {
  my PROP $prop = (my $glob = shift)->prop;
  if (my Env $env = $prop->{env}) {
    Env->is_https($env);
  } elsif (my $cgi = $prop->{cgi}) {
    ($cgi->can('protocol') and lc($cgi->protocol // '') eq 'https') ? 1 : 0;
  } else {
    0;
  }
}

sub http_host_domain {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{env};
  my $host = $env->{HTTP_HOST}
    or return undef;
  $host =~ s/:\d+$//;
  $host;
}

sub server_name_or_localhost {
  my PROP $prop = (my $glob = shift)->prop;
  my ($default) = @_;
  my Env $env = $prop->{env};
  $env->{SERVER_NAME} || ($default // 'localhost');
}

sub mkhost {
  my PROP $prop = (my $glob = shift)->prop;
  my ($scheme) = @_;
  $scheme ||= 'http';
  my Env $env = $prop->{env};

  # XXX? Is this secure?
  return $env->{HTTP_HOST} if nonempty($env->{HTTP_HOST});

  my $base = $env->{SERVER_NAME}
    // _invoke_or('localhost', $prop->{cgi}, 'server_name');
  if (my $port = $env->{SERVER_PORT}
      || _invoke_or(80, $prop->{cgi}, 'server_port')) {
    $base .= ":$port"  unless ($scheme eq 'http' and $port == 80
			       or $scheme eq 'https' and $port == 443);
  }
  $base;
}

sub mkquery {
  my ($self, $param, $sep) = @_;
  $sep //= '&';

  my @enc_param;
  my ($fkeys, $fgetall);
  if (not defined $param or not ref $param) {
    return wantarray ? () : '';
    # nop
  }

  if (UNIVERSAL::isa($param, ref $self)) {
    # $CON->mkquery($CON) == $CON->mkquery($CON->queryobj_for_mkquery)
    $param = $param->queryobj_for_mkquery;
  }

  if (ref $param eq 'HASH') {
    push @enc_param, $self->url_encode($_).'='.$self->url_encode($param->{$_})
      for sort keys %$param;
  } elsif ($fkeys = UNIVERSAL::can($param, 'keys')
      and $fgetall = UNIVERSAL::can($param, 'get_all')
      or ($fkeys = $fgetall = UNIVERSAL::can($param, 'param'))) {
    foreach my $key (YATT::Lite::Util::unique($fkeys->($param))) {
      my $enc = $self->url_encode($key);
      push @enc_param, "$enc=".$self->url_encode($_)
	for $fgetall->($param, $key);
    }
  } elsif (ref $param eq 'ARRAY') {
    if (grep {not defined} @$param) {
      croak "Undef found in mkquery()! " . YATT::Lite::Util::terse_dump($param);
    }
    my @list = @$param;
    while (my ($key, $value) = splice @list, 0, 2) {
      push @enc_param, $self->url_encode($key).'='.$self->url_encode($value);
    }
  }

  unless (@enc_param) {
    wantarray ? () : '';
  } else {
    wantarray ? @enc_param : '?'.join($sep, @enc_param);
  }
}

# GH-251: Mount-prefix aware link builders.
# Naming follows the widespread "*_path = path only / *_url = absolute URL"
# convention. $query accepts only HASH/ARRAY ref or query object (like $CON).

sub site_path {
  my ($glob, $path, $query) = splice @_, 0, 3;
  if (@_) {
    croak "Too many arguments for site_path!"
      . " (query parameters must be passed as one HASH/ARRAY ref)";
  }
  if (not defined $path or $path eq '') {
    $path = '/';
  } elsif ($path !~ m{^/}) {
    croak "site_path requires a '/'-leading path: $path";
  }
  $glob->site_prefix . $path . $glob->_query_string_of(site_path => $query);
}

sub site_url {
  my $glob = shift;
  $glob->mkprefix . $glob->site_path(@_);
}

sub current_path {
  my ($glob, $query) = splice @_, 0, 2;
  if (@_) {
    croak "Too many arguments for current_path!"
      . " (query parameters must be passed as one HASH/ARRAY ref)";
  }
  $glob->request_path . $glob->_query_string_of(current_path => $query);
}

sub current_url {
  my $glob = shift;
  $glob->mkprefix . $glob->current_path(@_);
}

sub _query_string_of {
  my ($glob, $caller, $query) = @_;
  if (defined $query and not ref $query) {
    croak "query for $caller must be a HASH/ARRAY ref or query object: $query";
  }
  scalar $glob->mkquery($query);
}

sub dir_location {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{env};
  ($env->{'yatt.script_name'} // '').($prop->{location} // "/");
}

sub file_page {
  my PROP $prop = (my $glob = shift)->prop;
  my $fn = $prop->{file};
  $fn =~ s/\.\w+\z//;
  $fn;
}

# The url path of the current page: dir_location + request_file.
# GH-251: Like mapped_path, this follows how the request spelled the
# file name (Apache content-negotiation model: the requested name is
# the base name; negotiation just appends extensions to it).
#
sub file_location {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{env};
  my $loc = $glob->dir_location;
  if (defined (my $rf = $prop->{request_file})) {
    $loc . $rf;
  } elsif (not $prop->{is_index} and my $fn = $prop->{file}) {
    # Fallback for old-style connections without request_file:
    # trim the last extension ("foo.tar.yatt" => "foo.tar").
    $fn =~ s/\.\w+\z//;
    $loc . $fn;
  } else {
    $loc;
  }
}

# page_location: canonical form of file_location, based on the
# physical file name. Unlike file_location, this is NOT affected by
# how the request spelled the url.
# (page = spelling-independent identity, cf. is_current_page)
sub page_location {
  my PROP $prop = (my $glob = shift)->prop;
  my $loc = $glob->dir_location;
  if (not $prop->{is_index} and my $fn = $prop->{file}) {
    $fn =~ s/\.\w+\z//;
    $loc .= $fn;
  }
  $loc;
}

# is_current_file($path): true when $path addresses the current page.
# $path is a site-rooted literal (same form as site_path's argument):
# canonical (/auth/login), physical (/auth/login.yatt), or directory
# form for index pages (/auth/). Mount prefix and request spelling
# do not affect the result. Subpath is ignored (cf. is_current_page).
sub is_current_file {
  my PROP $prop = (my $glob = shift)->prop;
  my ($path) = @_;
  return 0 unless defined $path;
  my $loc = $glob->location;
  my $fn  = $prop->{file} // '';
  (my $canon = $fn) =~ s/\.\w+\z//;
  return 1 if $path eq $loc . $canon;
  return 1 if $path eq $loc . $fn;
  return 1 if $prop->{is_index} and $path eq $loc;
  0;
}

sub is_current_page {
  my PROP $prop = (my $glob = shift)->prop;
  my ($file, $page) = do {
    @_ <= 1 ? (rootname($prop->{file}), $_[0]) : @_;
  };
  rootname($prop->{file}) eq $file
    or return 0;
  $page //= '';
  $page =~ s{^/}{}; # Treat /foo as foo.
  if (empty(my $subpath = $prop->{subpath})) {
    $page eq '';
  } elsif ($page eq '') {
    0
  } else {
    $subpath =~ m{^/$page};
  }
}

# GH-251: mapped_path now reproduces the url path of the request:
# site_prefix + location + request_file + subpath. Since request_file
# keeps the file name part as it appeared in the request, extension
# is reproduced only when the request spelled it. For connections
# which lack request_file (old-style construction), falls back to
# the physical file name as before.
sub mapped_path {
  my PROP $prop = (my $glob = shift)->prop;
  my @path = do {
    my $loc = $prop->{location} // "/";
    $loc .= $prop->{request_file} // do {
      (defined $prop->{file} and not $prop->{is_index})
	? $prop->{file} : '';
    };
    ($glob->site_prefix . $loc);
  };
  if (defined (my $sp = $prop->{subpath})) {
    $path[0] =~ s!/+\z!!;
    $sp =~ s!^/*!/!;
    push @path, $sp;
  }
  if (wantarray) {
    @path;
  } else {
    my $res = join "", @path;
    $res =~ s!^/+!/!;
    $res;
  }
}

sub request_path {
  (my $uri = shift->request_uri // '') =~ s/\?.*//;
  $uri;
}

sub request_uri {
  my PROP $prop = (my $glob = shift)->prop;
  if (my Env $env = $prop->{env}) {
    $env->{REQUEST_URI};
  } elsif ($prop->{cgi}
      and my $sub = $prop->{cgi}->can('request_uri')) {
    $sub->($prop->{cgi});
  } else {
    $ENV{REQUEST_URI};
  }
}

#========================================

# True if $url, given as a plain string, stays on this origin:
# a path or relative reference, or an absolute http(s) url whose host
# equals mkhost. Written against how browsers parse Location:, not
# against RFC 3986 alone: for http(s), '\' is treated as '/', runs of
# slashes after the scheme collapse, and leading C0 controls / spaces
# are stripped before parsing. So "\\evil", "/\evil", "///evil",
# "http:\\evil" and " //evil" all mean evil.example to a browser and
# are rejected here.
sub is_same_origin_redirect_url {
  my ($glob, $url) = @_;
  return 0 unless defined $url and length $url;

  # Control chars (CR/LF would split the header) and whitespace.
  return 0 if $url =~ /[\x00-\x20\x7f]/;

  if ($url =~ m{^([A-Za-z][A-Za-z0-9+.-]*):(.*)\z}s) {
    # Has a scheme. Only http(s) to this very host is accepted.
    my ($scheme, $rest) = (lc($1), $2);
    return 0 unless $scheme eq 'http' or $scheme eq 'https';
    my ($host) = $rest =~ m{^//([^/?#\\]+)(?:[/?#]|\z)}
      or return 0;
    return lc($host) eq lc($glob->mkhost($scheme) // '') ? 1 : 0;
  }

  if ($url =~ m{^//([^/?#\\]+)(?:[/?#]|\z)}) {
    # Scheme-relative "//host/...": accepted only for this host.
    return lc($1) eq lc($glob->mkhost // '') ? 1 : 0;
  }

  if ($url =~ m{^[/\\]}) {
    # A path. Exactly one leading '/', not followed by '/' or '\'.
    return $url =~ m{^/(?![/\\])} ? 1 : 0;
  }

  # Relative reference ("./", "index?x=1", "?x=1", "#frag").
  1;
}

# GH-251: raise_redirect is the preferred name (raise_* family tells
# this never returns to the caller). redirect is kept for compatibility.
*raise_redirect = *redirect; *raise_redirect = *redirect;
sub redirect {
  my PROP $prop = (my $glob = shift)->prop;
  croak "undefined url" unless @_ and defined $_[0];
  my $url = do {
    if (ref $_[0]) {
      # To do external redirect, $url should pass as SCALAR REF.
      my $arg = shift;
      # die "redirect url is not a scalar ref: $arg";
      $$arg;
    } elsif ($glob->is_same_origin_redirect_url($_[0])) {
      shift;
    } else {
      die $glob->error_with_status(
        400, "External redirect is not allowed: %s"
        , YATT::Lite::Util::escape($_[0])
      );
    }
  };
  if ($prop->{_header_was_sent}++) {
    die "Can't redirect multiple times!";
  }

  # Make sure session is flushed before redirection.
  $glob->finalize_headers;

  ${$prop->{buffer}} = '';

  die [302, [Location => $url, $glob->list_header], []];
}

#========================================
# Session support is delegated to 'system'.
# 'system' must implement session_{start,resume,flush,destroy}

# To avoid confusion against $system->session_$verb,
# connection side interface is named ${verb}_session.

sub get_session {
  my PROP $prop = (my $glob = shift)->prop;
  # To avoid repeative false session tests.
  if (exists $prop->{_session}) {
    $prop->{_session};
  } else {
    $prop->{system}->session_resume($glob);
  }
}

sub start_session {
  my PROP $prop = (my $glob = shift)->prop;
  if (defined (my $sess = $prop->{_session})) {
    die $glob->error("load_session is called twice! sid=%s", $sess->id);
  }
  $prop->{system}->session_start($glob, @_);
}

sub delete_session {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{system}->session_delete($glob);
}

sub flush_session {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{system}->session_flush($glob);
}

#========================================

sub current_user {
  my PROP $prop = (my $glob = shift)->prop;
  my $cu = do {
    if (exists $prop->{_current_user}) {
      $prop->{_current_user}
    } elsif (defined $prop->{system}) {
      $prop->{_current_user} = $prop->{system}->load_current_user($glob);
    } else {
      $prop->{_current_user} = undef;
    }
  };

  return $cu unless @_;
  die $glob->error("current_user is empty") unless defined $cu;
  my $method = shift;

  $cu->$method(@_);
}

#========================================

use YATT::Lite::RegexpNames; # For re_name, re_integer, ...

sub param_type {
  my PROP $prop = (my $glob = shift)->prop;
  my $name = shift // croak "Undefined name!";
  my $type = shift // croak "Undefined type!";
  my $diag = shift;
  my $opts = shift;
  my $pat = ref $type eq 'Regexp' ? $type : do {
    my $pat_sub = $glob->can("re_$type")
      or croak "Unknown type: $type";
    $pat_sub->();
  };

  my $value = $glob->param($name);

  if (defined $value && $value =~ $pat) {
    return $&; # Also for taint check.
  } elsif ($diag) {
    die $glob->error_with_status
      (400, (ref $diag eq 'CODE' ? $diag->($value) : $diag)
       , $name, $value);
  } elsif (not defined $value) {
    return undef if $opts->{allow_undef};
    die $glob->error_with_status
      (400, "Parameter '%s' is missing!", $name);
  } else {
    # Just for default message. Production code should provide $diag.
    die $glob->error_with_status
      (400, "Parameter '%s' must match %s!: '%s'"
       , $name, $type, $value);
  }
}

#========================================

sub accept_language {
  my PROP $prop = (my $glob = shift)->prop;
  my (%opts) = @_;
  my $filter = delete $opts{filter};
  my $detail = delete $opts{detail};
  my $long   = delete $opts{long};
  if (keys %opts) {
    die $glob->error("Unknown option for accept_language: %s"
		     , join ", ", keys %opts);
  }

  my Env $env = $prop->{env};
  my $langlist = $env->{HTTP_ACCEPT_LANGUAGE}
    or return;
  my @langlist = sort {
    $$b[-1] <=> $$a[-1]
  } map {
    my ($lang, $qual) = split /\s*;\s*q=/;
    [$lang, $qual // 1]
  } split /\s*,\s*/, $langlist;

  if ($filter) {
    my $filtsub = do {
      if (ref $filter eq 'CODE') {
	$filter
      } elsif (ref $filter eq 'Regexp') {
	sub { grep {$$_[0] =~ $filter} @_ }
      } elsif (ref $filter eq 'HASH') {
	sub { grep {$filter->{$$_[0]}} @_ }
      } elsif (ref $filter eq 'ARRAY') {
	my $hash = +{map {$_ => 1} lexpand($filter)};
	sub { grep {$hash->{$$_[0]}} @_ }
      } else {
	die $glob->error("Unknown filter type for accept_language");
      }
    };
    @langlist = $filtsub->(@langlist);
  }

  if ($detail) {
    @langlist
  } else {
    if ($long) {
      # en-US => en_US
      $$_[0] =~ s/-/_/g for @langlist;
    } else {
      # en-US => en
      $$_[0] =~ s/-.*// for @langlist;
    }
    my %dup;
    wantarray ? (map {$dup{$$_[0]}++ ? () : $$_[0]} @langlist)
      : $langlist[0][0];
  }
}

1;
