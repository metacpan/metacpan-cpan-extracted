use strict;
use warnings;
use utf8;

use Test2::V0;
use Test::MasterData::Declare::Reader;

my $csv_file = "t/fixture/item.csv";

my $reader = Test::MasterData::Declare::Reader->read_csv_from(
    filepath   => $csv_file,
    table_name => "item",
);

isa_ok $reader, "Test::MasterData::Declare::Reader";

my $rows = $reader->rows;
is scalar(@$rows), 3;

my $row = shift @$rows;
like $row->row, hash {
    number("id");
    field id             => 1;
    field name           => "Short Coffee";
    field item_effect_id => 1;
    field begin_at       => "2017-01-01 00:00:00";
    field end_at         => "2018-01-01 00:00:00";
};

done_testing;
