package Venus::Template;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';
with 'Venus::Role::Explainable';

use overload (
  '""' => 'explain',
  'eq' => sub{$_[0]->render eq "$_[1]"},
  'ne' => sub{$_[0]->render ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0]->render)]}/},
  '~~' => 'explain',
  fallback => 1,
);

# ATTRIBUTES

attr 'markers';
attr 'variables';

# BUILDERS

sub build_self {
  my ($self, $data) = @_;

  $self->markers([qr/\{\{/, qr/\}\}/]) if !defined $self->markers;
  $self->variables({}) if !defined $self->variables;

  return $self;
}

# METHODS

sub assertion {
  my ($self) = @_;

  my $assert = $self->SUPER::assertion;

  $assert->clear->expression('string');

  return $assert;
}

sub default {
  return '';
}

sub explain {
  my ($self) = @_;

  return $self->render;
}

sub mappable {
  my ($self, $data) = @_;

  require Scalar::Util;
  require Venus::Array;
  require Venus::Hash;

  if (!$data) {
    return Venus::Hash->new;
  }
  if (!Scalar::Util::blessed($data) && ref($data) eq 'ARRAY') {
    return Venus::Array->new($data);
  }
  if (!Scalar::Util::blessed($data) && ref($data) eq 'HASH') {
    return Venus::Hash->new($data);
  }
  if (!Scalar::Util::blessed($data) || (Scalar::Util::blessed($data)
      && !($data->isa('Venus::Array') || $data->isa('Venus::Hash'))))
  {
    return Venus::Hash->new;
  }
  else {
    return $data;
  }
}

sub render {
  my ($self, $content, $variables) = @_;

  if (!defined $content) {
    $content = $self->get;
  }

  if (!defined $variables) {
    $variables = $self->variables;
  }
  else {
    $variables = $self->mappable($self->variables)->merge(
      $self->mappable($variables)->get
    );
  }

  $content =~ s/^\r?\n//;
  $content =~ s/\r?\n\ *$//;

  $content = $self->render_blocks($content, $variables);

  $content = $self->render_tokens($content, $variables);

  return $content;
}

sub render_blocks {
  my ($self, $content, $variables) = @_;

  my ($stag, $etag) = @{$self->markers};

  my $path = qr/[a-z_][\w.]*/;

  my $regexp = qr{
    $stag
    \s*
    (FOR|IF|IF\sNOT)
    \s+
    ($path)
    \s*
    $etag
    (.+)
    $stag
    \s*
    (END)
    \s+
    \2
    \s*
    $etag
  }xis;

  $variables = $self->mappable($variables);

  $content =~ s{
    $regexp
  }{
    my ($type, $path, $body) = ($1, $2, $3);
    if (lc($type) eq 'if') {
      $self->render_if(
        $body, $variables, !!scalar($variables->path($path)), $path
      );
    }
    elsif (lc($type) eq 'if not') {
      $self->render_if_not(
        $body, $variables, !!scalar($variables->path($path)), $path
      );
    }
    elsif (lc($type) eq 'for') {
      $self->render_foreach(
        $body, $self->mappable($variables->path($path))
      );
    }
  }gsex;

  return $content;
}

sub render_if {
  my ($self, $context, $variables, $boolean, $path) = @_;

  my $mappable = $self->mappable($variables);

  my ($stag, $etag) = @{$self->markers};

  $path = quotemeta $path;

  my $regexp = qr{
    $stag
    \s*
    ELSE
    \s+
    $path
    \s*
    $etag
  }xis;

  my ($a, $b) = split /$regexp/, $context;

  if ($boolean) {
    return $self->render($a, $mappable);
  }
  else {
    if ($b) {
      return $self->render($b, $mappable);
    }
    else {
      return '';
    }
  }
}

sub render_if_not {
  my ($self, $context, $variables, $boolean, $path) = @_;

  my $mappable = $self->mappable($variables);

  my ($stag, $etag) = @{$self->markers};

  $path = quotemeta $path;

  my $regexp = qr{
    $stag
    \s*
    ELSE
    \s+
    $path
    \s*
    $etag
  }xis;

  my ($a, $b) = split /$regexp/, $context;

  if (!$boolean) {
    return $self->render($a, $mappable);
  }
  else {
    if ($b) {
      return $self->render($b, $mappable);
    }
    else {
      return '';
    }
  }
}

sub render_foreach {
  my ($self, $context, $mappable) = @_;

  $mappable = $self->mappable($mappable);

  if (!$mappable->isa('Venus::Array')) {
    return '';
  }

  my @results = $self->mappable($mappable)->each(sub {
    my (@args) = @_;
    $self->render($context, $self->mappable($args[1])->do(
      'set', 'loop', {index => $args[0], place => $args[0]+1},
    ));
  });

  return join "\n", grep !!$_, @results;
}

sub render_tokens {
  my ($self, $content, $variables) = @_;

  my ($stag, $etag) = @{$self->markers};

  my $path = qr/[a-z_][\w.]*/;

  my $regexp = qr{
    $stag
    \s*
    ($path)
    \s*
    $etag
  }xi;

  $variables = $self->mappable($variables);

  $content =~ s{
    $regexp
  }{
    scalar($variables->path($1)) // ''
  }gsex;

  return $content;
}

1;



=head1 NAME

Venus::Template - Template Class

=cut

=head1 ABSTRACT

Template Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(
    'From: <{{ email }}>',
  );

  # $template->render;

  # "From: <>"

=cut

