package MyDB::Schema::Result::TitlePerson;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('title_person');
__PACKAGE__->add_columns(qw/ person_type /);
__PACKAGE__->add_columns(
    id        => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 1, default_value => '' },
    title_id  => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 0, default_value => '' },
    person_id => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 0, default_value => '' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(person => 'MyDB::Schema::Result::Person', 'person_id');
__PACKAGE__->belongs_to(title  => 'MyDB::Schema::Result::Title',  'title_id');

1;
