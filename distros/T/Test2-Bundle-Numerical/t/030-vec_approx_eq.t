use 5.008003;
use strict;
use warnings;
use lib 'lib';
use Test2::Bundle::Numerical qw(:all);

plan(3);
{
    package TestVector;
    sub new { my $class = shift; bless { data => [@_] }, $class }
    sub len { scalar @{ $_[0]->{data} } }
    sub to_array { [@{ $_[0]->{data} }] }
}
my $v1 = TestVector->new(1, 2, 3);
my $v2 = TestVector->new(1, 2, 3);
my $v3 = TestVector->new(1, 2, 4);
vec_approx_eq($v1, $v2, 'vec_approx_eq accepts equal vectors');
ok(!vec_approx_eq($v1, $v3, undef), 'vec_approx_eq rejects unequal vectors');
ok(vec_approx_eq($v1, $v1, undef), 'vec_approx_eq accepts the same object');
