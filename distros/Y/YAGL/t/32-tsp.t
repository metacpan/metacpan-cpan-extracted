#!perl

use strict;
use warnings;
use autodie;
use feature qw/ say /;
use lib 'lib';
use YAGL;
use Cwd;
use Test::More tests => 2;

use constant True  => 1;
use constant False => undef;
use constant DEBUG => False;

my $cwd = getcwd;

## -> State!
my $g = YAGL->new;
$g->read_csv(qq[$cwd/data/three-triangles.csv]);

my @hams = $g->hamiltonian_walks;

my @answers;
my $min = 0;
for my $h (@hams) {
    my $len = walk_length( $g, $h );
    $min = $len if $min == 0;
    if ( $len < $min ) {
        $min = $len;
        push @answers, { walk => $h, length => $len };
    }
    else {
        if (DEBUG) {
            push @answers, { walk => $h, length => $len };
        }
    }
}

my @sorted = sort { $a->{length} <=> $b->{length} } @answers;

my $wanted = shift @sorted;
my $length = $wanted->{length};
my $walk   = $wanted->{walk};

sub walk_length {
    ## ArrayRef -> Int
    my ( $graph, $walk ) = @_;
    my $sum = 0;
    for ( my $i = 0 ; $i < @$walk - 1 ; $i++ ) {
        my $j = $i + 1;
        my $dist =
          $graph->get_edge_attribute( $walk->[$i], $walk->[$j], 'weight' );
        say qq[Looking at edge ($i)-($j) of weight $dist: ], $walk->[$i],
          $walk->[$j]
          if DEBUG;
        $sum += $dist;
    }
    return $sum;
}

my $expected_length = 72;
my @expected_walk   = qw/a c b d e f h g i/;
my @got             = @$walk;

is_deeply( \@got, \@expected_walk, "Small TSP is the expected walk" );
ok( $length == $expected_length, "Small TSP is the expected length" );

__END__

#        A
#       / \
#      /   \
#      B - C
#     /     \
#    /       \
#   /         \
#   D          G
# /  \         / \
# E - F ----- H - I

# Local Variables:
# compile-command: "cd .. && perl t/32-tsp.t"
# End:
