use Test::More;

eval {
    require Test::CheckChanges;
    Test::CheckChanges->import();
};
if ($@) {
    plan skip_all => "Need Test::CheckChanges";
}

ok_changes();

