#!/usr/bin/perl -w
use strict;

use lib './inc';
use IO::Catch;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

use Test::More tests => 1 +3;

BEGIN {
  # Disable all ReadLine functionality
  $ENV{PERL_RL} = 0;
  use_ok('WWW::Mechanize::Shell');
};

TODO: {
  local $TODO = "Implement passing of multiple values";

  my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
  $s->agent->{content} = join "", <DATA>;
  $s->agent->{forms} = [ HTML::Form->parse($s->agent->{content}, 'http://localhost/test/') ];
  $s->agent->{form}  = @{$s->agent->{forms}} ? $s->agent->{forms}->[0] : undef;
  $s->cmd('value cat cat_foo cat_bar cat_baz');
  is_deeply([$s->agent->current_form->find_input('cat')->form_name_value],[qw[cat cat_foo cat cat_bar cat cat_baz]])
    or diag $s->agent->current_form->find_input('cat')->form_name_value;
  $s->cmd('value cat ""');
  is_deeply([$s->agent->current_form->find_input('cat')],[]);
  $s->cmd('value cat "cat_bar"');
  is_deeply([$s->agent->current_form->find_input('cat')],[qw[cat_bar]]);
};
__DATA__
<html>
<head>WWW::Mechanize::Shell test page</head>
<body>
<h1>Location: %s</h1>
<p>
  <a href="/test">Link /test</a>
  <a href="/foo">Link /foo</a>
  <a href="/slash_end">Link /</a>
  <a href="/slash_front">/Link </a>
  <a href="/slash_both">/Link in slashes/</a>
  <a href="/foo1.save_log_server_test.tmp">Link foo1.save_log_server_test.tmp</a>
  <a href="/foo2.save_log_server_test.tmp">Link foo2.save_log_server_test.tmp</a>
  <a href="/foo3.save_log_server_test.tmp">Link foo3.save_log_server_test.tmp</a>
  <table>
    <tr><th>Col1</th><th>Col2</th><th>Col3</th></tr>
    <tr><td>A1</td><td>A2</td><td>A3</td></tr>
    <tr><td>B1</td><td>B2</td><td>B3</td></tr>
    <tr><td>C1</td><td>C2</td><td>C3</td></tr>
  </table>
  <form action="/formsubmit">
    <input type="hidden" name="session" value="%s"/>
    <input type="text" name="query" value="%s"/>
    <input type="submit" name="submit" value="Go"/>
    <input type="checkbox" name="cat" value="cat_foo" %s />
    <input type="checkbox" name="cat" value="cat_bar" %s />
    <input type="checkbox" name="cat" value="cat_baz" %s />
  </form>
</p>
</body>
</html>
