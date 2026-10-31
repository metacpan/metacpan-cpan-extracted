package YATT::Lite::WebMVC0::Partial::Session2;
sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use constant DEBUG => ($ENV{DEBUG_YATT_SESSION2} // 0);
use YATT::Lite::Util qw/dputs
                        lexpand
                       /;

use Plack::Util;

#========================================

# This version of YATT::Lite::WebMVC0::Partial::Session2 directly
# calls *internal* methods of Plack::Middleware::Session.

use Plack::Middleware::Session;
sub default_session_middleware_class {'Plack::Middleware::Session'}

#========================================

use YATT::Lite::PSGIEnv;

use YATT::Lite::Partial
  (requires => [qw/
                    error
		  /]
   , fields => [qw/
                    _session_middleware
                    session_middleware_class
                    session_state
                    session_store
		  /]
   , -Entity, -CON
  );

#========================================

Entity psgix_session => sub {
  my ($this, @opts) = @_;
  my Env $env = $CON->env;
  unless ($env->{'psgix.session.options'}) {
    $CON->cget('system')->session_start($CON, @opts);
  }
  $env->{'psgix.session'};
};

Entity psgix_session_or_dummy => sub {
  my ($this) = @_;
  if ($this->entity_session_state_exists) {
    $this->entity_psgix_session;
  } else {
    +{};
  }
};

Entity psgix_session_options => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $env->{'psgix.session.options'};
};

Entity psgix_session_exists => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  defined $env->{'psgix.session.options'}
    and $env->{'psgix.session.options'}{'id'};
};

#----------------------------------------
Entity session_start => sub {
  my ($this, @opts) = @_;
  $CON->cget('system')->session_start($CON, @opts);
  "";
};

Entity session_state_id => sub {
  my ($this) = @_;
  $CON->cget('system')->session_state_extract_id($CON);
};

Entity session_state_exists => sub {
  $CON->cget('system')->session_state_exists($CON);
};

Entity session_change_id => sub {
  my ($this) = @_;
  $CON->cget('system')->session_change_id($CON);
};

Entity session_expire => sub {
  my ($this) = @_;
  $CON->cget('system')->session_expire($CON);
  "";
};

Entity session_middleware => sub {
  my ($this) = @_;
  my MY $self = $CON->cget('system');
  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };
  $mw;
};

Entity session_csrf_token => sub {
  my ($this, $name) = @_;
  $name //= "csrf_token"; # XXX: default name should be configurable.
  $this->entity_psgix_session->{$name} //= do {
    $this->entity_session_middleware->state->generate;
  };
};

#----------------------------------------
sub default_session_class {'Plack::Session'}

Entity session => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $env->{'plack.session'};
};

{
  foreach my $meth (qw(id get keys)) {
    Entity "session_$meth" => sub {
      my $this = shift;
      my Env $env = $CON->env;
      $env->{'plack.session'}->$meth(@_);
    };
  }
  foreach my $meth (qw(set remove)) {
    Entity "session_$meth" => sub {
      my $this = shift;
      my Env $env = $CON->env;
      $env->{'plack.session'}->$meth(@_);
      "";
    };
  }
}

#========================================

#
# Stolen from the top half of Plack::Middleware::Session->call
#
sub session_start {
  (my MY $self, my ($CON, @opts)) = @_;

  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  my Env $env = $CON->env;

  my $id = $self->session_state_extract_id($CON);
  my $session; $session = $self->session_store_fetch($CON, $id) if $id;

  $self->session_init_env($env, $session, $id, @opts);
}

sub session_expire {
  (my MY $self, my ($CON)) = @_;

  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  my Env $env = $CON->env;

  # XXX: How about renaming $options->{expire} to $options->{do_expire}
  # to avoid confusing with $options->{expires}.
  #
  if (my $options = $env->{'psgix.session.options'}) {

    $options->{expire} = 1;

  } else {
    my $id = $self->session_state_extract_id($CON);
    $self->session_init_env($env, {}, $id, expire => 1);
  }

}

sub session_init_env {
  (my MY $self, my Env $env, my ($session, $id, %opts)) = @_;

  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  if ($id && $session) {
    $env->{'psgix.session'} = $session;
  } else {
    $id = $mw->generate_id($env);
    $env->{'psgix.session'} = {};
  }

  $opts{path} //= $env->{'yatt.script_dir'};

  $env->{'psgix.session.options'} = { id => $id, %opts };

  $self->session_apply_cookie_defaults($env, $env->{'psgix.session.options'});

  $env->{'plack.session'}
    = Plack::Util::load_class($self->default_session_class)->new($env);

}

