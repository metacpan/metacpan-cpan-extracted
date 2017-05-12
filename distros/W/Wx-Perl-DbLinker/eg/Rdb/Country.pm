package Rdb::Country;

use strict;

use base qw(Rdb::DB::Object::AutoBase1);

__PACKAGE__->meta->setup(
    table   => 'countries',

    columns => [
        countryid  => { type => 'serial', not_null => 1 },
        country    => { type => 'text', not_null => 1 },
        mainlangid => { type => 'integer' },
    ],

    primary_key_columns => [ 'countryid' ],

        relationships => [
    	speaks =>{ 
		type => 'many to one',
		class => 'Rdb::Speak',
		column_map => {countryid => 'countryid'},
		},
    ]
);

1;

