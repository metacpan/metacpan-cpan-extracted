use strict;
use warnings;

use Test::More;
use Text::CSV::Auto;

my $expected_rows;
{
    my $auto = Text::CSV::Auto->new(
        file => 't/features.csv',
        max_rows => 2,
    );
    $expected_rows = $auto->slurp();

    $auto->export_to_csv(
        file => 't/export.tsv',
        csv_options => { sep_char=>"\t" },
    );
}

my $auto = Text::CSV::Auto->new(
    file => 't/export.tsv',
    max_rows => 2,
);

is_deeply(
    $auto->slurp(),
    $expected_rows,
    'rows match in new csv',
);

is(
    $auto->separator(),
    "\t",
    'the separator changed',
);

done_testing;
