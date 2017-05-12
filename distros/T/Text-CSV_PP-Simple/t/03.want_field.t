use Test::More tests => 6;
use Text::CSV_PP::Simple;

my $t = Text::CSV_PP::Simple->new({binary => 1});

$t->want_fields(0, 2);
my @data = $t->read_file('t/test.csv');

ok ($data[0]->[0] eq '01');
ok ($data[0]->[1] eq '2324');

ok ($data[1]->[0] eq '02');
ok ($data[1]->[1] eq '2343');

ok ($data[2]->[0] eq '03');
ok ($data[2]->[1] eq '9482');