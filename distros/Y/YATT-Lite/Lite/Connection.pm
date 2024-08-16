package YATT::Lite::Connection; sub PROP () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use Hash::Util qw/lock_keys/;

# XXX: MFields may be ok.
use YATT::Lite::MFields
  (# Incoming request. Should be filled by Dispatcher(Factory)
    [cf_env => getter => [env => 'glob']]
    , qw/cookies_in/

   # To debug liveness/leakage.
   , qw/cf_debug/

   # Outgoing response. Should be written by YATT and *.yatt
   , qw/cf_parent_fh cf_buffer
	headers header_was_sent
	cf_status cf_content_type cf_charset cf_encoding
	cookies_out/

   # To suppress HTTP header, set this.
   , 'cf_noheader'
   # To suppress flush_header on DESTROY, set this.
   , 'cf_no_auto_flush_headers'

   # To distinguish error state.
   , qw/is_error raised oldbuf diag_list error_list/

   # Session store
   , qw/session stash debug_stash/

   # For logging, compatible to psgix.logger (I hope. Not yet used.)
   , qw/cf_logger/

   # For poorman's logging logdump() series.
   , qw/cf_logfh/

   # Invocation context
   , qw/cf_system cf_yatt cf_backend cf_dbh/

   # Raw path_info. should match with env->{PATH_INFO}
   , qw/cf_path_info/

   # Location quad and is_index flag
   , qw/cf_dir cf_location cf_file cf_subpath
	cf_is_index/

   # Not used..
   , qw/cf_root/

   # User's choice of message language.
   , qw/cf_lang/
  );

use YATT::Lite::Util qw(
                         globref lexpand fields_hash incr_opt terse_dump
                         raise_response
                     );
use YATT::Lite::PSGIEnv;

sub prop { *{shift()}{HASH} }

sub YATT {
  my PROP $prop = prop(my $glob = shift);
  $prop->{cf_yatt};
}

# # XXX: Experimental. This can slowdown 20%! the code like: print $CON (text);
# use overload qw/%{}  as_hash
# 		bool as_bool/;
# sub as_hash { *{shift()}{HASH} }
# sub as_bool { defined $_[0] }

#========================================
# Constructors
#========================================

sub create {
  my ($class, $self) = splice @_, 0, 2;
  require IO::Handle;
  my ($prop, @task) = $class->build_prop(@_);
  $class->build_fh_for($prop, $self);
  $_->[0]->($self, $_->[1]) for @task;
  $self->after_create;
  $self;
}

sub after_create {}

sub build_prop {
  my $class = shift;
  my $fields = fields_hash($class);
  my PROP $prop = lock_keys(my %prop, keys %$fields);
  my @task;
  while (my ($name, $value) = splice @_, 0, 2) {
    if (my $sub = $class->can("configure_$name")) {
      push @task, [$sub, $value];
    } elsif (not exists $fields->{"cf_$name"}) {
      confess "No such config item '$name' in class $class";
    } else {
      $prop->{"cf_$name"} = $value;
    }
  }
  wantarray ? ($prop, @task) : $prop;
}

sub build_fh_for {
  (my $class, my PROP $prop) = splice @_, 0, 2;
  unless (defined $_[0]) {
    my $enc = $$prop{cf_encoding} ? ":encoding($$prop{cf_encoding})" : '';
    $prop->{cf_buffer} //= (\ my $str);
    ${$prop->{cf_buffer}} //= "";
    open $_[0], ">$enc", $prop->{cf_buffer} or die $!;
  } elsif ($$prop{cf_encoding}) {
    binmode $_[0], ":encoding($$prop{cf_encoding})";
  }
  bless $_[0], $class;
  *{$_[0]} = $prop;
  $_[0];
}

sub configure_encoding {
  my PROP $prop = prop(my $glob = shift);
  my $enc = shift;
  $prop->{cf_encoding} = $enc;
  binmode $glob, ":encoding($enc)";
}

sub get_encoding_layer {
  my PROP $prop = prop(my $glob = shift);
  $$prop{cf_encoding} ? ":encoding($$prop{cf_encoding})" : '';
}

#========================================

sub cget {
  confess "Not enough arguments" if @_ < 2;
  confess "Too many arguments" if @_ > 3;
  my PROP $prop = prop(my $glob = shift);
  my ($name, $default) = @_;
  my $fields = fields_hash($glob);
  if (not exists $fields->{"cf_$name"}) {
    confess "No such config item '$name' in class " . ref $glob;
  }
  $prop->{"cf_$name"} // $default;
}

sub configure {
  my PROP $prop = prop(my $glob = shift);
  my $fields = fields_hash($glob);
  my (@task);
  while (my ($name, $value) = splice @_, 0, 2) {
    unless (defined $name) {
      croak "Undefined name given for @{[ref($glob)]}->configure(name=>value)!";
    }
    $name =~ s/^-//;
    if (my $sub = $glob->can("configure_$name")) {
      push @task, [$sub, $value];
    } elsif (not exists $fields->{"cf_$name"}) {
      confess "No such config item '$name' in class " . ref $glob;
    } else {
      $prop->{"cf_$name"} = $value;
    }
  }
  if (wantarray) {
    # To delay configure_zzz.
    @task;
  } else {
    $$_[0]->($glob, $$_[1]) for @task;
    $glob;
  }
}

# For debugging aid.
sub cf_pairs {
  my PROP $prop = prop(my $glob = shift);
  my $fields = fields_hash($glob);
  map {
    [substr($_, 3) => $prop->{$_}]
  } grep {/^cf_/ && $_ ne 'cf_buffer'} keys %$fields;
}

#========================================

sub is_error {
  my PROP $prop = prop(my $glob = shift);
  $prop->{is_error};
}

sub as_error {
  my PROP $prop = prop(my $glob = shift);
  $prop->{is_error}++;
  if (my $buf = $prop->{cf_buffer}) {
    push @{$prop->{oldbuf}}, $$buf if $$buf ne '';
    $glob->rewind;
  }
  $glob->configure(@_) if @_;
  $glob;
}

sub error_with_status {
  my ($glob, $code) = splice @_, 0, 2;
  $glob->as_error->configure(status => $code)
    ->raise(error => incr_opt(depth => \@_), @_);
}

sub error {
  # XXX: as_error?
  shift->raise(error => incr_opt(depth => \@_), @_);
}

sub raise {
  my PROP $prop = prop(my $glob = shift);
  my ($type, @err) = @_; # To keep args visible in backtrace.
  $prop->{raised} = $type;
  if (my $yatt = $prop->{cf_yatt}) {
    $yatt->raise($type, incr_opt(depth => \@err), @err);
  } elsif (my $system = $prop->{cf_system}) {
    $system->raise($type, incr_opt(depth => \@err), @err);
  } else {
    shift @err if @err and ref $err[0] eq 'HASH'; # drop opts.
    my $fmt = shift @err;
    croak sprintf($fmt, @err);
  }
}

sub error_fh {
  my PROP $prop = prop(my $glob = shift);
  if (my Env $env = $prop->{cf_env}) {
    $env->{'psgi.errors'}
  } elsif (fileno(STDERR)) {
    \*STDERR;
  } else {
    undef;
  }
}

