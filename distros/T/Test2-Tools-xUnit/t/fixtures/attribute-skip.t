use Test2::Tools::xUnit;
use Test2::V0;

sub skip_with_reason : Test Skip(some reason) {
    ok(1);
}

sub skip_with_no_reason : Test Skip {
    ok(1);
}

sub skip_with_no_test : Skip {
    ok(1);
}

done_testing;
