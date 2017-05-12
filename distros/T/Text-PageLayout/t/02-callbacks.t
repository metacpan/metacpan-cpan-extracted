use strict;
use warnings;
use utf8;
use 5.010;

use Test::More tests => 4;

use Text::PageLayout;

sub head {
    my %param = @_;
    return "head %d/%d ($param{page_number})\n"
};

sub foot {
    my %param = @_;
    return "foot %d/%d ($param{page_number})\n"
};

sub process_template {
    my %param = @_;
    sprintf $param{template}, $param{page_number}, $param{total_pages};
}

sub split_paragraph {
    my %param = @_;
    my ($first, $second) = split /\n\n/, $param{paragraph}, 2;
    return ("$first\n", $second);
}

my $block = "a\nb\nc\nd\n";
$block = "$block\n$block";

my $l = Text::PageLayout->new(
    page_size           => 20,
    paragraphs          => [ ($block) x 3 ],
    separator           => "SEP\nSEP\n",
    header              => \&head,
    footer              => \&foot,
    process_template    => \&process_template,
    split_paragraph     => \&split_paragraph,
);

ok $l, "could create object";

my @pages = $l->pages;

is scalar(@pages), 2, "layout on two pages";


my $p0 = <<EOP;
head 1/2 (1)
a
b
c
d

a
b
c
d
SEP
SEP
a
b
c
d



foot 1/2 (1)
EOP

my $p1 = <<EOP;
head 2/2 (2)
a
b
c
d
SEP
SEP
a
b
c
d

a
b
c
d



foot 2/2 (2)
EOP

is "$pages[0]", $p0, 'first page';
is "$pages[1]", $p1, 'second page';