# Simple level-less but tagged and serialized logging.
sub logdump {
  my $self = shift;
  $self->logemit($_[0], terse_dump(@_[1..$#_]));
}

sub logbacktrace {
  my $self = shift;
  $self->logemit($_[0], terse_dump(@_[1..$#_]), Carp::longmess());
}

sub logemit {
  my PROP $prop = prop(my $glob = shift);
  my $fh = $prop->{cf_logfh} || $glob->error_fh;
  my $logger = $prop->{cf_logger};
  return unless $fh || $logger;
  my $tag = do {
    unless (defined $_[0]) {
      shift;
      'undef'
    } elsif (ref $_[0]) {
      unshift @_, terse_dump(shift @_);
      'debug';
    } elsif ($_[0] =~ /^[\w\.\-]+$/) {
      shift;
    } else {
      'debug';
    }
  };
  my $msg = join(" ", map {(my $cp = $_) =~ s/\n/\n /g; $cp} @_);
  if ($fh) {
    print $fh uc($tag).": [", $glob->iso8601_datetime(), " #$$] $msg\n";
  } else {
    my ($level, $type) = $tag =~ /^(\w+)(?:\.([\w\-\.]+))?$/;
    $logger->({level => $level || 'debug', message => $msg});
  }
}

# XXX: precise?
sub iso8601_datetime {
  my ($glob, $time) = @_;
  my ($S, $M, $H, $d, $m, $y) = localtime($time // time);
  $y += 1900; $m++;
  sprintf '%04d-%02d-%02dT%02d:%02d:%02d', ($y, $m, $d, $H, $M, $S);
}

# Alternative, for more rich logging.
sub logger {
  my PROP $prop = prop(my $glob = shift);
  $prop->{cf_logger};
}

#========================================

DESTROY {
  # Note: localizing $@ in DESTROY is not so good idea in general.
  # But I do this here because I found some module stamps $@ in mkheader.
  # Anyway, in usual case, $con lives along with entire request processing,
  # so this may not be a problem.
  local $@;

  my PROP $prop = prop(my $glob = shift);
  $glob->flush_headers
    unless $prop->{cf_no_auto_flush_headers};
  if (my $backend = delete $prop->{cf_backend}) {
    if ($prop->{cf_debug} and my $errfh = $glob->error_fh) {
      print $errfh "DEBUG: Connection->backend is detached($backend)\n";
    }
    # DBSchema->DESTROY should be called automatically. <- Have tests for this!
    #$backend->disconnect("Explicitly from Connection->DESTROY");
  }
  if ($prop->{cf_debug} and my $errfh = $glob->error_fh) {
    print $errfh "DEBUG: Connection->DESTROY (glob=$glob, prop=$prop)\n";
  }
  delete $prop->{$_} for keys %$prop;
  #undef *$glob;
}

sub header_was_sent {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{header_was_sent} = 1;
  my $parent = $prop->{cf_parent_fh};
  if ($parent and my $sub = $parent->can('header_was_sent')) {
    $sub->($parent);
  }
}

sub flush_headers {
  my PROP $prop = (my $glob = shift)->prop;

  return if $prop->{header_was_sent}++;

  my $was_error = $prop->{is_error};

  $glob->finalize_headers;

  if (not $prop->{cf_noheader}) {
    my $fh = $prop->{cf_parent_fh} // $glob;
    my $header = $glob->mkheader;
    if (not $was_error and my ($err) = $glob->error_list) {
      die "\n\nError during first call of flush_headers(): $err\n";
    } else {
      print $fh $header;
    }
  }
  $glob->flush;
}

sub finalize_headers {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_yatt}->finalize_connection($glob)   if $prop->{cf_yatt};
  $prop->{cf_system}->finalize_connection($glob) if $prop->{cf_system};
  $glob->finalize_cookies if $prop->{cookies_out};
}

sub flush {
  my PROP $prop = (my $glob = shift)->prop;
  $glob->IO::Handle::flush();
  if ($prop->{cf_parent_fh}) {
    print {$prop->{cf_parent_fh}} ${$prop->{cf_buffer}};
    ${$prop->{cf_buffer}} = '';
    $prop->{cf_parent_fh}->IO::Handle::flush();
    # XXX: flush 後は、 parent_fh の dup にするべき。
    # XXX: でも、 multipart (server push) とか continue とかは？
  }
}

sub rewind {
  my PROP $prop = (my $glob = shift)->prop;
  seek *$glob, 0, 0;
  ${$prop->{cf_buffer}} = '';
  $glob;
}

#========================================
# Cookie support, based on Cookie::Baker

sub cookies_in {
  my PROP $prop = (my $glob = shift)->prop;
  my Env $env = $prop->{cf_env};
  $prop->{cookies_in} ||= do {
    if (defined $env->{HTTP_COOKIE}) {
      YATT::Lite::Util::permissive_require('Cookie::Baker');
      Cookie::Baker::crush_cookie($env->{HTTP_COOKIE});
    } else {
      +{};
    }
  };
}

sub set_cookie {
  my PROP $prop = (my $glob = shift)->prop;
  if (@_ == 1 and ref $_[0]) {
    my $cookie = shift;
    if (ref $cookie eq 'HASH') {
      defined (my $name = $cookie->{name}) or do {
        Carp::croak "set_cookie: name is undef!";
      };
      $prop->{cookies_out}{$name} = $cookie;
    } else {
      my $name = $cookie->name;
      $prop->{cookies_out}{$name} = $cookie;
    }
  } else {
    my $name = shift;
    $prop->{cookies_out}{$name} = $glob->new_cookie($name, @_);
  }
}

sub new_cookie {
  my $glob = shift;		# not used.
  my ($name, $value, @opts) = @_;
  YATT::Lite::Util::permissive_require('Cookie::Baker');
  my $baked = {value => $value};
  while (my ($k, $v) = splice @opts, 0, 2) {
    $k =~ s/^-//; # For backward compatibility with CGI::Cookie style options.
    $baked->{$k} = $v;
  }
  Cookie::Baker::bake_cookie($name, $baked);
}

sub finalize_cookies {
  my PROP $prop = (my $glob = shift)->prop;
  return unless $prop->{cookies_out};
  $prop->{headers}{'Set-Cookie'} = [values %{$prop->{cookies_out}}];
}
#========================================

# XXX: Should be renamed to result, text, as_text, as_string or value;
sub buffer {
  my PROP $prop = prop(my $glob = shift);
  $glob->IO::Handle::flush();
  ${$prop->{cf_buffer}}
}

sub diag_list {
  my PROP $prop = prop(my $glob = shift);
  my $list = $prop->{diag_list}
    or return;
  wantarray ? @$list : $list;
}

sub add_diag {
  my PROP $prop = prop(my $glob = shift);
  push @{$prop->{diag_list}}, shift;
  $glob;
}

sub error_list {
  my PROP $prop = prop(my $glob = shift);
  my $list = $prop->{error_list}
    or return;
  wantarray ? @$list : $list;
}

sub add_error {
  my PROP $prop = prop(my $glob = shift);
  push @{$prop->{error_list}}, my $err = shift;
  $glob->add_diag($err->reason);
  $glob;
}

sub oldbuf {
  my PROP $prop = prop(my $glob = shift);
  my $oldbuf = $prop->{oldbuf}
    or return;
  wantarray ? @$oldbuf : $oldbuf;
}

sub mkheader {
  my PROP $prop = (my $glob = shift)->prop;
  my ($code) = shift // $prop->{cf_status} // 200;

  # For GH-200 (to avoid "Can't locate Clone.pm" from HTTP::Headers)
  YATT::Lite::Util::permissive_require('HTTP::Headers');

  my $headers = HTTP::Headers->new("Content-type", $glob->_mk_content_type
				   , map($_ ? %$_ : (), $prop->{headers})
				   , @_);
  YATT::Lite::Util::mk_http_status($code)
      . $headers->as_string . "\015\012";
}

sub _mk_content_type {
  my PROP $prop = (my $glob = shift)->prop;
  my $ct = $prop->{cf_content_type} || "text/html";
  if ($ct =~ m{^text/} && $ct !~ /;\s*charset/) {
    my $cs = $prop->{cf_charset} || "utf-8";
    $ct .= qq|; charset=$cs|;
  }
  $ct;
}

sub set_header {
  my PROP $prop = prop(my $glob = shift);
  my ($key, $value) = @_;
  $prop->{headers}{$key} = $value;
  $glob;
}

sub set_header_list {
  my PROP $prop = prop(my $glob = shift);
  while (my ($k, $v) = splice @_, 0, 2) {
      $prop->{headers}{$k} = $v;
  }
  $glob;
}

sub append_header {
  my PROP $prop = prop(my $glob = shift);
  my ($key, @values) = @_;
  push @{$prop->{headers}{$key}}, @values;
}

# For PSGI only.
sub list_header {
  my PROP $prop = prop(my $glob = shift);
  my $headers = $prop->{headers}
    or return;
  map {
    my $k = $_;
    map {$k => $_} lexpand($headers->{$k});
  } keys %$headers;
}

sub content_type {
  my PROP $prop = prop(my $glob = shift);
  $prop->{cf_content_type}
}
sub set_content_type {
  my PROP $prop = prop(my $glob = shift);
  $prop->{cf_content_type} = shift;
  $glob;
}

sub charset {
  my PROP $prop = prop(my $glob = shift);
  $prop->{cf_charset}
}
sub set_charset {
  my PROP $prop = prop(my $glob = shift);
  $prop->{cf_charset} = shift;
  $glob;
}

#========================================

sub configure_stash {
  my PROP $prop = prop(my $glob = shift);
  my ($value) = @_;
  $prop->{stash} = $value;
}

sub stash {
  my PROP $prop = prop(my $glob = shift);
  unless (@_) {
    $prop->{stash} //= {}
  } elsif (@_ == 1) {
    $prop->{stash}{$_[0]}
  } else {
    my $name = shift;
    $prop->{stash}{$name} = shift;
    $glob;
  }
}

#========================================

sub gettext {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_yatt}->lang_gettext($prop->{cf_lang}, @_);
}

sub ngettext {
  my PROP $prop = (my $glob = shift)->prop;
  $prop->{cf_yatt}->lang_ngettext($prop->{cf_lang}, @_);
}

#========================================

sub backend {
  my PROP $prop = (my $glob = shift)->prop;

  # XXX: Exposing bare backend may harm.
  #      But anyway, you can get backend via cget('backend').
  #
  return $prop->{cf_backend} unless @_;

  my $method = shift;
  unless (defined $method) {
    $glob->error("backend: null method is called");
  } elsif (not $prop->{cf_backend}) {
    $glob->error("backend is empty");
  } elsif (not my $sub = $prop->{cf_backend}->can($method)) {
    $glob->error("unknown method called for backend: %s", $method);
  } else {
    $sub->($prop->{cf_backend}, @_);
  }
}

{
  foreach (qw/model resultset
	      txn_do txn_begin txn_commit txn_rollback
	      txn_scope_guard
	     /) {
    my $method = $_;
    *{globref(__PACKAGE__, $method)} = sub {
      my PROP $prop = (my $glob = shift)->prop;
      $prop->{cf_backend}->$method(@_);
    };
  }
}

1;
