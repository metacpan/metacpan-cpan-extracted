package Example::Schema::Result::CreditCard;

use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;

use base 'Example::Schema::Result';

__PACKAGE__->table("credit_card");
__PACKAGE__->load_components(qw/Valiant::Result/);

__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
  person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 },
  card_number => { data_type => 'varchar', is_nullable => 0, size => '20' },
  expiration => { data_type => 'date', is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->validates(card_number => (presence=>1, length=>[13,20], with=>'looks_like_a_cc' ));
__PACKAGE__->validates(expiration => (presence=>1, with=>'looks_like_a_datetime', with=>'is_future' ));

__PACKAGE__->belongs_to(
  person =>
  'Example::Schema::Result::Person',
  { 'foreign.id' => 'self.person_id' }
);

sub looks_like_a_cc {
  my ($self, $attribute_name, $value) = @_;
  return if $value =~/^\d{13,20}$/;
  $self->errors->add($attribute_name, 'does not look like a credit card'); 
}

my $strp = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d');

sub looks_like_a_datetime {
  my ($self, $attribute_name, $value) = @_;
  my $dt = $strp->parse_datetime($value);
  $self->errors->add($attribute_name, 'does not look like a datetime value') unless $dt;
}

sub is_future {
  my ($self, $attribute_name, $value) = @_;
  my $dt = $strp->parse_datetime($value);
  $self->errors->add($attribute_name, 'must be in the future') unless $dt && ($dt > DateTime->now);
}


1;