#
# Cookie attribute defaults for the session cookie, applied to
# psgix.session.options so that both State::Cookie#finalize and
# #expire_session_id see them (merge_options only fills what is absent):
#
#  secure   - 1 whenever the request came over TLS (psgi.url_scheme,
#             X-Forwarded-Proto or HTTPS), not only when $env->{HTTPS} is set.
#  httponly - 1, unless the configured session_state defines it.
#  samesite - Lax, unless the configured session_state defines it.
#
sub session_apply_cookie_defaults {
  (my MY $self, my Env $env, my $options) = @_;
  my $state = $self->{_session_middleware}->state;

  if (Env->is_https($env)) {
    $options->{secure} //= 1;
  }
  foreach my $spec ([httponly => 1], [samesite => 'Lax']) {
    my ($attr, $default) = @$spec;
    next if exists $options->{$attr};
    next if $state->can($attr) and defined $state->$attr;
    $options->{$attr} = $default;
  }
  $options;
}

sub session_state_exists {
  (my MY $self, my $CON) = @_;
  defined $self->session_state_extract_id($CON);
}

#
# The session id as claimed by the client's cookie. Only an id that
# passes the state's validator (Plack::Session::State: /\A[0-9a-f]{40}\Z/)
# is returned; anything else is treated as "no cookie" so it never
# reaches $store->fetch/remove (with Plack::Session::Store::File, an
# unvalidated id is a file path).
#
sub session_state_extract_id {
  (my MY $self, my $CON) = @_;
  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  my $state = $mw->state;
  my $id = $CON->cookies_in->{$state->session_key};
  return undef unless defined $id and length $id;
  if ($state->can('validate_session_id')) {
    return undef unless $state->validate_session_id($id);
  }
  $id;
}

#
# In some case, you may want to clear previous session explicitly
# even when previous cookie state exists.
#
sub session_change_id {
  (my MY $self, my $CON) = @_;
  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  my Env $env = $CON->env;

  if (not $env->{'psgix.session'}) {
    if (my $prev_sid = $self->session_state_extract_id($CON)) {
      $self->session_store_remove($CON, $prev_sid);
    }

    $self->session_init_env($env);

    return $env->{'psgix.session.options'}{'id'};
  } else {
    $mw->change_id($env);
  }
}

sub session_store_fetch {
  (my MY $self, my ($CON, $id)) = @_;
  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  $mw->store->fetch($id);
}

sub session_store_remove {
  (my MY $self, my ($CON, $id)) = @_;
  my $mw = $self->{_session_middleware} or do {
    Carp::croak("Session middleware is not initialized!");
  };

  $mw->store->remove($id);
}

#
# Stolen from the bottom half of Plack::Middleware::Session->call
#
sub finalize_response {
  (my MY $self, my ($env, $res)) = @_;

  dputs('START') if DEBUG >= 4;

  $self->maybe::next::method($env, $res);

  my $mw = $self->{_session_middleware};
  my $session = $env->{'psgix.session'};
  my $options = $env->{'psgix.session.options'};

  if (not $session) {
    return;
  }

  # XXX: See comment in session_expire() too.
  #
  if ($options->{expire}) {
    dputs('EXPIRE') if DEBUG >= 4;
    $mw->expire_session($options->{id}, $res, $env);
  } else {
    $mw->change_id($env) if $options->{change_id};
    $mw->commit($env);
    $mw->save_state($options->{id}, $res, $env);
    dputs('SAVED') if DEBUG >= 4;
  }

  dputs('DONE') if DEBUG >= 4;
}

#
# This prepare_app is called very late of inheritance chain.
#
sub prepare_app {
  (my MY $self) = @_;

  dputs('START') if DEBUG >= 3;

  my $mw = $self->{_session_middleware} = do {
    my $class = $self->{session_middleware_class}
      || $self->default_session_middleware_class;

    my $state = ($self->{session_state}
                    ? $self->create_session_backend(State => $self->{session_state})
                    : Plack::Util::load_class($self->default_session_state)->new());

    $class->new({app => sub {[200, [], []]}
                 , state => $state
                 , ($self->{session_store}
                    ? (store => $self->create_session_backend(Store => $self->{session_store})) : ())
               });
  };

  dputs('session_middleware is created') if DEBUG >= 3;

  $mw->prepare_app;

  dputs('after session_middleware->prepare_app') if DEBUG >= 3;

  dputs('begin maybe::next::method') if DEBUG >= 3;

  $self->maybe::next::method;

  dputs('DONE') if DEBUG >= 3;
}

sub default_session_state {'Plack::Session::State::Cookie'}
sub default_session_store {'Plack::Session::Store'}
sub default_session_class_prefix {'Plack::Session'}

# From Session::inflate_backend
sub create_session_backend {
  (my MY $self, my ($kind, $spec)) = @_;

  # When $spec is not [$backend => @opts], just return it.
  return $spec if defined $spec and ref $spec ne 'ARRAY';

  my ($backend, @args) = lexpand($spec);

  my $prefix = join("::", $self->default_session_class_prefix, $kind);

  my $class = Plack::Util::load_class($backend, $prefix);

  $class->new(@args);
}

1;
