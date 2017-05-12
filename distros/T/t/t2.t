use strict;
use warnings;

use T2 Basic => [qw/ok done_testing note/];
use T2 Compare => [qw/like is/];
use T2(
    Exception => [qw/dies/],
    Warnings => [qw/warns/],
);

t2->ok(1, "ok works");

t2 is => ('a', 'a', 'is works');

t2 like => (
    'foo bar baz',
    qr/bar/,
    "like works"
);

t2->like(
    t2->dies(sub { t2->foo }),
    qr/No such function 'foo'/,
    "Can't call unimported method"
);

t2->ok(
    !t2->warns(sub {
        t2->like(
            t2->dies(sub {die "this is an error xxx"}),
            qr/this is an error xxx/,
            "Called tool that takes code block prototype"
        ),
    }),
    "No warnings"
);

t2 note => "done_testing is next";
t2->done_testing;
