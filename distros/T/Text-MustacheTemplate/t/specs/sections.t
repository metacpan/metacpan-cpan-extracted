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
=== Truthy: Truthy sections should have their contents rendered.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "\"This should be rendered.\"",
   "template" : "\"{{#boolean}}This should be rendered.{{/boolean}}\""
}

=== Falsey: Falsey sections should have their contents omitted.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "\"\"",
   "template" : "\"{{#boolean}}This should not be rendered.{{/boolean}}\""
}

=== Null is falsey: Null is falsey.
--- case
{
   "data" : {
      "null" : null
   },
   "expected" : "\"\"",
   "template" : "\"{{#null}}This should not be rendered.{{/null}}\""
}

=== Context: Objects and hashes should be pushed onto the context stack.
--- case
{
   "data" : {
      "context" : {
         "name" : "Joe"
      }
   },
   "expected" : "\"Hi Joe.\"",
   "template" : "\"{{#context}}Hi {{name}}.{{/context}}\""
}

=== Parent contexts: Names missing in the current context are looked up in the stack.
--- case
{
   "data" : {
      "a" : "foo",
      "b" : "wrong",
      "c" : {
         "d" : "baz"
      },
      "sec" : {
         "b" : "bar"
      }
   },
   "expected" : "\"foo, bar, baz\"",
   "template" : "\"{{#sec}}{{a}}, {{b}}, {{c.d}}{{/sec}}\""
}

=== Variable test: Non-false sections have their value at the top of context,
accessible as {{.}} or through the parent context. This gives
a simple way to display content conditionally if a variable exists.

--- case
{
   "data" : {
      "foo" : "bar"
   },
   "expected" : "\"bar is bar\"",
   "template" : "\"{{#foo}}{{.}} is {{foo}}{{/foo}}\""
}

=== List Contexts: All elements on the context stack should be accessible within lists.
--- case
{
   "data" : {
      "tops" : [
         {
            "middles" : [
               {
                  "bottoms" : [
                     {
                        "bname" : "x"
                     },
                     {
                        "bname" : "y"
                     }
                  ],
                  "mname" : "1"
               }
            ],
            "tname" : {
               "lower" : "a",
               "upper" : "A"
            }
         }
      ]
   },
   "expected" : "a1.A1x.A1y.",
   "template" : "{{#tops}}{{#middles}}{{tname.lower}}{{mname}}.{{#bottoms}}{{tname.upper}}{{mname}}{{bname}}.{{/bottoms}}{{/middles}}{{/tops}}"
}

=== Deeply Nested Contexts: All elements on the context stack should be accessible.
--- case
{
   "data" : {
      "a" : {
         "one" : 1
      },
      "b" : {
         "two" : 2
      },
      "c" : {
         "d" : {
            "five" : 5,
            "four" : 4
         },
         "three" : 3
      }
   },
   "expected" : "1\n121\n12321\n1234321\n123454321\n12345654321\n123454321\n1234321\n12321\n121\n1\n",
   "template" : "{{#a}}\n{{one}}\n{{#b}}\n{{one}}{{two}}{{one}}\n{{#c}}\n{{one}}{{two}}{{three}}{{two}}{{one}}\n{{#d}}\n{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}\n{{#five}}\n{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}\n{{one}}{{two}}{{three}}{{four}}{{.}}6{{.}}{{four}}{{three}}{{two}}{{one}}\n{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}\n{{/five}}\n{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}\n{{/d}}\n{{one}}{{two}}{{three}}{{two}}{{one}}\n{{/c}}\n{{one}}{{two}}{{one}}\n{{/b}}\n{{one}}\n{{/a}}\n"
}

=== List: Lists should be iterated; list items should visit the context stack.
--- case
{
   "data" : {
      "list" : [
         {
            "item" : 1
         },
         {
            "item" : 2
         },
         {
            "item" : 3
         }
      ]
   },
   "expected" : "\"123\"",
   "template" : "\"{{#list}}{{item}}{{/list}}\""
}

=== Empty List: Empty lists should behave like falsey values.
--- case
{
   "data" : {
      "list" : []
   },
   "expected" : "\"\"",
   "template" : "\"{{#list}}Yay lists!{{/list}}\""
}

=== Doubled: Multiple sections per template should be permitted.
--- case
{
   "data" : {
      "bool" : true,
      "two" : "second"
   },
   "expected" : "* first\n* second\n* third\n",
   "template" : "{{#bool}}\n* first\n{{/bool}}\n* {{two}}\n{{#bool}}\n* third\n{{/bool}}\n"
}

=== Nested (Truthy): Nested truthy sections should have their contents rendered.
--- case
{
   "data" : {
      "bool" : true
   },
   "expected" : "| A B C D E |",
   "template" : "| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |"
}

=== Nested (Falsey): Nested falsey sections should be omitted.
--- case
{
   "data" : {
      "bool" : false
   },
   "expected" : "| A  E |",
   "template" : "| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |"
}

=== Context Misses: Failed context lookups should be considered falsey.
--- case
{
   "data" : {},
   "expected" : "[]",
   "template" : "[{{#missing}}Found key 'missing'!{{/missing}}]"
}

=== Implicit Iterator - String: Implicit iterators should directly interpolate strings.
--- case
{
   "data" : {
      "list" : [
         "a",
         "b",
         "c",
         "d",
         "e"
      ]
   },
   "expected" : "\"(a)(b)(c)(d)(e)\"",
   "template" : "\"{{#list}}({{.}}){{/list}}\""
}

=== Implicit Iterator - Integer: Implicit iterators should cast integers to strings and interpolate.
--- case
{
   "data" : {
      "list" : [
         1,
         2,
         3,
         4,
         5
      ]
   },
   "expected" : "\"(1)(2)(3)(4)(5)\"",
   "template" : "\"{{#list}}({{.}}){{/list}}\""
}

=== Implicit Iterator - Decimal: Implicit iterators should cast decimals to strings and interpolate.
--- case
{
   "data" : {
      "list" : [
         1.1,
         2.2,
         3.3,
         4.4,
         5.5
      ]
   },
   "expected" : "\"(1.1)(2.2)(3.3)(4.4)(5.5)\"",
   "template" : "\"{{#list}}({{.}}){{/list}}\""
}

=== Implicit Iterator - Array: Implicit iterators should allow iterating over nested arrays.
--- case
{
   "data" : {
      "list" : [
         [
            1,
            2,
            3
         ],
         [
            "a",
            "b",
            "c"
         ]
      ]
   },
   "expected" : "\"(123)(abc)\"",
   "template" : "\"{{#list}}({{#.}}{{.}}{{/.}}){{/list}}\""
}

=== Implicit Iterator - HTML Escaping: Implicit iterators with basic interpolation should be HTML escaped.
--- case
{
   "data" : {
      "list" : [
         "&",
         "\"",
         "<",
         ">"
      ]
   },
   "expected" : "\"(&amp;)(&quot;)(&lt;)(&gt;)\"",
   "template" : "\"{{#list}}({{.}}){{/list}}\""
}

=== Implicit Iterator - Triple mustache: Implicit iterators in triple mustache should interpolate without HTML escaping.
--- case
{
   "data" : {
      "list" : [
         "&",
         "\"",
         "<",
         ">"
      ]
   },
   "expected" : "\"(&)(\")(<)(>)\"",
   "template" : "\"{{#list}}({{{.}}}){{/list}}\""
}

=== Implicit Iterator - Ampersand: Implicit iterators in an Ampersand tag should interpolate without HTML escaping.
--- case
{
   "data" : {
      "list" : [
         "&",
         "\"",
         "<",
         ">"
      ]
   },
   "expected" : "\"(&)(\")(<)(>)\"",
   "template" : "\"{{#list}}({{&.}}){{/list}}\""
}

=== Implicit Iterator - Root-level: Implicit iterators should work on root-level lists.
--- case
{
   "data" : [
      {
         "value" : "a"
      },
      {
         "value" : "b"
      }
   ],
   "expected" : "\"(a)(b)\"",
   "template" : "\"{{#.}}({{value}}){{/.}}\""
}

=== Dotted Names - Truthy: Dotted names should be valid for Section tags.
--- case
{
   "data" : {
      "a" : {
         "b" : {
            "c" : true
         }
      }
   },
   "expected" : "\"Here\" == \"Here\"",
   "template" : "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"Here\""
}

=== Dotted Names - Falsey: Dotted names should be valid for Section tags.
--- case
{
   "data" : {
      "a" : {
         "b" : {
            "c" : false
         }
      }
   },
   "expected" : "\"\" == \"\"",
   "template" : "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\""
}

=== Dotted Names - Broken Chains: Dotted names that cannot be resolved should be considered falsey.
--- case
{
   "data" : {
      "a" : {}
   },
   "expected" : "\"\" == \"\"",
   "template" : "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\""
}

=== Surrounding Whitespace: Sections should not alter surrounding whitespace.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : " | \t|\t | \n",
   "template" : " | {{#boolean}}\t|\t{{/boolean}} | \n"
}

=== Internal Whitespace: Sections should not alter internal whitespace.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : " |  \n  | \n",
   "template" : " | {{#boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n"
}

=== Indented Inline Sections: Single-line sections should not alter surrounding whitespace.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : " YES\n GOOD\n",
   "template" : " {{#boolean}}YES{{/boolean}}\n {{#boolean}}GOOD{{/boolean}}\n"
}

=== Standalone Lines: Standalone lines should be removed from the template.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "| This Is\n|\n| A Line\n",
   "template" : "| This Is\n{{#boolean}}\n|\n{{/boolean}}\n| A Line\n"
}

=== Indented Standalone Lines: Indented standalone lines should be removed from the template.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "| This Is\n|\n| A Line\n",
   "template" : "| This Is\n  {{#boolean}}\n|\n  {{/boolean}}\n| A Line\n"
}

=== Standalone Line Endings: "\r\n" should be considered a newline for standalone tags.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "|\r\n|",
   "template" : "|\r\n{{#boolean}}\r\n{{/boolean}}\r\n|"
}

=== Standalone Without Previous Line: Standalone tags should not require a newline to precede them.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "#\n/",
   "template" : "  {{#boolean}}\n#{{/boolean}}\n/"
}

=== Standalone Without Newline: Standalone tags should not require a newline to follow them.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "#\n/\n",
   "template" : "#{{#boolean}}\n/\n  {{/boolean}}"
}

=== Padding: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "|=|",
   "template" : "|{{# boolean }}={{/ boolean }}|"
}

