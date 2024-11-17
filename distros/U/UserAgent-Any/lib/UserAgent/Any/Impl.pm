package UserAgent::Any::Impl;

use 5.036;

use Carp;
use Exporter 'import';
use List::Util 'pairs';
use Moo::Role;
use Readonly;
use UserAgent::Any::Impl::Helper;
use UserAgent::Any::Response;

use namespace::clean;

our $VERSION = 0.01;

has ua => (
  is => 'ro',
  required => 1,
);

requires map { ($_, $_.'_cb', $_.'_p') } @UserAgent::Any::Impl::Helper::METHODS;

1;
