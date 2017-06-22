use Test2::V0;
use Test2::API qw/intercept/;
use Test2::Plugin::SourceDiag;

my $events = intercept {
    Test2::Plugin::SourceDiag->import(show_source => 0, show_args => 1);

    my $x = 'X';
    my $y = 'Y';

    is($x, $y, "fail");
};

is(
    $events->[1]->message,
    "Failure Arguments: ('X', 'Y', 'fail')",
    "Got arguments"
);

done_testing;
