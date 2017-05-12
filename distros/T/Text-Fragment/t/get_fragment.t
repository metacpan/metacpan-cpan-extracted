#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Text::Fragment qw(get_fragment);
use Test::More 0.98;

subtest "not found" => sub {
    my $text = <<'_';
1
2
3
4 // FRAGMENT id=id1 cause=different-label
5 # DIFFERENT_LABEL id=id2
_

    my $res = get_fragment(text=>$text, id=>"id1");
    is($res->[0], 404, "status");
};

subtest "get" => sub {
    my $text = <<'_';
1
2
3
4 # FRAGMENT id=id1 a=1 b="2 "
# BEGIN FRAGMENT id=id2
a
b
# END FRAGMENT
 5  #FRAGMENT  id=id3
# BEGIN FRAGMENT id=id4
c
# END FRAGMENT
# END FRAGMENT id=id4
_

    is_deeply(
        get_fragment(text=>$text, id=>"id1"),
        [200, "OK", {
            raw     => "4 # FRAGMENT id=id1 a=1 b=\"2 \"\n",
            id      => "id1",
            attrs   => {id=>"id1", a=>1, b=>"2 "},
            payload => "4",
        }]
    );
};

subtest "no enl, single-line, ini-style" => sub {
    is_deeply(
        get_fragment(text=>"1;FRAGMENT id=i", id=>"i", comment_style=>"ini"),
        [200, "OK", {
            raw     => "1;FRAGMENT id=i",
            id      => "i",
            attrs   => {id=>"i"},
            payload => "1",
        }]
    );
};

DONE_TESTING:
done_testing;
