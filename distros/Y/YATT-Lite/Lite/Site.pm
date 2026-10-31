package YATT::Lite::Site; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';

#========================================
# YATT::Lite::Site is the public facade API of YATT::Lite.
#
# This class is inserted as a parent class of YATT::Lite::Factory,
# so that every site object satisfies `$site isa YATT::Lite::Site`
# (YATT::Lite::WebMVC0::SiteApp = Site + PSGI adapter).
#
# This class must NOT declare any fields and must NOT have parent classes.
# Methods only. All instance fields it touches are defined in Factory
# (or its subclasses), so keep `$self` untyped here.
#========================================

use YATT::Lite::Util qw(catch try_invoke);
use YATT::Lite::PSGIEnv;

require File::Basename;
require Encode;

require YATT::Lite::Response;

#========================================
# Class methods to open a site.
#========================================

# Resolve which class implements the factory machinery.
# (Site is a *parent* of Factory, so Site itself cannot inherit them.)
sub _facade_factory_class {
  my ($pack) = @_;
  if ($pack->can('find_load_factory_script')) {
    $pack;
  } else {
    require YATT::Lite::Factory;
    'YATT::Lite::Factory';
  }
}

# Load the site object defined by app.psgi/runyatt.psgi, searching upward
# from $opts{dir}. Dies when not found. Defaults to offline => 1
# (error_handler passes raw die through) since this entry is mainly for
# programs and tools; the web entry point is app.psgi itself.
#
# Like Node's require.cache, one factory script yields one site object
# per process: loading the same script twice would collide on app_ns
# anyway, so subsequent load()s return the cached instance (with any
# explicitly given opts re-configured onto it).
our %SCRIPT_CACHE;
sub load {
  my ($pack, %opts) = @_;
  my $class = $pack->_facade_factory_class;
  my $dir = delete $opts{dir} // '.';
  my $stop_at = delete $opts{stop_at};
  my ($script) = $class->find_factory_script($dir, stop_at => $stop_at)
    or croak "Can't find factory script (app.psgi or runyatt.psgi)"
    . " at or above: $dir"
    . (defined $stop_at ? " (search stopped at: $stop_at)" : "");
  my $key = YATT::Lite::Util::normalize_fs_path($class->rel2abs($script));
  if (my $site = $SCRIPT_CACHE{$key}) {
    $site->configure(%opts) if %opts;
    return $site;
  }
  $opts{offline} = 1 unless exists $opts{offline};
  my $site = $class->load_factory_script($key)
    or croak "Can't load YATT::Lite::Factory instance from $script";
  $site->configure(%opts);
  $SCRIPT_CACHE{$key} = $site;
}

# Like load, but falls back to a plain SiteApp when no factory script
# is found. app_ns is auto-uniquified so that multiple default sites
# can coexist in one process. The class of the synthesized site can be
# overridden with class => 'My::SiteApp'.
sub load_or_default {
  my ($pack, %opts) = @_;
  my $class = $pack->_facade_factory_class;
  my $app_class = delete $opts{class} // 'YATT::Lite::WebMVC0::SiteApp';
  if ($class->find_factory_script($opts{dir}, stop_at => $opts{stop_at})) {
    return $pack->load(%opts);
  }
  my $dir = delete $opts{dir};
  delete $opts{stop_at};
  $opts{offline} = 1 unless exists $opts{offline};
  YATT::Lite::Util::ckrequire($app_class);
  $app_class->new
    (app_ns => $pack->_uniq_default_app_ns
     , (defined $dir ? (app_root => $dir, doc_root => $dir) : ())
     , header_charset => 'utf-8'
     , tmpl_encoding => 'utf-8'
     , output_encoding => 'utf-8'
     , %opts);
}

our $DEFAULT_APP_NS_SEQ = 0;
sub _uniq_default_app_ns {
  my ($pack) = @_;
  my $ns;
  do {
    my $seq = $DEFAULT_APP_NS_SEQ++;
    $ns = 'MyYATT' . ($seq ? $seq : '');
  } while (do {no strict 'refs'; %{"${ns}::"}});
  $ns;
}

