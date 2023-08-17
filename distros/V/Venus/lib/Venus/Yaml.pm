package Venus::Yaml;

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

  $package ||= $self->package
    or $self->error({throw => 'error_on_config'});

  # YAML::XS
  if ($package eq 'YAML::XS') {
    $self->decoder(sub {
      my ($text) = @_;
      local $YAML::XS::Boolean = 'JSON::PP';
      YAML::XS::Load($text);
    });
    $self->encoder(sub {
      my ($data) = @_;
      local $YAML::XS::Boolean = 'JSON::PP';
      YAML::XS::Dump($data);
    });
  }

  # YAML::PP::LibYAML
  if ($package eq 'YAML::PP::LibYAML') {
    $self->decoder(sub {
      my ($text) = @_;
      YAML::PP->new(boolean => 'JSON::PP')->load_string($text);
    });
    $self->encoder(sub {
      my ($data) = @_;
      YAML::PP->new(boolean => 'JSON::PP')->dump_string($data);
    });
  }

  # YAML::PP
  if ($package eq 'YAML::PP') {
    $self->decoder(sub {
      my ($text) = @_;
      YAML::PP->new(boolean => 'JSON::PP')->load_string($text);
    });
    $self->encoder(sub {
      my ($data) = @_;
      YAML::PP->new(boolean => 'JSON::PP')->dump_string($data);
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
    'YAML::XS' => '0.67',
    'YAML::PP::LibYAML' => '0.004',
    'YAML::PP' => '0.023',
  );
  for my $package (
    grep defined,
    $ENV{VENUS_YAML_PACKAGE},
    qw(YAML::XS YAML::PP::LibYAML YAML::PP)
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

# ERRORS

sub error_on_config {
  my ($self) = @_;

  return {
    name => 'on.config',
    message => 'No suitable YAML package',
    raise => true,
  };
}

1;



=head1 NAME

Venus::Yaml - Yaml Class

=cut

=head1 ABSTRACT

Yaml Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Yaml;

  my $yaml = Venus::Yaml->new(
    value => { name => ['Ready', 'Robot'], version => 0.12, stable => !!1, }
  );

  # $yaml->encode;

=cut

=head1 DESCRIPTION

This package provides methods for reading and writing L<YAML|https://yaml.org>
data. B<Note:> This package requires that a suitable YAML library is installed,
currently either C<YAML::XS> C<0.67+>, C<YAML::PP::LibYAML> C<0.004+>, or
C<YAML::PP> C<0.23+>. You can use the C<VENUS_YAML_PACKAGE> environment
variable to include or prioritize your preferred YAML library.

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

  decode(Str $yaml) (Any)

The decode method decodes the YAML string, sets the object value, and returns
the decoded value.

I<Since C<0.01>>

=over 4

=item decode example 1

  # given: synopsis;

  my $decode = $yaml->decode("codename: ['Ready','Robot']\nstable: true");

  # { codename => ["Ready", "Robot"], stable => 1 }

=back

=cut

=head2 encode

  encode() (Str)

The encode method encodes the objects value as a YAML string and returns the
encoded string.

I<Since C<0.01>>

=over 4

=item encode example 1

  # given: synopsis;

  my $encode = $yaml->encode;

  # "---\nname:\n- Ready\n- Robot\nstable: true\nversion: 0.12\n"

=back

=cut

=head1 ERRORS

This package may raise the following errors:

=cut

=over 4

=item error: C<error_on_config>

This package may raise an error_on_config exception.

B<example 1>

  # given: synopsis;

  my $input = {
    throw => 'error_on_config',
  };

  my $error = $yaml->catch('error', $input);

  # my $name = $error->name;

  # "on_config"

  # my $message = $error->message;

  # "No suitable YAML package"

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut