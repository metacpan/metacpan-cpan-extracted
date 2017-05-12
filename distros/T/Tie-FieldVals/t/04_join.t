use strict;
use Test::More tests => 12;
use Data::Dumper;

use_ok( 'Tie::FieldVals' );
use_ok( 'Tie::FieldVals::Row' );
use_ok( 'Tie::FieldVals::Select' );
use_ok( 'Tie::FieldVals::Row::Join' );
use_ok( 'Tie::FieldVals::Join' );

# join the two data files
my @join_recs = ();
my $join_obj = tie @join_recs, 'Tie::FieldVals::Join',
   datafile=>'t/test2.data',
   joinfile=>'t/test1.data',
   join_field=>'Author';

ok($join_obj, "Tie::FieldVals:Join object made");
ok(@join_recs, "Tie::FieldVals::Join array has content");
my $count = @join_recs;
my $expected_count = 119;
is($count, $expected_count, "Has $expected_count records");

# look at the first row
my $vals = $join_recs[0];
ok($vals, "We have a row hash[0]");
my $row_obj = tied %{$vals};
ok($row_obj, "We have a row object[0]");

my $ok_str = 'Author:Adams,Douglas
AuthorCom:
AuthorEmail:
AuthorURL:http://www.umd.umich.edu/~nhughes/dna/
AuthorURLName:
Binding:trade paperback
Comment:"A dictionary of things that there aren\'t any words for yet."
Copyright:1990
Genre:Humour
GenreCom:
Quote:#Oshkosh:# The noise made by someone who has just been grossly
flattered and is trying to make light of it.
SeeAlso:
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
my @ok_names = qw(Author
AuthorEmail
AuthorURL
AuthorURLName
AuthorCom
SeeAlso
Title
Series
SeriesOrder
Copyright
Binding
Genre
GenreCom
Status
Quote
Comment);

my @names = $join_obj->field_names();

is_deeply(\@names, \@ok_names, "field_names matches");

