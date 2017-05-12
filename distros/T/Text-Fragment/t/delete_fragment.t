#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Text::Fragment qw(delete_fragment);
use Test::More 0.98;

test_delete_fragment(
    name          => "one-line/shell, noop",
    args          => {text=>"1\n2\n3\n", id=>"id1"},
    status        => 304,
);
test_delete_fragment(
    name          => "one-line/shell, noop 2",
    args          => {text=>"1\n2\n3\nx # FRAGMENT id=id1\n", id=>"i"},
    text          => "1\n2\n3\n",
    status        => 304,
);
test_delete_fragment(
    name          => "one-line/shell",
    args          => {text=>"1\n2\n3\nx # FRAGMENT id=id1\n", id=>"id1"},
    text          => "1\n2\n3\n",
    orig_payload  => "x",
    orig_fragment => "x # FRAGMENT id=id1\n",
);
test_delete_fragment(
    name          => "one-line/shell, no ending newline",
    args          => {text=>"1\n2\n3\nx # FRAGMENT id=id1", id=>"id1"},
    text          => "1\n2\n3",
    orig_payload  => "x",
    orig_fragment => "x # FRAGMENT id=id1",
);
test_delete_fragment(
    name          => "one-line/shell, no ending newline, beginning",
    args          => {text=>"x # FRAGMENT id=id1", id=>"id1"},
    text          => "",
    orig_payload  => "x",
    orig_fragment => "x # FRAGMENT id=id1",
);
test_delete_fragment(
    name          => "multiline/shell, no ending newline",
    args          => {text=>"1\n# BEGIN FRAGMENT id=id1\nx\n# END FRAGMENT",
                      id=>"id1"},
    text          => "1",
    orig_payload  => "x\n",
    orig_fragment => "# BEGIN FRAGMENT id=id1\nx\n# END FRAGMENT",
);
test_delete_fragment(
    name          => "multiline/shell, no ending newline, beginning",
    args          => {text=>"# BEGIN FRAGMENT id=id1\nx\n# END FRAGMENT",
                      id=>"id1"},
    text          => "",
    orig_payload  => "x\n",
    orig_fragment => "# BEGIN FRAGMENT id=id1\nx\n# END FRAGMENT",
);
test_delete_fragment(
    name          => "multiline/cpp, multiple fragments",
    args          => {text=><<'_', id=>"id1", comment_style=>"cpp"},
1
// BEGIN FRAGMENT id=id1
x
y
// END FRAGMENT id=id1
2
// BEGIN FRAGMENT id=id2
a
b
// END FRAGMENT id=id2
c // FRAGMENT id=id3
_
    text          => <<'_',
1
2
// BEGIN FRAGMENT id=id2
a
b
// END FRAGMENT id=id2
c // FRAGMENT id=id3
_
    orig_payload  => "x\ny\n",
    orig_fragment => <<'_',
// BEGIN FRAGMENT id=id1
x
y
// END FRAGMENT id=id1
_
);
test_delete_fragment(
    name          => "one-line/c, multiple occurences",
    args          => {text=><<_, id=>"id1", comment_style=>"c"},
1
x1 /* FRAGMENT id=id1 */
2
3
 x2  /* FRAGMENT id=id1 */
_
    text          => <<'_',
1
2
3
_
    orig_payload  => " x2",
    orig_fragment => " x2  /* FRAGMENT id=id1 */\n",
);

DONE_TESTING:
done_testing;

sub test_delete_fragment {
    my %targs = @_;

    subtest $targs{name} => sub {
        my $res = delete_fragment(%{ $targs{args} });
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
