package Web::Dispatch::Node;

use Moo;

with 'Web::Dispatch::ToApp';

for (qw(match run)) {
  has "_${_}" => (is => 'ro', required => 1, init_arg => $_);
}

sub call {
  my ($self, $env) = @_;
  if (my ($env_delta, @match) = $self->_match->($env)) {
    ($env_delta, $self->_curry(@match));
  } else {
    ()
  }
}

sub _curry {
  my ($self, @args) = @_;
  my $run = $self->_run;
  my $code = sub { $run->(@args, $_[0]) };
  # if the first argument is a hashref, localize %_ to it to permit
  # use of $_{name} inside the dispatch sub
  ref($args[0]) eq 'HASH'
    ? do { my $v = $args[0]; sub { local *_ = $v; &$code } }
    : $code
}

1;
