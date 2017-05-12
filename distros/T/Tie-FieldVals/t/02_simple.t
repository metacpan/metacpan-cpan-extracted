use strict;
use Test::More tests => 9;

use_ok( 'Tie::FieldVals' );
use_ok( 'Tie::FieldVals::Row' );

# open the data file
my @all_recs = ();
my $df = tie @all_recs, 'Tie::FieldVals',
   datafile=>'t/test1.data',
   cache_size=>100, memory=>0;

ok($df, "Tie::FieldVals object made");
ok(@all_recs, "Tie::FieldVals array has content");
my $count = @all_recs;
my $expected_count = 119;
is($count, $expected_count, "Has $expected_count records");

# look at the first row
my $vals = $all_recs[0];
ok($vals, "We have a row hash[0]");
my $row_obj = tied %{$vals};
ok($row_obj, "We have a row object[0]");

my $ok_str = 'Author:Adams,Douglas
Binding:trade paperback
Comment:"A dictionary of things that there aren\'t any words for yet."
Copyright:1990
Genre:Humour
GenreCom:
Quote:#Oshkosh:# The noise made by someone who has just been grossly
flattered and is trying to make light of it.
Series:
SeriesOrder:
Status:owned
Title:Deeper Meaning of Liff;The
';

my $vals_str = '';
foreach my $key (sort keys %{$vals})
{
	$vals_str .= $key . ":" . $vals->{$key} . "\n";
}
is($vals_str, $ok_str, "values[0] match");

# check the object
$ok_str = 'Author:Adams,Douglas
Title:Deeper Meaning of Liff;The
Series:
SeriesOrder:
Copyright:1990
Binding:trade paperback
Genre:Humour
GenreCom:
Status:owned
Quote:#Oshkosh:# The noise made by someone who has just been grossly
flattered and is trying to make light of it.
Comment:"A dictionary of things that there aren\'t any words for yet."';
$vals_str = $row_obj->get_as_string();

is($vals_str, $ok_str, "get_as_string[0] matches");
