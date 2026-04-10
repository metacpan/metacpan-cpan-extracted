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
my $v2 = TestVector->new(1, 2, 4);
my $v3 = TestVector->new(2, 3, 4);
vec_ne($v1, $v2, 'vec_ne accepts unequal vectors');
vec_ne($v1, $v3, 'vec_ne accepts another unequal pair');
vec_ne($v2, $v3, 'vec_ne accepts a third unequal pair');
