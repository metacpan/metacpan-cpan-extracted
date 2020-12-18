use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Plugin::SourceDiag;

my $events = intercept {
    Test2::Plugin::SourceDiag->import(show_source => 1, show_args => 1, inject_name => 1);

    my $x = 'X';
    my $y = 'Y';

    is($x, $y);
};

if ($events->[0]->name) {
    is($events->[0]->name, 'is($x, $y);', "injected name");
    is($events->[1]->message, "Failure Arguments: ('X', 'Y')", "got args");
}
else {
    is($events->[1]->message . "\n", <<'    EOT', "Could not set name, so added to message");
Failure source code:
------------
11:     is($x, $y);
------------
Failure Arguments: ('X', 'Y')
    EOT
}

$events = intercept {
    Test2::Plugin::SourceDiag->import(show_source => 1, show_args => 1, inject_name => 1);

    my $x = 'X';
    my $y = 'Y';

    is($x, $y, "named");
};

is($events->[0]->name, 'named', "do not injected name");
is(
    $events->[1]->message,
    "Failure source code:\n------------\n34:     is(\$x, \$y, \"named\");\n------------\nFailure Arguments: ('X', 'Y', 'named')",
    "got args and source"
);

done_testing;
