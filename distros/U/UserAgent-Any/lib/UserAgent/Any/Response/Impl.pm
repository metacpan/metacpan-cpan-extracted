package UserAgent::Any::Response::Impl;

use 5.036;

use Moo::Role;

use namespace::clean;

our $VERSION = 0.01;

has res => (
  is => 'ro',
  required => 1,
);

# This is used to compensate for some response implementation that don’t decode
# JSON content (as it’s not in the spec).
has _forced_charset => (
  is => 'ro',
  lazy => 1,
  default => sub ($self) {
    if ($self->header('Content-Type') =~ m{^ application/json \s* ; .* \s* charset=([^ ;]+) }xi)
    {
      return $1;
    } else {
      return;
    }
  },
);

requires qw(status_code status_text success content raw_content headers header);

1;
