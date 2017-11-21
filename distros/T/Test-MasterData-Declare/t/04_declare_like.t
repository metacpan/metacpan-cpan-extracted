use strict;
use warnings;
use Test2::V0;
use Test::MasterData::Declare;

master_data {
    load_csv
        item => "t/fixture/item.csv",
        item_effect => "t/fixture/item_effect.csv";

    subtest "item.id must be like a number and between 1 to 10" => sub { 
        table item => "id",
            like_number 1 => 10;
    };
    subtest "item_effect.id must be like a number and between 1 to 10" => sub { 
        table item_effect => "id",
            like_number 1 => 3;
    };

    my $event = intercept {
        table item => "id",
            if_column name => "Short Coffee",
            like_number 2;
    };
    is $event, array {
        item object {
            call pass => 0;
        };
        item object {
            call message => match qr!Failed test at t/04_declare_like.t line \d+\.!;
        };
        item object {
            prop blessed => "Test2::Event::Diag",
        };
    };

    table item_effect => "effect_parameters",
        if_column effect_type => 1,
        json night_resistance =>
            like_number 1 => 100,
            sub { $_[0] % 5 == 0 };
};

done_testing;