#========================================
# resolve_file: filename => (dirhandler, template_name [, location])
#
# Files under doc_root are resolved via location (exactly like the web
# does), others fall back to the physical dirhandler.
#========================================

sub resolve_file {
  my ($self, $fn) = @_;
  defined $fn and $fn ne ''
    or croak "resolve_file: filename is missing!";
  my $abs = YATT::Lite::Util::normalize_fs_path($self->rel2abs($fn));
  my $dir = File::Basename::dirname($abs);
  my $name = File::Basename::basename($abs);
  my $loc = $self->_loc_under_doc_root($dir);
  my $dh = defined $loc
    ? $self->get_lochandler($loc)
    : $self->get_dirhandler($dir);
  wantarray ? ($dh, $name, $loc) : $dh;
}

sub _loc_under_doc_root {
  my ($self, $dir) = @_;
  my $root = $self->{doc_root}
    or return undef;
  $root = YATT::Lite::Util::normalize_fs_path($self->rel2abs($root));
  $root =~ s{/+\z}{};
  if ($dir eq $root) {
    '/';
  } elsif (index($dir, "$root/") == 0) {
    substr($dir, length($root));
  } else {
    undef;
  }
}

#========================================
# request($method, $path, $args, %opts)
#
# Synthesizes a PSGI env and runs it through the real call($env),
# so the result is identical to a real web request
# (path resolution, sigil, public check, SIG traps, error page and all).
#========================================

sub request {
  my ($self, $method, $path, $args, %opts) = @_;
  my $call = $self->can('call')
    or croak "request() requires a web-capable site (SiteApp), not: "
    . ref($self);
  my Env $env = $self->psgi_env_for($method, $path, $args, %opts);
  $self->prepare_app unless $self->{is_psgi};
  YATT::Lite::Response->from_psgi($call->($self, $env));
}

