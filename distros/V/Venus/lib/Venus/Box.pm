package Venus::Box;

use 5.018;

use strict;
use warnings;

use Venus::Class 'with';

with 'Venus::Role::Buildable';
with 'Venus::Role::Proxyable';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data,
  };
}

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  return {
    value => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  require Venus::Type;

  $data //= {};

  $self->{value} = Venus::Type->new(value => $data->{value})->deduce;

  return $self;
}

sub build_proxy {
  my ($self, $package, $method, @args) = @_;

  require Scalar::Util;

  my $value = $self->{value};

  if (not(Scalar::Util::blessed($value))) {
    require Venus::Error;
    return Venus::Error->throw(
      "$package can only operate on objects, not $value"
    );
  }
  if (!$value->can($method)) {
    if (my $handler = $self->can("__handle__${method}")) {
      return sub {$self->$handler(@args)};
    }
    elsif (!$value->can('AUTOLOAD')) {
      return undef;
    }
  }
  return sub {
    my $result = [
      $value->$method(@args)
    ];
    $result = $result->[0] if @$result == 1;
    if (Scalar::Util::blessed($result)) {
      return not(UNIVERSAL::isa($result, 'Venus::Box'))
        ? ref($self)->new(value => $result)
        : $result;
    }
    else {
      require Venus::Type;
      return ref($self)->new(
        value => Venus::Type->new(value => $result)->deduce
      );
    }
  };
}

# METHODS

sub __handle__unbox {
  my ($self, $code, @args) = @_;
  return $code ? $self->$code(@args)->{value} : $self->{value};
}

1;



=head1 NAME

Venus::Box - Box Class

=cut

=head1 ABSTRACT

Box Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Box;

  my $box = Venus::Box->new(
    value => {},
  );

  # $box->keys->count->unbox;

=cut

=head1 DESCRIPTION

This package provides a pure Perl boxing mechanism for wrapping objects and
values, and chaining method calls across all objects.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Proxyable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 unbox

  unbox(Str $method, Any @args) (Any)

The unbox method returns the un-boxed underlying object. This is a virtual
method that dispatches to C<__handle__unbox>. This method supports dispatching,
i.e. providing a method name and arguments whose return value will be acted on
by this method.

I<Since C<0.01>>

=over 4

=item unbox example 1

  # given: synopsis;

  my $unbox = $box->unbox;

  # bless({ value => {} }, "Venus::Hash")

=back

=over 4

=item unbox example 2

  # given: synopsis;

  my $unbox = $box->unbox('count');

  # 0

=back

=cut