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
=== Inline: Comment blocks should be removed from the template.
--- case
{
   "data" : {},
   "expected" : "1234567890",
   "template" : "12345{{! Comment Block! }}67890"
}

=== Multiline: Multiline comments should be permitted.
--- case
{
   "data" : {},
   "expected" : "1234567890\n",
   "template" : "12345{{!\n  This is a\n  multi-line comment...\n}}67890\n"
}

=== Standalone: All standalone comment lines should be removed.
--- case
{
   "data" : {},
   "expected" : "Begin.\nEnd.\n",
   "template" : "Begin.\n{{! Comment Block! }}\nEnd.\n"
}

=== Indented Standalone: All standalone comment lines should be removed.
--- case
{
   "data" : {},
   "expected" : "Begin.\nEnd.\n",
   "template" : "Begin.\n  {{! Indented Comment Block! }}\nEnd.\n"
}

=== Standalone Line Endings: "\r\n" should be considered a newline for standalone tags.
--- case
{
   "data" : {},
   "expected" : "|\r\n|",
   "template" : "|\r\n{{! Standalone Comment }}\r\n|"
}

=== Standalone Without Previous Line: Standalone tags should not require a newline to precede them.
--- case
{
   "data" : {},
   "expected" : "!",
   "template" : "  {{! I'm Still Standalone }}\n!"
}

=== Standalone Without Newline: Standalone tags should not require a newline to follow them.
--- case
{
   "data" : {},
   "expected" : "!\n",
   "template" : "!\n  {{! I'm Still Standalone }}"
}

=== Multiline Standalone: All standalone comment lines should be removed.
--- case
{
   "data" : {},
   "expected" : "Begin.\nEnd.\n",
   "template" : "Begin.\n{{!\nSomething's going on here...\n}}\nEnd.\n"
}

=== Indented Multiline Standalone: All standalone comment lines should be removed.
--- case
{
   "data" : {},
   "expected" : "Begin.\nEnd.\n",
   "template" : "Begin.\n  {{!\n    Something's going on here...\n  }}\nEnd.\n"
}

=== Indented Inline: Inline comments should not strip whitespace
--- case
{
   "data" : {},
   "expected" : "  12 \n",
   "template" : "  12 {{! 34 }}\n"
}

=== Surrounding Whitespace: Comment removal should preserve surrounding whitespace.
--- case
{
   "data" : {},
   "expected" : "12345  67890",
   "template" : "12345 {{! Comment Block! }} 67890"
}

=== Variable Name Collision: Comments must never render, even if variable with same name exists.
--- case
{
   "data" : {
      "! comment" : 1,
      "! comment " : 2,
      "!comment" : 3,
      "comment" : 4
   },
   "expected" : "comments never show: ><",
   "template" : "comments never show: >{{! comment }}<"
}

