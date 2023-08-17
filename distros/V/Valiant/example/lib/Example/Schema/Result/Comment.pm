package Example::Schema::Result::Comment;

use Example::Syntax;
use base 'Example::Schema::Result';

__PACKAGE__->table('comments');
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
    post_id => {
        data_type => 'integer',
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
__PACKAGE__->validates(content => ( length => [5, 3500] ));

__PACKAGE__->belongs_to(
    person => 'Example::Schema::Result::Person',
    { 'foreign.id' => 'self.person_id' },
    {
        on_delete => 'CASCADE',
    },
);
__PACKAGE__->belongs_to(
    post => 'Example::Schema::Result::Post',
    { 'foreign.id' => 'self.post_id' },
    {
        on_delete => 'CASCADE',
    },
);

1;
