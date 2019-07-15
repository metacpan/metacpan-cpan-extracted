use 5.012;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

package MyPerlDateA {
    use MyTest;
    use parent qw/MyTest::Cookbook::DateRecipe02a/;

    sub to_string {
        return scalar(localtime(shift->get_epoch));
    }
};

package MyPerlDateB {
    use MyTest;
    use parent qw/MyTest::Cookbook::DateRecipe02b/;

    sub new {
        my $class = shift;
        my $obj = $class->SUPER::new();
        XS::Framework::obj2hv($obj);
        $obj->{_date} = localtime($obj->get_epoch);
        return $obj;
    }

    sub to_string {
        return shift->{_date}
    }
};


my $date_a = MyTest::Cookbook::DateRecipe02a->new;
my $date_b = MyTest::Cookbook::DateRecipe02b->new;

my $date_A = MyPerlDateA->new;
my $s_date_A = $date_A->to_string;
say "date a = ", $s_date_A, ", ref = ", ref($date_A);
ok $s_date_A;
isa_ok($date_A, 'MyTest::Cookbook::DateRecipe02a');
isa_ok($date_A, 'MyPerlDateA');

my $date_B = MyPerlDateB->new;
my $s_date_B = $date_B->to_string;
say "date b = ", $s_date_B, ", ref = ", ref($date_B);
ok $s_date_B;
isa_ok($date_B, 'MyTest::Cookbook::DateRecipe02b');
isa_ok($date_B, 'MyPerlDateB');


done_testing;
