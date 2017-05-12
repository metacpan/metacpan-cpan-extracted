use Test::More;

eval 'use Test::CheckChanges 0.040;';
if ($@) {
    plan skip_all => 'Test::CheckChanges required for testing the Changes file';
} else {
    plan tests => 1;
}

ok_changes();
