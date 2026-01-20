package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;

my $test = test(__FILE__);

=name

Venus::Template

=cut

$test->for('name');

=tagline

Template Class

=cut

$test->for('tagline');

=abstract

Template Class for Perl 5

=cut

$test->for('abstract');

=includes

method: new
method: render

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Template;

  my $template = Venus::Template->new(
    'From: <{{ email }}>',
  );

  # $template->render;

  # "From: <>"

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Template');
  is $result->render, 'From: <>';
  $result->context({email => 'noreply@example.com'});
  is $result->render, 'From: <noreply@example.com>';

  $result
});

=description

This package provides a simple yet powerful templating system for Perl 5 that
supports variable interpolation, loops, and conditional blocks. The templating
system is designed to only operate on raw Perl data and as such does not
support operators, filters, virtual method, etc.

+=head2 Syntax

+=head3 Tags

The opening and closing tags are C<{{> and C<}}>. Content between these tags
can be:

+=over 4

+=item *

Simple path access (e.g., C<{{ name }}>)

+=item *

Nested path access (e.g., C<{{ user.email }}>)

+=item *

Control structures (described below)

+=back

To include literal tags in your template, escape them using either:

+=over 4

+=item *

Single backslash: C<\{{> and C<\}}>

+=item *

Escaped braces: C<\{\{> and C<\}\}>

+=back

+=head3 Tokens

Variable substitution uses dot notation to access nested data:

  # access hash key 'name' in hash 'user'
  {{ user.name }}

  # access hash key 'name' in first element of array 'users'
  {{ users.0.name }}

  # access deeply nested hash keys
  {{ profile.address.zip }}

+=head3 Loops

Loops iterate over arrays using the C<for> control structure:

  {{ for users }}
    Name: {{ user.name }}
  {{ end users }}

Special loop variables are available within C<for> blocks:

+=over 4

+=item *

C<{{ loop.index }}> - Zero-based iteration counter

+=item *

C<{{ loop.place }}> - One-based iteration counter

+=item *

C<{{ loop.item }}> - Current item value (useful for arrays of simple values)

+=back

For nested loops, parent loop information is accessible via:


+=over 4

+=item *

C<{{ loop.parent }}> - Immediate parent loop's data

+=item *

C<{{ loop.level.0 }}> - First loop

+=item *

C<{{ loop.level.1 }}> - Second loop

+=item *

C<{{ loop.level.2 }}> - Third loop

+=back

+=head3 Controls

Conditional blocks use C<if>, C<if not>, and optional C<else>:

  {{ if user.admin }}
    Admin: {{ user.name }}
  {{ else user.admin }}
    User: {{ user.name }}
  {{ end user.admin }}

  {{ if not user.active }}
    Account inactive
  {{ end user.active }}

+=head2 Structure

The template engine expects variables to be provided as hashrefs. Arrays should
be provided as arrayrefs. When iterating over arrays:

+=over 4

+=item *

Arrays of hashrefs: Access hash keys via C<{{ user.name }}>

+=item *

Arrays of simple values: Access values via C<{{ loop.item }}>

+=back

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

+=head2 Context

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

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=integrates

Venus::Role::Accessible
Venus::Role::Buildable
Venus::Role::Explainable
Venus::Role::Valuable

=cut

$test->for('integrates');

=attribute context

The context attribute is read-write, accepts C<(hashref)> values, and is
optional.

=signature context

  context(hashref $context) (hashref)

=metadata context

{
  since => '4.15',
}

=cut

=example-1 context

  # given: synopsis

  package main;

  my $set_context = $template->context({});

  # {}

=cut

$test->for('example', 1, 'context', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=example-2 context

  # given: synopsis

  # given: example-1 context

  package main;

  my $get_context = $template->context;

  # {}

=cut

$test->for('example', 2, 'context', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, {};

  $result
});

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Template)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Template;

  my $new = Venus::Template->new;

  # bless(..., "Venus::Template")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Template');

  !$result
});

=example-2 new

  package main;

  use Venus::Template;

  my $new = Venus::Template->new('hello world');

  # bless(..., "Venus::Template")

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Template');
  ok $result->value, 'hello world';

  $result
});

=example-3 new

  package main;

  use Venus::Template;

  my $new = Venus::Template->new(value => 'hello world');

  # bless(..., "Venus::Template")

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Template');
  ok $result->value, 'hello world';

  $result
});

=example-4 new

  package main;

  use Venus::Template;

  my $new = Venus::Template->new(context => {greeting => 'hello'});

  # bless(..., "Venus::Template")

