package MyDB::Schema::Result::Title;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('title');
__PACKAGE__->add_columns(qw/ href release_date title can_rent adult /);
__PACKAGE__->add_columns(
    id                     => { data_type => 'integer', size => 16, is_nullable => 0, is_auto_increment => 1, default_value => '' },
    run_time               => { data_type => 'integer', size =>  4, is_nullable => 1, is_auto_increment => 0, default_value => '' },
    datasource_id          => { data_type => 'integer', size =>  4, is_nullable => 1, is_auto_increment => 0, default_value => '' }, # Lovefilm/Netflix/IMDB etc
    datasource_internal_id => { data_type => 'integer', size => 10, is_nullable => 1, is_auto_increment => 0, default_value => '' }, # lovefilm/netflix ID
    number_of_ratings      => { data_type => 'integer', size =>  6, is_nullable => 1, is_auto_increment => 0, default_value => '' },
    rating                 => { data_type => 'integer', size =>  4, is_nullable => 1, is_auto_increment => 0, default_value => '' },
);
__PACKAGE__->add_columns(
    adult             => { data_type => 'boolean', is_nullable => 0, default_value => '' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( 
    datasource_id =>
    'MyDB::Schema::Result::Datasource',
    'id'
);
__PACKAGE__->has_many(title_person   => 'MyDB::Schema::Result::TitlePerson', 'person_id');
__PACKAGE__->many_to_many( persons   => 'title_person', 'person_id');
__PACKAGE__->has_many(title_categories => 'MyDB::Schema::Result::TitleCategories', 'title_id');
__PACKAGE__->many_to_many(categories   => 'title_categories', 'catergory');

1;
