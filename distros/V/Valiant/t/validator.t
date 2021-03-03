use Test::Most;

{
  package Local::Test::Validator::Box;

  use Moo;

  with 'Valiant::Validator';

  has max_size => (is=>'ro', required=>1);

  sub validate {
    my ($self, $record, $opts) = @_;
    my $size = $record->height + $record->width + $record->length;
    if($size > $self->max_size) {
      $record->errors->add(undef, "Total of all size cannot exceed ${\$self->max_size}", $opts),
    }
  }

  1;

  package Local::Test::Box;

  use Moo;
  use Valiant::Validations;

  has [qw(height width length)] => (is=>'ro', required=>1);

  validates [qw(height width length)] => (numericality=>+{});

  validates_with 'Box', max_size=>25;
  validates_with 'Box', max_size=>50, on=>'big', message=>'Big for Big!!';
  validates_with 'Box', max_size=>30, on=>'big', if=>'is_odd_shape';

  sub is_odd_shape {
    my ($self) = @_;
    return $self->height > 30 ? 1:0;
  }
}

{
  ok my $object = Local::Test::Box->new(
    height => 67,
    width => 6,
    length => 7);

  ok $object->validate()->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      '*' => [
             'Total of all size cannot exceed 25'
           ]
    };

  ok $object->invalid(context=>'big');
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      '*' => [
             'Total of all size cannot exceed 25',
             'Big for Big!!',
             'Total of all size cannot exceed 30',
           ]
    };
}

done_testing;
