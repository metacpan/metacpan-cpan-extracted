use Test::More tests => 9;
use Text::CSV_PP::Simple;

my $t = Text::CSV_PP::Simple->new({binary => 1});

$t->field_map qw/id name number/;
my @data = $t->read_file('t/test.csv');

ok ($data[0]->{"id"} eq '01');
ok ($data[0]->{"name"} eq 'asdf');
ok ($data[0]->{"number"} eq '2324');

ok ($data[1]->{"id"} eq '02');
ok ($data[1]->{"name"} eq 'werw');
ok ($data[1]->{"number"} eq '2343');

ok ($data[2]->{"id"} eq '03');
ok ($data[2]->{"name"} eq 'powe');
ok ($data[2]->{"number"} eq '9482');

