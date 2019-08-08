use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

my @zones = available_zones();
my $cnt = @zones;
is($cnt, 1212);

if ($ENV{TEST_FULL}) {
    use_system_zones();
    my @zones = available_zones();
    ok(@zones > 0);
}

done_testing();