=head1 DESCRIPTION

This package provides a templating system, and methods for rendering templates
using simple markup and minimal control structures. The default opening and
closing markers, denoting a template token, block, or control structure, are
C<{{> and C<}}>. A token takes the form of C<{{ foo }}> or C<{{ foo.bar }}>. A
block takes the form of C<{{ for foo.bar }}> where C<foo.bar> represents any
valid path, resolvable by L<Venus::Array/path> or L<Venus::Hash/path>, which
returns an arrayref or L<Venus::Array> object, and must be followed by
C<{{ end foo }}>. Control structures take the form of C<{{ if foo }}> or
C<{{ if not foo }}>, may contain a nested C<{{ else foo }}> control structure,
and must be followed by C<{{ end foo }}>. Leading and trailing whitespace is
automatically removed from all replacements.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 variables

  variables(HashRef)

This attribute is read-write, accepts C<(HashRef)> values, is optional, and defaults to C<{}>.

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

=head2 render

  render(Str $template, HashRef $variables) (Str)

The render method processes the template by replacing the tokens and control
structurs with the appropriate replacements and returns the result. B<Note:>
The rendering process expects variables to be hashrefs and sets (arrayrefs) of
hashrefs.

I<Since C<0.01>>

=over 4

=item render example 1

  # given: synopsis;

  my $result = $template->render;

  # "From: <>"

=back

=over 4

=item render example 2

  # given: synopsis;

  $template->value(
    'From: {{ if name }}{{ name }}{{ end name }} <{{ email }}>',
  );

  $template->variables({
    email => 'noreply@example.com',
  });

  my $result = $template->render;

  # "From:  <noreply@example.com>"

=back

=over 4

=item render example 3

  # given: synopsis;

  $template->value(
    'From: {{ if name }}{{ name }}{{ end name }} <{{ email }}>',
  );

  $template->variables({
    name => 'No-Reply',
    email => 'noreply@example.com',
  });

  my $result = $template->render;

  # "From: No-Reply <noreply@example.com>"

=back

=over 4

=item render example 4

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for chat.messages }}
    {{ user.name }}: {{ message }}
    {{ end chat.messages }}
  ));

  $template->variables({
    chat => { messages => [
      { user => { name => 'user1' }, message => 'ready?' },
      { user => { name => 'user2' }, message => 'ready!' },
      { user => { name => 'user1' }, message => 'lets begin!' },
    ]}
  });

  my $result = $template->render;

  # user1: ready?
  # user2: ready!
  # user1: lets begin!

=back

=over 4

=item render example 5

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for chat.messages }}
    {{ if user.legal }}
    {{ user.name }} [18+]: {{ message }}
    {{ else user.legal }}
    {{ user.name }} [-18]: {{ message }}
    {{ end user.legal }}
    {{ end chat.messages }}
  ));

  $template->variables({
    chat => { messages => [
      { user => { name => 'user1', legal => 1 }, message => 'ready?' },
      { user => { name => 'user2', legal => 0 }, message => 'ready!' },
      { user => { name => 'user1', legal => 1 }, message => 'lets begin!' },
    ]}
  });

  my $result = $template->render;

  # user1 [18+]: ready?
  # user2 [-18]: ready!
  # user1 [18+]: lets begin!

=back

=over 4

=item render example 6

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for chat.messages }}
    {{ if user.admin }}@{{ end user.admin }}{{ user.name }}: {{ message }}
    {{ end chat.messages }}
  ));

  $template->variables({
    chat => { messages => [
      { user => { name => 'user1', admin => 1 }, message => 'ready?' },
      { user => { name => 'user2', admin => 0 }, message => 'ready!' },
      { user => { name => 'user1', admin => 1 }, message => 'lets begin!' },
    ]}
  });

  my $result = $template->render;

  # @user1: ready?
  # user2: ready!
  # @user1: lets begin!

=back

=over 4

=item render example 7

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for chat.messages }}
    [{{ loop.place }}] {{ user.name }}: {{ message }}
    {{ end chat.messages }}
  ));

  $template->variables({
    chat => { messages => [
      { user => { name => 'user1' }, message => 'ready?' },
      { user => { name => 'user2' }, message => 'ready!' },
      { user => { name => 'user1' }, message => 'lets begin!' },
    ]}
  });

  my $result = $template->render;

  # [1] user1: ready?
  # [2] user2: ready!
  # [3] user1: lets begin!

=back

=over 4

=item render example 8

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for chat.messages }}
    [{{ loop.index }}] {{ user.name }}: {{ message }}
    {{ end chat.messages }}
  ));

  $template->variables({
    chat => { messages => [
      { user => { name => 'user1' }, message => 'ready?' },
      { user => { name => 'user2' }, message => 'ready!' },
      { user => { name => 'user1' }, message => 'lets begin!' },
    ]}
  });

  my $result = $template->render;

  # [0] user1: ready?
  # [1] user2: ready!
  # [2] user1: lets begin!

=back

=cut

=head1 OPERATORS

This package overloads the following operators:

=cut

=over 4

=item operation: C<("")>

This package overloads the C<""> operator.

B<example 1>

  # given: synopsis;

  my $result = "$template";

  # "From: <>"

B<example 2>

  # given: synopsis;

  my $result = "$template, $template";

  # "From: <>, From: <>"

=back

=over 4

=item operation: C<(~~)>

This package overloads the C<~~> operator.

B<example 1>

  # given: synopsis;

  my $result = $template ~~ 'From: <>';

  # 1

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut