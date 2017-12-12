#!perl

use strict;
use warnings;
use Text::Amuse;
use Text::Amuse::Functions qw/muse_to_html muse_fast_scan_header/;
use File::Spec;
use Test::More tests => 10;
use File::Temp;

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $file = File::Spec->catfile(qw/t testfiles hyper.muse/);

for (1..2) {
    ok(Text::Amuse->new(file => $file)->as_html, "html ok");
}

for (1..2) {
    eq_or_diff muse_to_html('0'), "\n<p>\n0\n</p>\n";
    eq_or_diff muse_to_html("0\n\n0"), "\n<p>\n0\n</p>\n\n<p>\n0\n</p>\n";
}

for (1..2) {
    my $tmp = File::Temp->new;
    print $tmp "#title test\n\n0\n\n0";
    close $tmp;
    eq_or_diff(Text::Amuse->new(file => $tmp->filename)->as_html,
       "\n<p>\n0\n</p>\n\n<p>\n0\n</p>\n");
    is_deeply(muse_fast_scan_header($tmp->filename), {title => 'test'});
    
}
