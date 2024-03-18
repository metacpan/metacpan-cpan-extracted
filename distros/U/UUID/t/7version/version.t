use strict;
use warnings;
use Test::More;
use MyNote;
use UUID qw(:all);

{
    generate_v0(my $u);
    my $v = version($u);
    is $v, 0, 'generate 0';
}
{
    generate_v1(my $u);
    my $v = version($u);
    is $v, 1, 'generate 1';
}
{
    generate_v4(my $u);
    my $v = version($u);
    is $v, 4, 'generate 4';
}
{
    generate_v6(my $u);
    my $v = version($u);
    is $v, 6, 'generate 6';
}
{
    generate_v7(my $u);
    my $v = version($u);
    is $v, 7, 'generate 7';
}
{
    my $u = '00000000-0000-0000-0000-000000000000';
    my $v = version($u);
    is $v, -1, 'uuid string';
}
{
    my $u = '';
    my $v = version($u);
    is $v, -1, 'empty string';
}
{
    my $u = undef;
    my $v = version($u);
    is $v, -1, 'undef';
}
{
    my $u = 432;
    my $v = version($u);
    is $v, -1, 'number';
}

done_testing;
