package Example::Schema::Result::Contact::Phone;

use Example::Syntax;
use base 'Example::Schema::Result';

__PACKAGE__->table("contact_phone");
__PACKAGE__->load_components(qw/Valiant::Result/);

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  contact_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  phone_number => { data_type => 'varchar', is_nullable => 0, size => '96' },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  contact =>
  'Example::Schema::Result::Contact',
  { 'foreign.id' => 'self.contact_id' }
);

__PACKAGE__->validates(phone_number => (
    presence => 1,
    length => [3,24],
    numericality => 'positive_integer')
);

1;
