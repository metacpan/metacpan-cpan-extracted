use strict;
use warnings;
use utf8;
use 5.010;

use Test::More tests => 3;
use Text::PageLayout;
use Data::Dumper;
$Data::Dumper::Useqq = 1;

my $block = "a\nb\n" x 12;

my $l = Text::PageLayout->new(
    page_size   => 5,
    paragraphs  => [$block],
    header      => '',
    footer      => '',
    tolerance   => 0,
    split_paragraph => sub {
        my %param = @_;
        my @lines = split /\n\K/, $param{paragraph};
        my @first = splice @lines, 0, $param{max_lines};
        return join('', @first), join('', @lines);
    },
);

my $res = join '|', $l->pages;
is $res,
   "a\nb\na\nb\na\n|b\na\nb\na\nb\n|a\nb\na\nb\na\n|b\na\nb\na\nb\n|a\nb\na\nb\n\n",
   "A single, big block is split into multiple chunks";

# test that a no-op splitter can cause the test layout to fail, by creating
# paragraphs that don't even fit on empty pages
$l = Text::PageLayout->new(
    page_size   => 5,
    paragraphs  => [$block],
    header      => '',
    footer      => '',
    tolerance   => 0,
    split_paragraph => sub {
        my %param = @_;
        return ($param{paragraph}, '');
    },
);

my $success = eval { $l->pages(); 1 };
my $error   = "$@";
ok !$success, 'Cannot lay out a paragraph longer than a page if the split is a no-op';
like $error, qr/Paragraph too long/, 'descriptive error message';
