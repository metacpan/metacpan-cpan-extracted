use strict;
use warnings;

use T2 -as => 'ttt', Basic => [qw/ok done_testing note/];
use T2 -as => 'ttt', Compare => [qw/like is/];
use T2(
    -as => 'ttt',
    Exception => [qw/dies/],
    Warnings => [qw/warns/],
);

ttt->ok(1, "ok works");

ttt is => ('a', 'a', 'is works');

ttt like => (
    'foo bar baz',
    qr/bar/,
    "like works"
);

ttt->ok(
    !ttt->warns(sub {
        ttt->like(
            ttt->dies(sub {die "this is an error xxx"}),
            qr/this is an error xxx/,
            "Called tool that takes code block prototype"
        ),
    }),
    "No warnings"
);

ttt note => "done_testing is next";
ttt->done_testing;
