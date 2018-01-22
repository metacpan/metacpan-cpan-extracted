use Test::AllModules;

all_ok(
    search_path => 'WebService::BitFlyer',
    use_ok      => 1,
    fork        => 1,
    shuffle     => 1,
);