sub psgi_env_for {
  my ($self, $method, $path, $args, %opts) = @_;
  $method = uc($method // 'GET');
  defined $path and $path =~ m{^/}
    or croak "request path must start with '/': " . ($path // '(undef)');
  my ($path_info, $query) = $path =~ m{^([^?]*) (?:\?(.*))?\z}x;

  my Env $env = Env->psgi_simple_env(PATH_INFO => $path_info);
  $env->{REQUEST_METHOD} = $method;
  $env->{SCRIPT_NAME} = '';
  $env->{SERVER_NAME} = 'localhost';
  $env->{SERVER_PORT} = 80;
  $env->{SERVER_PROTOCOL} = 'HTTP/1.1';
  $env->{HTTP_HOST} = 'localhost';

  my $encoded = $self->encode_query($args);
  if ($method eq 'POST' or $method eq 'PUT') {
    $env->{QUERY_STRING} = $query // '';
    my $body = $encoded // '';
    open my $input, '<', \$body or die "Can't open in-memory body: $!";
    $env->{'psgi.input'} = $input;
    $env->{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
    $env->{CONTENT_LENGTH} = length($body);
  } else {
    $env->{QUERY_STRING} = join '&', grep {defined $_ and $_ ne ''}
      ($query, $encoded);
  }
  $env->{REQUEST_URI} = $path_info
    . (($env->{QUERY_STRING} // '') ne '' ? "?$env->{QUERY_STRING}" : '');

  if (my $override = $opts{env}) {
    $env->{$_} = $override->{$_} for keys %$override;
  }
  $env;
}

# $args: HASH (value may be ARRAY for multi-value), ARRAY of pairs,
# or a raw query string.
sub encode_query {
  my ($self, $args) = @_;
  return undef unless defined $args;
  return $args unless ref $args;
  my @pairs;
  if (ref $args eq 'HASH') {
    foreach my $key (sort keys %$args) {
      my $value = $args->{$key};
      push @pairs, _url_encode($key) . '=' . _url_encode($_)
	for ref $value eq 'ARRAY' ? @$value : $value;
    }
  } elsif (ref $args eq 'ARRAY') {
    my @list = @$args;
    while (my ($key, $value) = splice @list, 0, 2) {
      push @pairs, _url_encode($key) . '=' . _url_encode($value);
    }
  } else {
    croak "Unsupported args type for query: " . ref $args;
  }
  join '&', @pairs;
}

sub _url_encode {
  my ($str) = @_;
  $str //= '';
  $str = Encode::encode_utf8($str) if utf8::is_utf8($str);
  $str =~ s{([^0-9A-Za-z_.~-])}{sprintf("%%%02X", ord $1)}eg;
  $str;
}

#========================================
# render_file($fn, $args, %opts)
#
# Dispatch (part resolution, sigil, public check, argument reordering)
# is identical to the web, but the error policy defaults to tool style:
# no error page conversion, raw die passes through (perl -d friendly).
# Pass error_style => 'web' for web-equivalent error handling.
#========================================

sub render_file {
  my ($self, $fn, $args, %opts) = @_;
  my $error_style = delete $opts{error_style} // 'raw';
  $error_style =~ /^(?:raw|web)\z/
    or croak "Unknown error_style: $error_style (raw or web)";

  my ($dh, $name, $loc) = $self->resolve_file($fn);

  my Env $env = $self->psgi_env_for(GET => $self->_path_info_for($name, $loc));
  try_invoke($self, 'set_yatt_script_name', $env);

  require Hash::MultiValue;
  my $params = Hash::MultiValue->new
    (map {
      my $key = $_; my $value = $args->{$key};
      ref $value eq 'ARRAY' ? (map {($key => $_)} @$value) : ($key => $value);
    } $args ? keys %$args : ());

  my $con = $self->make_connection
    (undef
     , env => $env
     , path_info => $env->{PATH_INFO}
     , parameters => $params
     , file => $name
     , noheader => 1
     , yatt => $dh);

  my $dh_fields = YATT::Lite::Util::fields_hash($dh);
  my $error = catch {
    if ($error_style eq 'web'
	or not ($dh_fields and $dh_fields->{_ignore_die})) {
      $self->run_dirhandler($dh, $con, $name);
    } else {
      # Tool style: neutralize the __DIE__/__WARN__ traps installed by
      # DirApp::handle, so plain die reaches the caller (and perl -d) as is.
      local $dh->{_ignore_die} = 1;
      local $dh->{_ignore_warn} = 1;
      $self->run_dirhandler($dh, $con, $name);
    }
  };

  try_invoke($con, 'flush_headers');

  if ($error_style eq 'web' and $con->can('is_error') and $con->is_error) {
    return $self->_error_to_response($con->error_list->[0], $env, $con);
  }

  if (not $error or YATT::Lite::Util::is_done($error)) {
    $self->_response_of_connection($con);
  } elsif (ref $error eq 'ARRAY' or ref $error eq 'CODE') {
    YATT::Lite::Response->from_psgi($error);
  } elsif ($error_style eq 'web'
	   and UNIVERSAL::isa($error, 'YATT::Lite::Error')) {
    $self->_error_to_response($error, $env, $con);
  } else {
    die $error;
  }
}

sub _path_info_for {
  my ($self, $name, $loc) = @_;
  my $req_name = $name;
  if (defined(my $ext = $self->{ext_public})) {
    $req_name =~ s/\.\Q$ext\E\z//;
  }
  my $path_info = $loc // '/';
  $path_info .= '/' unless $path_info =~ m{/\z};
  $path_info . $req_name;
}

sub _response_of_connection {
  my ($self, $con) = @_;
  my @headers = $con->can('list_header') ? $con->list_header : ();
  YATT::Lite::Response->new
    (status => (try_invoke($con, [cget => 'status']) // 200)
     , headers => \@headers
     , body => [$con->buffer]);
}

sub _error_to_response {
  my ($self, $err, $env, $con) = @_;
  if ($self->can('error_response')) {
    YATT::Lite::Response->from_psgi($self->error_response($err, $env, $con));
  } else {
    die $err;
  }
}

1;
