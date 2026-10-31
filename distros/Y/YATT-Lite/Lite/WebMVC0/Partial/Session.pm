package YATT::Lite::WebMVC0::Partial::Session;
sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use YATT::Lite::Partial
  (requires => [qw/error
		   app_path_ensure_existing
		   app_path_var_tmp
		  /]
   , fields => [qw/session_driver
		   session_config
		   session_debug
		   session_path
		   csrftok_name
		   tmpdir
		  /]
   , -Entity, -CON
  );

use YATT::Lite::Util qw/lexpand escape nonempty symtab
			num_is_ge secure_random_hex/;

# session_config: name, expire, plus cookie attributes
# (httponly/secure/samesite) to override the defaults in session_cookie_opts.
use YATT::Lite::Types [Config => fields => [qw/name expire
                                                httponly secure samesite/]];

#========================================

use YATT::Lite::WebMVC0::Connection;
sub Connection () {'YATT::Lite::WebMVC0::Connection'}
sub ConnProp () {Connection}

#========================================
# Session support, based on CGI::Session.
#========================================

Entity sess => sub {
  my ($this) = shift;

  # This will call MY->session_resume.
  my $sess = $CON->get_session
    or return undef;

  $sess->param(@_);
};

#
# CSRF token is a random value kept *in* the session, never the session
# id itself: printing the sid into every form would hand it to any
# script in the page (defeating HttpOnly) and to anyone who sees the html.
#
Entity csrf_token_input => sub {
  my ($this, $name) = @_;
  my MY $self = $CON->cget('system');
  $name ||= $self->csrftok_name;

  my $token = $self->session_csrf_token($CON) // '';

  \ sprintf <<END, $name, escape($token);
<input type="hidden" name="%s" value="%s">
END
};

Entity csrf_token_check => sub {
  my ($this, $name) = @_;
  my MY $self = $CON->cget('system');
  $name ||= $self->csrftok_name;

  nonempty(my $token = $self->session_csrf_token($CON, 0))
    or return undef;
  nonempty(my $got = $CON->param($name))
    or return undef;

  $token eq $got;
};

{
  my $symtab = symtab(MY);
  foreach my $meth (grep {/^session_/} keys %$symtab) {
    my $sub = MY->can($meth);
    Entity $meth => sub {
      my $this = shift;
      my ConnProp $prop = $CON->prop;
      my MY $self = $prop->{system};
      $self->$meth($CON, @_);
    };
  }
}

#========================================

# Session id as claimed by the client's cookie. A value that is not a
# plain token is treated as "no cookie" so it never reaches the driver.
sub session_sid {
  (my MY $self, my ($con)) = @_;
  my ConnProp $prop = $con->prop;
  my $sid_name = $self->session_sid_name;
  my $ck = $con->cookies_in->{$sid_name}
    or return undef;
  my $sid = ref $ck ? $ck->value : $ck;
  return undef unless defined $sid and $sid =~ $self->session_sid_validator;
  $sid;
}

sub session_sid_validator { qr{^[A-Za-z0-9_-]{1,128}\z} }

# Returns the CSRF token of the current session, creating it on first use.
# With $create false, returns undef when there is no session or no token yet.
sub session_csrf_token {
  (my MY $self, my ($con, $create)) = @_;
  $create //= 1;
  my $sess = $con->get_session
    or return undef;
  my $key = $self->csrftok_session_key;
  my $token = $sess->param($key);
  if (not nonempty($token) and $create) {
    $token = secure_random_hex(16);
    $sess->param($key, $token);
  }
  $token;
}

# Cookie attributes for the session cookie. Defaults: HttpOnly,
# SameSite=Lax, and Secure whenever the request itself came over TLS.
# Each can be overridden via session_config => {httponly => 0, ...}.
sub session_cookie_opts {
  (my MY $self, my ($con, $path)) = @_;
  my Config $opts = $self->{session_config};
  my $httponly = $opts->{httponly} // 1;
  my $samesite = $opts->{samesite} // 'Lax';
  my $secure   = $opts->{secure} // $con->is_https;
  (-path => $path
   , ($httponly ? (-httponly => 1) : ())
   , ($secure   ? (-secure => 1) : ())
   , (nonempty($samesite) ? (-samesite => $samesite) : ()));
}

