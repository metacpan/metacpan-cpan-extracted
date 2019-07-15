use strict;
use warnings;
BEGIN { require "./t/cookbook/TestCookbook.pm"; }

my $base = MyTest::Cookbook::Base06->new;
is $base->method, "from base";

my $der_a = MyTest::Cookbook::Derived06A->new;
is $der_a->method, "from derived-A";
is $der_a->specific_method(), 'specific-A';

my $der_b = MyTest::Cookbook::Derived06B->new;
is $der_b->method, "from derived-B";
is $der_b->specific_method(), 'specific-B';

done_testing;
