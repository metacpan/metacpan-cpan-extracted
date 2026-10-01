use strict;
use warnings;
use Test::More;
use Text::Markdown::Discount;

my %flags = (
    MKD_NOLINKS          => 0x00000001,
    MKD_NOIMAGE          => 0x00000002,
    MKD_NOPANTS          => 0x00000004,
    MKD_NOHTML           => 0x00000008,
    MKD_STRICT           => 0x00000010,
    MKD_TAGTEXT          => 0x00000020,
    MKD_NO_EXT           => 0x00000040,
    MKD_CDATA            => 0x00000080,
    MKD_NOSUPERSCRIPT    => 0x00000100,
    MKD_NORELAXED        => 0x00000200,
    MKD_NOTABLES         => 0x00000400,
    MKD_NOSTRIKETHROUGH  => 0x00000800,
    MKD_TOC              => 0x00001000,
    MKD_1_COMPAT         => 0x00002000,
    MKD_AUTOLINK         => 0x00004000,
    MKD_SAFELINK         => 0x00008000,
    MKD_NOHEADER         => 0x00010000,
    MKD_TABSTOP          => 0x00020000,
    MKD_NODIVQUOTE       => 0x00040000,
    MKD_NOALPHALIST      => 0x00080000,
    MKD_NODLIST          => 0x00100000,
    MKD_EXTRA_FOOTNOTE   => 0x00200000,
    MKD_NOSTYLE          => 0x00400000,
    MKD_NODLDISCOUNT     => 0x00800000,
    MKD_DLEXTRA          => 0x01000000,
    MKD_FENCEDCODE       => 0x02000000,
    MKD_IDANCHOR         => 0x04000000,
    MKD_GITHUBTAGS       => 0x08000000,
    MKD_URLENCODEDANCHOR => 0x10000000,
    MKD_LATEX            => 0x40000000,
    MKD_EXPLICITLIST     => 0x80000000,
);

for my $name (sort keys %flags) {
    no strict 'refs';
    is(&{"Text::Markdown::Discount::$name"}(), $flags{$name}, "$name retains its legacy value");
}

my $combined = Text::Markdown::Discount::MKD_NOHEADER()
    | Text::Markdown::Discount::MKD_NOPANTS()
    | Text::Markdown::Discount::MKD_DLEXTRA()
    | Text::Markdown::Discount::MKD_FENCEDCODE();

is(
    Text::Markdown::Discount::markdown("```perl\nsay 'hi';\n```", $combined),
    "<pre><code class=\"perl\">say 'hi';\n</code></pre>\n",
    'combined legacy flags are translated to Discount 3 flags',
);

is(
    Text::Markdown::Discount::markdown(
        "term\n: definition",
        Text::Markdown::Discount::MKD_DLEXTRA()
            | Text::Markdown::Discount::MKD_NODLIST()
            | Text::Markdown::Discount::MKD_NOHEADER()
            | Text::Markdown::Discount::MKD_NOPANTS(),
    ),
    "<p>term\n: definition</p>\n",
    'MKD_NODLIST disables both definition list styles',
);

done_testing;
