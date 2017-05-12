use Test::More;
use Test::Differences;

# use large enough data sets that this thing chooses context => 3 instead
# of "full document context".
my $a = ( "\n" x 30 ) . "a\n";
my $b = ( "\n" x 30 ) . "b\n";

my @tests = ( 
    sub { eq_or_diff [ "a", "b" ], [ "a", "b" ] }, 
);

plan tests => scalar @tests;

$_->() for @tests;
