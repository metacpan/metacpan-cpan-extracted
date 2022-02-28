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

done_testing;
