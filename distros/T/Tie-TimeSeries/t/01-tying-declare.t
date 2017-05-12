#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Tie::TimeSeries;

plan tests => 4;

# ----------
# 1
my $tied = tie my %hash, 'Tie::TimeSeries';
ok( ref($tied) eq 'Tie::TimeSeries', "tied with no arguments");

# 2
$tied = undef;
eval {
    $tied = tie %hash, 'Tie::TimeSeries', a=>1;
};
ok( ref($tied) eq 'Tie::TimeSeries' , "Couldn't tied with bad argument");

# 3
$tied = undef;
$tied = tie %hash, 'Tie::TimeSeries', 0=>0, 1=>10, 2=>20, 3=>30;
ok( ref($tied) eq 'Tie::TimeSeries', "tied with several arguments");

# 4
$tied = undef;
eval {
    $tied = tie %hash, 'Tie::TimeSeries', 0=>0, 1=>10, a=>15, 2=>20, 3=>30;
};
ok( ref($tied) eq 'Tie::TimeSeries' && scalar(keys %hash) == 4, "tied with several arguments and bad one");


# ----------
