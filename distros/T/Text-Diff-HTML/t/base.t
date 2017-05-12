#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;

BEGIN { use_ok 'Text::Diff::HTML' or die; }


BEGIN {
    # Mock parent class.
    package Text::Diff::Unified;

    no warnings 'redefine';
    sub file_header { return '<file_header>'; }
    sub hunk_header { return '<hunk_header>'; }
    sub file_footer { return '<file_footer>'; }
    sub hunk_footer { return '<hunk_footer>'; }
    sub hunk        { return                  }
}

ok my $html_diff = Text::Diff::HTML->new, 'Construct HTML diff object';
isa_ok $html_diff, 'Text::Diff::HTML';

is $html_diff->file_header,
    '<div class="file"><span class="fileheader">&lt;file_header&gt;</span>',
    'file_header should output a span and escape its value';

is $html_diff->hunk_header,
    '<div class="hunk"><span class="hunkheader">&lt;hunk_header&gt;</span>',
    'hunk_header should output a span and escape its value';

is $html_diff->file_footer,
    '<span class="filefooter">&lt;file_footer&gt;</span></div>',
    'file_footer should output a span and escape its value';

is $html_diff->hunk_footer,
    '<span class="hunkfooter">&lt;hunk_footer&gt;</span></div>',
    'hunk_footer should output a span and escape its value';

# Build up the arguments for hunk().
my @file_one = (
    "This is the first file. We this line will be changed.\n",
    "This one will stay <em>the same.</em>\n",
    "And so will this one.\n",
);

my @file_two = (
    "This is the first file. We this line will be changed.\n",
    "This one will stay <em>the same.</em>\n",
    "But only the second file will have this line.\n",
);

my @ops = (
    [0, 0, ' '],
    [1, 1, ' '],
    [2, 2, '-'],
    [3, 2, '+'],
);

# Now make sure it outputs what we want.
is $html_diff->hunk(\@file_one, \@file_two, \@ops),
    qq{<span class="ctx">  This is the first file. We this line will be changed.\n}
    . qq{  This one will stay &lt;em&gt;the same.&lt;/em&gt;\n}
    . qq{</span><del>- And so will this one.\n}
    . qq{</del><ins>+ But only the second file will have this line.\n}
    . qq{</ins>},
    'hunk() should give us what we expect.';
