use Test::Most;

{
  package Local::Test::Validator::Gpa;

  # An example custom validator.

  use Moo;
  use Valiant::I18N;

  with 'Valiant::Validator::Each';

  has gpa_scale => (is=>'ro', required=>1);

  # Gets run for each attribute

  sub validate_each {
    my ($self, $record, $attribute, $value) = @_;
    my $scale = $self->_cb_value($record, $self->gpa_scale); # allow coderef for dynamic setting
    unless( ($value >= 0) && ($value <= $scale) ) {
      $record->errors->add(
        $attribute,
        "G.P.A must be between 0 and $scale",
        $self->options);
    }
  }

  1;

  package Local::Test::Transcript;

  use Moo;
  use Valiant::Validations;

  has major_gpa   => (is=>'ro', required=>1);
  has minor_gpa   => (is=>'ro', required=>1);
  has overall_gpa => (is=>'ro', required=>1);

  has scale => (is=>'rw', required=>1, default=>4);

  validates [qw(major_gpa minor_gpa overall_gpa)] => (
    gpa => {
      gpa_scale=> sub { shift->scale },
    },
  );

  validates ['major_gpa', 'overall_gpa'] => (
    with => {
      cb => sub {
        my ($self, $attr, $value, $opts) = @_;
        $self->errors->add($attr, 'Needs 2.5 to graduate', $opts)
          unless $value > 2.5;
      },
      on => 'can_graduate',
    },
    on => 'check_graduate',
  );

  validates [qw(major_gpa minor_gpa overall_gpa)] => (
    with => {
      cb => sub {
        my ($self, $attr, $value, $opts) = @_;
        $self->errors->add($attr, 'Cannot be negative', $opts)
          unless $value > 0;
      },
      message => 'no negatives',
      if => sub { shift->scale > 5 },
    },
  );

}

{
  ok my $object = Local::Test::Transcript->new(
    major_gpa => -1,
    minor_gpa => 6,
    overall_gpa=> 7);

  ok $object->validate()->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'minor_gpa' => [
        'Minor Gpa G.P.A must be between 0 and 4',
      ],
      'overall_gpa' => [
        'Overall Gpa G.P.A must be between 0 and 4',
      ],
      'major_gpa' => [
        'Major Gpa G.P.A must be between 0 and 4'
      ]
    };  
        
  $object->errors->clear;
  ok $object->validate(context=>'can_graduate')->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'minor_gpa' => [
        'Minor Gpa G.P.A must be between 0 and 4',
      ],
      'overall_gpa' => [
        'Overall Gpa G.P.A must be between 0 and 4',
      ],
      'major_gpa' => [
        'Major Gpa G.P.A must be between 0 and 4',
        'Major Gpa Needs 2.5 to graduate'
      ]
    };  

  $object->errors->clear;
  ok $object->validate(context=>'check_graduate')->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'minor_gpa' => [
        'Minor Gpa G.P.A must be between 0 and 4',
      ],
      'overall_gpa' => [
        'Overall Gpa G.P.A must be between 0 and 4',
      ],
      'major_gpa' => [
        'Major Gpa G.P.A must be between 0 and 4',
        'Major Gpa Needs 2.5 to graduate'
      ]
    };  

  $object->errors->clear;
  ok $object->validate(context=>['can_graduate','check_graduate'])->invalid;
  is_deeply +{ $object->errors->to_hash(full_messages=>1) },
    {
      'minor_gpa' => [
        'Minor Gpa G.P.A must be between 0 and 4',
      ],
      'overall_gpa' => [
        'Overall Gpa G.P.A must be between 0 and 4',
      ],
      'major_gpa' => [
        'Major Gpa G.P.A must be between 0 and 4',
        'Major Gpa Needs 2.5 to graduate'
      ]
    };  

  $object->errors->clear;
  $object->scale(6);
  ok $object->validate()->invalid;
  is_deeply +{ $object->errors->to_hash(1) },
    {
      'overall_gpa' => [
        'Overall Gpa G.P.A must be between 0 and 6',
      ],
      'major_gpa' => [
        'Major Gpa G.P.A must be between 0 and 6',
        'Major Gpa no negatives',
      ]
    };  
    
}

done_testing;
