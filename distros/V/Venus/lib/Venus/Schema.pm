package Venus::Schema;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Encaseable';

# METHODS

sub rule {
  my ($self, $data) = @_;

  my $ruleset = $self->ruleset;

  push @{$ruleset}, $data if ref $data eq 'HASH';

  return $self;
}

sub rules {
  my ($self, @data) = @_;

  $self->rule($_) for @data;

  return $self;
}

sub ruleset {
  my ($self, $data) = @_;

  my $ruleset = $self->encased('ruleset');

  $ruleset = $self->recase('ruleset', ref $data eq 'ARRAY' ? $data : []) if !$ruleset;

  return $ruleset;
}

sub shorthand {
  my ($self, $data) = @_;

  my @pairs;

  if (ref $data eq 'ARRAY') {
    for (my $i = 0; $i < @{$data}; $i += 2) {
      push @pairs, [$data->[$i], $data->[$i + 1]];
    }
  }
  elsif (ref $data eq 'HASH') {
    while (my ($key, $value) = each %{$data}) {
      push @pairs, [$key, $value];
    }
  }
  else {
    return [];
  }

  my @ruleset;

  for my $pair (@pairs) {
    my ($key, $type) = @{$pair};

    my $presence = 'required';

    if ($key =~ s/!$//) {
      $presence = 'required';
    }
    elsif ($key =~ s/\?$//) {
      $presence = 'optional';
    }
    elsif ($key =~ s/\*$//) {
      $presence = 'present';
    }

    my $selector;

    if ($key =~ /\./) {
      $selector = [split /\./, $key];
    }
    else {
      $selector = $key;
    }

    push @ruleset, {
      selector => $selector,
      presence => $presence,
      execute => $type,
    };
  }

  return \@ruleset;
}

sub validate {
  my ($self, $data) = @_;

  require Venus::Validate;

  my $validate = Venus::Validate->new(input => $data);

  my $errors = $validate->errors([]);

  my $ruleset = $self->ruleset;

  for my $rule (@{$ruleset}) {
    my $selector = $rule->{selector};
    my $presence = $rule->{presence} || 'optional';
    my $executes = $rule->{executes} || (
      $rule->{execute} ? [$rule->{execute}] : undef
    );

    next if $presence ne 'optional' && $presence ne 'present' && $presence ne 'required';

    my @nodes;

    if (defined $selector) {
      if (ref $selector eq 'ARRAY') {
        @nodes = ($validate);
        for my $i (0..$#{$selector}) {
          my $path = $selector->[$i];
          my $method = ($i == $#{$selector}) ? $presence : 'optional';
          @nodes = map +($_->each($method, $path)), @nodes;
        }
      }
      else {
        @nodes = ($validate->$presence($selector));
      }
    }
    else {
      @nodes = ($validate->$presence);
    }

    for my $node (@nodes) {
      for my $execute (@{$executes || []}) {
        my ($method, @args) = ref $execute eq 'ARRAY' ? @{$execute} : ($execute);

        $node->$method(@args);
      }
      $validate->sync($node);
    }
  }

  my $value = $validate->value;

  return wantarray ? ($errors, $value) : $errors;
}

1;



=head1 NAME

Venus::Schema - Schema Class

=cut

=head1 ABSTRACT

Schema Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  # bless({...}, 'Venus::Schema')

  # $schema->validate;

  # ([], undef)

=cut

=head1 DESCRIPTION

This package provides a mechanism for validating complex data structures using
data validation rules provided as a ruleset.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Encaseable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 new

  new(any @args) (Venus::Schema)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Schema;

  my $new = Venus::Schema->new;

  # bless(..., "Venus::Schema")

=back

=cut

=head2 rule

  rule(hashref $rule) (Venus::Schema)

The rule method appends a new rule to the L</ruleset> to be used during
L</validate>, and returns the invocant. A "rule" is a hashref that consists of
an optional C<selector> key whose value will be provided to the
L<Venus::Validate/select> method, a C<presence> key whose value must be one of
the "required", "optional", or "present" L<Venus::Validate> methods, and a
C<executes> key whose value must be an arrayref where each element is a
L<Venus::Validate> validation method name or an arrayref with a method name and
arguments.

I<Since C<4.15>>

=over 4

=item rule example 1

  # given: synopsis

  package main;

  my $rule = $schema->rule;

  # bless({...}, 'Venus::Schema')

=back

=over 4

=item rule example 2

  # given: synopsis

  package main;

  my $rule = $schema->rule({
    presence => 'required',
    executes => ['string'],
  });

  # bless({...}, 'Venus::Schema')

=back

=over 4

=item rule example 3

  # given: synopsis

  package main;

  my $rule = $schema->rule({
    selector => 'name',
    presence => 'required',
    executes => ['string'],
  });

  # bless({...}, 'Venus::Schema')

=back

=over 4

=item rule example 4

  # given: synopsis

  package main;

  my $rule = $schema->rule({
    selector => 'name',
    presence => 'required',
    executes => [['type', 'string']],
  });

  # bless({...}, 'Venus::Schema')

=back

=cut

=head2 rules

  rules(hashref @rules) (Venus::Schema)

The rules method appends new rules to the L</ruleset> using the L</rule> method
and returns the invocant.

I<Since C<4.15>>

=over 4

=item rules example 1

  # given: synopsis

  package main;

  my $rules = $schema->rules;

  # bless(..., "Venus::Schema")

=back

=over 4

=item rules example 2

  # given: synopsis

  package main;

  my $rules = $schema->rules({
    presence => 'required',
    executes => ['string'],
  });

  # bless(..., "Venus::Schema")

=back

=over 4

=item rules example 3

  # given: synopsis

  package main;

  my $rules = $schema->rules(
    {
      selector => 'first_name',
      presence => 'required',
      executes => ['string'],
    },
    {
      selector => 'last_name',
      presence => 'required',
      executes => ['string'],
    }
  );

  # bless(..., "Venus::Schema")

=back

=cut

=head2 ruleset

  ruleset(arrayref $ruleset) (arrayref)

The ruleset method gets and sets the L<"rules"|/rule> to be used during
L<"validation"|/validate>.

I<Since C<4.15>>

=over 4

=item ruleset example 1

  # given: synopsis

  package main;

  my $ruleset = $schema->ruleset;

  # []

=back

=over 4

=item ruleset example 2

  # given: synopsis

  package main;

  my $ruleset = $schema->ruleset([
    {
      selector => 'first_name',
      presence => 'required',
      executes => ['string'],
    },
    {
      selector => 'last_name',
      presence => 'required',
      executes => ['string'],
    }
  ]);

  # [
  #   {
  #     selector => 'first_name',
  #     presence => 'required',
  #     executes => ['string'],
  #   },
  #   {
  #     selector => 'last_name',
  #     presence => 'required',
  #     executes => ['string'],
  #   }
  # ]

=back

=cut

=head2 shorthand

  shorthand(arrayref | hashref $data) (arrayref)

The shorthand method accepts an arrayref or hashref of shorthand notation and
returns a ruleset arrayref. This provides a concise way to define validation
rules. Keys can have suffixes to indicate presence: C<!> for (explicit)
required, C<?> (explicit) for optional, C<*> for (explicit) present (i.e., must
exist but can be null), and no suffix means (implicit) required. Keys using dot
notation (e.g., C<website.url>) result in arrayref selectors for nested path
validation.

I<Since C<4.15>>

=over 4

=item shorthand example 1

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
  ]);

  # [
  #   {
  #     selector => 'fname',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  #   {
  #     selector => 'lname',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  # ]