sub session_regenerate_id {
  (my MY $self, my ($con, @with_init)) = @_;
  my ConnProp $prop = $con->prop;

  if (defined $prop->{_session}) {
    $self->session_delete($con);
  }

  $self->session_start($con, @with_init);
}

# This will be called back from $CON->get_session.
# usually called from before_dirhandler
sub session_resume {
  (my MY $self, my ($con)) = @_;
  $con->logbacktrace("session.resume")
    if num_is_ge($self->{session_debug}, 2);

  my ConnProp $prop = $con->prop;

  if (exists $prop->{_session}) {
    $con->logdump("session.resume" => "session is already loaded")
      if $self->{session_debug};
    return $prop->{_session};
  }
  $prop->{_session} = undef;

  my $sid = $self->session_sid($con) or do {
    $con->logdump("session.resume" => "sid is empty")
       if $self->{session_debug};
    return undef;
  };

  my $sess = $self->session_create_by(load => $con, $sid)
    or $self->error("Can't load session for sid='%s': %s"
		    , $sid, CGI::Session->errstr);

 CHK: {
    if ($sess->is_expired) {
      $con->logdump("session.resume" => expired => $sid)
	if $self->{session_debug};
    } elsif (not $sess->id) {
      $con->logdump("session.resume" => "id is empty"
		    , claimed_sid => $sid, sessobj => $sess)
	if $self->{session_debug};
    } else {
      last CHK;
    }
    # not ok.
    delete $prop->{_session}; # To allow calling session_start.
    return undef; # XXX: Should we notify?
  };

  $con->logdump("session.resume" => OK => sid => $sid)
    if $self->{session_debug};

  $prop->{_session} = $sess;
}

# This will be called back from $CON->start_session.
sub session_start {
  (my MY $self, my ($con, @with_init)) = @_;

  my $opts = shift @with_init if @with_init and ref $with_init[0] eq 'HASH';
  my $path = delete $opts->{path} || $self->session_path($con);
  if (keys %$opts) {
    $self->error("Invalid option for session_start: %s"
		 , join ", ", keys %$opts);
  }

  $con->logbacktrace("session.start")
    if num_is_ge($self->{session_debug}, 2);

  my ConnProp $prop = $con->prop;

  if (defined $prop->{_session}) {
    $self->error("session is called twice! sid=%s", $prop->{_session}->id);
  }
  $prop->{_session} = undef;

  my $sess = $self->session_create_by(new => $con)
    or $self->error("Can't create new session: %s", CGI::Session->errstr);

  $con->set_cookie($self->session_sid_name
		   , $sess->id
		   , $self->session_cookie_opts($con, $path));
  $sess->clear;
  $self->session_init($con, $sess, @with_init) if @with_init;

  $prop->{_session} = $sess;
}

sub session_create_by {
  (my MY $self, my ($method, $con, $sid)) = @_;
  require CGI::Session;

  my ($type, %driver_opts) = $self->session_driver;
  my Config $opts = $self->{session_config};

  # Unless the DSN names an id generator, use ours (OS CSPRNG, 160 bits)
  # instead of CGI::Session's default id:md5 (md5 of pid, time and rand()).
  unless ($type =~ /(?:^|;)\s*id\s*:/) {
    $self->ensure_secure_id_generator;
    $type .= ";id:" . $self->secure_id_generator_name;
  }

  my $expire = delete($opts->{expire}) // $self->default_session_expire;
  my %cgi_sess_opts = map {
    # cookie attributes are ours, not CGI::Session's.
    /^(?:httponly|secure|samesite)$/ ? () : ($_ => $opts->{$_})
  } keys %$opts;
  if (my $sess = CGI::Session->$method($type, $sid, \%driver_opts, \%cgi_sess_opts)) {
    unless ($sess->is_expired) {
      $sess->expire($expire);
    }
    return $sess;
  }
}

sub session_init {
  my MY $self = shift;
  my ConnProp $prop = (my $con = shift)->prop;
  my ($sess, @with_init) = @_;

  foreach my $spec (@with_init) {
    unless (defined $spec) {
      $self->error("Undefined session initializer");
    } elsif (ref $spec eq 'ARRAY') {
      my ($name, @value) = @$spec;
      $sess->param($name, @value);
    } elsif (not ref $spec or ref $spec eq 'Regexp') {
      $spec = qr{^\Q$spec} unless ref $spec;
      foreach my $name ($con->param) {
	next unless $name =~ $spec;
	my (@value) = $con->param($name);
	$sess->param($name, @value);
      }
    } else {
      $self->error("Invalid session initializer: %s"
		   , terse_dump($spec));
    }
  }
}

