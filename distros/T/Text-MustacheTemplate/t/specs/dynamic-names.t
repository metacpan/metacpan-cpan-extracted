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
=== Basic Behavior - Partial: The asterisk operator is used for dynamic partials.
--- case
{
   "data" : {
      "dynamic" : "content"
   },
   "expected" : "\"Hello, world!\"",
   "partials" : {
      "content" : "Hello, world!"
   },
   "template" : "\"{{>*dynamic}}\""
}

=== Basic Behavior - Name Resolution: The asterisk is not part of the name that will be resolved in the context.

--- case
{
   "data" : {
      "*dynamic" : "wrong",
      "dynamic" : "content"
   },
   "expected" : "\"Hello, world!\"",
   "partials" : {
      "content" : "Hello, world!",
      "wrong" : "Invisible"
   },
   "template" : "\"{{>*dynamic}}\""
}

=== Context Misses - Partial: Failed context lookups should be considered falsey.
--- case
{
   "data" : {},
   "expected" : "\"\"",
   "partials" : {
      "missing" : "Hello, world!"
   },
   "template" : "\"{{>*missing}}\""
}

=== Failed Lookup - Partial: The empty string should be used when the named partial is not found.
--- case
{
   "data" : {
      "dynamic" : "content"
   },
   "expected" : "\"\"",
   "partials" : {
      "foobar" : "Hello, world!"
   },
   "template" : "\"{{>*dynamic}}\""
}

=== Context: The dynamic partial should operate within the current context.
--- case
{
   "data" : {
      "example" : "partial",
      "text" : "Hello, world!"
   },
   "expected" : "\"*Hello, world!*\"",
   "partials" : {
      "partial" : "*{{text}}*"
   },
   "template" : "\"{{>*example}}\""
}

=== Dotted Names: The dynamic partial should operate within the current context.
--- case
{
   "data" : {
      "foo" : {
         "bar" : {
            "baz" : "partial"
         }
      },
      "text" : "Hello, world!"
   },
   "expected" : "\"*Hello, world!*\"",
   "partials" : {
      "partial" : "*{{text}}*"
   },
   "template" : "\"{{>*foo.bar.baz}}\""
}

=== Dotted Names - Operator Precedence: The dotted name should be resolved entirely before being dereferenced.
--- case
{
   "data" : {
      "foo" : "test",
      "test" : {
         "bar" : {
            "baz" : "partial"
         }
      },
      "text" : "Hello, world!"
   },
   "expected" : "\"\"",
   "partials" : {
      "partial" : "*{{text}}*"
   },
   "template" : "\"{{>*foo.bar.baz}}\""
}

=== Dotted Names - Failed Lookup: The dynamic partial should operate within the current context.
--- case
{
   "data" : {
      "foo" : {
         "bar" : {
            "baz" : "partial"
         },
         "text" : "Hello, world!"
      }
   },
   "expected" : "\"**\"",
   "partials" : {
      "partial" : "*{{text}}*"
   },
   "template" : "\"{{>*foo.bar.baz}}\""
}

=== Dotted names - Context Stacking: Dotted names should not push a new frame on the context stack.
--- case
{
   "data" : {
      "section1" : {
         "value" : "section1"
      },
      "section2" : {
         "dynamic" : "partial",
         "value" : "section2"
      }
   },
   "expected" : "\"section1\"",
   "partials" : {
      "partial" : "\"{{value}}\""
   },
   "template" : "{{#section1}}{{>*section2.dynamic}}{{/section1}}"
}

=== Dotted names - Context Stacking Under Repetition: Dotted names should not push a new frame on the context stack.
--- case
{
   "data" : {
      "section1" : [
         1,
         2
      ],
      "section2" : {
         "dynamic" : "partial",
         "value" : "section2"
      },
      "value" : "test"
   },
   "expected" : "testtest",
   "partials" : {
      "partial" : "{{value}}"
   },
   "template" : "{{#section1}}{{>*section2.dynamic}}{{/section1}}"
}

