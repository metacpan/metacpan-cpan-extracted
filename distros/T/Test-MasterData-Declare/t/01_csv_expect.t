use strict;
use warnings;
use Test::More;
use Test::MasterData::Declare;

master_data {
    load_csv item => "t/fixture/item.csv";

    expect_row item => sub {
        my $row = shift;
        like $row->{name}, qr/\A[A-Za-z0-9 ]+\z/;
    };
};

done_testing;
