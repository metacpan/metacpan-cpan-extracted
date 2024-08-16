package YATT::Lite::WebMVC0::Connection; sub PROP () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use base qw(YATT::Lite::Connection);
use YATT::Lite::MFields
(qw/cf_cgi
    cf_is_psgi cf_hmv
    cf_parameters

    cf_site_prefix

    cf_no_nested_query

    cf_no_unicode_params

    dir_config_cache
    _site_config_is_examined

    _sigil_type_item

    current_user
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
      unless ($prop->{cf_is_psgi}) {
	croak "Connection method $name is PSGI mode only!"
      }
      $prop->{cf_cgi}->$name(@_);
    };
  }

  foreach my $name (qw(url_param)) {
    *{globref(PROP, $name)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      $prop->{cf_cgi}->$name(@_);
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
      if ($prop->{cf_env}) {
	$prop->{cf_env}->{$env} // $default;
      } elsif ($prop->{cf_cgi} and my $sub = $prop->{cf_cgi}->can($method)) {
	$sub->($prop->{cf_cgi}) // $default;
      } else {
	$default;
      }
    };
  }

  foreach my $name (qw(file subpath parameters)) {
    my $cf = "cf_$name";
    *{globref(PROP, $name)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      $prop->{$cf};
    };
  }
}

#========================================

sub param {
  my PROP $prop = (my $glob = shift)->prop;
  if (my $ixh = $prop->{cf_parameters}) {
    return keys %$ixh unless @_;
    defined (my $key = shift)
      or croak "undefined key!";
    if (@_) {
      if (@_ >= 2) {
	$ixh->{$key} = [@_]
      } else {
	$ixh->{$key} = shift;
      }
    } else {
      # If cf_parameters is enabled, value is returned AS-IS.
      $ixh->{$key};
    }
  } elsif (my $hmv = $prop->{cf_hmv}) {
    return $hmv->keys unless @_;
    if (@_ == 1) {
      return wantarray ? $hmv->get_all($_[0]) : $hmv->get($_[0]);
    } else {
      $hmv->add(@_);
      return $glob;
    }
  } elsif (my $cgi = $prop->{cf_cgi}) {
    return $cgi->param(@_);
  } else {
    croak "Neither Hash::MultiValue nor CGI is found in connection!";
  }
}

# Annoying multi_param support.
sub multi_param {
  my PROP $prop = (my $glob = shift)->prop;
  if (my $ixh = $prop->{cf_parameters}) {
    return keys %$ixh unless @_;
    defined (my $key = shift)
      or croak "undefined key!";
    # If cf_parameters is enabled, value is returned AS-IS.
    $ixh->{$key};

  } elsif (my $hmv = ($prop->{cf_hmv} // do {
    $prop->{cf_is_psgi} && $prop->{cf_cgi}->parameters
  })) {
    return $hmv->keys unless @_;
    return wantarray ? $hmv->get_all($_[0]) : $hmv->get($_[0]);
  } elsif (my $cgi = $prop->{cf_cgi}) {
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

sub parse_request_sigil_psgi {
  my PROP $prop = (my $glob = shift)->prop;
  my ($req) = @_;


  my Env $env = $prop->{cf_env};

  if ($env->{CONTENT_TYPE} and defined $env->{CONTENT_LENGTH}) {
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
    (page => $subpage);
  } elsif (defined $action) {
    (action => $action);
  } else {
    ();
  }
}

#========================================

sub queryobj {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_parameters} || $prop->{cf_hmv} || $prop->{cf_cgi};
}

sub param_exists {
  my ($glob, $name) = @_;
  exists $glob->as_hash->{$name};
}

