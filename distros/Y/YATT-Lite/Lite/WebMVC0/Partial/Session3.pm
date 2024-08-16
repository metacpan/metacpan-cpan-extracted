package YATT::Lite::WebMVC0::Partial::Session3;
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

use Session::ExpiryFriendly;
use Plack::Middleware::Session::ExpiryFriendly;
sub default_session_middleware_class {'Plack::Middleware::Session::ExpiryFriendly'}

#========================================

use YATT::Lite::PSGIEnv;

use YATT::Lite::Partial
  (requires => [qw/
                    error
		  /]
   , fields => [qw/
                    _session_middleware
                    cf_session_middleware_class
                    cf_session_state
                    cf_session_store
                    cf_session_serializer
                    _session
                    cf_session_cookie_option
                    _session_in_request
		  /]
   , -Entity, -CON
  );

#========================================

Entity psgix_session => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $env->{'psgix.session'};
};

Entity psgix_session_options => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $env->{'psgix.session.options'};
};

#----------------------------------------
Entity session_start => sub {
  my ($this, @opts) = @_;
  my Env $env = $CON->env;
  $CON->cget('system')->{_session}->start_session($env, @opts);
  "";
};

Entity get_session => sub {
  my ($this) = @_;
  my Env $env = $CON->env;
  $CON->cget('system')->{_session}->get_session($env);
};
#----------------------------------------

sub finalize_response {
  (my MY $self, my ($env, $res)) = @_;
  $self->{_session_middleware}->finalize( $env, $res );
}

#
# This prepare_app is called very late of inheritance chain.
#
sub prepare_app {
  (my MY $self) = @_;

  dputs('START') if DEBUG >= 3;

  my $sef = Session::ExpiryFriendly->new(
        ($self->{cf_session_state}
            ? (state => $self->create_session_backend(state => $self->{cf_session_state})) : ()),
        ($self->{cf_session_store}
            ? (store => $self->create_session_backend(store => $self->{cf_session_store})) : ()),
  );

    if ( my $opt = $self->{cf_session_cookie_option} ) {
        for my $attr (qw(session_key path domain expires secure httponly)) {
            $sef->state->$attr($opt->{$attr}) if exists $opt->{$attr};
        }
    }

  $self->{_session} = $sef;

  my $mw = $self->{_session_middleware} = do {
    my $class = $self->{cf_session_middleware_class}
      || $self->default_session_middleware_class;

    $class->new({app => sub {[200, [], []]}, session => $sef});
  };

  dputs('session_middleware is created') if DEBUG >= 3;

  $mw->prepare_app;

  dputs('after session_middleware->prepare_app') if DEBUG >= 3;

  dputs('begin maybe::next::method') if DEBUG >= 3;

  $self->maybe::next::method;

  dputs('DONE') if DEBUG >= 3;
}

sub default_session_state {'Session::ExpiryFriendly::State::Cookie'}
sub default_session_store {'Session::ExpiryFriendly::Store::DBI'}

# From Session::inflate_backend
sub create_session_backend {
  (my MY $self, my ($kind, $spec)) = @_;

  # When $spec is not [$backend => @opts], just return it.
  return $spec if defined $spec and ref $spec ne 'ARRAY';

  my $prefix = $self->can("default_session_$kind")->();

  my ($backend, @args) = lexpand($spec);

  my $class = Plack::Util::load_class($backend, $prefix);

  if (my $sub = $self->can("create_session_${kind}_$backend")) {
    $sub->($self, $class, @args);
  } else {
    $class->new(@args);
  }
}

1;
