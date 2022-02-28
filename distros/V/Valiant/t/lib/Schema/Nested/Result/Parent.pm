package Schema::Nested::Result::Parent;

use base 'Schema::Result';

__PACKAGE__->table("parent");

__PACKAGE__->add_columns(
  id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 },
  value => { data_type => 'varchar', is_nullable => 0, size => 48 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  children =>
  'Schema::Nested::Result::Child',
  { 'foreign.parent_id' => 'self.id' },
);

__PACKAGE__->validates( value => (presence=>1, length=>[1,48]) );

__PACKAGE__->accept_nested_for('children', {allow_destroy=>1});

1;

__END__

__PACKAGE__->accept_nested_for(
  might => {
    update_only => 1,
    reject_if => sub {
      my ($self, $params) = @_;
      return ($params->{value}||'') eq 'test14' ? 1:0;
    },
  }
);

