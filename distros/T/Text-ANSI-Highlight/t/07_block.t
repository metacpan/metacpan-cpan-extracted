use v5.16;
use warnings;
use utf8;
use Test::More 0.98;

use lib 't/lib';
use Highlighters;

use Text::ANSI::Highlight;
use Text::ANSI::Highlight::Block::embedz;

my $text = sub { $_[0] =~ s/\e\[[0-9;]*m//gr };

# The parts of a block of pandoc-embedz: the texts of the parts are
# the text of the block, and each has its language
subtest 'embedz: parts' => sub {
    my $parts = sub {
        my($info, $text) = @_;
        my @part = Text::ANSI::Highlight::Block::embedz::parts($info, $text);
        is join('', map { $_->[1] } @part), $text, "$info: the text is the same";
        [ map { $_->[0] // '-' } @part ];
    };
    my $yaml = "data: a.csv\nwith:\n  n: 1\n";
    my $tmpl = "{% for r in data %}\n- {{ r.name }}\n{% endfor %}\n";
    my $csv  = "name,value\nA,1\n";

    is_deeply $parts->('embedz', "---\n$yaml---\n$tmpl---\n$csv"),
        [ qw(- yaml - jinja - -) ], 'three sections, no format';
    is_deeply $parts->('embedz', "---\nformat: csv\n---\n$tmpl---\n$csv"),
        [ qw(- yaml - jinja - -) ], 'the format in YAML: CSV has no language';
    is_deeply $parts->('{.embedz format=json}', "---\n$yaml---\n$tmpl---\n[1]\n"),
        [ qw(- yaml - jinja - json) ], 'the format in the attributes';
    is_deeply $parts->('embedz', "---\n$yaml---\n$tmpl"),
        [ qw(- yaml - jinja) ], 'two sections';
    is_deeply $parts->('embedz', "---\nglobal:\n  a: 1\n---\n"),
        [ qw(- yaml -) ], 'YAML only';
    is_deeply $parts->('embedz', "---\n$yaml"),
        [ qw(- yaml) ], 'YAML which is not closed';
    is_deeply $parts->('{.embedz as=t format=json}', "---\n$yaml---\n[1]\n"),
        [ qw(- yaml - json) ], 'as: the section after YAML is the data';
    is_deeply $parts->('embedz', "---\ntemplate: t\nformat: json\n---\n---\n[1]\n"),
        [ qw(- yaml - - json) ], 'template in YAML, empty template';

    # without the separator, by the attributes
    is_deeply $parts->('{.embedz define=棒グラフ}', $tmpl), [ 'jinja' ], 'define';
    is_deeply $parts->('{.embedz data=a.csv as=t}', $yaml), [ 'yaml' ], 'data and as';
    is_deeply $parts->('{.embedz data=a.csv template=t}', $yaml), [ 'yaml' ], 'data and template';
    is_deeply $parts->('{.embedz as=t format=toml}', "a = 1\n"), [ 'toml' ], 'as: the data';
    is_deeply $parts->('{.embedz as=t}', $csv), [ '-' ], 'as: the data of no format';
    is_deeply $parts->('{.embedz data=a.csv}', $tmpl), [ 'jinja' ], 'data';
    is_deeply $parts->('{.embedz}', $tmpl), [ 'jinja' ], 'no attribute';
    is_deeply $parts->('embedz', $tmpl), [ 'jinja' ], 'the name only';
    is_deeply $parts->('embedz', ''), [], 'empty';
};

# the parts by the class method, with the labels
subtest 'parts' => sub {
    my @part = Text::ANSI::Highlight->parts('embedz', "---\na: 1\n---\n{{ a }}\n---\nx\n");
    is_deeply [ map { $_->[2] } @part ],
        [ undef, 'config', undef, 'template', undef, 'data' ], 'the labels of embedz';
    is_deeply [ Text::ANSI::Highlight->parts('{.embedz as=t}', "x\n") ],
        [ [ undef, "x\n", 'data' ] ], 'one part with a label';
    is_deeply [ Text::ANSI::Highlight->parts('{.perl .numberLines}', "my \$x;\n") ],
        [ [ 'perl', "my \$x;\n" ] ], 'a block which has no module is one part';
    is_deeply [ Text::ANSI::Highlight->parts('', "x\n") ], [ [ '', "x\n" ] ], 'no name';
    is_deeply [ Text::ANSI::Highlight->parts(undef, "x\n") ], [ [ '', "x\n" ] ], 'undef';
};

my @highlighter = grep { Text::ANSI::Highlight->new($_)->language('yaml') }
    Highlighters::available();

SKIP: {
    skip 'no highlighter which knows YAML is installed', 1 unless @highlighter;
    for my $name (@highlighter) {
        my $hl = Text::ANSI::Highlight->new($name);
        subtest "$name: a block of embedz in Markdown" => sub {
            my $calls = 0;
            no strict 'refs';
            no warnings 'redefine';
            my $func = "Text::ANSI::Highlight::${name}::highlight";
            my $orig = \&$func;
            local *$func = sub { $calls++; goto &$orig };

            my $doc = "# Title\n\n"
                . "```{.embedz define=棒グラフ}\n{# c #}\n{% for r in data %}\n- {{ r.name }}\n{% endfor %}\n```\n\n"
                . "```embedz\n---\ndata: a.csv\nwith:\n  n: 1\n---\n{{ n }}\n```\n\n"
                . "```perl\nmy \$x; # c\n```\n";
            # whether a template is colored, and which words of it,
            # depends on the highlighter and its version: ask it
            my $jinja = defined(($hl->highlight([ jinja => "{% for r in data %}\n" ]))[0]);
            $calls = 0;
            my $out = $hl->markdown($doc);
            is $text->($out), $doc, 'the text is the same';
            like $out, qr/^\e\[[\d;]+mdata\e/m, 'YAML is colored';
            like $out, qr/^(?:\e\[[\d;]*m)+\{% for|\e\[[\d;]+mfor\e/m, 'the template is colored'
                if $jinja;
            like $out, qr/^---$/m, 'the separator is as it is';
            like $out, qr/^```\{\.embedz define=棒グラフ\}$/m, 'the fence is as it is';
            like $out, qr/^\e\[[\d;]+mmy\e/m, 'the other code is colored';
            is $calls, 1, 'one call';

            # the line of the fence can be given to highlight
            my @out = $hl->highlight(
                [ '{.embedz define=t}' => "{% for r in data %}\n{% endfor %}\n" ],
                [ 'embedz' => "---\ndata: a.csv\n---\n{{ n }}\n" ],
                [ '{.c .numberLines}' => "int x; /* c */\n" ],
                [ '{.embedz as=t}' => "a,b\n" ]);
            if ($jinja) {
                like $out[0], qr/\e\[[\d;]*[1-9]/, 'highlight: the template';
                is $text->($out[0]), "{% for r in data %}\n{% endfor %}\n", 'highlight: its text is the same';
            } else {
                is $out[0], undef, 'highlight: a template which the highlighter does not color';
            }
            like $out[1], qr/^---\n\e\[[\d;]+mdata\e/, 'highlight: YAML';
            like $out[2], qr/\e\[[\d;]+mint\e/, 'highlight: a class in braces';
            is $out[3], undef, 'highlight: nothing to color';
            is scalar(@out), 4, 'highlight: as many as given';
        };
    }
}

done_testing;
