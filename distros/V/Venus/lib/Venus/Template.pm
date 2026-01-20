package Venus::Template;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'attr', 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Valuable';
with 'Venus::Role::Buildable';
with 'Venus::Role::Accessible';
with 'Venus::Role::Explainable';

# STATE

state $TOKEN_PATH_NOTATION = qr/[a-z_][\w.]*/;
state $TOKEN_TAG_OPEN = qr/\{\{/;
state $TOKEN_TAG_CLOSE = qr/\}\}/;

# OVERLOADS

use overload (
  '""' => 'explain',
  'eq' => sub{$_[0]->render eq "$_[1]"},
  'ne' => sub{$_[0]->render ne "$_[1]"},
  'qr' => sub{qr/@{[quotemeta($_[0]->render)]}/},
  '~~' => 'explain',
  fallback => 1,
);

# ATTRIBUTES

attr 'context';

# BUILDERS

sub build_data {
  my ($self, $data, $args) = @_;

  $data->{context} = $data->{context} ? ({%{$data->{context}}, %{$args}}) : $args;

  $data->{value} ||= '';

  return $data;
}

# METHODS

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
  my ($self, $content, $context, $parent_loops) = @_;

  if (!defined $content) {
    $content = $self->get;
  }

  if (!defined $context) {
    $context = $self->context;
  }
  else {
    $context = $self->mappable($self->context)->merge(
      $self->mappable($context)->get
    );
  }

  $content =~ s/^\r?\n//;
  $content =~ s/\r?\n\ *$//;

  $parent_loops ||= [];

  $content = $self->render_blocks($content, $context, $parent_loops);

  $content = $self->render_tokens($content, $context);

  return $content;
}

sub render_blocks {
  my ($self, $content, $context, $parent_loops) = @_;

  my $token_tag_open = $TOKEN_TAG_OPEN;

  my $token_tag_close = $TOKEN_TAG_CLOSE;

  my $path = $TOKEN_PATH_NOTATION;

  my $regexp = qr{
    (?<!\\)
    (?<!\\\{)
    $token_tag_open
    \s*
    (FOR|IF|IF\sNOT)
    \s+
    ($path)
    \s*
    $token_tag_close
    (?!\})
    (.+?)
    (?<!\\)
    (?<!\\\{)
    $token_tag_open
    \s*
    (END)
    \s+
    \2
    \s*
    $token_tag_close
    (?!\})
  }xis;

  $parent_loops ||= [];

  $context = $self->mappable($context);

  $content =~ s{
    $regexp
  }{
    my ($type, $path, $block) = ($1, $2, $3);
    if (lc($type) eq 'if') {
      $self->render_if(
        $block, $context, !!scalar($context->path($path)), $path, $parent_loops,
      );
    }
    elsif (lc($type) eq 'if not') {
      $self->render_if_not(
        $block, $context, !!scalar($context->path($path)), $path, $parent_loops,
      );
    }
    elsif (lc($type) eq 'for') {
      $self->render_foreach(
        $block, $self->mappable($context->path($path)), $parent_loops,
      );
    }
  }gsex;

  $content =~ s/\\(\{\{|\}\})/$1/g;

  return $content;
}

sub render_if {
  my ($self, $content, $context, $boolean, $path, $parent_loops) = @_;

  my $mappable = $self->mappable($context);

  my $token_tag_open = $TOKEN_TAG_OPEN;

  my $token_tag_close = $TOKEN_TAG_CLOSE;

  $path = quotemeta $path;

  my $regexp = qr{
    $token_tag_open
    \s*
    ELSE
    \s+
    $path
    \s*
    $token_tag_close
  }xis;

  $parent_loops ||= [];

  my ($a, $b) = split /$regexp/, $content;

  if ($boolean) {
    return $self->render($a, $mappable, $parent_loops);
  }
  else {
    if ($b) {
      return $self->render($b, $mappable, $parent_loops);
    }
    else {
      return '';
    }
  }
}

sub render_if_not {
  my ($self, $content, $context, $boolean, $path, $parent_loops) = @_;

  my $mappable = $self->mappable($context);

  my $token_tag_open = $TOKEN_TAG_OPEN;

  my $token_tag_close = $TOKEN_TAG_CLOSE;

  $path = quotemeta $path;

  my $regexp = qr{
    $token_tag_open
    \s*
    ELSE
    \s+
    $path
    \s*
    $token_tag_close
  }xis;

  $parent_loops ||= [];

  my ($a, $b) = split /$regexp/, $content;

  if (!$boolean) {
    return $self->render($a, $mappable, $parent_loops);
  }
  else {
    if ($b) {
      return $self->render($b, $mappable, $parent_loops);
    }
    else {
      return '';
    }
  }
}

