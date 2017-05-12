package TestApp::Schema::Result::MultiPk;
use parent 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components('Core');
__PACKAGE__->table('MultiPk');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    bill => { data_type => 'varchar' },
    ted  => { data_type => 'varchar' }
);
__PACKAGE__->set_primary_key(qw{bill ted});

1;
