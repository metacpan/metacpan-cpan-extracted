package exampleHello;

use base qw/Exporter/;
use strict;

our @EXPORT_OK = qw/hello_name hello_where/;

sub hello_name {my %arg = @_; "hello, " . ($arg{name} || '')}
sub hello_where {
  my ($at, $in) = @_;
  return @_ > 1 ? "hello, $at in $in" : "hello, $at";
}

sub hey {
  my ($at, $in) = @_;
  unless ($at) {
    return "hey, $in";
  } else {
    return "hey, $at in $in";
  }
}

1;
