use v5.18;

use Sereal::Encoder;
use Sereal::Decoder;

use Tree::VP;
use List::MoreUtils qw<uniq>;
use Text::Levenshtein::Damerau::XS ();
use File::Slurp::Tiny qw(read_file read_lines write_file);

my $comparison = 0;
sub distance {
    $comparison++;
    return Text::Levenshtein::Damerau::XS::xs_edistance(lc($_[0]), lc($_[1]));
}

my $dict = shift(@ARGV) || "/usr/share/dict/words";

my $sereal_tree_file = "/tmp/tree_vp_spelling_example.sereal";

unless (-f $sereal_tree_file) {
    my @words = uniq(map { lc($_) } @{ read_lines($dict, chomp => 1, array_ref => 1, binmode => ":utf8" ) });
    # @words = splice(@words, 0, 1000);
    say "collect " . (0+@words) . " words";
    my $vptree = Tree::VP->new( distance => \&distance );
    $vptree->build(\@words);
    my $encoder = Sereal::Encoder->new();
    write_file($sereal_tree_file, $encoder->encode($vptree->tree));
}

my $decoder = Sereal::Decoder->new;
my $tree2 = $decoder->decode( read_file($sereal_tree_file) );

my $vptree = Tree::VP->new( distance => \&distance, tree => $tree2 );

$| = 1;
print "(init with $comparison comparisons) ready\nyou type: ";
while (<>) {
    $comparison = 0;
    chomp;
    my $q = $_;
    my $r = $vptree->search(query => $q, size => 5);
    say "my guess ($comparison comparisons): " . join " ", map { "$_->{value} ($_->{distance})" } @{$r->{results}};
    print "you type: ";
}
