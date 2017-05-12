use strict;
use warnings;
use utf8;
use 5.010;

use Test::More tests => 8;

use Text::PageLayout;

my $head = <<HEAD;
Head
----
HEAD

my $foot = <<FOOT;
----
Foot
FOOT

my $block = "a\nb\nc\nd\n";

my $l = Text::PageLayout->new(
    page_size   => 20,
    paragraphs  => [ ($block) x 5 ],
    header      => $head,
    footer      => $foot,
);

ok $l, "could create object";

my @pages = $l->pages;

is scalar(@pages), 2, "layout on two pages";

for my $p (0..1) {
    my $lines = $pages[$p] =~ tr/\n//;
    is $lines, 20, "Page $p has 20 lines";
}

is "$pages[0]", "$head$block\n$block\n$block\n\n$foot", "First page";
is "$pages[1]", "$head$block\n$block\n\n\n\n\n\n\n$foot", "Second page";

$l->fillup_pages(0);
@pages = $l->pages;

is "$pages[0]", "$head$block\n$block\n$block$foot", "First page, no fillup";
is "$pages[1]", "$head$block\n$block$foot", "Second page, no fillup";
