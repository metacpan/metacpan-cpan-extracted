use Test::More tests => 5;

use Tie::Hash::Cannabinol;
ok(1);

my %hash : Stoned;

my @keys = qw(one two three four);

@hash{@keys} = 1 .. 4;
my $k = (keys %hash)[0];
my $v = $hash{$k} for 1 .. 10;
my $e = exists $hash{$k};

ok(1) for 2 .. 5;
