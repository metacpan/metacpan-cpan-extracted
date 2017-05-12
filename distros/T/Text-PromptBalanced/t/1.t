# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More qw(no_plan);
BEGIN { use_ok('Text::PromptBalanced','balance_factory') };

#########################

# {{{ Default
{
  my $b = balance_factory();
  ok($b->(q<foo bar>) == 1, "Unconfigured should always be balanced");
  ok($b->(q<(o" bar>) == 1, "Unconfigured should ignore metacharacters");
  ok($b->(q<"o) bar>) == 1, "Unconfigured should ignore metacharacters");
}
# }}}
# {{{ Escape - no further specifications
{
  my $b = balance_factory ( escape => 1 );
  ok($b->(q<foo bar>) == 1, "Default escape should always be balanced");
  ok($b->(q<(o" bar>) == 1, "Default escape should ignore metacharacters");
  ok($b->(q<"o) bar>) == 1, "Default escape should ignore metacharacters");
  ok($b->(q<"\) bar>) == 1, "Default escape should escape metacharacters");
}
# }}}
# {{{ Comment
{
  my $b = balance_factory (
    comment => { type => 'to-eol', open => '#' }
  );
  ok($b->(q<#foo bar>) == 1, "Comment should always be balanced");
  ok($b->(q<(# bar>) == 1, "Comment-only should ignore metacharacters");
  ok($b->(q<#o) bar>) == 1, "Comment-only should suppress metacharacters");
  ok($b->(q<#") bar>) == 1, "Comment-only should suppress metacharacters");
}
# }}}
# {{{ Comment and Escape
{
  my $b = balance_factory (
    comment => { type => 'to-eol', open => '#' },
    escape => 1,
  );
  ok($b->(q<#foo bar>) == 1, "Comment should always be balanced");
  ok($b->(q<(# bar>) == 1, "Comment-only should ignore metacharacters");
  ok($b->(q<#o) bar>) == 1, "Comment-only should suppress metacharacters");
  ok($b->(q<#") bar>) == 1, "Comment-only should suppress metacharacters");
  ok($b->(q<\#foo bar>) == 1, "Escaped comment has no effect");
  ok($b->(q<(\# bar>) == 1, "Escaped comment with metacharacters");
  ok($b->(q<\#o) bar>) == 1, "Comment-only should suppress metacharacters");
  ok($b->(q<\#") bar>) == 1, "Comment-only should suppress metacharacters");
}
# }}}
# {{{ Parentheses
{
  my ($state,$b) =
    balance_factory (
      parentheses => { type => 'balanced', open => '(', close => ')' }
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<(foo bar)>) == 1,
     "Balanced metacharacters always balance");
  ok($b->(q<(foo bar>) == 0,
     "Unbalanced metacharacter remains unbalanced");
  ok($state->{parentheses} == 1,
     "Counted an open parenthesis");
  ok($b->(q<foo bar)>) == 1,
     "Rebalancing the metacharacter resets the counter");
  ok($b->(q<((foo bar))>) == 1,
     "Nested balanced metacharacters always balance");
  ok($b->(q<((foo bar>) == 0,
     "Nested unbalanced metacharacters remain unbalanced");
  ok($state->{parentheses} == 2,
     "Counted two open parentheses");
  ok($b->(q<foo bar))>) == 1,
     "Closing metacharacters always balance");
}
# }}}
# {{{ Parentheses and Escape
{
  my ($state,$b) =
    balance_factory (
      parentheses => { type => 'balanced', open => '(', close => ')' },
      escape => 1
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<\(foo bar\)>) == 1,
     "Escaped balanced metacharacters always balance");
  ok($b->(q<(foo bar\)>) == 0,
     "Unbalanced metacharacter with escaped metacharacter remains unbalanced");
  ok($state->{parentheses} == 1,
     "Counted an open parenthesis");
  ok($b->(q<foo bar)>) == 1,
     "Rebalancing the metacharacter resets the counter");
  ok($b->(q<((foo bar))>) == 1,
     "Nested balanced metacharacters always balance");
  ok($b->(q<((foo bar\)\)>) == 0,
     "Nested unbalanced metacharacters remain unbalanced");
  ok($state->{parentheses} == 2,
     "Counted two open parentheses");
  ok($b->(q<\)\)foo bar))>) == 1,
     "Closing metacharacters (not counting escaped versions) always balance");
}
# }}}
# {{{ HTML tag
{
  my ($state,$b) =
    balance_factory (
      tag => { type => 'unbalanced', open => '<', close => '>' }
    );
  ok($b->(q[foo bar]) == 1,
     "No metacharacters always balance");
  ok($b->(q[<foobar>]) == 1,
     "Balanced metacharacters always balance");
  ok($b->(q[<foobar]) == 0,
     "Open without close tag balances");
  ok($state->{tag} == 1,
     "Counted an open tag");
  ok($b->(q[foobar>]) == 1,
     "Rebalancing the metacharacter resets the counter");
  ok($b->(q[<<foobar>]) == 1,
     "Second open tag is ignored");
  ok($b->(q[<<foobar]) == 0,
     "Two open tags don't accidentally rebalance");
  ok($state->{tag} == 1,
     "Still only have one opening tag");
  ok($b->(q[foobar>]) == 1,
     "Closing metacharacters always balance");
}
# }}}
# {{{ HTML tag and Escape
{
  my ($state,$b) =
    balance_factory (
      tag => { type => 'unbalanced', open => '<', close => '>' },
      escape => 1
    );
  ok($b->(q[foo bar]) == 1,
     "No metacharacters always balance");
  ok($b->(q[<foobar>]) == 1,
     "Balanced metacharacters always balance");
  ok($b->(q[<foobar\>]) == 0,
     "Escaped metacharacter is always ignored");
  ok($state->{tag} == 1,
     "Counted an open tag");
  ok($b->(q[\>foobar>]) == 1,
     "Rebalancing the metacharacter (ignoring the escape) resets the counter");
  ok($b->(q[<<foobar\>>]) == 1,
     "Second open tag is ignored, and escaped closing tag is ignored");
  ok($b->(q[<<foobar]) == 0,
     "Two open tags don't accidentally rebalance");
  ok($state->{tag} == 1,
     "Still only have one opening tag");
  ok($b->(q[foobar>]) == 1,
     "Closing metacharacters always balance");
}
# }}}
# {{{ String
{
  my ($state,$b) =
    balance_factory (
      string => { type => 'toggle', open => '"' }
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<"foo bar">) == 1,
     "Two occurrences clear the toggle");
  ok($b->(q<""foo bar"">) == 1,
     "Four occurrences also clear the toggle");
  ok($b->(q<"foo bar>) == 0,
     "One occurrence doesn't clear the toggle");
  ok($state->{string} == 1,
     "Counted one toggle of the string");
  ok($b->(q<foo bar">) == 1,
     "An occurrence on the next line toggles, though");
}
# }}}
# {{{ String and Escape
{
  my ($state,$b) =
    balance_factory (
      string => { type => 'toggle', open => '"' },
      escape => 1,
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<"foo bar">) == 1,
     "Two occurrences clear the toggle");
  ok($b->(q<""foo bar"">) == 1,
     "Four occurrences also clear the toggle");
  ok($b->(q<"foo bar\">) == 0,
     "One occurrence and one escaped occurrence doesn't clear the toggle");
  ok($state->{string} == 1,
     "Counted one toggle of the string");
  ok($b->(q<\"foo bar">) == 1,
     "An occurrence (not counting the escaped one) on the next line toggles, though");
}
# }}}
# {{{ Parentheses and To-EOL comment
{
  my ($state,$b) =
    balance_factory (
      parentheses => { type => 'balanced', open => '(', close => ')' },
      comment => { type => 'to-eol', open => '#' }
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<(foo bar)>) == 1,
     "Balanced metacharacters always balance");
  ok($b->(q<(foo # bar)>) == 0,
     "Comment character ignores closing paren");
  ok($state->{parentheses} == 1,
     "Counted a single open parenthesis");
  ok($b->( # (( Rebalancing parens
    q<)foo # bar)>) == 1,
     "Comment character ignores closing paren");
}
# }}}
# {{{ String and To-EOL comment
{
  my ($state,$b) =
    balance_factory (
      string => { type => 'toggle', open => '"' },
      comment => { type => 'to-eol', open => '#' },
   );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<"foo bar">) == 1,
     "Balanced metacharacters always balance");
  ok($b->(q<"foo # bar">) == 0,
     "Comment character ignores closing double-quote");
  ok($state->{string} == 1,
     "String toggle is still set");
  ok($b->(q<"foo # bar)>) == 1,
     "Comment character ignores closing double-quote");
}
# }}}
# {{{ Parentheses, String and ignore
{
  my ($state,$b) =
    balance_factory (
      parentheses => {
        type => 'balanced',
        open => '(', close => ')',
        ignore_in => 'string'
      },
      string => { type => 'toggle', open => '"' },
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<(foo bar)>) == 1,
     "Balanced metacharacters always balance");
  ok($b->(q<("foo bar")>) == 1,
     "String inside parentheses toggles/balances");
  ok($b->(q<"(foo bar)">) == 1,
     "Parentheses inside strings shouldn't matter, but does it still balance?");
  ok($b->(q<"(foo bar">) == 1,
     "Unbalanced open parenthesis inside a string should be ignored");
  ok($b->(q<"foo) bar">) == 1,
     "Unbalanced closing parenthesis inside a string should be ignored");
}
# }}}
# {{{ String and Comment with ignore
{
  my ($state,$b) =
    balance_factory (
      string => { type => 'toggle', open => '"' },
      comment => { type => 'to-eol', open => '#', ignore_in => 'string' },
    );
  ok($b->(q<foo bar>) == 1,
     "No metacharacters always balance");
  ok($b->(q<"foo bar" #>) == 1,
     "String followed by comment should still balance");
  ok($b->(q<""foo bar#">) == 1,
     "Quotes after the comment should be ignored");
  ok($b->(q<"foo # bar">) == 1,
     "Comments inside a quote should be ignored");
}
# }}}
