package UserAgent::Any::Response::Impl;

use 5.036;

use Moo::Role;

use namespace::clean;

our $VERSION = 0.01;

has res => (
  is => 'ro',
  required => 1,
);

requires qw(status_code status_text success content raw_content headers header);

1;