sub as_hash {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_parameters} // $prop->{cf_hmv} // do {
    if ($prop->{cf_is_psgi}) {
      $prop->{cf_cgi}->parameters
    } else {
      $prop->{cf_cgi}->Vars
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
  if (my $dict = $prop->{cf_parameters}) {
    # For nested_query (array_param)
    delete $dict->{$key};
  } elsif ($dict = $prop->{cf_hmv}) {
    # For direct Hash::MultiValue.
    $dict->remove($key);
  } elsif (($dict = $prop->{cf_cgi})->can("parameters")) {
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

  # If cf_cgi is empty and cf_parameters is given,
  # request sigils are collected via parse_request_sigil_hmv.
  #
  if (not $prop->{cf_cgi} and $prop->{cf_parameters}) {
    $glob->parse_request_sigil_hmv($prop->{cf_parameters});
  }
}

sub configure_cgi {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_cgi} = my $cgi = shift;
  return unless $glob->is_form_content_type($cgi->content_type);
  return if $prop->{cf_parameters};

  #
  # parse_request_sigil should be called before parse_nested_query.
  #
  if ($prop->{cf_is_psgi}) {
    $glob->parse_request_sigil_psgi($cgi);
  } else {
    $glob->parse_request_sigil_cgi($cgi);
  }

  unless ($prop->{cf_no_nested_query}) {
    if ($prop->{cf_is_psgi}) {
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
     , (!$prop->{cf_no_unicode_params} && $prop->{cf_encoding})
   );
}

sub convert_array_param_psgi {
  my PROP $prop = (my $glob = shift)->prop;
  my ($req) = @_;
  my Env $env = $prop->{cf_env};
  $prop->{cf_parameters} = do {
    if ($env->{CONTENT_TYPE} and defined $env->{CONTENT_LENGTH}) {
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
  $prop->{cf_parameters}
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
  $prop->{cf_site_prefix} || do {
    my Env $env = $prop->{cf_env};
    $env->{'yatt.script_name'} // ''
  }
}

# Location of DirApp
sub location {
  my PROP $prop = (my $glob = shift)->prop;
  (my $loc = ($prop->{cf_location} // '')) =~ s,/*$,/,;
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

  my $req = do {
    if ($opts{mapped_path}) {
      $glob->mapped_path;
    } else {
      $glob->request_path;
    }
  };

  my $path = do {
    if (defined $file and $file =~ m!^/!) {
      $glob->site_prefix.$file;
    } else {
      my ($orig, $dir) = ('');
      if (($dir = $req) =~ s{([^/]+)$}{}) {
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
  };

  # XXX: /../ truncation
  # XXX: If sep is '&', scalar ref quoting is required.
  # XXX: connection should have default separator.
  my $url = '';
  $url .= $glob->mkprefix unless $opts{local};
  $url .= $path . $glob->mkquery($param, $opts{separator});
  $url;
}

sub mkprefix {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{cf_env};
  my $scheme
    = $env->{HTTP_X_FORWARDED_PROTO}
    || $env->{'psgi.url_scheme'} || $prop->{cf_cgi}->protocol;
  my $host = $glob->mkhost($scheme);
  $scheme . '://' . $host . join("", @_);
}

sub http_host_domain {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{cf_env};
  my $host = $env->{HTTP_HOST}
    or return undef;
  $host =~ s/:\d+$//;
  $host;
}

sub server_name_or_localhost {
  my PROP $prop = (my $glob = shift)->prop;
  my ($default) = @_;
  my Env $env = $prop->{cf_env};
  $env->{SERVER_NAME} || ($default // 'localhost');
}

sub mkhost {
  my PROP $prop = (my $glob = shift)->prop;
  my ($scheme) = @_;
  $scheme ||= 'http';
  my Env $env = $prop->{cf_env};

  # XXX? Is this secure?
  return $env->{HTTP_HOST} if nonempty($env->{HTTP_HOST});

  my $base = $env->{SERVER_NAME}
    // _invoke_or('localhost', $prop->{cf_cgi}, 'server_name');
  if (my $port = $env->{SERVER_PORT}
      || _invoke_or(80, $prop->{cf_cgi}, 'server_port')) {
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
    # $CON->mkquery($CON) == $CON->mkquery($CON->queryobj)
    $param = $param->queryobj;
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

sub dir_location {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{cf_env};
  ($env->{'yatt.script_name'} // '').($prop->{cf_location} // "/");
}

# script_name + path_info - subpage
# (script_name == location of this dir (DirApp))
#
sub file_location {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{cf_env};
  my $loc = $glob->dir_location;
  if (not $prop->{cf_is_index}
      and my $fn = $prop->{cf_file}) {
    $fn =~ s/\..*//;
    $loc .= $fn;
  }
  $loc;
}

# XXX: not yet tested.
sub is_current_file {
  my PROP $prop = (my $glob = shift)->prop;
  my ($fn) = @_;
  $glob->file_location eq $fn
}

sub is_current_page {
  my PROP $prop = (my $glob = shift)->prop;
  my ($file, $page) = do {
    @_ <= 1 ? (rootname($prop->{cf_file}), $_[0]) : @_;
  };
  rootname($prop->{cf_file}) eq $file
    or return 0;
  $page //= '';
  $page =~ s{^/}{}; # Treat /foo as foo.
  if (empty(my $subpath = $prop->{cf_subpath})) {
    $page eq '';
  } elsif ($page eq '') {
    0
  } else {
    $subpath =~ m{^/$page};
  }
}

sub mapped_path {
  my PROP $prop = (my $glob = shift)->prop;
  my @path = do {
    my $loc = $prop->{cf_location} // "/";
    $loc .= $prop->{cf_file} if defined $prop->{cf_file}
      and not $prop->{cf_is_index};
    ($loc);
  };
  if (defined (my $sp = $prop->{cf_subpath})) {
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
  if (my Env $env = $prop->{cf_env}) {
    $env->{REQUEST_URI};
  } elsif ($prop->{cf_cgi}
      and my $sub = $prop->{cf_cgi}->can('request_uri')) {
    $sub->($prop->{cf_cgi});
  } else {
    $ENV{REQUEST_URI};
  }
}

#========================================

sub redirect {
  my PROP $prop = (my $glob = shift)->prop;
  croak "undefined url" unless @_ and defined $_[0];
  my $url = do {
    if (ref $_[0]) {
      # To do external redirect, $url should pass as SCALAR REF.
      my $arg = shift;
      # die "redirect url is not a scalar ref: $arg";
      $$arg;
    } elsif ($_[0] =~ m{^(?:\w+:)?//([^/]+)}
	     and $1 ne ($glob->mkhost // '')) {
      die $glob->error_with_status(
        400, "External redirect is not allowed: %s", $_[0]
      );
    } else {
      # taint check
      shift;
    }
  };
  if ($prop->{header_was_sent}++) {
    die "Can't redirect multiple times!";
  }

  # Make sure session is flushed before redirection.
  $glob->finalize_headers;

  ${$prop->{cf_buffer}} = '';

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
  if (exists $prop->{session}) {
    $prop->{session};
  } else {
    $prop->{cf_system}->session_resume($glob);
  }
}

sub start_session {
  my PROP $prop = (my $glob = shift)->prop;
  if (defined (my $sess = $prop->{session})) {
    die $glob->error("load_session is called twice! sid=%s", $sess->id);
  }
  $prop->{cf_system}->session_start($glob, @_);
}

sub delete_session {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_system}->session_delete($glob);
}

sub flush_session {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_system}->session_flush($glob);
}

#========================================

sub current_user {
  my PROP $prop = (my $glob = shift)->prop;
  my $cu = do {
    if (exists $prop->{current_user}) {
      $prop->{current_user}
    } elsif (defined $prop->{cf_system}) {
      $prop->{current_user} = $prop->{cf_system}->load_current_user($glob);
    } else {
      $prop->{current_user} = undef;
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

  my Env $env = $prop->{cf_env};
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
