# Test2::Tools::Explain, a data dumper for Test2


Test2::Suite dropped the `explain()` function that had been
part of Test::More.  For those who miss it in Test2, you can use
Test2::Tools::Explain.

    use Test2::Tools::Explain;

    my $errors = fleeble_the_whatzit();
    is( $errors, [], 'Should have no errors from fleebling' ) or diag explain( $errors );

Note that `explain` does not output anything.  It returns a formatted
string.
