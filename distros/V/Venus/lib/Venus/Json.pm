package Venus::Json;

use 5.018;

use strict;
use warnings;

use overload (
  '""' => 'explain',
  '~~' => 'explain',
  fallback => 1,
);

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';
with 'Venus::Role::Explainable';

# ATTRIBUTES

attr 'decoder';
attr 'encoder';

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    value => $data
  };
}

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  return {
    value => $data
  };
}

sub build_nil {
  my ($self, $data) = @_;

  return {
    value => $data
  };
}

sub build_self {
  my ($self, $data) = @_;

  return $self->config;
}

# METHODS

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->clear->expression('hashref');

  return $assert;
}

sub config {
  my ($self, $package) = @_;

  $package ||= $self->package or do {
    my $throw;
    $throw = $self->throw;
    $throw->name('on.config');
    $throw->message('No suitable JSON package');
    $throw->error;
  };

  $package = $package->new
    ->canonical
    ->allow_nonref
    ->allow_unknown
    ->allow_blessed
    ->convert_blessed
    ->pretty;

  if ($package->can('escape_slash')) {
    $package->escape_slash;
  }

  # Cpanel::JSON::XS
  if ($package->isa('Cpanel::JSON::XS')) {
    $self->decoder(sub {
      my ($text) = @_;
      $package->decode($text);
    });
    $self->encoder(sub {
      my ($data) = @_;
      $package->encode($data);
    });
  }

  # JSON::XS
  if ($package->isa('JSON::XS')) {
    $self->decoder(sub {
      my ($text) = @_;
      $package->decode($text);
    });
    $self->encoder(sub {
      my ($data) = @_;
      $package->encode($data);
    });
  }

  # JSON::PP
  if ($package->isa('JSON::PP')) {
    $self->decoder(sub {
      my ($text) = @_;
      $package->decode($text);
    });
    $self->encoder(sub {
      my ($data) = @_;
      $package->encode($data);
    });
  }

  return $self;
}

sub decode {
  my ($self, $data) = @_;

  # double-traversing the data structure due to lack of serialization hooks
  return $self->set(FROM_BOOL($self->decoder->($data)));
}

sub encode {
  my ($self) = @_;

  # double-traversing the data structure due to lack of serialization hooks
  return $self->encoder->(TO_BOOL($self->get));
}

sub explain {
  my ($self) = @_;

  return $self->encode;
}

sub package {
  my ($self) = @_;

  state $engine;

  return $engine if defined $engine;

  my %packages = (
    'JSON::XS' => '3.0',
    'JSON::PP' => '2.27105',
    'Cpanel::JSON::XS' => '4.09',
  );
  for my $package (
    grep defined,
    $ENV{VENUS_JSON_PACKAGE},
    qw(Cpanel::JSON::XS JSON::XS JSON::PP)
  )
  {
    my $criteria = "require $package; $package->VERSION($packages{$package})";
    if (do {local $@; eval "$criteria"; $@}) {
      next;
    }
    else {
      $engine = $package;
      last;
    }
  }

  return $engine;
}

sub FROM_BOOL {
  my ($value) = @_;

  require Venus::Boolean;

  if (ref($value) eq 'HASH') {
    for my $key (keys %$value) {
      $value->{$key} = FROM_BOOL($value->{$key});
    }
    return $value;
  }

  if (ref($value) eq 'ARRAY') {
    for my $key (keys @$value) {
      $value->[$key] = FROM_BOOL($value->[$key]);
    }
    return $value;
  }

  return Venus::Boolean::TO_BOOL(Venus::Boolean::FROM_BOOL($value));
}

sub TO_BOOL {
  my ($value) = @_;

  require Venus::Boolean;

  if (ref($value) eq 'HASH') {
    $value = {
      %$value
    };
    for my $key (keys %$value) {
      $value->{$key} = TO_BOOL($value->{$key});
    }
    return $value;
  }

  if (ref($value) eq 'ARRAY') {
    $value = [
      @$value
    ];
    for my $key (keys @$value) {
      $value->[$key] = TO_BOOL($value->[$key]);
    }
    return $value;
  }

  return Venus::Boolean::TO_BOOL_JPO($value);
}

1;



=head1 NAME

Venus::Json - Json Class

=cut

=head1 ABSTRACT

Json Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Json;

  my $json = Venus::Json->new(
    value => { name => ['Ready', 'Robot'], version => 0.12, stable => !!1, }
  );

  # $json->encode;

=cut

=head1 DESCRIPTION

This package provides methods for reading and writing L<JSON|https://json.org>
data. B<Note:> This package requires that a suitable JSON library is installed,
currently either C<JSON::XS> C<3.0+>, C<JSON::PP> C<2.27105+>, or
C<Cpanel::JSON::XS> C<4.09+>. You can use the C<VENUS_JSON_PACKAGE> environment
variable to include or prioritize your preferred JSON library.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 decoder

  decoder(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, and is optional.

=cut

=head2 encoder

  encoder(CodeRef)

This attribute is read-write, accepts C<(CodeRef)> values, and is optional.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Accessible>

L<Venus::Role::Buildable>

L<Venus::Role::Explainable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 decode

  decode(Str $json) (Any)

The decode method decodes the JSON string, sets the object value, and returns
the decoded value.

I<Since C<0.01>>

=over 4

=item decode example 1

  # given: synopsis;

  my $decode = $json->decode('{"codename":["Ready","Robot"],"stable":true}');

  # { codename => ["Ready", "Robot"], stable => 1 }

=back

=cut

=head2 encode

  encode() (Str)

The encode method encodes the objects value as a JSON string and returns the
encoded string.

I<Since C<0.01>>

=over 4

=item encode example 1

  # given: synopsis;

  my $encode = $json->encode;

  # '{ "name": ["Ready", "Robot"], "stable": true, "version": 0.12 }'

=back

=cut