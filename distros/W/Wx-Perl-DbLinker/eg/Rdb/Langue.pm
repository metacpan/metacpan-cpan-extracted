package Rdb::Langue;

use strict;

use base qw(Rdb::DB::Object::AutoBase1);

__PACKAGE__->meta->setup(
    table   => 'langues',

    columns => [
        langid => { type => 'serial', not_null =>1},
        langue => { type => 'text', not_null => 1 },
    ],

    primary_key_columns => [ 'langid' ],
    
        relationships => [
    	speaks =>{ 
		type => 'many to one',
		class => 'Rdb::Speak',
		column_map => {langid => 'langid'},
		},
    ]
);

1;

