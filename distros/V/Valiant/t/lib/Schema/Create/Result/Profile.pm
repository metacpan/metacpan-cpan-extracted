package Schema::Create::Result::Profile;

use DBIx::Class::Candy -base => 'Schema::Result';

table "profile";

column id => { data_type => 'bigint', is_nullable => 0, is_auto_increment => 1 };
column person_id => { data_type => 'integer', is_nullable => 0, is_foreign_key => 1 };
column address => { data_type => 'varchar', is_nullable => 0, size => 48 };
column city => { data_type => 'varchar', is_nullable => 0, size => 32 };
column zip => { data_type => 'varchar', is_nullable => 0, size => 5 };
column birthday => { data_type => 'date', is_nullable => 1 };

primary_key "id";
unique_constraint ['id','person_id'];

belongs_to person => (
  'Schema::Create::Result::Person',
  { 'foreign.id' => 'self.person_id' }
);

validates address => (presence=>1, length=>[2,48]);
validates city => (presence=>1, length=>[2,32]);
validates zip => (presence=>1, format=>'zip', on=>['create','update']); # context here to make sure context passed to nested
validates birthday => (
  date => {
    max => sub { pop->now->subtract(days=>2) }, 
    min => sub { pop->years_ago(30) }, 
  }
);


1;
