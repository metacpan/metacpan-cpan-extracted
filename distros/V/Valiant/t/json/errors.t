use Test::Most;
use Valiant::JSON::JSONBuilder;

{
  package Local::Test::User;

  use Moo;
  use Valiant::Validations;

  has username => (is=>'ro');

  validates username => (presence=>1, length=>[3,20]);
}

# The builder is framework agnostic: the content type used to pick the error
# source style comes from the builder itself, not from a web request.

DEFAULT_JSON_POINTER_STYLE: {
  my $user = Local::Test::User->new(username=>'');
  $user->validate;
  ok $user->errors->size, 'user has errors';

  my $jb = Valiant::JSON::JSONBuilder->new(model=>$user);
  lives_ok { $jb->string('username')->errors } 'errors works without a web context';

  is_deeply $jb->render_perl, +{
    local_test_user => { username => '' },
    errors => [
      { detail => "Username can't be blank", source => { pointer => 'local_test_user/username' } },
      { detail => "Username is too short (minimum is 3 characters)", source => { pointer => 'local_test_user/username' } },
    ],
  }, 'errors render at the top level, one object per message, JSON pointer style';
}

FORM_PARAMETER_STYLE: {
  my $user = Local::Test::User->new(username=>'');
  $user->validate;

  my $jb = Valiant::JSON::JSONBuilder->new(model=>$user, content_type=>'application/x-www-form-urlencoded');
  $jb->string('username')->errors;

  is_deeply $jb->render_perl->{errors}[0]{source}, +{ parameter => 'local_test_user.username' },
    'form content types use parameter style sources';
}

UNKNOWN_CONTENT_TYPE_FALLS_BACK: {
  my $user = Local::Test::User->new(username=>'');
  $user->validate;

  my $jb = Valiant::JSON::JSONBuilder->new(model=>$user, content_type=>'text/weird');
  lives_ok { $jb->string('username')->errors } 'unknown content type does not crash';
  is_deeply $jb->render_perl->{errors}[0]{source}, +{ pointer => 'local_test_user/username' },
    'and falls back to pointer style sources';
}

NO_ERRORS_NO_KEY: {
  my $user = Local::Test::User->new(username=>'jjn');
  $user->validate;

  my $jb = Valiant::JSON::JSONBuilder->new(model=>$user);
  $jb->string('username')->errors;

  ok !exists $jb->render_perl->{errors}, 'no errors key when the model is valid';
}

MODEL_WITHOUT_ERRORS_API: {
  my $plain = bless +{}, 'Local::Test::Plain';

  my $jb = Valiant::JSON::JSONBuilder->new(model=>$plain, namespace=>'plain');
  warning_like { $jb->errors } qr/does not support the errors API/, 'carps on a model without errors';
  ok !exists $jb->render_perl->{errors}, 'and adds no errors key';
}

done_testing;