=back

=over 4

=item shorthand example 2

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'email?' => 'string',
    'age*' => 'number',
  ]);

  # [
  #   {
  #     selector => 'email',
  #     presence => 'optional',
  #     execute => 'string',
  #   },
  #   {
  #     selector => 'age',
  #     presence => 'present',
  #     execute => 'number',
  #   },
  # ]

=back

=over 4

=item shorthand example 3

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'login' => 'string',
    'password' => 'string',
  ]);

  # [
  #   {
  #     selector => 'login',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  #   {
  #     selector => 'password',
  #     presence => 'required',
  #     execute => 'string',
  #   },
  # ]

=back

=over 4

=item shorthand example 4

  # given: synopsis

  package main;

  my $shorthand = $schema->shorthand([
    'website.url' => 'string',
    'profile.bio.text' => 'string',
  ]);

  # [
  #   {
  #     selector => ['website', 'url'],
  #     presence => 'required',
  #     execute => 'string',
  #   },
  #   {
  #     selector => ['profile', 'bio', 'text'],
  #     presence => 'required',
  #     execute => 'string',
  #   },
  # ]

=back

=over 4

=item shorthand example 5

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $ruleset = $schema->shorthand([
    'fname!' => 'string',
    'lname!' => 'string',
    'email?' => 'string',
    'login' => 'string',
  ]);

  $schema->rules(@{$ruleset});

  my $input = {
    fname => 'Elliot',
    lname => 'Alderson',
    login => 'mrrobot',
  };

  my $errors = $schema->validate($input);

  # []

=back

=cut

=head2 validate

  validate(any $data) (arrayref)

The validate method validates the data provided using the L</ruleset> and
returns an arrayref containing the errors encountered, if any. Returns the
errors arrayref, and the data validated in list context.

I<Since C<4.15>>

=over 4

=item validate example 1

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $errors = $schema->validate;

  # []

=back

=over 4

=item validate example 2

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  $schema->rule({
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  });

  my $errors = $schema->validate;

  # [['handles', ['required', []]]]

=back

=over 4

=item validate example 3

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $input = {
    fname => 'Elliot',
    lname => 'Alderson',
    handles => [
      {name => 'mrrobot'},
      {name => 'fsociety'},
    ],
    level => 5,
    skills => undef,
    role => 'Engineer',
  };

  $schema->rule({
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'skills',
    presence => 'present',
  });

  $schema->rule({
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  });

  $schema->rule({
    selector => ['handles', 'name'],
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  my $errors = $schema->validate($input);

  # []

=back

=over 4

=item validate example 4

  package main;

  use Venus::Schema;

  my $schema = Venus::Schema->new;

  my $input = {
    fname => 'Elliot',
    lname => 'Alderson',
    handles => [
      {name => 'mrrobot'},
      {name => 'fsociety'},
    ],
    level => 5,
    skills => undef,
    role => 'Engineer',
  };

  $schema->rule({
    selector => 'fname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'lname',
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  $schema->rule({
    selector => 'skills',
    presence => 'required',
  });

  $schema->rule({
    selector => 'handles',
    presence => 'required',
    executes => [['type', 'arrayref']],
  });

  $schema->rule({
    selector => ['handles', 'name'],
    presence => 'required',
    executes => ['string', 'trim', 'strip'],
  });

  my $errors = $schema->validate($input);

  # [['skills', ['required', []]]]

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut