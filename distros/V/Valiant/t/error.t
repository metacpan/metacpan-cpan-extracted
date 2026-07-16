use Test::Most;
use Valiant::Error;
use Valiant::I18N;
{
  package Local::MessageRetrieval;

  use Moo;
  use Valiant::Validations;

  has [qw/name age email password/] => (is=>'ro');
}

my $model = Local::MessageRetrieval->new;

$model->errors->add(undef, "Your Form is invalid");
$model->errors->add(name => "is too short", +{aaa=>1,bbb=>2,ccc=>3});
$model->errors->add(name => "has disallowed characters");
$model->errors->add(age => "must be above 5");
$model->errors->add(email => "does not look like an email address");
$model->errors->add(password => "is too short");
$model->errors->add(password => "can't look like your name");
$model->errors->add(password => "needs to contain both numbers and letters");

ok $model->invalid;

my @all =  $model->errors->errors->all;

ok $all[0]->match(undef, "Your Form is invalid");
ok !$all[0]->match(undef, "Your Form is invalidXX");
ok $all[1]->match(name => "is too short");
ok !$all[1]->match(name => "Your Form is invalid");


ok $all[1]->match(name => "is too short", +{aaa=>1, bbb=>2});
ok !$all[1]->strict_match(name => "is too short", +{aaa=>1, bbb=>2});
ok $all[1]->strict_match(name => "is too short", +{aaa=>1, bbb=>2,ccc=>3});

ok !$all[0]->equals($all[1]);
ok $all[0]->equals($all[0]);

{
  ok my $err = Valiant::Error->new(
    object => $model,
    attribute => 'name',
    type => 'has disallowed characters',
  );

  ok $all[2]->equals($err);
  ok !$all[1]->equals($err), 'not equals';
}

{
  ok my $err = Valiant::Error->new(
    object => $model,
    attribute => 'name',
    type => 'is too short',
    options => +{aaa=>1,bbb=>2,ccc=>3}
  );

  ok !$all[2]->equals($err), 'not equals';
  ok $all[1]->equals($err), 'all1 equals err';

  ok my $err2 = $err->clone;
  ok $err2->equals($err);
}


##clone

{
  # match() must iterate option KEYS only (bug: iterated keys AND values,
  # so a passed value colliding with another option key forced a false non-match)
  ok my $err = Valiant::Error->new(
    object => $model,
    attribute => 'name',
    type => 'is too short',
    options => +{ aaa => 'bbb', bbb => 'xxx' },
  );
  ok $err->match(name => 'is too short', +{ aaa => 'bbb' }),
    'match iterates option keys only';
}

{
  package Local::IndexSpy;

  use Moo;
  use Valiant::Validations;

  has number => (is=>'ro');

  our @seen;
  around 'human_attribute_name' => sub {
    my ($orig, $self, $attribute, @rest) = @_;
    push @seen, $attribute;
    return $self->$orig($attribute, @rest);
  };

  sub read_attribute_for_validation { return undef }
}

{
  # generate_message must strip a dot-indexed nesting the same way full_message
  # does, so both build the same i18n namespace for a nested-indexed attribute.
  @Local::IndexSpy::seen = ();
  ok my $obj = Local::IndexSpy->new;
  ok my $err = Valiant::Error->new(
    object => $obj,
    attribute => 'credit_cards.0.number',
    type => _t('invalid'),
    raw_type => _t('invalid'),
    i18n => $obj->i18n,
  );
  $err->message;
  ok +(grep { $_ eq 'credit_cards.number' } @Local::IndexSpy::seen),
    'generate_message strips the dot index (credit_cards.0.number -> credit_cards.number)';
  ok !+(grep { $_ eq 'credit_cards.0.number' } @Local::IndexSpy::seen),
    'generate_message does not keep the un-stripped dot index';
}

done_testing;
