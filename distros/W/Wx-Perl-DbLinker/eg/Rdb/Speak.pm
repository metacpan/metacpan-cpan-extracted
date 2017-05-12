package Rdb::Speak;

use strict;

use base qw(Rdb::DB::Object::AutoBase1);

__PACKAGE__->meta->setup(
    table   => 'speaks',

    columns => [
        speaksid  => { type => 'serial', not_null=>1 },
        countryid => { type => 'integer', not_null => 1 },
        langid    => { type => 'integer', not_null => 1 },
    ],

    primary_key_columns => [ 'speaksid' ],

       relationships => [
	    countryid_country => {
	    	type => 'many to one',
		class => 'Rdb::Country',
		column_map => {countryid => 'countryid'},
	    },
	    langid_lang => {
		type => 'many to one',
		class => 'Rdb::Langue',
		column_map => {langid => 'langid'},
	    },

    ],
);

1;

