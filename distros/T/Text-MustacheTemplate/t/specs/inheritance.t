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
=== Default: Default content should be rendered if the block isn't overridden
--- case
{
   "data" : {},
   "expected" : "Default title\n",
   "template" : "{{$title}}Default title{{/title}}\n"
}

=== Variable: Default content renders variables
--- case
{
   "data" : {
      "bar" : "baz"
   },
   "expected" : "default baz content\n",
   "template" : "{{$foo}}default {{bar}} content{{/foo}}\n"
}

=== Triple Mustache: Default content renders triple mustache variables
--- case
{
   "data" : {
      "bar" : "<baz>"
   },
   "expected" : "default <baz> content\n",
   "template" : "{{$foo}}default {{{bar}}} content{{/foo}}\n"
}

=== Sections: Default content renders sections
--- case
{
   "data" : {
      "bar" : {
         "baz" : "qux"
      }
   },
   "expected" : "default qux content\n",
   "template" : "{{$foo}}default {{#bar}}{{baz}}{{/bar}} content{{/foo}}\n"
}

=== Negative Sections: Default content renders negative sections
--- case
{
   "data" : {
      "baz" : "three"
   },
   "expected" : "default three content\n",
   "template" : "{{$foo}}default {{^bar}}{{baz}}{{/bar}} content{{/foo}}\n"
}

=== Mustache Injection: Mustache injection in default content
--- case
{
   "data" : {
      "bar" : {
         "baz" : "{{qux}}"
      }
   },
   "expected" : "default {{qux}} content\n",
   "template" : "{{$foo}}default {{#bar}}{{baz}}{{/bar}} content{{/foo}}\n"
}

=== Inherit: Default content rendered inside inherited templates
--- case
{
   "data" : {},
   "expected" : "default content",
   "partials" : {
      "include" : "{{$foo}}default content{{/foo}}"
   },
   "template" : "{{<include}}{{/include}}\n"
}

=== Overridden content: Overridden content
--- case
{
   "data" : {},
   "expected" : "...sub template title...",
   "partials" : {
      "super" : "...{{$title}}Default title{{/title}}..."
   },
   "template" : "{{<super}}{{$title}}sub template title{{/title}}{{/super}}"
}

=== Data does not override block: Context does not override argument passed into parent
--- case
{
   "data" : {
      "var" : "var in data"
   },
   "expected" : "var in template",
   "partials" : {
      "include" : "{{$var}}var in include{{/var}}"
   },
   "template" : "{{<include}}{{$var}}var in template{{/var}}{{/include}}"
}

=== Data does not override block default: Context does not override default content of block
--- case
{
   "data" : {
      "var" : "var in data"
   },
   "expected" : "var in include",
   "partials" : {
      "include" : "{{$var}}var in include{{/var}}"
   },
   "template" : "{{<include}}{{/include}}"
}

=== Overridden parent: Overridden parent
--- case
{
   "data" : {},
   "expected" : "test override",
   "partials" : {
      "parent" : "{{$stuff}}...{{/stuff}}"
   },
   "template" : "test {{<parent}}{{$stuff}}override{{/stuff}}{{/parent}}"
}

=== Two overridden parents: Two overridden parents with different content
--- case
{
   "data" : {},
   "expected" : "test |override1 default| |override2 default|\n",
   "partials" : {
      "parent" : "|{{$stuff}}...{{/stuff}}{{$default}} default{{/default}}|"
   },
   "template" : "test {{<parent}}{{$stuff}}override1{{/stuff}}{{/parent}} {{<parent}}{{$stuff}}override2{{/stuff}}{{/parent}}\n"
}

=== Override parent with newlines: Override parent with newlines
--- case
{
   "data" : {},
   "expected" : "peaked\n\n:(\n",
   "partials" : {
      "parent" : "{{$ballmer}}peaking{{/ballmer}}"
   },
   "template" : "{{<parent}}{{$ballmer}}\npeaked\n\n:(\n{{/ballmer}}{{/parent}}"
}

