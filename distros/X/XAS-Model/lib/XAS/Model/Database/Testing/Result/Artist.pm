package # hide from CPAN
  XAS::Model::Database::Testing::Result::Artist;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
    'artist_id' => {
        data_type => 'integer',
    },
    'name' => {
        data_type => 'varchar',
        size => '96',
    });

__PACKAGE__->set_primary_key('artist_id');
__PACKAGE__->has_many(
    'cd_rs' => 'XAS::Model::Database::Testing::Result::CD',
    {'foreign.artist_fk'=>'self.artist_id'});

1;

