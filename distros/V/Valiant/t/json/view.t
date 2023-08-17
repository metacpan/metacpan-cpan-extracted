use Test::Most;

{
  package Local::Test::User;

  use Moo;

  has username => (is=>'ro');
  has active => (is=>'ro');
  has profile => (is=>'ro', default=>sub { Local::Test::Profile->new });

  package Local::Test::Profile;

  use Moo;

  has age => (is=>'ro');
  has name => (is=>'ro');
  has email => (is=>'ro'); 

  package Local::Test::Profile::Email;

  use Moo;

  has address => (is=>'ro');

  package Local::Test::View;

  use Moo;
  use Valiant::JSON::JSONBuilder;

  has 'person' => (is=>'ro', required=>1);

  has 'jb' => (
    is=>'ro',
    lazy=>1,
    builder=> sub {
      my $self = shift;
      return Valiant::JSON::JSONBuilder->new(
        view=>$self,
        model=>'person');
    } 
  );

  sub render_empty {
    my $self = shift;
    return $self->jb->render_perl;
  }

  sub render_person {
    my $self = shift;
    return $self->jb->string('username')
      ->boolean('active')
      ->object('profile', \&render_profile)
      ->if(1, \&render_if)
      ->render_perl;
  }

  sub render_if {
    my ($view, $jb) = @_;
    $jb->string('custom', 'custom_value');
  }

  sub render_profile {
    my ($view, $jb, $profile) = @_;
    $jb->number('age')
      ->string('name')
      ->array('email', \&render_email);
  }

  sub render_email {
    my ($view, $jb, $email) = @_;
    $jb->string('address');
  }
}

ok my $user = Local::Test::User->new(
  username=>'bob',
  active=>1,
  profile=>Local::Test::Profile->new(
    age=>40,
    name=>'John',
    email=>[
      Local::Test::Profile::Email->new(address=>'test@test.com'),
      Local::Test::Profile::Email->new(address=>'test2@test.com'),
    ],
  ),
);  

ok my $view = Local::Test::View->new(person=>$user);

is_deeply $view->render_empty, +{ person=>{} };

is_deeply $view->render_person, +{
  person=>{
    username=>'bob',
    custom=>'custom_value',
    active=>1,
    profile=>{
      age=>40,
      name=>'John',
      email => [
        {
          address => "test\@test.com",
        },
        {
          address => "test2\@test.com",
        },
      ],
    },
  },
};

done_testing;