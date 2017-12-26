use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use Text::Amuse::Functions qw/muse_to_html muse_to_tex/;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 30;

my $fn = Text::Amuse::Document->new(file => catfile(t => testfiles => 'footnotes.muse'));

my @got = $fn->elements;

is(scalar(grep { $_->type ne 'null'} @got), 4, # added 3 lines
   "4 not null element") or diag Dumper(\@got);
is($fn->get_footnote('[1]')->string, "first\n");
is($fn->get_footnote('[2]')->string, "second\nthird\n");
is($fn->get_footnote('[3]')->string, "third\n");
is($fn->get_footnote(), undef);
is($fn->get_footnote('[4]'), undef);

{
    my $muse =<<'MUSE';
#title test

First test

[1968]
MUSE

    my $html = muse_to_html($muse);
    my $ltx  = muse_to_tex($muse);

    like $html, qr{1968}, "Found the date in HTML";
    unlike $html, qr{footnote}, "Not an html footnote";
    like $ltx, qr{1968}, "Found the date in TeX";
    unlike $ltx, qr{footnote}, "Not a footnote";
    is $html, "\n<p>\nFirst test\n</p>\n\n<p>\n[1968]\n</p>\n", "html is good";
    is $ltx, "\nFirst test\n\n\n[1968]\n\n", "ltx is good";
}

{
    my $muse =<<'MUSE';
#title test

First test [1968]

[1968]
MUSE

    my $html = muse_to_html($muse);
    my $ltx  = muse_to_tex($muse);
    like $html, qr{1968.*1968}s, "Found the date in HTML";
    unlike $html, qr{footnote}, "Not an html footnote";
    like $ltx, qr{1968.*1968}s, "Found the date in TeX";
    unlike $ltx, qr{footnote}, "Not a footnote";
    is $html, "\n<p>\nFirst test [1968]\n</p>\n\n<p>\n[1968]\n</p>\n", "html is good";
    is $ltx, "\nFirst test [1968]\n\n\n[1968]\n\n", "ltx is good";
}

{
    my $muse =<<'MUSE';
#title test

First test [1968] [3]

[1968]

[3] fusnota
MUSE

    my $html = muse_to_html($muse);
    my $ltx  = muse_to_tex($muse);
    like $html, qr{1968.*1968}s, "Found the date in HTML";
    like $html, qr{fn_back3}, "Found an html footnote";
    unlike $html, qr{fn_back1968}, "1968 is not a footnote";
    # diag $html;
    like $ltx, qr{1968.*1968}s, "Found the date in TeX";
    unlike $ltx, qr/\\footnote\{\}/, "Not a footnote";
    like $ltx, qr/\\footnote\{fusnota\}/, "Found footnote";
    # diag $ltx;
    # diag $html;
}

{
    my $muse =<<'MUSE';
#title test

Zero [0]

[0] zero
MUSE

    my $html = muse_to_html($muse);
    my $ltx  = muse_to_tex($muse);
    like $html, qr{0.*0}s, "Found zero in HTML";
    unlike $html, qr{footnote}, "Not an html footnote";
    like $ltx, qr{0.*0}s, "Found zero in TeX";
    unlike $ltx, qr{footnote}, "Not a footnote";
    is $html, "\n<p>\nZero [0]\n</p>\n\n<p>\n[0] zero\n</p>\n", "html is good";
    is $ltx, "\nZero [0]\n\n\n[0] zero\n\n", "ltx is good";
}
