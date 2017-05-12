#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Text::Fragment qw(set_fragment_attrs);
use Test::More 0.98;

subtest "invalid attr name" => sub {
    my $res = set_fragment_attrs(text=>"", id=>"id1", attrs=>{"x "=>1});
    is($res->[0], 400, "status");
};

subtest "not found" => sub {
    my $text = <<'_';
1
2
3
4 // FRAGMENT id=id1 cause=different-label
5 # DIFFERENT_LABEL id=id2
_

    my $res = set_fragment_attrs(text=>$text, id=>"id1", attrs=>{a=>1});
    is($res->[0], 404, "status");
};

subtest "set_attrs single-line" => sub {
    my $text = <<'_';
1
2
3
4 # FRAGMENT id=id1 a=1 b=2
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
        set_fragment_attrs(text=>$text, id=>"id1",
                           attrs=>{a=>10, b=>undef, c=>"3 "}),
        [200, "OK", {
            text => <<'_',
1
2
3
4 # FRAGMENT id=id1 a=10 c="3 "
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
            orig_attrs => {id=>"id1", a=>1, b=>2},
        }]
    );
};

subtest "set_attrs multiline" => sub {
    my $text = <<'_';
1
2
3
4 # FRAGMENT id=id1
# BEGIN FRAGMENT id=id2  a=1 b=2
a
b
# END FRAGMENT
_

    is_deeply(
        set_fragment_attrs(text=>$text, id=>"id2",
                           attrs=>{a=>10, b=>undef, c=>"3 "}),
        [200, "OK", {
            text => <<'_',
1
2
3
4 # FRAGMENT id=id1
# BEGIN FRAGMENT id=id2 a=10 c="3 "
a
b
# END FRAGMENT id=id2
_
            orig_attrs => {id=>"id2", a=>1, b=>2},
        }]
    );
};

DONE_TESTING:
done_testing;
