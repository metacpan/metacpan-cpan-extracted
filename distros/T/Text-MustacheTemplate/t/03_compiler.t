use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;

use Text::MustacheTemplate;
use Text::MustacheTemplate::Lexer;
use Text::MustacheTemplate::Parser;
use Text::MustacheTemplate::Compiler;

filters {
    input    => [qw/chomp/],
    skip     => [qw/chomp/],
    vars     => [qw/eval/],
    expected => [qw/chomp/],
};

local $Text::MustacheTemplate::LAMBDA_TEMPLATE_RENDERING = 1;
local %Text::MustacheTemplate::REFERENCES = (
    user  => _parse("<strong>{{name}}</strong>\n"),
    world => _parse('everyone!'),
    article => _parse(<<'__TEMPLATE__'),
<h1>{{$title}}The News of Today{{/title}}</h1>
{{$body}}
<p>Nothing special happened.</p>
{{/body}}
__TEMPLATE__
    normal => _parse('{{$text}}Here goes nothing.{{/text}}'),
    bold   => _parse(q[<b>{{$text}}Here also goes nothing but it's bold.{{/text}}</b>]),
);

sub _parse {
    my $src = shift;
    my @tokens = Text::MustacheTemplate::Lexer->tokenize($src);
    local $Text::MustacheTemplate::Parser::SOURCE = $src;
    my $ast = Text::MustacheTemplate::Parser->parse(@tokens);
    return Text::MustacheTemplate::Compiler->compile($ast);
}

for my $block (blocks) {
    my $template = _parse($block->input);
    my $result = $template->($block->vars);
    SKIP: {
      skip $block->skip, 1 if $block->has_section('skip');
      is $result, $block->expected, $block->name;
    }
}

done_testing;
__DATA__

=== Empty
--- input:
--- vars: undef
--- expected:
=== Variables
--- input
* {{name}}
* {{age}}
* {{company}}
* {{{company}}}
--- vars
{
    name    => 'Chris',
    company => '<b>GitHub</b>',
}
--- expected
* Chris
* 
* &lt;b&gt;GitHub&lt;/b&gt;
* <b>GitHub</b>
=== Variables: Dotted Names
--- input
* {{client.name}}
* {{age}}
* {{client.company.name}}
* {{{company.name}}}
--- vars
{
    client => {
        name => 'Chris & Friends',
        age => 50,
    },
    company => {
        name => '<b>GitHub</b>',
    },
}
--- expected
* Chris &amp; Friends
* 
* 
* <b>GitHub</b>
=== Variables: Lambdas
--- input
* {{time.hour}}
* {{today}}
--- vars
{
    year => 1970,
    month => 1,
    day => 1,
    time => sub {
        return {
            hour   => 0,
            minute => 0,
            second => 0
        };
    },
    today => sub {
      return "{{year}}-{{month}}-{{day}}";
    },
}
--- expected
* 0
* 1970-1-1
=== Section: False Values or Empty Lists
--- input
Shown.
{{#person}}
  Never shown!
{{/person}}
--- vars
{
    person => 0,
}
--- expected
Shown.

=== Section: Non-Empty Lists
--- input
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
--- vars
{
    repo => [
        { name => 'resque' },
        { name => 'hub' },
        { name => 'rip' },
    ],
}
--- expected
  <b>resque</b>
  <b>hub</b>
  <b>rip</b>

=== Section: Non-Empty Lists (Current Context)
--- input
{{#repo}}
  <b>{{.}}</b>
{{/repo}}
--- vars
{
    repo => [qw/resque hub rip/],
}
--- expected
  <b>resque</b>
  <b>hub</b>
  <b>rip</b>

=== Section: Lambdas
--- input
{{#wrapped}}{{name}} is awesome.{{/wrapped}}
--- vars
{
    name => 'Willy',
    wrapped => sub { "<b>$_[0]</b>" },
}
--- expected
<b>Willy is awesome.</b>
=== Section: Non-False Values
--- input
{{#person?}}
  Hi {{name}}!
{{/person?}}
--- vars
{
    'person?' => { name => 'Jon' },
}
--- expected
  Hi Jon!

=== Section: Inverted Sections
--- input
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
{{^repo}}
  No repos :(
{{/repo}}
--- vars
{
    repo => [],
}
--- expected
  No repos :(

=== Comments
--- input
<h1>Today{{! ignore me }}.</h1>
--- vars
{}
--- expected
<h1>Today.</h1>
=== Partials
--- input
<h2>Names</h2>
{{#names}}
  {{> user}}
{{/names}}
--- vars
{
    names => [
        { name => 'Willy' },
        { name => 'Jon'   },
    ],
}
--- expected
<h2>Names</h2>
  <strong>Willy</strong>
  <strong>Jon</strong>

=== Partials: Dynamic Names
--- input
Hello {{>*dynamic}}
--- vars
{
    dynamic => 'world',
}
--- expected
Hello everyone!
=== Blocks
--- input
<h1>{{$title}}The News of Today{{/title}}</h1>
{{$body}}
<p>Nothing special happened.</p>
{{/body}}
--- vars
{}
--- expected
<h1>The News of Today</h1>
<p>Nothing special happened.</p>

=== Parents
--- skip: unclear specification
--- input
{{<article}}
  Never shown
  {{$body}}
    {{#headlines}}
    <p>{{.}}</p>
    {{/headlines}}
  {{/body}}
{{/article}}

{{<article}}
  {{$title}}Yesterday{{/title}}
{{/article}}
--- vars
{
    headlines => [
        "A pug's handler grew mustaches.",
        "What an exciting day!",
    ],
}
--- expected
<h1>The News of Today</h1>
<p>A pug's handler grew mustaches.</p>
<p>What an exciting day!</p>

<h1>Yesterday</h1>
<p>Nothing special happened.</p>

=== Parents: Dynamic Names
--- input
{{<*dynamic}}
  {{$text}}Hello World!{{/text}}
{{/*dynamic}}
--- vars
{
    dynamic => 'bold',
}
--- expected
<b>Hello World!</b>
=== Set Delimiter
--- input
* {{foo}}
{{=<% %>=}}
* <% foo %>
<%={{ }}=%>
* {{ foo }}
--- vars
{
    foo => 'foo!',
}
--- expected
* foo!
* foo!
* foo!
=== Set Delimiter in Block
--- input
* {{foo}}
  {{$body}}{{=<% %>=}}
* <% foo %>
<%/body%>
* <%#bar%>foo<%/bar%>
--- vars
{
    foo => 'foo!',
    bar => sub { '<%'.$_[0].'%>' },
}
--- expected
* foo!
* foo!
* foo!