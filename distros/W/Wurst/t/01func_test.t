use FindBin;
use lib "$FindBin::Bin/../blib/arch/";
use lib "$FindBin::Bin/../blib/lib/";

use Test::More tests => 16;
use Wurst;

$Coord=pdb_read ("extras/testfiles/1JB0.pdb", '', '');
$Coord2=coord_read ("extras/testfiles/1jb0A.bin");


$classfcn = aa_strct_clssfcn_read("extras/testfiles/classfile", 0.4);
$pvecout = strct_2_prob_vec($Coord2, $classfcn);
if(!prob_vec_write($pvecout, "1jb0A.bak")){
 BAIL_OUT("prob_vec error");
}

$pvec = prob_vec_read("1jb0A.bak");

ok (defined($Coord),"pdb_read");
ok (defined($Coord2),"coord_read_read");
ok (defined($pvec),"prob_vec_read");

if (!defined($Coord) or !defined($Coord2) or !defined($pvec)) {
    BAIL_OUT("file reading error");
}

# tests for coord_geo_gap
my @cgg_values = coord_geo_gap ($Coord, 1, 10);
ok (@cgg_values, "coord_geo_gap return");
is (scalar (@cgg_values), 4, "coord_geo_gap return size");
is ($cgg_values[3], 14, "coord_geo_gap num_gap");


# tests for pair_set_gap
my $seq = coord_get_seq($Coord2);
$mat = score_mat_new(seq_size ($seq), seq_size ($seq));
score_pvec($mat, $pvec, $pvec);
my $pair_set = score_mat_sum_smpl (my $result_mat, $mat, 3, 1, 3, 1, $S_AND_W);

my @psg_values = pair_set_gap($pair_set, 3, 1);
is (scalar (@psg_values), 2, "pair_set_gap return size");
is ($psg_values[0], 0, "pair_set_gap open_penalty");
is ($psg_values[1], 0, "pair_set_gap widen_penalty");


# tests for pair_set_score
my @pss_values = pair_set_score($pair_set);
is (scalar (@pss_values), 2, "pair_set_score return size");
is ($pss_values[0], 4410, "pair_set_score gap_score");
is ($pss_values[1], 4410, "pair_set_score no_gap_score");


# tests for coord_rmsd
my @cr_values = coord_rmsd ($pair_set, $Coord2, $Coord2, 0);
is (scalar (@cr_values), 3, "coord_rmsd return size");


# tests for get_rmsd
my @gr_values = get_rmsd ($pair_set, $Coord2, $Coord2);
is (scalar (@gr_values), 2, "coord_rmsd return size");
is ($gr_values[0], 0, "get_rmsd rmsd");
is ($gr_values[1], 740, "get_rmsd count");