=== Inherit indentation: Inherit indentation when overriding a parent
--- case
{
   "data" : {},
   "expected" : "stop:\n  hammer time\n",
   "partials" : {
      "parent" : "stop:\n  {{$nineties}}collaborate and listen{{/nineties}}\n"
   },
   "template" : "{{<parent}}{{$nineties}}hammer time{{/nineties}}{{/parent}}"
}

=== Only one override: Override one parameter but not the other
--- case
{
   "data" : {},
   "expected" : "new default one, override two",
   "partials" : {
      "parent" : "{{$stuff}}new default one{{/stuff}}, {{$stuff2}}new default two{{/stuff2}}"
   },
   "template" : "{{<parent}}{{$stuff2}}override two{{/stuff2}}{{/parent}}"
}

=== Parent template: Parent templates behave identically to partials when called with no parameters
--- case
{
   "data" : {},
   "expected" : "default content|default content",
   "partials" : {
      "parent" : "{{$foo}}default content{{/foo}}"
   },
   "template" : "{{>parent}}|{{<parent}}{{/parent}}"
}

=== Recursion: Recursion in inherited templates
--- case
{
   "data" : {},
   "expected" : "override override override don't recurse",
   "partials" : {
      "parent" : "{{$foo}}default content{{/foo}} {{$bar}}{{<parent2}}{{/parent2}}{{/bar}}",
      "parent2" : "{{$foo}}parent2 default content{{/foo}} {{<parent}}{{$bar}}don't recurse{{/bar}}{{/parent}}"
   },
   "template" : "{{<parent}}{{$foo}}override{{/foo}}{{/parent}}"
}

=== Multi-level inheritance: Top-level substitutions take precedence in multi-level inheritance
--- case
{
   "data" : {},
   "expected" : "c",
   "partials" : {
      "grandParent" : "{{$a}}g{{/a}}",
      "older" : "{{<grandParent}}{{$a}}o{{/a}}{{/grandParent}}",
      "parent" : "{{<older}}{{$a}}p{{/a}}{{/older}}"
   },
   "template" : "{{<parent}}{{$a}}c{{/a}}{{/parent}}"
}

=== Multi-level inheritance, no sub child: Top-level substitutions take precedence in multi-level inheritance
--- case
{
   "data" : {},
   "expected" : "p",
   "partials" : {
      "grandParent" : "{{$a}}g{{/a}}",
      "older" : "{{<grandParent}}{{$a}}o{{/a}}{{/grandParent}}",
      "parent" : "{{<older}}{{$a}}p{{/a}}{{/older}}"
   },
   "template" : "{{<parent}}{{/parent}}"
}

=== Text inside parent: Ignores text inside parent templates, but does parse $ tags
--- case
{
   "data" : {},
   "expected" : "hmm",
   "partials" : {
      "parent" : "{{$foo}}default content{{/foo}}"
   },
   "template" : "{{<parent}} asdfasd {{$foo}}hmm{{/foo}} asdfasdfasdf {{/parent}}"
}

=== Text inside parent: Allows text inside a parent tag, but ignores it
--- case
{
   "data" : {},
   "expected" : "default content",
   "partials" : {
      "parent" : "{{$foo}}default content{{/foo}}"
   },
   "template" : "{{<parent}} asdfasd asdfasdfasdf {{/parent}}"
}

=== Block scope: Scope of a substituted block is evaluated in the context of the parent template
--- case
{
   "data" : {
      "fruit" : "apples",
      "nested" : {
         "fruit" : "bananas"
      }
   },
   "expected" : "I say bananas.",
   "partials" : {
      "parent" : "{{#nested}}{{$block}}You say {{fruit}}.{{/block}}{{/nested}}"
   },
   "template" : "{{<parent}}{{$block}}I say {{fruit}}.{{/block}}{{/parent}}"
}