sub session_driver {
  (my MY $self) = @_;
  $self->{session_driver}
    ? lexpand($self->{session_driver})
      : $self->default_session_driver;
}

sub session_delete {
  my MY $self = shift;
  my ConnProp $prop = (my $con = shift)->prop;
  my $opts = shift;
  my $path = delete $opts->{path} || $self->session_path($con);
  if (keys %$opts) {
    $self->error("Invalid option for session_delete: %s"
		 , join ", ", keys %$opts);
  }

  $con->logbacktrace("session.delete")
    if num_is_ge($self->{session_debug}, 2);

  if (my $sess = delete $prop->{_session}) {
    my $sid = $sess->id;
    $sess->delete;
    $sess->flush;
    $con->logdump("session.delete" => OK => sid => $sid)
      if $self->{session_debug};
  } else {
    $con->logdump("session.delete" => 'NOP')
      if $self->{session_debug};
  }
  my $name = $self->session_sid_name;
  my @rm = ($name, '', -expires => '-10y'
            , $self->session_cookie_opts($con, $path));
  $con->set_cookie(@rm);
}

sub session_flush {
  my MY $self = shift;
  my ConnProp $prop = (my $glob = shift)->prop;
  my $sess = $prop->{_session}
    or return;
  return if $sess->errstr;
  $sess->flush;
  if (my $err = $sess->errstr) {
    local $prop->{_session};
    $self->error("Can't flush session: %s", $err);
  }
}

sub configure_use_session {
  (my MY $self, my $value) = @_;
  if ($value) {
    $self->{session_config}
      //= ref $value ? +{lexpand($value)} : +{$self->default_session_config};
    $self->{session_driver} //= [$self->default_session_driver];
  }
}

sub session_path {
  (my MY $self, my ($con)) = @_;
  $self->{session_path} || $con->site_location;
}

sub session_sid_name {
  (my MY $self) = @_;
  my Config $opts = $self->{session_config};
  $opts->{name} || $self->default_session_sid_name;
}

sub default_session_expire  { '1d' }
sub default_session_sid_name { 'SID' }
sub default_session_config  {}

sub default_session_driver  {
  (my MY $self) = @_;
  my $tmpdir = $self->{tmpdir} //= $self->app_path_var_tmp('sess');
  ("driver:file"
   , Directory => $tmpdir
  )
}

sub cmd_session_list {
  (my MY $self, my @param) = @_;
  print join("\t", qw(id created accessed), @param), "\n";
  require CGI::Session;
  my ($type, %driver_opts) = $self->session_driver;
  CGI::Session->find($type, sub {
    my ($sess) = @_;
    print join("\t", map {defined $_ ? $_ : "(undef)"}
	       $sess->id, $sess->ctime, $sess->atime
	       , map {$sess->param($_)} @param), "\n";
  }, \%driver_opts);
}


sub csrftok_name {
  (my MY $self) = @_;
  $self->{csrftok_name} || $self->default_csrftok_name;
}

sub default_csrftok_name { '--csrftok' }

# Session parameter name under which the CSRF token is stored.
sub csrftok_session_key { '_yatt_csrf_token' }

#========================================
# Session id generator plugged into CGI::Session (as "id:yatt_secure").
#
# CGI::Session only accepts generators named CGI::Session::ID::<word>
# and loads them with `require`, so the package is defined here and
# registered in %INC once, right before CGI::Session needs it.
#========================================

sub secure_id_generator_name { 'yatt_secure' }

sub ensure_secure_id_generator {
  (my MY $self) = @_;
  my $name = $self->secure_id_generator_name;
  my $pm = "CGI/Session/ID/$name.pm";
  return if $INC{$pm};
  require CGI::Session::ErrorHandler;
  my $pkg = "CGI::Session::ID::$name";
  no strict 'refs';
  @{"${pkg}::ISA"} = ('CGI::Session::ErrorHandler');
  *{"${pkg}::generate_id"} = sub { secure_random_hex(20) }; # 40 hex chars
  *{"${pkg}::generate"} = \&{"${pkg}::generate_id"};
  $INC{$pm} = __FILE__;
}

1;
