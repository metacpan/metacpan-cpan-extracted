use strict;
use warnings;

use Test::More tests => 18;
use Text::CSV::LibCSV;

my $data = <<'END_CSV';
one,two,three
END_CSV
csv_parse($data, sub{
    is(scalar @_, 3);
    is(shift, 'one');
    is(shift, 'two');
    is(shift, 'three');
}) or die;

# data contains a NUL character
$data = <<"END_CSV";
ab\0,c
END_CSV
csv_parse($data, sub {
    is(scalar @_, 2);
    is(shift, "ab\0");
    is(shift, "c");
}) or die;

# OO interface
my $parser = Text::CSV::LibCSV->new;
isa_ok($parser, 'Text::CSV::LibCSV');
is($parser->opts(CSV_STRICT), 0);
$parser->parse('foo,bar,baz', sub {
    is(scalar @_, 3);
    is(shift, 'foo');
    is(shift, 'bar');
    is(shift, 'baz');
}) or die $parser->strerror;

my $callback = sub {
    is(scalar @_, 3);
};
ok($parser->parse_file('t/test.csv', $callback));
open my $fh, '<', 't/test.csv' or die "cannot open file.";
ok($parser->parse_fh($fh, $callback));
ok($parser->parse($fh, $callback));
close $fh;

