package MyDB::Schema::Result::Person;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('person');
__PACKAGE__->add_columns(qw/ href name person_type/);
__PACKAGE__->add_columns(
    id => { data_type => 'integer', size =>   6, is_nullable => 0, is_auto_increment => 1, default_value => '' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(title_persons => 'MyDB::Schema::Result::TitlePerson', 'person_id');
__PACKAGE__->many_to_many(titles => 'title_persons', 'title');

1;
