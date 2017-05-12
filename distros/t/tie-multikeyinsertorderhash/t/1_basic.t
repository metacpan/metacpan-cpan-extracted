use Test::More tests=>16;

BEGIN { require_ok('Tie::MultiKeyInsertOrderHash') }

require Tie::MultiKeyInsertOrderHash;
tie my %hash => 'Tie::MultiKeyInsertOrderHash';

ok(tied %hash,"Hash tied ok");

$hash{Foo}="1";
ok($hash{Foo},"Store/Retrive test");
is($hash{Foo}->[0],1,"Store/Retrive test");
ok(exists $hash{Foo},"Exists test");
delete $hash{Foo};
ok(!exists $hash{Foo},"Delete test");

$hash{A}="1";
$hash{B}="2";
$hash{A}="3";
$hash{B}="4";
$hash{C}="5";

is_deeply([keys %hash],[qw/A B A B C/],"Keys in right order test");


#print STDERR Data::Dumper->Dump([[values %hash],[qw/1 2 3 4 5/]]);

is_deeply([values %hash],[[1,3],[2,4],[1,3],[2,4],[5]],"Values in right order test");

is_deeply([each %hash],[qw/A 1/],"1st each test");
is_deeply([each %hash],[qw/B 2/],"2nd each test");
is_deeply([each %hash],[qw/A 3/],"3rd each test");
is_deeply([each %hash],[qw/B 4/],"4th each test");
is_deeply([each %hash],[qw/C 5/],"5th each test");

is($hash{A}->[0],1,"1st Value Order test");
is($hash{A}->[1],3,"2nd Value Order test");
is($hash{B}->[1],4,"3rd Value Order test");
