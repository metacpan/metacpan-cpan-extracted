package Venus::Opts;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';
with 'Venus::Role::Proxyable';

# ATTRIBUTES

attr 'named';
attr 'parsed';
attr 'specs';
attr 'warns';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data,
  };
}

sub build_self {
  my ($self, $data) = @_;

  $self->named({}) if !$self->named;
  $self->parsed({}) if !$self->parsed;
  $self->specs([]) if !$self->specs;
  $self->warns([]) if !$self->warns;

  return $self->parse;
}

sub build_proxy {
  my ($self, $package, $method, $value) = @_;

  my $has_value = exists $_[3];

  return sub {
    return $self->get($method) if !$has_value; # no value
    return $self->set($method, $value);
  };
}

# METHODS

sub default {
  my ($self) = @_;

  return [@ARGV];
}

sub exists {
  my ($self, $name) = @_;

  return if not defined $name;

  my $pos = $self->name($name);

  return if not defined $pos;

  return CORE::exists $self->parsed->{$pos};
}

sub get {
  my ($self, $name) = @_;

  return if not defined $name;

  my $pos = $self->name($name);

  return if not defined $pos;

  return $self->parsed->{$pos};
}

sub parse {
  my ($self, $extras) = @_;

  return $self->parsed if %{$self->parsed};

  my $value = $self->value;
  my $specs = $self->specs;

  my $parsed = {};
  my @configs = qw(default no_auto_abbrev no_ignore_case);

  $extras = [] if !$extras;

  require Getopt::Long;

  my $warns = [];
  local $SIG{__WARN__} = sub {
    push @$warns, map s/\n+$//gr, @_;
    return;
  };

  # configure parser
  Getopt::Long::Configure(Getopt::Long::Configure(@configs, @$extras));

  # parse args using spec
  Getopt::Long::GetOptionsFromArray([@$value], $parsed, @$specs);

  $self->parsed($parsed);
  $self->warns($warns);

  return $self;
}

sub name {
  my ($self, $name) = @_;

  if (defined $self->named->{$name}) {
    return $self->named->{$name};
  }

  if (defined $self->parsed->{$name}) {
    return $name;
  }

  return undef;
}

sub set {
  my ($self, $name, $data) = @_;

  return if not defined $name;

  my $pos = $self->name($name);

  return if not defined $pos;

  return $self->parsed->{$pos} = $data;
}

sub unnamed {
  my ($self) = @_;

  my $list = [];

  my $opts = $self->parsed;
  my $data = +{reverse %{$self->named}};

  for my $index (sort keys %$opts) {
    unless (exists $data->{$index}) {
      push @$list, $opts->{$index};
    }
  }

  return $list;
}

1;



=head1 NAME

Venus::Opts - Opts Class

=cut

=head1 ABSTRACT

Opts Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Opts;

  my $opts = Venus::Opts->new(
    value => ['--resource', 'users', '--help'],
    specs => ['resource|r=s', 'help|h'],
    named => { method => 'resource' } # optional
  );

  # $opts->method; # $resource
  # $opts->get('resource'); # $resource

  # $opts->help; # $help
  # $opts->get('help'); # $help

=cut

=head1 DESCRIPTION

This package provides methods for handling command-line arguments.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 named

  named(HashRef)

This attribute is read-write, accepts C<(HashRef)> values, is optional, and defaults to C<{}>.

=cut

=head2 parsed

  parsed(HashRef)

This attribute is read-write, accepts C<(HashRef)> values, is optional, and defaults to C<{}>.

=cut

=head2 specs

  specs(ArrayRef)

This attribute is read-write, accepts C<(ArrayRef)> values, is optional, and defaults to C<[]>.

=cut

=head2 warns

  warns(ArrayRef)

This attribute is read-write, accepts C<(ArrayRef)> values, is optional, and defaults to C<[]>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

L<Venus::Role::Buildable>

L<Venus::Role::Proxyable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 default

  default() (ArrayRef)

The default method returns the default value, i.e. C<[@ARGV]>.

I<Since C<0.01>>

=over 4

=item default example 1

  # given: synopsis;

  my $default = $opts->default;

  # []

=back

=cut

=head2 exists

  exists(Str $key) (Bool)

The exists method takes a name or index and returns truthy if an associated
value exists.

I<Since C<0.01>>

=over 4

=item exists example 1

  # given: synopsis;

  my $exists = $opts->exists('resource');

  # 1

=back

=over 4

=item exists example 2

  # given: synopsis;

  my $exists = $opts->exists('method');

  # 1

=back

=over 4

=item exists example 3

  # given: synopsis;

  my $exists = $opts->exists('resources');

  # undef

=back

=cut

=head2 get

  get(Str $key) (Any)

The get method takes a name or index and returns the associated value.

I<Since C<0.01>>

=over 4

=item get example 1

  # given: synopsis;

  my $get = $opts->get('resource');

  # "users"

=back

=over 4

=item get example 2

  # given: synopsis;

  my $get = $opts->get('method');

  # "users"

=back

=over 4

=item get example 3

  # given: synopsis;

  my $get = $opts->get('resources');

  # undef

=back

=cut

=head2 name

  name(Str $key) (Str | Undef)

The name method takes a name or index and returns index if the the associated
value exists.

I<Since C<0.01>>

=over 4

=item name example 1

  # given: synopsis;

  my $name = $opts->name('resource');

  # "resource"

=back

=over 4

=item name example 2

  # given: synopsis;

  my $name = $opts->name('method');

  # "resource"

=back

=over 4

=item name example 3

  # given: synopsis;

  my $name = $opts->name('resources');

  # undef

=back

=cut

=head2 parse

  parse(ArrayRef $args) (Opts)

The parse method optionally takes additional L<Getopt::Long> parser
configuration options and retuns the options found based on the object C<args>
and C<spec> values.

I<Since C<0.01>>

=over 4

=item parse example 1

  # given: synopsis;

  my $parse = $opts->parse;

  # { help => 1, resource => "users" }

=back

=over 4

=item parse example 2

  # given: synopsis;

  my $parse = $opts->parse(['bundling']);

  # { help => 1, resource => "users" }

=back

=cut

=head2 set

  set(Str $key, Any $data) (Any)

The set method takes a name or index and sets the value provided if the
associated argument exists.

I<Since C<0.01>>

=over 4

=item set example 1

  # given: synopsis;

  my $set = $opts->set('method', 'people');

  # "people"

=back

=over 4

=item set example 2

  # given: synopsis;

  my $set = $opts->set('resource', 'people');

  # "people"

=back

=over 4

=item set example 3

  # given: synopsis;

  my $set = $opts->set('resources', 'people');

  # undef

=back

=cut

=head2 unnamed

  unnamed() (ArrayRef)

The unnamed method returns an arrayref of values which have not been named
using the C<named> attribute.

I<Since C<0.01>>

=over 4

=item unnamed example 1

  # given: synopsis;

  my $unnamed = $opts->unnamed;

  # [1]

=back

=cut