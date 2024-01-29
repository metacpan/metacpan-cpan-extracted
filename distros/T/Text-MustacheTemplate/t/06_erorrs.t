use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;

use Text::MustacheTemplate;

filters {
    input => [qw/chomp/],
};

for my $block (blocks) {
    eval { Text::MustacheTemplate->parse($block->input) };
    note $@;
    ok $@, $block->name;
}

done_testing;
__DATA__
=== Incorrect Variable Close Delimiter
--- input: {{aa}
=== Incorrect Raw Variable Close Delimiter
--- input: {{{aa}}
=== Non Closed Section
--- input: {{#a}}
=== Non Opened Section
--- input: {{/a}}
=== Unbalanced Section
--- input: {{#a}}{{#b}}{{/a}}{{/b}}
=== Unbalanced Section with new lines
--- input
{{#a}}
  {{#b}}
  {{/a}}
{{/b}}
=== New Line includes after open delimiter of variable tag
--- input
{{
a}}
=== New Line includes before close delimiter of variable tag
--- input
{{a
}}
=== New Line includes after open delimiter of raw variable tag
--- input
{{{
a}}}
=== New Line includes before close delimiter of raw variable tag
--- input
{{{a
}}}
=== Delimiter tag must not include equals
--- input: {{=<%= =%>=}}
=== Delimiter tag must not include a single delimiter
--- input: {{=<%=}}
=== Delimiter tag must not include 3+ delimiters
--- input: {{=<% %% %>=}}
=== Never ending comment
--- input
{{!
  this is correct
}}but the following is incorrect{{!
never
  ending
    comment...