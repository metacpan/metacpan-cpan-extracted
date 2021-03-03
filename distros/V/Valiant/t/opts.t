use Test::Most;

# Make sure you can pass opts via 'validate or via an opts arguement when
# creating a validation and that those opts end up in the %options hash
# for callbacks and I18n
#
# This also ends up being a drive by test for callback and scalar rfs on messages.

{
  package Local::Test::Opts;

  use Moo;
  use Valiant::Validations;
  use Valiant::I18N;

  has age => (is=>'ro');

  validates age => (
    with => {
      opts => { opt1 => 'opt1' },
      message => sub {
        my ($self, $attribute_name, $value, $opts) = @_;
        Test::Most::is $opts->{opt1}, 'opt1';
        Test::Most::is $opts->{opt2}, 'opt2';
        Test::Most::is $opts->{opt3}, 'opt3';
        Test::Most::is $opts->{attribute}, 'Age';
        Test::Most::is $opts->{count}, '1';
        Test::Most::is $opts->{model}, 'Opts';
        Test::Most::is $opts->{object}, $self;
        Test::Most::is $opts->{value}, $value;
        'opts';
      },
      cb => sub {
        my ($self, $attribute_name, $value, $opts) = @_;
        Test::Most::is $opts->{opt1}, 'opt1';
        Test::Most::is $opts->{opt2}, 'opt2';
        $self->errors->add($attribute_name, 'will be ignored', { opt3=>'opt3', %$opts });
      },
    },
    with => sub { shift->errors->add(shift, 'ignore2', +{%{ pop @_ }, opt1=>'optB' }) },
    message => \'{{value}} {{attribute}} {{opt1}} {{opt2}}'
  );
}

{
  ok my $object = Local::Test::Opts->new(age=>1110);
  ok $object->validate(opt2=>'opt2')->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      age => [
        "Age opts",
        "Age 1110 Age optB opt2",
      ],
    };
}

done_testing;
