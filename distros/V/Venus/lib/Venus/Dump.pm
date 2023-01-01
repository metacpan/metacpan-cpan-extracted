package Venus::Dump;

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

  $self->encoder(sub {
    my ($data) = @_;
    require Data::Dumper;
    no warnings 'once';
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 0;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Deparse = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Useqq = 1;
    Data::Dumper->Dump([$data]) =~ s/^"|"$//gr;
  });

  $self->decoder(sub {
    my ($text) = @_;
    eval $text;
  });

  return $self;
}

# METHODS

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->clear->expression('hashref');

  return $assert;
}

sub decode {
  my ($self, $data) = @_;

  # double-traversing the data structure due to lack of boolean support
  return $self->set(FROM_BOOL($self->decoder->($data)));
}

sub encode {
  my ($self) = @_;

  # double-traversing the data structure due to lack of boolean support
  return $self->encoder->(TO_BOOL($self->get));
}

sub explain {
  my ($self) = @_;

  return $self->encode;
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

  return Venus::Boolean::TO_BOOL_TFO($value);
}

1;



=head1 NAME

Venus::Dump - Dump Class

=cut

=head1 ABSTRACT

Dump Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Dump;

  my $dump = Venus::Dump->new(
    value => { name => ['Ready', 'Robot'], version => 0.12, stable => !!1, }
  );

  # $dump->encode;

=cut

=head1 DESCRIPTION

This package provides methods for reading and writing dumped (i.e.
stringified) Perl data.

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

  decode(Str $text) (Any)

The decode method decodes the Perl string, sets the object value, and returns
the decoded value.

I<Since C<0.01>>

=over 4

=item decode example 1

  # given: synopsis;

  my $decode = $dump->decode('{codename=>["Ready","Robot"],stable=>!!1}');

  # { codename => ["Ready", "Robot"], stable => 1 }

=back

=cut

=head2 encode

  encode() (Str)

The encode method encodes the objects value as a Perl string and returns the
encoded string.

I<Since C<0.01>>

=over 4

=item encode example 1

  # given: synopsis;

  my $encode = $dump->encode;

  # '{name => ["Ready","Robot"], stable => !!1, version => "0.12"}'

=back

=cut