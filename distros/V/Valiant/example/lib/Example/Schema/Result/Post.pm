package Example::Schema::Result::Post;

use Example::Syntax;
use base 'Example::Schema::Result';

__PACKAGE__->table('posts');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
        is_nullable => 0,
    },
    person_id => {
        data_type => 'integer',
        is_nullable => 0,
    },
    title => {
        data_type => 'text',
        is_nullable => 0,
    },
    content => {
        data_type => 'text',
        is_nullable => 0,
    },
    created_at => {
        data_type => 'datetime',
        set_on_create => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    author => 'Example::Schema::Result::Person',
    { 'foreign.id' => 'self.person_id' },
    {
        on_delete => 'CASCADE',
    },
);

__PACKAGE__->has_many(
  comments =>
  'Example::Schema::Result::Comment',
  { 
    'foreign.post_id' => 'self.id',
  }
);

1;
