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
my $v4 = TestVector->new(1, 2, 3);
vec_is($v1, $v2, 'vec_is accepts equal vectors');
vec_is($v1, $v4, 'vec_is accepts another equal vector');
vec_is($v2, $v4, 'vec_is accepts matching values');
