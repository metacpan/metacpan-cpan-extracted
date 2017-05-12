use strict;
use Test::More tests => 8;

use Tie::FieldVals;
use Tie::FieldVals::Row;
use Tie::FieldVals::Select;

# open the data file
my @all_recs = ();
my $df = tie @all_recs, 'Tie::FieldVals',
   datafile=>'t/test_sort2.data',
   cache_all=>1, memory=>0;

# make a selection
my @sel_recs = ();
my $sel_obj = tie @sel_recs, 'Tie::FieldVals::Select',
   datafile=>'t/test_sort2.data';

ok($sel_obj, "Tie::FieldVals:Select object made");
ok(@sel_recs, "Tie::FieldVals::Select array has content");
my $count = @sel_recs;
my $expected_count = 25;
is($count, $expected_count, "Has $expected_count records");

# look at the first row
is_deeply($sel_recs[0], $all_recs[0], "row[0] matches");

# sort numeric
$sel_obj->sort_records(sort_by=>[qw(Copyright)],
    sort_numeric=>{Copyright=>1},
    sort_reversed=>{Copyright=>1},
);
# 25th should be first
is_deeply($sel_recs[0], $all_recs[24], "sort(1) matches");

# sort by Author
$sel_obj->sort_records(sort_by=>[qw(Author Title)]);

is_deeply($sel_recs[0], $all_recs[22], "sort(2) matches");

# sort by lastword of Author
$sel_obj->sort_records(sort_by=>[qw(Author Title)],
    sort_lastword=>{Author=>1},
    sort_reversed=>{Title=>1},
);
# 5th should be first
is_deeply($sel_recs[0], $all_recs[4], "sort(3) matches");

# sort by lastword of Author
$sel_obj->sort_records(sort_by=>[qw(Author Copyright)],
    sort_lastword=>{Author=>1},
    sort_reversed=>{Author=>1},
);

is_deeply($sel_recs[0], $all_recs[21], "sort(4) matches");

