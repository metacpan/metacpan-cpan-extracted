package Web::Dispatch;

use Sub::Quote;
use Scalar::Util qw(blessed);

sub MAGIC_MIDDLEWARE_KEY { __PACKAGE__.'.middleware' }

use Moo;
use Web::Dispatch::Parser;
use Web::Dispatch::Node;

with 'Web::Dispatch::ToApp';

has dispatch_app => (
  is => 'lazy', builder => sub { shift->dispatch_object->to_app }
);
has dispatch_object => (is => 'ro', required => 0, weak_ref => 1);
has parser_class => (
  is => 'ro', default => quote_sub q{ 'Web::Dispatch::Parser' }
);
has node_class => (
  is => 'ro', default => quote_sub q{ 'Web::Dispatch::Node' }
);
has _parser => (is => 'lazy');

after BUILDARGS => sub {
  my ( $self, %args ) = @_;
  die "Either dispatch_app or dispatch_object need to be supplied."
    if !$args{dispatch_app} and !$args{dispatch_object}
};

sub _build__parser {
  my ($self) = @_;
  $self->parser_class->new;
}

sub call {
  my ($self, $env) = @_;
  my $res = $self->_dispatch($env, $self->dispatch_app);
  return $res->[0] if ref($res) eq 'ARRAY' and @{$res} == 1 and ref($res->[0]) eq 'CODE';
  return $res;
}

sub _dispatch {
  my ($self, $env, @match) = @_;
  while (defined(my $try = shift @match)) {

    return $try if ref($try) eq 'ARRAY';
    if (ref($try) eq 'HASH') {
      $env = { 'Web::Dispatch.original_env' => $env, %$env, %$try };
      next;
    }

    my @result = $self->_to_try($try, \@match)->($env, @match);
    next unless @result and defined($result[0]);

    my $first = $result[0];

    if (my $res = $self->_have_result($first, \@result, \@match, $env)) {

      return $res;
    }

    # make a copy so we don't screw with it assigning further up
    my $env = $env;
    unshift @match, sub { $self->_dispatch($env, @result) };
  }

  return;
}

sub _have_result {
  my ($self, $first, $result, $match, $env) = @_;

  if (ref($first) eq 'ARRAY') {
    return $first;
  }
  elsif (blessed($first) && $first->isa('Plack::Middleware')) {
    return $self->_uplevel_middleware($first, $result);
  }
  elsif (ref($first) eq 'HASH' and $first->{+MAGIC_MIDDLEWARE_KEY}) {
    return $self->_redispatch_with_middleware($first, $match, $env);
  }
  elsif (
    blessed($first) &&
    not($first->can('to_app')) &&
    not($first->isa('Web::Dispatch::Matcher'))
  ) {
    return $first;
  }
  return;
}

sub _uplevel_middleware {
  my ($self, $match, $results) = @_;
  die "Multiple results but first one is a middleware ($match)"
    if @{$results} > 1;
  # middleware needs to uplevel exactly once to wrap the rest of the
  # level it was created for - next elsif unwraps it
  return { MAGIC_MIDDLEWARE_KEY, $match };
}

sub _redispatch_with_middleware {
  my ($self, $first, $match, $env) = @_;

  my $mw = $first->{+MAGIC_MIDDLEWARE_KEY};

  $mw->app(sub { $self->_dispatch($_[0], @{$match}) });

  return $mw->to_app->($env);
}

sub _to_try {
  my ($self, $try, $more) = @_;

  # sub (<spec>) {}      becomes a dispatcher
  # sub {}               is a PSGI app and can be returned as is
  # '<spec>' => sub {}   becomes a dispatcher
  # $obj isa WD:Predicates::Matcher => sub { ... } -  become a dispatcher
  # $obj w/to_app method is a Plack::App-like thing - call it to get a PSGI app
  #

  if (ref($try) eq 'CODE') {
    if (defined(my $proto = prototype($try))) {
      $self->_construct_node(match => $proto, run => $try);
    } else {
      $try
    }
  } elsif (!ref($try)
    and (ref($more->[0]) eq 'CODE'
      or ($more->[0] and !ref($more->[0]) and $self->dispatch_object
        and $self->dispatch_object->can($more->[0])))
  ) {
    $self->_construct_node(match => $try, run => shift(@$more));
  } elsif (
    (blessed($try) && $try->isa('Web::Dispatch::Matcher'))
    and (ref($more->[0]) eq 'CODE')
  ) {
    $self->_construct_node(match => $try, run => shift(@$more));
  } elsif (blessed($try) && $try->can('to_app')) {
    $try->to_app;
  } else {
    die "No idea how we got here with $try";
  }
}

sub _construct_node {
  my ($self, %args) = @_;
  $args{match} = $self->_parser->parse($args{match}) if !ref $args{match};
  if ( my $obj = $self->dispatch_object) {
    # if possible, call dispatchers as methods of the app object
    my $dispatch_sub = $args{run};
    $args{run} = sub { $obj->$dispatch_sub(@_) };
  }
  $self->node_class->new(\%args)->to_app;
}

1;
