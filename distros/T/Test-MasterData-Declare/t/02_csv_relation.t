use strict;
use warnings;
use Test::More;
use Test::MasterData::Declare;

master_data {
    load_csv
        item        => "t/fixture/item.csv",
        item_effect => "t/fixture/item_effect.csv";

    relation
        item           => "item_effect",
        item_effect_id => "id";
};

done_testing;
