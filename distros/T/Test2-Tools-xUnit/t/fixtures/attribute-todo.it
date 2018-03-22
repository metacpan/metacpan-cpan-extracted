use Test2::Tools::xUnit;
use Test2::Tools::Basic;
use Test2::Plugin::SRand '1'; # custom seed to preserve order

sub todo_with_reason : Test Todo(some reason) {
    ok(1);
}

sub todo_with_no_reason : Test Todo {
    ok(1);
}

sub todo_with_no_test : Todo {
    ok(1);
}

sub failing_todo : Test Todo {
    ok(0);
}

done_testing;
