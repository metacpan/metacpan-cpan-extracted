use strict;
use Test::More tests => 9;

use Tie::FieldVals;
use Tie::FieldVals::Row;
use Tie::FieldVals::Select;

# make a selection
my @sel_recs = ();
my $sel_obj = tie @sel_recs, 'Tie::FieldVals::Select',
   datafile=>'t/test1.data',
   selection=>{'Author'=>'Bloomfield,Frena'};

ok($sel_obj, "Tie::FieldVals:Select object made");
ok(@sel_recs, "Tie::FieldVals::Select array has content");
my $count = @sel_recs;
my $expected_count = 2;
is($count, $expected_count, "Has $expected_count records");

my $first = 'Author:Bloomfield,Frena
Title:The Dragon Paths
Series:
SeriesOrder:
Copyright:1973
Binding:trade paperback
Genre:Kids Fantasy
GenreCom:
Status:owned
Quote:*Tom sat in the bright sunlight. Gloomily he turned over a handful of
coins which he had laid out on the cobbles before him. The city rang
noisily about him as he regarded the results of his morning\'s work. Most of
the money he had begged. In a city full of beggars, he usually managed to
persuade some among the passing crowds to toss him the small change from
their money pouches.
    He did not pluck at their robes or whine, as the others did. He stood
quietly at their elbows while they considered some purchase in the markets
or in an open shop. Then, when they caught his grave eyes fixed upon them,
they often gave him some small coins while they swatted the other beggars
away from them.*
    (opening paragraphs)
Comment:';

my $second = 'Author:Bloomfield,Frena
Title:Sky Fleets of Atlantis
Series:
SeriesOrder:
Copyright:1979
Binding:trade paperback
Genre:Kids Fantasy
GenreCom:
Status:owned
Quote:*She screamed when they told her. They drew back from her and
the priests tried to comfort her, but she refused to let them calm
her.
    "We\'ve waited so long for him," she wept, "and now you\'ll take him
from us."
    "No, no," they said soothingly, but in a way she was right and they
knew it. Her husband stood beside her, looking strained and unhappy.
She turned on him too.
    "You could stop them!" she cried.
    "It is written," he said helplessly. "How can we argue with the
Seers?"*
    (opening paragraphs)
Comment:';

# look at the first row
my $vals = $sel_recs[0];
ok($vals, "We have a row hash[0]");
my $row_obj = tied %{$vals};
ok($row_obj, "We have a row object[0]");

my $vals_str = $row_obj->get_as_string();

is($vals_str, $first, "get_as_string[0] matches");

# sort numeric
$sel_obj->sort_records(sort_by=>[qw(Copyright)],
    sort_numeric=>{Copyright=>1},
    sort_reversed=>{Copyright=>1},
);

# second should be first
$vals = $sel_recs[0];
$row_obj = tied %{$vals};

$vals_str = $row_obj->get_as_string();

is($vals_str, $second, "sort (1) matches");

# sort by title
$sel_obj->sort_records(sort_by=>[qw(Title)]);

# second should be first
$vals = $sel_recs[0];
$row_obj = tied %{$vals};

$vals_str = $row_obj->get_as_string();

is($vals_str, $second, "sort (2) matches");

# sort by title Title
$sel_obj->sort_records(sort_by=>[qw(Title)],
    sort_title=>{Title=>1});

# first should be first
$vals = $sel_recs[0];
$row_obj = tied %{$vals};

$vals_str = $row_obj->get_as_string();

is($vals_str, $first, "sort (3) matches");

