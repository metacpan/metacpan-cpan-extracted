use strict;
use Test::More tests => 7;

use Tie::FieldVals;
use Tie::FieldVals::Row;
use Tie::FieldVals::Select;

# make a selection
my @sel_recs = ();
my $sel_obj = tie @sel_recs, 'Tie::FieldVals::Select',
   datafile=>'t/test_sort2.data',
   selection=>{'Author'=>'Alfred Bester'};

ok($sel_obj, "Tie::FieldVals:Select object made");
ok(@sel_recs, "Tie::FieldVals::Select array has content");
my $count = @sel_recs;
my $expected_count = 4;
is($count, $expected_count, "Has $expected_count records");

my @rstr;
$rstr[0] = 'Author:Alfred Bester
Title:The Demolished Man
Series:
SeriesOrder:
Copyright:1953
Binding:trade paperback
Genre:SF
GenreCom:
Status:owned
Quote:
Comment:a man plans the perfect crime, in a future where telepaths make
all crime impossible.';

$rstr[1] = 'Author:Alfred Bester
Title:The Decievers
Series:
SeriesOrder:
Copyright:1981
Binding:paperback
Genre:SF
GenreCom:
Status:owned
Quote:*He was wearing a jumpsuit of radiation armor, colored white,
signifying executive level. He wore a white helmet with the visor down. He
was armed, as all executives were in this quasi-military installation. He
walked statelily across the floodlit concrete plain toward the giant hangar
looming in the night. His control seemed massive.
    As the towering hangar, shaped like a domed observatory, a squad of
black-armored guards lay dozing before an entry hatch. The executive kicked
the sergeant brutally but quite dispassionately. The squad leader exclaimed
and scrambled to his feet, followed by the rest of his men. They opened the
hatch for the man in white who stepped through into pitch black. Then,
almost as an afterthought, he turned back into the light, contemplated the
squad standing fearfully at attention and, quite dispassionately, shot
their sergeant.*
    (opening paragraphs)
Comment:';

$rstr[2] = 'Author:Alfred Bester
Title:The Stars My Destination
Title:Tiger Tiger
Series:
SeriesOrder:
Copyright:1956
Binding:trade paperback
Genre:SF
GenreCom:
Status:owned
Quote:*This was a Golden Age, a time of high adventure, rich living, and
hard dying... but nobody thought so. This was a future of fortune and
theft, pillage and rapine, culture and vice... but nobody admitted it.
This was an age of extremes, a fascinationg century of freaks... but nobody
loved it.*
    (opening paragraph)
Comment:Also known as "Tiger! Tiger!".  This is where the Tomorrow
People series got the word "jaunt" for teleport from.';

$rstr[3] = 'Author:Alfred Bester
Title:Virtual Unrealities
Series:
SeriesOrder:
Copyright:1997
Binding:trade paperback
Genre:SF
GenreCom:
Status:owned
Quote:
Comment:collected short stories';

# look at the first row
my $vals = $sel_recs[0];
my $row_obj = tied %{$vals};

my $vals_str = $row_obj->get_as_string();

is($vals_str, $rstr[0], "get_as_string[0] matches");

# sort numeric
$sel_obj->sort_records(sort_by=>[qw(Copyright)],
    sort_numeric=>{Copyright=>1},
    sort_reversed=>{Copyright=>1},
);

$vals = $sel_recs[0];
$row_obj = tied %{$vals};

$vals_str = $row_obj->get_as_string();

is($vals_str, $rstr[3], "sort (1) matches");

# sort by title
$sel_obj->sort_records(sort_by=>[qw(Title)]);

$vals = $sel_recs[0];
$row_obj = tied %{$vals};

$vals_str = $row_obj->get_as_string();

is($vals_str, $rstr[1], "sort (2) matches");

# sort by title Title
$sel_obj->sort_records(sort_by=>[qw(Title)],
    sort_title=>{Title=>1});

$vals = $sel_recs[0];
$row_obj = tied %{$vals};

$vals_str = $row_obj->get_as_string();

is($vals_str, $rstr[1], "sort (3) matches");

