#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};

{
    my $w;
    my $wrap = Wrap::Sub->new;
    $w = $wrap->wrap('wrap_1');

    is ($w->is_wrapped, 1, "sub is wrapped");

    is (wrap_1(), 'wrap_1', "wrapped sub does the right thing");

    my @array = wrap_1();

    is (ref \@array, 'ARRAY', "in list context, return is array");
}
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('wrap_2');

    my @ret = wrap_2('hello', 'world');

    is ($ret[0], 'hello', "arg 1 passed in to sub works");
    is ($ret[1], 'world', "arg 2 passed into sub works");
    is (ref $ret[2], 'ARRAY', "arg 3 passed into sub works");
}

done_testing();

sub wrap_1 {
    return "wrap_1";
}
sub wrap_2 {
    my @args = @_;
    my $list = [qw(1 2 3 4 5)];
    return (@args, $list);
}
sub wrap_3 {
    return 1000;
}
sub wrap_4 {
    my @args = @_;
    my @nums;
    for (@args){
        push @nums, $_ * 10;
    }
    return @nums;
}
