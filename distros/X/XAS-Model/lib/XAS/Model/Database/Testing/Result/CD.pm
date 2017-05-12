package # hide from CPAN
  XAS::Model::Database::Testing::Result::CD;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cd');
__PACKAGE__->add_columns(
    'cd_id' => {
        data_type => 'integer',
    },
    'artist_fk' => {
        data_type => 'integer',
    },
    'title' => {
        data_type => 'varchar',
        size => '96',
    }
);

__PACKAGE__->set_primary_key('cd_id');

__PACKAGE__->belongs_to(
    'artist' => 'XAS::Model::Database::Testing::Result::Artist',
    {'foreign.artist_id'=>'self.artist_fk'}
);

__PACKAGE__->has_many(
    'track_rs' => 'XAS::Model::Database::Testing::Result::Track',
    {'foreign.cd_fk'=>'self.cd_id'}
);

1;

