#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Text::Fragment qw(insert_fragment);
use Test::More 0.98;

test_insert_fragment(
    name          => "invalid syntax in ID -> fail",
    args          => {text=>"",
                      id=>"id with space", payload=>"x"},
    status        => 400,
);

test_insert_fragment(
    name          => "insert one-line/shell, noop",
    args          => {text=>"1\n2\n3\nx # FRAGMENT id=id-1",
                      id=>"id-1", payload=>"x"},
    status        => 304,
);
test_insert_fragment(
    name          => "insert one-line/shell",
    args          => {text=>"1\n2\n3\n", id=>"id1", payload=>"x"},
    text          => "1\n2\n3\nx # FRAGMENT id=id1\n",
);
test_insert_fragment( # failed in 0.01
    name          => "insert one-line/shell, longer ID doesn't get overwritten",
    args          => {text=>"foo-bar # FRAGMENT id=foo-bar", id=>"foo", payload=>"foo"},
    text          => "foo-bar # FRAGMENT id=foo-bar\nfoo # FRAGMENT id=foo",
);
test_insert_fragment(
    name          => "insert one-line/shell, set attrs",
    args          => {text=>"1\n2\n3\n", id=>"id1", payload=>"x",
                      attrs=>{a=>1, b=>"2 "}},
    text          => "1\n2\n3\nx # FRAGMENT id=id1 a=1 b=\"2 \"\n",
);
test_insert_fragment(
    name          => "insert one-line/shell, no ending newline",
    args          => {text=>"1\n2\n3", id=>"id1", payload=>"x"},
    text          => "1\n2\n3\nx # FRAGMENT id=id1",
);
test_insert_fragment( # failed in 0.02
    name          => "insert one-line/shell, insert to empty string adds ending newline",
    args          => {text=>"", id=>"foo", payload=>"foo"},
    text          => "foo # FRAGMENT id=foo\n",
);
test_insert_fragment(
    name          => "insert one-line/c, top style",
    args          => {text=>"1\n2\n3", id=>"id1", payload=>"x",
                      comment_style=>'c', top_style=>1},
    text          => "x /* FRAGMENT id=id1 */\n1\n2\n3",
);
test_insert_fragment(
    name          => "insert one-line/cpp, label",
    args          => {text=>"1\n2\n3\n", id=>"id1", payload=>"x",
                      comment_style=>"cpp", label=>"X"},
    text          => "1\n2\n3\nx // X id=id1\n",
);

test_insert_fragment(
    name          => "good_pattern",
    args          => {text=>"1\n2\n3\n", id=>"id1", payload=>"x",
                      good_pattern=>qr/^2/m},
    status        => 304,
);

test_insert_fragment(
    name          => "replace single-line/html, replace_pattern",
    args          => {text=>"1\n2\n3\n", id=>"id1", payload=>"x",
                      comment_style=>"html", replace_pattern=>qr/^2\R/m},
    text          => "1\nx <!-- FRAGMENT id=id1 -->\n3\n",
);
test_insert_fragment(
    name          => "replace multiline/ini",
    args          => {text=><<'_',id=>"id1",payload=>"x",comment_style=>"ini"},
1
; BEGIN FRAGMENT id=id1
2
; END FRAGMENT
_
    text          => "1\n; BEGIN FRAGMENT id=id1\nx\n; END FRAGMENT id=id1\n",
    orig_fragment => "; BEGIN FRAGMENT id=id1\n2\n; END FRAGMENT\n",
    orig_payload  => "2\n",
);
test_insert_fragment(
    name          => "replace doesn't replace attrs",
    args          => {text=>"# FRAGMENT id=id1 b=2 a=1", id=>"id1",
                      payload=>"x", attrs=>{b=>20, c=>30}},
    text          => "x # FRAGMENT id=id1 a=1 b=2\n",
);

DONE_TESTING:
done_testing;

sub test_insert_fragment {
    my %targs = @_;

    subtest $targs{name} => sub {
        my $res = insert_fragment(%{ $targs{args} });
        my $status = $targs{status} // 200;
        is($res->[0], $status, 'status');
        return if $status != 200;
        for (qw/text orig_payload orig_fragment/) {
            if (defined $targs{$_}) {
                is($res->[2]{$_}, $targs{$_}, $_);
            }
        }
    };
}
