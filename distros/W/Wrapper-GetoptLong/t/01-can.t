#!perl
use 5.006;
use strict;
use warnings;
use Test::More; # tests => 2; # qw/no_plan/;
use lib 'lib';

plan tests => 1;

use Wrapper::GetoptLong;

$ARGV[0]='-help';
my %H=();
my $wgol=new Wrapper::GetoptLong(\%H);
ok($wgol->can('init_getopts'));
done_testing();