=cut

$test->for('example', 4, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Template');
  is_deeply $result->context, {greeting => 'hello'};

  !$result
});

=method render

The render method processes the template by replacing the tokens and control
structurs with the appropriate replacements and returns the result. B<Note:>
The rendering process expects variables to be hashrefs and sets (arrayrefs) of
hashrefs. Within a C<for> loop, special values are available under the C<loop>
variable:

+=over 4

+=item *

C<{{ loop.index }}> - Zero-based index of current iteration

+=item *

C<{{ loop.place }}> - One-based index of current iteration

+=item *

C<{{ loop.item }}> - Current item value (especially useful for arrays of simple values, e.g. strings)

+=item *

C<{{ loop.parent }}> - Access to parent loop's metadata (if within nested loops)

+=item *

C<{{ loop.level }}> - Access to multi-level parent loop metadata (if within nested loops)

+=back

For nested loops, you can also access specific loop levels using zero-based numbering:

+=over 4

+=item *

C<{{ loop.level.0 }}> - Top-level loop

+=item *

C<{{ loop.level.1 }}> - One level under the top-level loop

+=item *

C<{{ loop.level.2 }}> - Two levels under the top-level loop

+=back

=signature render

  render(string $template, hashref $context) (string)

=metadata render

{
  since => '0.01',
}

=example-1 render

  # given: synopsis;

  my $result = $template->render;

  # "From: <>"

=cut

$test->for('example', 1, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'From: <>';

  $result
});

=example-2 render

  # given: synopsis;

  $template->value(
    'From: {{ if name }}{{ name }}{{ end name }} <{{ email }}>',
  );

  $template->context({
    email => 'noreply@example.com',
  });

  my $result = $template->render;

  # "From:  <noreply@example.com>"

=cut

$test->for('example', 2, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'From:  <noreply@example.com>';

  $result
});

=example-3 render

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

=cut

$test->for('example', 3, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, 'From: No-Reply <noreply@example.com>';

  $result
});

=example-4 render

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

=cut

$test->for('example', 4, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    'user1: ready?',
    'user2: ready!',
    'user1: lets begin!',
  ];

  $result
});

=example-5 render

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

=cut

$test->for('example', 5, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    'user1 [18+]: ready?',
    'user2 [-18]: ready!',
    'user1 [18+]: lets begin!',
  ];

  $result
});

=example-6 render

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

=cut

$test->for('example', 6, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    '@user1: ready?',
    'user2: ready!',
    '@user1: lets begin!',
  ];

  $result
});

=example-7 render

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

=cut

$test->for('example', 7, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    '[1] user1: ready?',
    '[2] user2: ready!',
    '[3] user1: lets begin!',
  ];

  $result
});

=example-8 render

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

=cut

$test->for('example', 8, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    '[0] user1: ready?',
    '[1] user2: ready!',
    '[2] user1: lets begin!',
  ];

  $result
});

=example-9 render

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

=cut

$test->for('example', 9, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    '[1] user 1',
    '[2] user 2',
    '[3] user 3',
  ];

  $result
});

=example-10 render

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

=cut

$test->for('example', 10, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    'Team A:',
    '[1] Player 1 (Team A)',
    '[2] Player 2 (Team A)',
    'Team B:',
    '[1] Player 1 (Team B)',
    '[2] Player 2 (Team B)',
  ];

  $result
});

=example-11 render

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

=cut

$test->for('example', 11, 'render', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is_deeply [map {s/^[\n\s]*|[\n\s]*$//gr} split /\n/, $result], [
    'Chapter 1: Intro',
    '1.1 Overview',
    '1.2 Details',
    'Chapter 2: Methods',
    '2.1 Overview',
    '2.2 Details',
  ];

  $result
});

=operator ("")

This package overloads the C<""> operator.

=cut

$test->for('operator', '("")');

=example-1 ("")

  # given: synopsis;

  my $result = "$template";

  # "From: <>"

=cut

$test->for('example', 1, '("")', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'From: <>';

  $result
});

=example-2 ("")

  # given: synopsis;

  my $result = "$template, $template";

  # "From: <>, From: <>"

=cut

$test->for('example', 2, '("")', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'From: <>, From: <>';

  $result
});

=operator (~~)

This package overloads the C<~~> operator.

=cut

$test->for('operator', '(~~)');

=example-1 (~~)

  # given: synopsis;

  my $result = $template ~~ 'From: <>';

  # 1

=cut

$test->for('example', 1, '(~~)', sub {
  1;
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Template.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
