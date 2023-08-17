package Example::View::JSON::Account::Edit;
 
use Moose;
use Example::Syntax;

extends 'Catalyst::View::Valiant::JSONBuilder';

has account => (is=>'ro', required=>1);

sub render_json($self, $c) {
  my $jb = $self->json_builder('account');

  return $jb->string('username')
    ->string('first_name')
    ->string('last_name')
    ->object('profile', \&render_profile)
    ->array('person_roles', \&render_person_role)
    ->array('credit_cards', \&render_credit_card)
    ->errors();
}

sub render_profile($self, $jb, $profile) {
  return $jb->string('address')
    ->string('city')
    ->number('state_id')
    ->string('zip')
    ->string('phone_number')
    ->string('birthday')
    ->string('status')
    ->boolean('registered')
    ->number('employment_id')
}

sub render_person_role($self, $jb, $person_role) {
  return $jb->number('role_id')
}

sub render_credit_card($self, $jb, $credit_card) {
  return $jb->number('id')
    ->string('card_number')
    ->string('expiration')
    ->boolean('_delete')
}

 
__PACKAGE__->config(status_codes=>[200,400]);
__PACKAGE__->meta->make_immutable();





__END__

  $jb->username_str
    ->first_name_str
    ->str::last_name
    ->profile(sub($jb, $profile) {
      $jb->address
        ->city
        ->state_id
        ->zip
        ->phone_number
        ->birthday
        ->status
        ->registered
        ->employment_id;
    })
    ->person_roles(sub($jb, $person_role) {
      $jb->role_id;
    })
    ->credit_cards(sub($jb, $credit_card) {
      $jb->id
        ->card_number
        ->expiration
        ->_delete;
    });



return $jb->string('username', {value=>undef, omit_undef=>1})
    ->with_model($self->account->profile, sub ($v, $jb, $profile) {
      $jb->string('address', +{name=>'address-proxy'})
    })
    ->string('first_name', {name=>'first-name', value=>'1111'})
    ->string('empty', {value=>'abc', omit_empty=>1})
    ->string('tokena', {value=>"ssss", name=>'token-a'})
    ->string('token', "sdfsdfsdfsdfsdf")
    ->object('profile', +{namespace=>'me'}, sub($v, $jb, $profile) {
      $jb->string('address')
        ->if(1, sub($v, $jb) { $jb->string('city', $jb->current_model->address) })
        ->if(sub {0}, sub($v, $jb) { $jb->string('city', $jb->current_model->address) })  
        ->number('state_id') 
    })
    ->object('profile', +{namespace=>'empty-profile', omit_empty=>1}, sub($v, $jb, $profile) {})
    ->object('profile', +{namespace=>'empty-profile-ok'}, sub($v, $jb, $profile) {}) 
    ->object('profile', \&render_profile)
    ->string('last_name')
    ->array('person_roles', +{namespace=>'empty-pr', omit_empty=>1}, sub($v, $jb, $person_role) {})
    ->array('person_roles', sub($v, $jb, $person_role) {
      $jb->number('role_id');
    })
    ->array('credit_cards', +{namespace=>'credit-cards'}, sub($v, $jb, $credit_card) {
      $jb->number('id')
        ->string('_delete')
        ->string('card_number');
        #->date('expiration')
    })
    ->if(scalar(@errors), sub ($v, $jb) {
      $jb->array(\@errors, {namespace=>'errors'}, sub ($v, $jb, $error) {
        $jb->string('source', $error->{source}) if exists $error->{source};
        $jb->string('detail', $error->{detail});
      })
    });

    # ->model() set current model until end, if hashref make that into a model