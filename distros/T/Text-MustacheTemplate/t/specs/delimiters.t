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
=== Pair Behavior: The equals sign (used on both sides) should permit delimiter changes.
--- case
{
   "data" : {
      "text" : "Hey!"
   },
   "expected" : "(Hey!)",
   "template" : "{{=<% %>=}}(<%text%>)"
}

=== Special Characters: Characters with special meaning regexen should be valid delimiters.
--- case
{
   "data" : {
      "text" : "It worked!"
   },
   "expected" : "(It worked!)",
   "template" : "({{=[ ]=}}[text])"
}

=== Sections: Delimiters set outside sections should persist.
--- case
{
   "data" : {
      "data" : "I got interpolated.",
      "section" : true
   },
   "expected" : "[\n  I got interpolated.\n  |data|\n\n  {{data}}\n  I got interpolated.\n]\n",
   "template" : "[\n{{#section}}\n  {{data}}\n  |data|\n{{/section}}\n\n{{= | | =}}\n|#section|\n  {{data}}\n  |data|\n|/section|\n]\n"
}

=== Inverted Sections: Delimiters set outside inverted sections should persist.
--- case
{
   "data" : {
      "data" : "I got interpolated.",
      "section" : false
   },
   "expected" : "[\n  I got interpolated.\n  |data|\n\n  {{data}}\n  I got interpolated.\n]\n",
   "template" : "[\n{{^section}}\n  {{data}}\n  |data|\n{{/section}}\n\n{{= | | =}}\n|^section|\n  {{data}}\n  |data|\n|/section|\n]\n"
}

=== Partial Inheritence: Delimiters set in a parent template should not affect a partial.
--- case
{
   "data" : {
      "value" : "yes"
   },
   "expected" : "[ .yes. ]\n[ .yes. ]\n",
   "partials" : {
      "include" : ".{{value}}."
   },
   "template" : "[ {{>include}} ]\n{{= | | =}}\n[ |>include| ]\n"
}

=== Post-Partial Behavior: Delimiters set in a partial should not affect the parent template.
--- case
{
   "data" : {
      "value" : "yes"
   },
   "expected" : "[ .yes.  .yes. ]\n[ .yes.  .|value|. ]\n",
   "partials" : {
      "include" : ".{{value}}. {{= | | =}} .|value|."
   },
   "template" : "[ {{>include}} ]\n[ .{{value}}.  .|value|. ]\n"
}

=== Surrounding Whitespace: Surrounding whitespace should be left untouched.
--- case
{
   "data" : {},
   "expected" : "|  |",
   "template" : "| {{=@ @=}} |"
}

=== Outlying Whitespace (Inline): Whitespace should be left untouched.
--- case
{
   "data" : {},
   "expected" : " | \n",
   "template" : " | {{=@ @=}}\n"
}

=== Standalone Tag: Standalone lines should be removed from the template.
--- case
{
   "data" : {},
   "expected" : "Begin.\nEnd.\n",
   "template" : "Begin.\n{{=@ @=}}\nEnd.\n"
}

=== Indented Standalone Tag: Indented standalone lines should be removed from the template.
--- case
{
   "data" : {},
   "expected" : "Begin.\nEnd.\n",
   "template" : "Begin.\n  {{=@ @=}}\nEnd.\n"
}

=== Standalone Line Endings: "\r\n" should be considered a newline for standalone tags.
--- case
{
   "data" : {},
   "expected" : "|\r\n|",
   "template" : "|\r\n{{= @ @ =}}\r\n|"
}

=== Standalone Without Previous Line: Standalone tags should not require a newline to precede them.
--- case
{
   "data" : {},
   "expected" : "=",
   "template" : "  {{=@ @=}}\n="
}

=== Standalone Without Newline: Standalone tags should not require a newline to follow them.
--- case
{
   "data" : {},
   "expected" : "=\n",
   "template" : "=\n  {{=@ @=}}"
}

=== Pair with Padding: Superfluous in-tag whitespace should be ignored.
--- case
{
   "data" : {},
   "expected" : "||",
   "template" : "|{{= @   @ =}}|"
}

