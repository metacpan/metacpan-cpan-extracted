package MyDB::Schema::Result::TitleCategories;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('title_category');
__PACKAGE__->add_columns(
    id          => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 1, default_value => '' },
    title_id    => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 0, default_value => '' },
    category_id => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 0, default_value => '' },

);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(catergory  => 'MyDB::Schema::Result::Category', 'category_id');
__PACKAGE__->belongs_to(title      => 'MyDB::Schema::Result::Title',    'title_id');

1;
