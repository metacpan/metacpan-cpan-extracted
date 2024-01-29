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
=== Falsey: Falsey sections should have their contents rendered.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "\"This should be rendered.\"",
   "template" : "\"{{^boolean}}This should be rendered.{{/boolean}}\""
}

=== Truthy: Truthy sections should have their contents omitted.
--- case
{
   "data" : {
      "boolean" : true
   },
   "expected" : "\"\"",
   "template" : "\"{{^boolean}}This should not be rendered.{{/boolean}}\""
}

=== Null is falsey: Null is falsey.
--- case
{
   "data" : {
      "null" : null
   },
   "expected" : "\"This should be rendered.\"",
   "template" : "\"{{^null}}This should be rendered.{{/null}}\""
}

=== Context: Objects and hashes should behave like truthy values.
--- case
{
   "data" : {
      "context" : {
         "name" : "Joe"
      }
   },
   "expected" : "\"\"",
   "template" : "\"{{^context}}Hi {{name}}.{{/context}}\""
}

=== List: Lists should behave like truthy values.
--- case
{
   "data" : {
      "list" : [
         {
            "n" : 1
         },
         {
            "n" : 2
         },
         {
            "n" : 3
         }
      ]
   },
   "expected" : "\"\"",
   "template" : "\"{{^list}}{{n}}{{/list}}\""
}

=== Empty List: Empty lists should behave like falsey values.
--- case
{
   "data" : {
      "list" : []
   },
   "expected" : "\"Yay lists!\"",
   "template" : "\"{{^list}}Yay lists!{{/list}}\""
}

=== Doubled: Multiple inverted sections per template should be permitted.
--- case
{
   "data" : {
      "bool" : false,
      "two" : "second"
   },
   "expected" : "* first\n* second\n* third\n",
   "template" : "{{^bool}}\n* first\n{{/bool}}\n* {{two}}\n{{^bool}}\n* third\n{{/bool}}\n"
}

=== Nested (Falsey): Nested falsey sections should have their contents rendered.
--- case
{
   "data" : {
      "bool" : false
   },
   "expected" : "| A B C D E |",
   "template" : "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"
}

=== Nested (Truthy): Nested truthy sections should be omitted.
--- case
{
   "data" : {
      "bool" : true
   },
   "expected" : "| A  E |",
   "template" : "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"
}

=== Context Misses: Failed context lookups should be considered falsey.
--- case
{
   "data" : {},
   "expected" : "[Cannot find key 'missing'!]",
   "template" : "[{{^missing}}Cannot find key 'missing'!{{/missing}}]"
}

=== Dotted Names - Truthy: Dotted names should be valid for Inverted Section tags.
--- case
{
   "data" : {
      "a" : {
         "b" : {
            "c" : true
         }
      }
   },
   "expected" : "\"\" == \"\"",
   "template" : "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"\""
}

=== Dotted Names - Falsey: Dotted names should be valid for Inverted Section tags.
--- case
{
   "data" : {
      "a" : {
         "b" : {
            "c" : false
         }
      }
   },
   "expected" : "\"Not Here\" == \"Not Here\"",
   "template" : "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""
}

=== Dotted Names - Broken Chains: Dotted names that cannot be resolved should be considered falsey.
--- case
{
   "data" : {
      "a" : {}
   },
   "expected" : "\"Not Here\" == \"Not Here\"",
   "template" : "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""
}

=== Surrounding Whitespace: Inverted sections should not alter surrounding whitespace.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : " | \t|\t | \n",
   "template" : " | {{^boolean}}\t|\t{{/boolean}} | \n"
}

=== Internal Whitespace: Inverted should not alter internal whitespace.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : " |  \n  | \n",
   "template" : " | {{^boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n"
}

=== Indented Inline Sections: Single-line sections should not alter surrounding whitespace.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : " NO\n WAY\n",
   "template" : " {{^boolean}}NO{{/boolean}}\n {{^boolean}}WAY{{/boolean}}\n"
}

=== Standalone Lines: Standalone lines should be removed from the template.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "| This Is\n|\n| A Line\n",
   "template" : "| This Is\n{{^boolean}}\n|\n{{/boolean}}\n| A Line\n"
}

=== Standalone Indented Lines: Standalone indented lines should be removed from the template.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "| This Is\n|\n| A Line\n",
   "template" : "| This Is\n  {{^boolean}}\n|\n  {{/boolean}}\n| A Line\n"
}

=== Standalone Line Endings: "\r\n" should be considered a newline for standalone tags.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "|\r\n|",
   "template" : "|\r\n{{^boolean}}\r\n{{/boolean}}\r\n|"
}

=== Standalone Without Previous Line: Standalone tags should not require a newline to precede them.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "^\n/",
   "template" : "  {{^boolean}}\n^{{/boolean}}\n/"
}

=== Standalone Without Newline: Standalone tags should not require a newline to follow them.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "^\n/\n",
   "template" : "^{{^boolean}}\n/\n  {{/boolean}}"
}

=== Padding: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {
      "boolean" : false
   },
   "expected" : "|=|",
   "template" : "|{{^ boolean }}={{/ boolean }}|"
}

