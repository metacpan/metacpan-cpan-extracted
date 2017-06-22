use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Plugin::SourceDiag;

my $events = intercept {
    Test2::Plugin::SourceDiag->import();
    ok(0, "This will fail");

    is(
        {a => 1},
        {a => 2},
        "foo",
    );

    # Oooh, tricky :-) logical line number is 21: "hash test", I am amazed PPI knows that!
    is(
        {a => 1},
        hash {
            field a => 2;
            end;
        },
        "hash test",
    );
};

shift @$events until $events->[0]->causes_fail;
my $fail = shift @$events;
my $diag = shift @$events;
is($diag->message, <<EOT, "Got first diagnostics");
Failure source code:
------------
7:     ok(0, "This will fail");
------------
EOT


shift @$events until $events->[0]->causes_fail;
$fail = shift @$events;
$diag = shift @$events;
is($diag->message, <<EOT, "Got second diagnostics");
Failure source code:
------------
 9:     is(
10:         {a => 1},
11:         {a => 2},
12:         "foo",
13:     );
------------
EOT

shift @$events until $events->[0]->causes_fail;
$fail = shift @$events;
$diag = shift @$events;
is($diag->message, <<EOT, "Got third diagnostics");
Failure source code:
------------
16:     is(
17:         {a => 1},
18:         hash {
19:             field a => 2;
20:             end;
21:         },
22:         "hash test",
23:     );
------------
EOT

done_testing;
