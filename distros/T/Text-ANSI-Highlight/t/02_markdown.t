use v5.16;
use warnings;
use utf8;
use Test::More 0.98;

use lib 't/lib';
use Highlighters;

use Text::ANSI::Highlight;

my @highlighter = Highlighters::available();
plan skip_all => 'no highlighter is installed' unless @highlighter;

my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };

my $md = <<'END';
# Title

Some *text* and `code`.

```perl
my $x = 1; # perl
__DATA__
foo
```

After the block: f() { echo; }

~~~bash
f() { echo "$HOME"; } # sh
[[ $a == b ]] && f # sh
~~~

   ````c
   int x = 1; /* ``` in a longer fence */
   ````

```
no language
```

```nosuchlanguage
foo bar
```

## Last
END

for my $name (@highlighter) {
    my $hl = Text::ANSI::Highlight->new(with => $name);
    # the text around the code is colored when the highlighter knows
    # Markdown
    my $prose = $name ne 'sourcehighlight';

    subtest "$name: Markdown" => sub {
        my $out = $hl->markdown($md);
        is $text->($out), $md, 'the text is the same';
        my @line = split /^/, $out;
        my %at = map { $text->($line[$_]) => $line[$_] } keys @line;
        for ("```perl\n", "```\n", "~~~bash\n", "~~~\n", "   ````c\n", "   ````\n",
             "no language\n", "foo bar\n") {
            is $at{$_}, $_, 'as it is: ' . s/\n//r;
        }
        for ("my \$x = 1; # perl\n", "f() { echo \"\$HOME\"; } # sh\n",
             "[[ \$a == b ]] && f # sh\n", "   int x = 1; /* ``` in a longer fence */\n") {
            like $at{$_}, qr/\e\[[\d;]*[1-9]/, 'code, colored: ' . s/\n//r;
        }
        if ($prose) {
            like $at{"# Title\n"}, qr/\A\e\[[\d;]+m# Title\e\[0m\n\z/, 'the heading at the top';
            like $at{"## Last\n"}, qr/\A\e\[[\d;]+m## Last\e\[0m\n\z/,
                'the heading after all the code is a heading';
            is $at{"After the block: f() { echo; }\n"}, "After the block: f() { echo; }\n",
                'the text after the code is not code';
        } else {
            is $at{$_}, $_, 'as it is: ' . s/\n//r for "# Title\n", "## Last\n";
        }
    };

    subtest "$name: Markdown, the edges" => sub {
        if ($prose) {
            my $plain = $hl->markdown("# Title\n\ntext only\n");
            like $plain, qr/\e\[[\d;]+m# Title\e\[0m/, 'no code: the text is colored';
            is $text->($plain), "# Title\n\ntext only\n", 'no code: the text is the same';
        } else {
            is $hl->markdown("# Title\n\ntext only\n"), undef, 'no code: nothing is colored';
        }

        # The text which has a fence is not given as Markdown: the
        # fence would be taken as the beginning of code
        my $open = "# Title\n\n```perl\nmy \$x; # c\n```\n\n## Middle\n\n```c\nint x;\n";
        my $o = $hl->markdown($open);
        is $text->($o), $open, 'a fence which is not closed: the text is the same';
        like $o, qr/^## Middle\n\n```c\nint x;\n\z/m, 'the text with it is as it is';

        is $hl->markdown("# Title\n\n~~~\n"), undef, 'only a fence which is not closed';
        is $hl->markdown(""), undef, 'empty';

        # front matter which is not closed would take all the text
        my $rule = "---\n\ntext\n\n```c\nint x; /* c */\n```\n";
        my $r = $hl->markdown($rule);
        is $text->($r), $rule, 'a rule at the top: the text is the same';
        like $r, qr/\A---\n\ntext\n\n```c\n\e/, 'and it is as it is';

        # Markdown in a fence of Markdown
        my $nested = "````markdown\n# Inner\n\n```c\nint x; /* c */\n```\n````\n";
        my $n = $hl->markdown($nested);
        is $text->($n), $nested, 'Markdown in a fence: the text is the same';
        like $n, qr/^\e\[[\d;]+mint\e/m, 'the code in it is colored';

        my $wide = "# 見出し\n\n```perl\nmy \$x = 'あ'; # い\n```\n";
        my $w = $hl->markdown($wide);
        is $text->($w), $wide, 'wide characters';

        my $crlf = "# Title\r\n\r\n```c\r\nint x; /* c */\r\n```\r\n";
        my $c = $hl->markdown($crlf);
        is $text->($c), $crlf, 'CRLF: the text is the same';
    };

    # Markdown in fences of Markdown, and blocks given to highlight,
    # go to the highlighter with the rest: it is called once
    subtest "$name: the highlighter is called once" => sub {
        my $calls = 0;
        no strict 'refs';
        no warnings 'redefine';
        my $func = "Text::ANSI::Highlight::${name}::highlight";
        my $orig = \&$func;
        local *$func = sub { $calls++; goto &$orig };
        my $inner = "# Inner\n\n```c\nint x; /* c */\n```\n";
        my $doc = "# Top\n\n````markdown\n$inner````\n\ntext\n\n"
            . "````md\n$inner````\n\n```perl\nmy \$x; # c\n```\n";
        my $out = $hl->markdown($doc);
        is $text->($out), $doc, 'markdown: the text is the same';
        is scalar(() = $out =~ /^\e\[[\d;]+mint\e/mg), 2, 'markdown: the code in both';
        is $calls, 1, 'markdown: one call';

        $calls = 0;
        my @out = $hl->highlight([ markdown => $inner ], [ c => "int y; /* c */\n" ],
                                 [ md => $inner ], [ perl => "my \$x; # c\n" ]);
        is scalar(grep { defined } @out), 4, 'highlight: all colored';
        is $text->($out[0]), $inner, 'highlight: the text of Markdown is the same';
        like $out[2], qr/^\e\[[\d;]+mint\e/m, 'highlight: the code in Markdown';
        is $calls, 1, 'highlight: one call';
    };

    subtest "$name: Markdown by highlight, file and text" => sub {
        my($out) = $hl->highlight([ markdown => $md ]);
        is $text->($out), $md, 'highlight with the language markdown';
        is $text->($hl->text($md, name => 'README.md')), $md, 'text with the name of a file';
        is $text->($hl->text($md, language => 'md')), $md, 'text with the language';
    };
}

# A class in braces is the language, as pandoc takes it
subtest 'a class in braces' => sub {
    plan skip_all => 'no highlighter is installed' unless Highlighters::available();
    my $hl = Text::ANSI::Highlight->new((Highlighters::available())[0]);
    my $doc = "```{.c .numberLines}\nint x; /* c */\n```\n";
    my $out = $hl->markdown($doc);
    is $text->($out // ''), $doc, 'the text is the same';
    like $out // '', qr/\e\[[\d;]+mint\e/, 'colored';
};

done_testing;
