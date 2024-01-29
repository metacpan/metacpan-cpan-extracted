use strict;
use warnings;

use Test::More 0.98;
use Test::Base::Less;
use JSON::PP qw/decode_json/;

use Text::MustacheTemplate;
use Text::MustacheTemplate::HTML;

# emulate CGI.escapeHTML https://docs.ruby-lang.org/ja/latest/method/CGI/s/escapeHTML.html
local $Text::MustacheTemplate::HTML::ESCAPE = do {
    my %m = (
        q!'! => '&#39;',
        q!&! => '&amp;',
        q!"! => '&quot;',
        q!<! => '&lt;',
        q!>! => '&gt;',
    );
    sub {
        my $text = shift;
        $text =~ s/(['&"<>])/$m{$1}/mego;
        return $text;
    };
};

subtest parse => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $template = Text::MustacheTemplate->parse($case->{template});
        my $result = $template->($case->{data});
        is $result, $case->{expected}, $block->name;
    }
};

subtest render => sub {
    for my $block (blocks) {
        my $case = decode_json($block->case);
        local %Text::MustacheTemplate::REFERENCES = exists $case->{partials} ? (
            map { $_ => Text::MustacheTemplate->parse($case->{partials}->{$_}) } keys %{$case->{partials}}
        ) : ();
        my $result = Text::MustacheTemplate->render($case->{template}, $case->{data});
        is $result, $case->{expected}, $block->name;
    }
};

done_testing;

__DATA__
=== Basic Behavior: The greater-than operator should expand to the named partial.
--- case
{
   "data" : {},
   "expected" : "\"from partial\"",
   "partials" : {
      "text" : "from partial"
   },
   "template" : "\"{{>text}}\""
}

=== Failed Lookup: The empty string should be used when the named partial is not found.
--- case
{
   "data" : {},
   "expected" : "\"\"",
   "partials" : {},
   "template" : "\"{{>text}}\""
}

=== Context: The greater-than operator should operate within the current context.
--- case
{
   "data" : {
      "text" : "content"
   },
   "expected" : "\"*content*\"",
   "partials" : {
      "partial" : "*{{text}}*"
   },
   "template" : "\"{{>partial}}\""
}

=== Recursion: The greater-than operator should properly recurse.
--- case
{
   "data" : {
      "content" : "X",
      "nodes" : [
         {
            "content" : "Y",
            "nodes" : []
         }
      ]
   },
   "expected" : "X<Y<>>",
   "partials" : {
      "node" : "{{content}}<{{#nodes}}{{>node}}{{/nodes}}>"
   },
   "template" : "{{>node}}"
}

=== Surrounding Whitespace: The greater-than operator should not alter surrounding whitespace.
--- case
{
   "data" : {},
   "expected" : "| \t|\t |",
   "partials" : {
      "partial" : "\t|\t"
   },
   "template" : "| {{>partial}} |"
}

=== Inline Indentation: Whitespace should be left untouched.
--- case
{
   "data" : {
      "data" : "|"
   },
   "expected" : "  |  >\n>\n",
   "partials" : {
      "partial" : ">\n>"
   },
   "template" : "  {{data}}  {{> partial}}\n"
}

=== Standalone Line Endings: "\r\n" should be considered a newline for standalone tags.
--- case
{
   "data" : {},
   "expected" : "|\r\n>|",
   "partials" : {
      "partial" : ">"
   },
   "template" : "|\r\n{{>partial}}\r\n|"
}

=== Standalone Without Previous Line: Standalone tags should not require a newline to precede them.
--- case
{
   "data" : {},
   "expected" : "  >\n  >>",
   "partials" : {
      "partial" : ">\n>"
   },
   "template" : "  {{>partial}}\n>"
}

=== Standalone Without Newline: Standalone tags should not require a newline to follow them.
--- case
{
   "data" : {},
   "expected" : ">\n  >\n  >",
   "partials" : {
      "partial" : ">\n>"
   },
   "template" : ">\n  {{>partial}}"
}

=== Standalone Indentation: Each line of the partial should be indented before rendering.
--- case
{
   "data" : {
      "content" : "<\n->"
   },
   "expected" : "\\\n |\n <\n->\n |\n/\n",
   "partials" : {
      "partial" : "|\n{{{content}}}\n|\n"
   },
   "template" : "\\\n {{>partial}}\n/\n"
}

=== Padding Whitespace: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "|[]|",
   "partials" : {
      "partial" : "[]"
   },
   "template" : "|{{> partial }}|"
}