=== Dotted names - Context Stacking Failed Lookup: Dotted names should resolve against the proper context stack.
--- case
{
   "data" : {
      "section1" : [
         1,
         2
      ],
      "section2" : {
         "dynamic" : "partial",
         "value" : "section2"
      }
   },
   "expected" : "\"\"\"\"",
   "partials" : {
      "partial" : "\"{{value}}\""
   },
   "template" : "{{#section1}}{{>*section2.dynamic}}{{/section1}}"
}

=== Recursion: Dynamic partials should properly recurse.
--- case
{
   "data" : {
      "content" : "X",
      "nodes" : [
         {
            "content" : "Y",
            "nodes" : []
         }
      ],
      "template" : "node"
   },
   "expected" : "X<Y<>>",
   "partials" : {
      "node" : "{{content}}<{{#nodes}}{{>*template}}{{/nodes}}>"
   },
   "template" : "{{>*template}}"
}

=== Dynamic Names - Double Dereferencing: Dynamic Names can't be dereferenced more than once.
--- case
{
   "data" : {
      "dynamic" : "test",
      "test" : "content"
   },
   "expected" : "\"\"",
   "partials" : {
      "content" : "Hello, world!"
   },
   "template" : "\"{{>**dynamic}}\""
}

=== Dynamic Names - Composed Dereferencing: Dotted Names are resolved entirely before dereferencing begins.
--- case
{
   "data" : {
      "bar" : "buzz",
      "fizz" : {
         "buzz" : {
            "content" : null
         }
      },
      "foo" : "fizz"
   },
   "expected" : "\"\"",
   "partials" : {
      "content" : "Hello, world!"
   },
   "template" : "\"{{>*foo.*bar}}\""
}

=== Surrounding Whitespace: A dynamic partial should not alter surrounding whitespace; any
whitespace preceding the tag should be treated as indentation while any
whitespace succeding the tag should be left untouched.

--- case
{
   "data" : {
      "partial" : "foobar"
   },
   "expected" : "| \t|\t |",
   "partials" : {
      "foobar" : "\t|\t"
   },
   "template" : "| {{>*partial}} |"
}

=== Inline Indentation: Whitespace should be left untouched: whitespaces preceding the tag
should be treated as indentation.

--- case
{
   "data" : {
      "data" : "|",
      "dynamic" : "partial"
   },
   "expected" : "  |  >\n>\n",
   "partials" : {
      "partial" : ">\n>"
   },
   "template" : "  {{data}}  {{>*dynamic}}\n"
}

=== Standalone Line Endings: "\r\n" should be considered a newline for standalone tags.
--- case
{
   "data" : {
      "dynamic" : "partial"
   },
   "expected" : "|\r\n>|",
   "partials" : {
      "partial" : ">"
   },
   "template" : "|\r\n{{>*dynamic}}\r\n|"
}

=== Standalone Without Previous Line: Standalone tags should not require a newline to precede them.
--- case
{
   "data" : {
      "dynamic" : "partial"
   },
   "expected" : "  >\n  >>",
   "partials" : {
      "partial" : ">\n>"
   },
   "template" : "  {{>*dynamic}}\n>"
}

=== Standalone Without Newline: Standalone tags should not require a newline to follow them.
--- case
{
   "data" : {
      "dynamic" : "partial"
   },
   "expected" : ">\n  >\n  >",
   "partials" : {
      "partial" : ">\n>"
   },
   "template" : ">\n  {{>*dynamic}}"
}

=== Standalone Indentation: Each line of the partial should be indented before rendering.
--- case
{
   "data" : {
      "content" : "<\n->",
      "dynamic" : "partial"
   },
   "expected" : "\\\n |\n <\n->\n |\n/\n",
   "partials" : {
      "partial" : "|\n{{{content}}}\n|\n"
   },
   "template" : "\\\n {{>*dynamic}}\n/\n"
}

=== Padding Whitespace: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "boolean" : true,
      "dynamic" : "partial"
   },
   "expected" : "|[]|",
   "partials" : {
      "partial" : "[]"
   },
   "template" : "|{{> * dynamic }}|"
}

