use Test::Most;

{
  package Local::Test::If;

  use Moo;
  use Valiant::Validations;

  has 'name' => (
    is => 'ro',
  );

  validates 'name' => (
    length => {
      in => [2,11],
      if => sub {
        my ($self, $attr, $value, $opts) = @_;
        Test::Most::ok $opts->{opt} if $value eq 'CC';
        return $self->name eq 'AA';
      },
    },
    with => {
      cb => sub {
        my ($self, $attr, $value, $opts) = @_;
        Test::Most::ok $opts->{special} if $value eq 'BB';
        $self->errors->add($attr, 'failed');
      },
    },
    if => sub {
      # An 'if' or 'unless' that is a global option does not
      # get $attribute or $value since its scoped to the collection
      # of validations and the collection could refer to one or more
      # attributes.
      my ($self, $object, $opts) = @_;
      return $self->name eq 'BB';
    },
  );
}

{
  ok my $object = Local::Test::If->new(name=>'CC');
  ok $object->validate(opt=>1)->valid;
}

{
  ok my $object = Local::Test::If->new(name=>'BB');
  ok $object->validate(special=>1)->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      name => [
      "Name failed",
      ],      
    };
}

# Need to specify the number of tests to make sure we are hitting
# and passing tests inside the test class.

done_testing(7);
