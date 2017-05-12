use strict;
use Test::More tests => 13;

use_ok( 'Tie::FieldVals' );
use_ok( 'Tie::FieldVals::Row' );
use_ok( 'Tie::FieldVals::Select' );

# make a selection
my @sel_recs = ();
my $sel_obj = tie @sel_recs, 'Tie::FieldVals::Select',
   datafile=>'t/test1.data',
   selection=>{'Author'=>'Austen,Jane'};

ok($sel_obj, "Tie::FieldVals:Select object made");
ok(@sel_recs, "Tie::FieldVals::Select array has content");
my $count = @sel_recs;
my $expected_count = 3;
is($count, $expected_count, "Has $expected_count records");

# look at the first row
my $vals = $sel_recs[0];
ok($vals, "We have a row hash[0]");
my $row_obj = tied %{$vals};
ok($row_obj, "We have a row object[0]");

my $ok_str = 'Author:Austen,Jane
Binding:paperback
Comment:
Copyright:
Genre:Historical
GenreCom:
Quote:
Series:
SeriesOrder:
Status:owned
Title:Persuasion
';

my $vals_str = '';
foreach my $key (sort keys %{$vals})
{
	$vals_str .= $key . ":" . $vals->{$key} . "\n";
}
is($vals_str, $ok_str, "values[0] match");

# check the object
$ok_str = 'Author:Austen,Jane
Title:Persuasion
Series:
SeriesOrder:
Copyright:
Binding:paperback
Genre:Historical
GenreCom:
Status:owned
Quote:
Comment:';

$vals_str = $row_obj->get_as_string();

is($vals_str, $ok_str, "get_as_string[0] matches");

# make another selection
undef $sel_obj;
untie @sel_recs;
@sel_recs = ();
$sel_obj = tie @sel_recs, 'Tie::FieldVals::Select',
   datafile=>'t/test1.data',
   selection=>{'Copyright'=>'>= 1990'};

ok($sel_obj, "Tie::FieldVals:Select object made");
ok(@sel_recs, "Tie::FieldVals::Select array has content");
$count = @sel_recs;
$expected_count = 36;
is($count, $expected_count, "Has $expected_count records");

