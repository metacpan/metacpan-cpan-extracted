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
   , fields => [qw/cf_session_driver
		   cf_session_config
		   cf_session_debug
		   cf_session_path
		   cf_csrftok_name
		   cf_tmpdir
		  /]
   , -Entity, -CON
  );

use YATT::Lite::Util qw/lexpand escape nonempty symtab
			num_is_ge/;

use YATT::Lite::Types [Config => fields => [qw/name expire/]];

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

Entity csrf_token_input => sub {
  my ($this, $name) = @_;
  $name ||= $CON->cget('system')->csrftok_name;

  \ sprintf <<END, $name, escape($CON->get_session_sid);
<input type="hidden" name="%s" value="%s">
END
};

Entity csrf_token_check => sub {
  my ($this, $name) = @_;
  $name ||= $CON->cget('system')->csrftok_name;

  nonempty(my $sid = $CON->get_session_sid)
    or return undef;
  nonempty(my $got = $CON->param($name))
    or return undef;

  $sid eq $got;
};

{
  my $symtab = symtab(MY);
  foreach my $meth (grep {/^session_/} keys %$symtab) {
    my $sub = MY->can($meth);
    Entity $meth => sub {
      my $this = shift;
      my ConnProp $prop = $CON->prop;
      my MY $self = $prop->{cf_system};
      $self->$meth($CON, @_);
    };
  }
}

#========================================

# This will be called back from $CON->get_session_sid.
sub session_sid {
  (my MY $self, my ($con)) = @_;
  my ConnProp $prop = $con->prop;
  my $sid_name = $self->session_sid_name;
  my $ck = $con->cookies_in->{$sid_name}
    or return undef;
  ref $ck ? $ck->value : $ck;
}

sub session_regenerate_id {
  (my MY $self, my ($con, @with_init)) = @_;
  my ConnProp $prop = $con->prop;

  if (defined $prop->{session}) {
    $self->session_delete($con);
  }

  $self->session_start($con, @with_init);
}

# This will be called back from $CON->get_session.
# usually called from before_dirhandler
sub session_resume {
  (my MY $self, my ($con)) = @_;
  $con->logbacktrace("session.resume")
    if num_is_ge($self->{cf_session_debug}, 2);

  my ConnProp $prop = $con->prop;

  if (exists $prop->{session}) {
    $con->logdump("session.resume" => "session is already loaded")
      if $self->{cf_session_debug};
    return $prop->{session};
  }
  $prop->{session} = undef;

  my $sid = $self->session_sid($con) or do {
    $con->logdump("session.resume" => "sid is empty")
       if $self->{cf_session_debug};
    return undef;
  };

  my $sess = $self->session_create_by(load => $con, $sid)
    or $self->error("Can't load session for sid='%s': %s"
		    , $sid, CGI::Session->errstr);

 CHK: {
    if ($sess->is_expired) {
      $con->logdump("session.resume" => expired => $sid)
	if $self->{cf_session_debug};
    } elsif (not $sess->id) {
      $con->logdump("session.resume" => "id is empty"
		    , claimed_sid => $sid, sessobj => $sess)
	if $self->{cf_session_debug};
    } else {
      last CHK;
    }
    # not ok.
    delete $prop->{session}; # To allow calling session_start.
    return undef; # XXX: Should we notify?
  };

  $con->logdump("session.resume" => OK => sid => $sid)
    if $self->{cf_session_debug};

  $prop->{session} = $sess;
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
    if num_is_ge($self->{cf_session_debug}, 2);

  my ConnProp $prop = $con->prop;

  if (defined $prop->{session}) {
    $self->error("session is called twice! sid=%s", $prop->{session}->id);
  }
  $prop->{session} = undef;

  my $sess = $self->session_create_by(new => $con)
    or $self->error("Can't create new session: %s", CGI::Session->errstr);

  $con->set_cookie($self->session_sid_name
		   , $sess->id
		   , -path => $path);
  $sess->clear;
  $self->session_init($con, $sess, @with_init) if @with_init;

  $prop->{session} = $sess;
}

sub session_create_by {
  (my MY $self, my ($method, $con, $sid)) = @_;
  require CGI::Session;

  my ($type, %driver_opts) = $self->session_driver;
  my Config $opts = $self->{cf_session_config};

  my $expire = delete($opts->{expire}) // $self->default_session_expire;
  if (my $sess = CGI::Session->$method($type, $sid, \%driver_opts, $opts)) {
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
  $self->{cf_session_driver}
    ? lexpand($self->{cf_session_driver})
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
    if num_is_ge($self->{cf_session_debug}, 2);

  if (my $sess = delete $prop->{session}) {
    my $sid = $sess->id;
    $sess->delete;
    $sess->flush;
    $con->logdump("session.delete" => OK => sid => $sid)
      if $self->{cf_session_debug};
  } else {
    $con->logdump("session.delete" => 'NOP')
      if $self->{cf_session_debug};
  }
  my $name = $self->session_sid_name;
  my @rm = ($name, '', -expires => '-10y', -path => $path);
  $con->set_cookie(@rm);
}

sub session_flush {
  my MY $self = shift;
  my ConnProp $prop = (my $glob = shift)->prop;
  my $sess = $prop->{session}
    or return;
  return if $sess->errstr;
  $sess->flush;
  if (my $err = $sess->errstr) {
    local $prop->{session};
    $self->error("Can't flush session: %s", $err);
  }
}

sub configure_use_session {
  (my MY $self, my $value) = @_;
  if ($value) {
    $self->{cf_session_config}
      //= ref $value ? +{lexpand($value)} : +{$self->default_session_config};
    $self->{cf_session_driver} //= [$self->default_session_driver];
  }
}

sub session_path {
  (my MY $self, my ($con)) = @_;
  $self->{cf_session_path} || $con->site_location;
}

sub session_sid_name {
  (my MY $self) = @_;
  my Config $opts = $self->{cf_session_config};
  $opts->{name} || $self->default_session_sid_name;
}

sub default_session_expire  { '1d' }
sub default_session_sid_name { 'SID' }
sub default_session_config  {}

sub default_session_driver  {
  (my MY $self) = @_;
  my $tmpdir = $self->{cf_tmpdir} //= $self->app_path_var_tmp('sess');
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
  $self->{cf_csrftok_name} || $self->default_csrftok_name;
}

sub default_csrftok_name { '--csrftok' }

1;
