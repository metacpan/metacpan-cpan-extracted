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
=== No Interpolation: Mustache-free templates should render as-is.
--- case
{
   "data" : {},
   "expected" : "Hello from {Mustache}!\n",
   "template" : "Hello from {Mustache}!\n"
}

=== Basic Interpolation: Unadorned tags should interpolate content into the template.
--- case
{
   "data" : {
      "subject" : "world"
   },
   "expected" : "Hello, world!\n",
   "template" : "Hello, {{subject}}!\n"
}

=== HTML Escaping: Basic interpolation should be HTML escaped.
--- case
{
   "data" : {
      "forbidden" : "& \" < >"
   },
   "expected" : "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n",
   "template" : "These characters should be HTML escaped: {{forbidden}}\n"
}

=== Triple Mustache: Triple mustaches should interpolate without HTML escaping.
--- case
{
   "data" : {
      "forbidden" : "& \" < >"
   },
   "expected" : "These characters should not be HTML escaped: & \" < >\n",
   "template" : "These characters should not be HTML escaped: {{{forbidden}}}\n"
}

=== Ampersand: Ampersand should interpolate without HTML escaping.
--- case
{
   "data" : {
      "forbidden" : "& \" < >"
   },
   "expected" : "These characters should not be HTML escaped: & \" < >\n",
   "template" : "These characters should not be HTML escaped: {{&forbidden}}\n"
}

=== Basic Integer Interpolation: Integers should interpolate seamlessly.
--- case
{
   "data" : {
      "mph" : 85
   },
   "expected" : "\"85 miles an hour!\"",
   "template" : "\"{{mph}} miles an hour!\""
}

=== Triple Mustache Integer Interpolation: Integers should interpolate seamlessly.
--- case
{
   "data" : {
      "mph" : 85
   },
   "expected" : "\"85 miles an hour!\"",
   "template" : "\"{{{mph}}} miles an hour!\""
}

=== Ampersand Integer Interpolation: Integers should interpolate seamlessly.
--- case
{
   "data" : {
      "mph" : 85
   },
   "expected" : "\"85 miles an hour!\"",
   "template" : "\"{{&mph}} miles an hour!\""
}

=== Basic Decimal Interpolation: Decimals should interpolate seamlessly with proper significance.
--- case
{
   "data" : {
      "power" : 1.21
   },
   "expected" : "\"1.21 jiggawatts!\"",
   "template" : "\"{{power}} jiggawatts!\""
}

=== Triple Mustache Decimal Interpolation: Decimals should interpolate seamlessly with proper significance.
--- case
{
   "data" : {
      "power" : 1.21
   },
   "expected" : "\"1.21 jiggawatts!\"",
   "template" : "\"{{{power}}} jiggawatts!\""
}

=== Ampersand Decimal Interpolation: Decimals should interpolate seamlessly with proper significance.
--- case
{
   "data" : {
      "power" : 1.21
   },
   "expected" : "\"1.21 jiggawatts!\"",
   "template" : "\"{{&power}} jiggawatts!\""
}

=== Basic Null Interpolation: Nulls should interpolate as the empty string.
--- case
{
   "data" : {
      "cannot" : null
   },
   "expected" : "I () be seen!",
   "template" : "I ({{cannot}}) be seen!"
}

=== Triple Mustache Null Interpolation: Nulls should interpolate as the empty string.
--- case
{
   "data" : {
      "cannot" : null
   },
   "expected" : "I () be seen!",
   "template" : "I ({{{cannot}}}) be seen!"
}

=== Ampersand Null Interpolation: Nulls should interpolate as the empty string.
--- case
{
   "data" : {
      "cannot" : null
   },
   "expected" : "I () be seen!",
   "template" : "I ({{&cannot}}) be seen!"
}

=== Basic Context Miss Interpolation: Failed context lookups should default to empty strings.
--- case
{
   "data" : {},
   "expected" : "I () be seen!",
   "template" : "I ({{cannot}}) be seen!"
}

=== Triple Mustache Context Miss Interpolation: Failed context lookups should default to empty strings.
--- case
{
   "data" : {},
   "expected" : "I () be seen!",
   "template" : "I ({{{cannot}}}) be seen!"
}

=== Ampersand Context Miss Interpolation: Failed context lookups should default to empty strings.
--- case
{
   "data" : {},
   "expected" : "I () be seen!",
   "template" : "I ({{&cannot}}) be seen!"
}

=== Dotted Names - Basic Interpolation: Dotted names should be considered a form of shorthand for sections.
--- case
{
   "data" : {
      "person" : {
         "name" : "Joe"
      }
   },
   "expected" : "\"Joe\" == \"Joe\"",
   "template" : "\"{{person.name}}\" == \"{{#person}}{{name}}{{/person}}\""
}

=== Dotted Names - Triple Mustache Interpolation: Dotted names should be considered a form of shorthand for sections.
--- case
{
   "data" : {
      "person" : {
         "name" : "Joe"
      }
   },
   "expected" : "\"Joe\" == \"Joe\"",
   "template" : "\"{{{person.name}}}\" == \"{{#person}}{{{name}}}{{/person}}\""
}

=== Dotted Names - Ampersand Interpolation: Dotted names should be considered a form of shorthand for sections.
--- case
{
   "data" : {
      "person" : {
         "name" : "Joe"
      }
   },
   "expected" : "\"Joe\" == \"Joe\"",
   "template" : "\"{{&person.name}}\" == \"{{#person}}{{&name}}{{/person}}\""
}

=== Dotted Names - Arbitrary Depth: Dotted names should be functional to any level of nesting.
--- case
{
   "data" : {
      "a" : {
         "b" : {
            "c" : {
               "d" : {
                  "e" : {
                     "name" : "Phil"
                  }
               }
            }
         }
      }
   },
   "expected" : "\"Phil\" == \"Phil\"",
   "template" : "\"{{a.b.c.d.e.name}}\" == \"Phil\""
}

=== Dotted Names - Broken Chains: Any falsey value prior to the last part of the name should yield ''.
--- case
{
   "data" : {
      "a" : {}
   },
   "expected" : "\"\" == \"\"",
   "template" : "\"{{a.b.c}}\" == \"\""
}

=== Dotted Names - Broken Chain Resolution: Each part of a dotted name should resolve only against its parent.
--- case
{
   "data" : {
      "a" : {
         "b" : {}
      },
      "c" : {
         "name" : "Jim"
      }
   },
   "expected" : "\"\" == \"\"",
   "template" : "\"{{a.b.c.name}}\" == \"\""
}

=== Dotted Names - Initial Resolution: The first part of a dotted name should resolve as any other name.
--- case
{
   "data" : {
      "a" : {
         "b" : {
            "c" : {
               "d" : {
                  "e" : {
                     "name" : "Phil"
                  }
               }
            }
         }
      },
      "b" : {
         "c" : {
            "d" : {
               "e" : {
                  "name" : "Wrong"
               }
            }
         }
      }
   },
   "expected" : "\"Phil\" == \"Phil\"",
   "template" : "\"{{#a}}{{b.c.d.e.name}}{{/a}}\" == \"Phil\""
}

=== Dotted Names - Context Precedence: Dotted names should be resolved against former resolutions.
--- case
{
   "data" : {
      "a" : {
         "b" : {}
      },
      "b" : {
         "c" : "ERROR"
      }
   },
   "expected" : "",
   "template" : "{{#a}}{{b.c}}{{/a}}"
}

=== Implicit Iterators - Basic Interpolation: Unadorned tags should interpolate content into the template.
--- case
{
   "data" : "world",
   "expected" : "Hello, world!\n",
   "template" : "Hello, {{.}}!\n"
}

=== Implicit Iterators - HTML Escaping: Basic interpolation should be HTML escaped.
--- case
{
   "data" : "& \" < >",
   "expected" : "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n",
   "template" : "These characters should be HTML escaped: {{.}}\n"
}

=== Implicit Iterators - Triple Mustache: Triple mustaches should interpolate without HTML escaping.
--- case
{
   "data" : "& \" < >",
   "expected" : "These characters should not be HTML escaped: & \" < >\n",
   "template" : "These characters should not be HTML escaped: {{{.}}}\n"
}

=== Implicit Iterators - Ampersand: Ampersand should interpolate without HTML escaping.
--- case
{
   "data" : "& \" < >",
   "expected" : "These characters should not be HTML escaped: & \" < >\n",
   "template" : "These characters should not be HTML escaped: {{&.}}\n"
}

=== Implicit Iterators - Basic Integer Interpolation: Integers should interpolate seamlessly.
--- case
{
   "data" : 85,
   "expected" : "\"85 miles an hour!\"",
   "template" : "\"{{.}} miles an hour!\""
}

=== Interpolation - Surrounding Whitespace: Interpolation should not alter surrounding whitespace.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "| --- |",
   "template" : "| {{string}} |"
}

=== Triple Mustache - Surrounding Whitespace: Interpolation should not alter surrounding whitespace.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "| --- |",
   "template" : "| {{{string}}} |"
}

=== Ampersand - Surrounding Whitespace: Interpolation should not alter surrounding whitespace.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "| --- |",
   "template" : "| {{&string}} |"
}

=== Interpolation - Standalone: Standalone interpolation should not alter surrounding whitespace.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "  ---\n",
   "template" : "  {{string}}\n"
}

=== Triple Mustache - Standalone: Standalone interpolation should not alter surrounding whitespace.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "  ---\n",
   "template" : "  {{{string}}}\n"
}

=== Ampersand - Standalone: Standalone interpolation should not alter surrounding whitespace.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "  ---\n",
   "template" : "  {{&string}}\n"
}

=== Interpolation With Padding: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "|---|",
   "template" : "|{{ string }}|"
}

=== Triple Mustache With Padding: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "|---|",
   "template" : "|{{{ string }}}|"
}

=== Ampersand With Padding: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "string" : "---"
   },
   "expected" : "|---|",
   "template" : "|{{& string }}|"
}