sub render_foreach {
  my ($self, $content, $context, $parent_loops) = @_;

  $context = $self->mappable($context);

  if (!$context->isa('Venus::Array')) {
    return '';
  }

  $parent_loops ||= [];

  my @results = $self->mappable($context)->each(sub {
    my (@args) = @_;

    my $value = $args[1];

    my $loop = {
      index => $args[0],
      item => $value,
      level => {},
      parent => $parent_loops->[0],
      place => $args[0]+1,
    };

    my $iteration_parent_loops = [$loop, @{$parent_loops}];

    $loop->{level}->{$_} = $iteration_parent_loops->[$_]
      for map {$#{$iteration_parent_loops} - $_} 0..$#{$iteration_parent_loops};

    $value = ref($value) ? $value : {};

    $self->render($content, $self->mappable($value)->do('set', 'loop', $loop), $iteration_parent_loops);
  });

  return join "\n", grep !!$_, @results;
}

sub render_tokens {
  my ($self, $content, $context) = @_;

  my $token_tag_open = $TOKEN_TAG_OPEN;

  my $token_tag_close = $TOKEN_TAG_CLOSE;

  my $path = $TOKEN_PATH_NOTATION;

  my $regexp = qr{
    (?<!\\)
    (?<!\\\{)
    $token_tag_open
    \s*
    ($path)
    \s*
    $token_tag_close
    (?!\})
  }xi;

  $context = $self->mappable($context);

  $content =~ s{
    $regexp
  }{
    scalar($context->path($1)) // ''
  }gsex;

  $content =~ s/\\(\{\{|\}\})/$1/g;

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

This package provides a simple yet powerful templating system for Perl 5 that
supports variable interpolation, loops, and conditional blocks. The templating
system is designed to only operate on raw Perl data and as such does not
support operators, filters, virtual method, etc.

=head2 Syntax

=head3 Tags

The opening and closing tags are C<{{> and C<}}>. Content between these tags
can be:

=over 4

=item *

Simple path access (e.g., C<{{ name }}>)

=item *

Nested path access (e.g., C<{{ user.email }}>)

=item *

Control structures (described below)

=back

To include literal tags in your template, escape them using either:

=over 4

=item *

Single backslash: C<\{{> and C<\}}>

=item *

Escaped braces: C<\{\{> and C<\}\}>

=back

=head3 Tokens

Variable substitution uses dot notation to access nested data:

  # access hash key 'name' in hash 'user'
  {{ user.name }}

  # access hash key 'name' in first element of array 'users'
  {{ users.0.name }}

  # access deeply nested hash keys
  {{ profile.address.zip }}

=head3 Loops

Loops iterate over arrays using the C<for> control structure:

  {{ for users }}
    Name: {{ user.name }}
  {{ end users }}

Special loop variables are available within C<for> blocks:

=over 4

=item *

C<{{ loop.index }}> - Zero-based iteration counter

=item *

C<{{ loop.place }}> - One-based iteration counter

=item *

C<{{ loop.item }}> - Current item value (useful for arrays of simple values)

=back

For nested loops, parent loop information is accessible via:


=over 4

=item *

C<{{ loop.parent }}> - Immediate parent loop's data

=item *

C<{{ loop.level.0 }}> - First loop

=item *

C<{{ loop.level.1 }}> - Second loop

=item *

C<{{ loop.level.2 }}> - Third loop

=back

=head3 Controls

Conditional blocks use C<if>, C<if not>, and optional C<else>:

  {{ if user.admin }}
    Admin: {{ user.name }}
  {{ else user.admin }}
    User: {{ user.name }}
  {{ end user.admin }}

  {{ if not user.active }}
    Account inactive
  {{ end user.active }}

=head2 Structure

The template engine expects variables to be provided as hashrefs. Arrays should
be provided as arrayrefs. When iterating over arrays:

=over 4

=item *

Arrays of hashrefs: Access hash keys via C<{{ user.name }}>

=item *

Arrays of simple values: Access values via C<{{ loop.item }}>

=back

Example data structure:

  {
    user => {
      name => 'Alice',
      admin => 1,
      profile => {
        email => 'alice@example.com'
      }
    },
    items => [
      'a', 'b', 'c'
    ],
    users => [
      {
        name => 'Bob',
        role => 'user'
      },
      {
        name => 'Carol',
        role => 'admin'
      }
    ]
  }

=head2 Context

The template engine expects variables to be provided via the L</context>
attribute, or as an argument to the L</render> method after the template.

Setting context during object construction:

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(context => {email => 'alice@example.com'});

  $template->render('From: <{{ email }}>');

Setting context during template rendering:

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(value => 'From: <{{ email }}>');

  $template->render(undef, {email => 'alice@example.com'});

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 context

  context(hashref $context) (hashref)

The context attribute is read-write, accepts C<(hashref)> values, and is
optional.

I<Since C<4.15>>

=over 4

=item context example 1

  # given: synopsis

  package main;

  my $set_context = $template->context({});

  # {}

=back

=over 4

=item context example 2

  # given: synopsis

  # given: example-1 context

  package main;

  my $get_context = $template->context;

  # {}

=back

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

=head2 new

  new(any @args) (Venus::Template)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Template;

  my $new = Venus::Template->new;

  # bless(..., "Venus::Template")

=back

=over 4

=item new example 2

  package main;

  use Venus::Template;

  my $new = Venus::Template->new('hello world');

  # bless(..., "Venus::Template")

=back

=over 4

=item new example 3

  package main;

  use Venus::Template;

  my $new = Venus::Template->new(value => 'hello world');

  # bless(..., "Venus::Template")

=back

=over 4

=item new example 4

  package main;

  use Venus::Template;

  my $new = Venus::Template->new(context => {greeting => 'hello'});

  # bless(..., "Venus::Template")

=back

=cut

=head2 render

  render(string $template, hashref $context) (string)

The render method processes the template by replacing the tokens and control
structurs with the appropriate replacements and returns the result. B<Note:>
The rendering process expects variables to be hashrefs and sets (arrayrefs) of
hashrefs. Within a C<for> loop, special values are available under the C<loop>
variable:

=over 4

=item *

C<{{ loop.index }}> - Zero-based index of current iteration

=item *

C<{{ loop.place }}> - One-based index of current iteration

=item *

C<{{ loop.item }}> - Current item value (especially useful for arrays of simple values, e.g. strings)

=item *

C<{{ loop.parent }}> - Access to parent loop's metadata (if within nested loops)

=item *

C<{{ loop.level }}> - Access to multi-level parent loop metadata (if within nested loops)

=back

For nested loops, you can also access specific loop levels using zero-based numbering:

=over 4

=item *

C<{{ loop.level.0 }}> - Top-level loop

=item *

C<{{ loop.level.1 }}> - One level under the top-level loop

=item *

C<{{ loop.level.2 }}> - Two levels under the top-level loop

=back

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

  $template->context({
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

  $template->context({
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

  $template->context({
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

  $template->context({
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

  $template->context({
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

  $template->context({
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

  $template->context({
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

=over 4

=item render example 9

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for names }}
    [{{ loop.place }}] {{ loop.item }}
    {{ end names }}
  ));

  $template->context({
    names => ['user 1', 'user 2', 'user 3'],
  });

  my $result = $template->render;

  # [1] user 1
  # [2] user 2
  # [3] user 3

=back

=over 4

=item render example 10

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for teams }}
    Team {{ loop.item }}:
    {{ for players }}
    [{{ loop.place }}] {{ loop.item }} (Team {{ loop.parent.item }})
    {{ end players }}
    {{ end teams }}
  ));

  $template->context({
    teams => ['A', 'B'],
    players => ['Player 1', 'Player 2'],
  });

  my $result = $template->render;

  # Team A:
  # [1] Player 1 (Team A)
  # [2] Player 2 (Team A)
  # Team B:
  # [1] Player 1 (Team B)
  # [2] Player 2 (Team B)

=back

=over 4

=item render example 11

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(q(
    {{ for chapters }}
    Chapter {{ loop.level.0.place }}: {{ loop.level.0.item }}
    {{ for sections }}
    {{ loop.level.1.place }}.{{ loop.level.0.place }} {{ loop.level.0.item }}
    {{ end sections }}
    {{ end chapters }}
  ));

  $template->context({
    chapters => ['Intro', 'Methods'],
    sections => ['Overview', 'Details']
  });

  my $result = $template->render;

  # Chapter 1: Intro
  # 1.1 Overview
  # 1.2 Details
  # Chapter 2: Methods
  # 2.1 Overview
  # 2.2 Details

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

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut