use Test::Most;
use Valiant::HTML::FormBuilder;
use DateTime;
use Valiant::HTML::Util::Collection;
use Valiant::HTML::Util::View;
use Valiant::HTML::Util::Form;

{
  package Local::Role;

  use Moo;
  use Valiant::Validations;

  has ['id', 'label'] => (is=>'ro', required=>1);

  package Local::State;

  use Moo;
  use Valiant::Validations;

  has ['id', 'name'] => (is=>'ro', required=>1);

  around '_humanize' => sub {
    my ($orig, $self, $text) = @_;
    return $text;
  };

  package Local::Profile;

  use Moo;
  use Valiant::Validations;

  has address => (is=>'ro');
  has zip => (is=>'ro');

  validates address => (
    length => {
      maximum => 40,
      minimum => 3,
    },
  );

  package Local::CreditCard;

  use Moo;
  use Valiant::Validations;

  has ['number', 'expiration'] => (is=>'ro', required=>1);

  validates number => (presence=>1, length=>[13,20] );
  validates expiration => (presence=>1, date=>'is_future' ); 

  package Local::Person;

  use Moo;
  use Valiant::Validations;
  use Valiant::Filters;

  has first_name => (is=>'ro');
  has last_name => (is=>'ro');
  has status => (is=>'rw');
  has type => (is=>'rw');
  has birthday => (is=>'rw');
  has due => (is=>'rw');
  has profile => (is=>'ro');
  has credit_cards => (is=>'ro');
  has state_id =>(is=>'ro');
  has state_id2 =>(is=>'ro');
  has state_ids =>(is=>'rw');
  has roles => (is=>'ro');

  validates ['first_name', 'last_name'] => (
    length => {
      maximum => 10,
      minimum => 3,
    }
  );

  validates profile => (object=>1); 
  validates credit_cards => (array=>[object=>1]); 
  validates roles => (array=>[object=>1]); 

  validates_with sub {
    my ($self, $opts) = @_;
    $self->errors->add(undef, 'Trouble 1', $opts);
    $self->errors->add(undef, 'Trouble 2', $opts);
    $self->errors->add('first_name', 'contains non alphabetic characters', $opts);
    $self->errors->add('status', 'bad value', $opts);
    $self->errors->add('type', 'bad value', $opts);
    $self->errors->add('birthday', 'bad value', $opts);
  };
}

ok my ($user, $admin, $guest) = map {
  Local::Role->new($_);
} (
  {id=>1, label=>'user'},
  {id=>2, label=>'admin'},
  {id=>3, label=>'guest'},
);

ok my $roles_collection = Valiant::HTML::Util::Collection->new($user, $admin, $guest);

ok my ($tx, $ny, $ca) = map {
  Local::State->new($_);
} (
  {id=>10, name=>'TX'},
  {id=>20, name=>'NY'},
  {id=>30, name=>'CA'},
);

ok my $states_collection = Valiant::HTML::Util::Collection->new($tx, $ny, $ca);

ok my $person = Local::Person->new(
  first_name=>'J', 
  last_name=>'Napiorkowski',
  birthday=>DateTime->new(year=>1969, month=>2, day=>13),
  due=>DateTime->new(year=>1969, month=>2, day=>13, hour=>10, minute=>45, second=>11, nanosecond=> 500000000, time_zone  => 'UTC'),
  profile=>Local::Profile->new(zip=>'78621', address=>'ab'),
  credit_cards=>[
    Local::CreditCard->new(number=>'234234223444', expiration=>DateTime->now->add(months=>11)),
    Local::CreditCard->new(number=>'342342342322', expiration=>DateTime->now->add(months=>11)),
    Local::CreditCard->new(number=>'111112222233', expiration=>DateTime->now->subtract(months=>11)),
  ],
  state_id => 10,
  state_ids => [10,30],
  roles=>[$user,$admin],
  type=>'admin');

ok $person->invalid; # runs validation and verify that the model has errors.

ok my $fb = Valiant::HTML::FormBuilder->new(
  model => $person,
  name => 'person');

is $fb->model_errors, '<ol><li>Trouble 1</li><li>Trouble 2</li></ol>';
is $fb->model_errors({class=>'foo'}), '<ol class="foo"><li>Trouble 1</li><li>Trouble 2</li></ol>';
is $fb->model_errors({max_errors=>1}), '<div>Trouble 1</div>';
is $fb->model_errors({max_errors=>1, class=>'foo'}), '<div class="foo">Trouble 1</div>';
is $fb->model_errors({show_message_on_field_errors=>1}), '<ol><li>Form has errors</li><li>Trouble 1</li><li>Trouble 2</li></ol>';
is $fb->model_errors({show_message_on_field_errors=>"Bad!"}), '<ol><li>Bad!</li><li>Trouble 1</li><li>Trouble 2</li></ol>';
is $fb->model_errors(sub {
  my (@errors) = @_;
  join " | ", @errors;
}), 'Trouble 1 | Trouble 2';

is $fb->label('first_name'), '<label for="person_first_name">First Name</label>';
is $fb->label('first_name', {class=>'foo'}), '<label class="foo" for="person_first_name">First Name</label>';
is $fb->label('first_name', 'Your First Name'), '<label for="person_first_name">Your First Name</label>';
is $fb->label('first_name', {class=>'foo'}, 'Your First Name'), '<label class="foo" for="person_first_name">Your First Name</label>';
is $fb->label('first_name', sub {
  my $translated_attribute = shift;
  return "$translated_attribute ",
    $fb->input('first_name');
}), '<label for="person_first_name">First Name <input id="person_first_name" name="person.first_name" type="text" value="J"/></label>';

is $fb->label('first_name', +{class=>'foo'}, sub {
  my $translated_attribute = shift;
  return "$translated_attribute ",
    $fb->input('first_name');
}), '<label class="foo" for="person_first_name">First Name <input id="person_first_name" name="person.first_name" type="text" value="J"/></label>';

is $fb->errors_for('first_name'), '<ol data-error-list="1" id="person_first_name_errors"><li data-error-param="1">First Name is too short (minimum is 3 characters)</li><li data-error-param="1">First Name contains non alphabetic characters</li></ol>';
is $fb->errors_for('first_name', {class=>'foo'}), '<ol class="foo" data-error-list="1" id="person_first_name_errors"><li data-error-param="1">First Name is too short (minimum is 3 characters)</li><li data-error-param="1">First Name contains non alphabetic characters</li></ol>';
is $fb->errors_for('first_name', {class=>'foo', max_errors=>1}), '<div class="foo" data-error-param="1" id="person_first_name_errors">First Name is too short (minimum is 3 characters)</div>';
is $fb->errors_for('first_name', sub {
  my (@errors) = @_;
  join " | ", @errors;
}), 'First Name is too short (minimum is 3 characters) | First Name contains non alphabetic characters';
is $fb->errors_for('first_name', {max_errors=>1},sub {
  my (@errors) = @_;
  join " | ", @errors;
}), 'First Name is too short (minimum is 3 characters)';

is $fb->input('first_name'), '<input id="person_first_name" name="person.first_name" type="text" value="J"/>';
is $fb->input('first_name', {class=>'foo'}), '<input class="foo" id="person_first_name" name="person.first_name" type="text" value="J"/>';
is $fb->input('first_name', {errors_classes=>'error'}), '<input class="error" id="person_first_name" name="person.first_name" type="text" value="J"/>';
is $fb->input('first_name', {class=>'foo', errors_classes=>'error'}), '<input class="foo error" id="person_first_name" name="person.first_name" type="text" value="J"/>';
is $fb->input('first_name', {class=>'foo', errors_attrs=>{ class=>'error'}}), '<input class="foo error" id="person_first_name" name="person.first_name" type="text" value="J"/>';

is $fb->password('first_name'), '<input id="person_first_name" name="person.first_name" type="password" value=""/>';
is $fb->password('first_name', {class=>'foo'}), '<input class="foo" id="person_first_name" name="person.first_name" type="password" value=""/>';
is $fb->password('first_name', {errors_classes=>'error'}), '<input class="error" id="person_first_name" name="person.first_name" type="password" value=""/>';
is $fb->password('first_name', {class=>'foo', errors_classes=>'error'}), '<input class="foo error" id="person_first_name" name="person.first_name" type="password" value=""/>';

is $fb->hidden('first_name'), '<input id="person_first_name" name="person.first_name" type="hidden" value="J"/>';
is $fb->hidden('first_name', {class=>'foo'}), '<input class="foo" id="person_first_name" name="person.first_name" type="hidden" value="J"/>';
is $fb->hidden('first_name', {errors_classes=>'error'}), '<input class="error" id="person_first_name" name="person.first_name" type="hidden" value="J"/>';
is $fb->hidden('first_name', {class=>'foo', errors_classes=>'error'}), '<input class="foo error" id="person_first_name" name="person.first_name" type="hidden" value="J"/>';

is $fb->text_area('first_name'), '<textarea id="person_first_name" name="person.first_name">J</textarea>';
is $fb->text_area('first_name', {class=>'foo'}), '<textarea class="foo" id="person_first_name" name="person.first_name">J</textarea>';
is $fb->text_area('first_name', {class=>'foo', errors_classes=>'error'}), '<textarea class="foo error" id="person_first_name" name="person.first_name">J</textarea>';

is $fb->checkbox('status'), '<input name="person.status" type="hidden" value="0"/><input id="person_status" name="person.status" type="checkbox" value="1"/>';
is $fb->checkbox('status', {class=>'foo'}), '<input name="person.status" type="hidden" value="0"/><input class="foo" id="person_status" name="person.status" type="checkbox" value="1"/>';
is $fb->checkbox('status', 'active', 'deactive'), '<input name="person.status" type="hidden" value="deactive"/><input id="person_status" name="person.status" type="checkbox" value="active"/>';
is $fb->checkbox('status', {include_hidden=>0}), '<input id="person_status" name="person.status" type="checkbox" value="1"/>';
$person->status(1);
is $fb->checkbox('status', {include_hidden=>0}), '<input checked id="person_status" name="person.status" type="checkbox" value="1"/>';
$person->status(0);
is $fb->checkbox('status', {include_hidden=>0, checked=>1}), '<input checked id="person_status" name="person.status" type="checkbox" value="1"/>';
is $fb->checkbox('status', {include_hidden=>0, errors_classes=>'err'}), '<input class="err" id="person_status" name="person.status" type="checkbox" value="1"/>';


is $fb->radio_button('type', 'admin'), '<input checked id="person_type_admin" name="person.type" type="radio" value="admin"/>';
is $fb->radio_button('type', 'user'), '<input id="person_type_user" name="person.type" type="radio" value="user"/>';
is $fb->radio_button('type', 'guest'), '<input id="person_type_guest" name="person.type" type="radio" value="guest"/>';

is $fb->radio_button('type', 'guest', {class=>'foo', errors_classes=>'err'}), '<input class="foo err" id="person_type_guest" name="person.type" type="radio" value="guest"/>';
is $fb->radio_button('type', 'guest', {checked=>1}), '<input checked id="person_type_guest" name="person.type" type="radio" value="guest"/>';

is $fb->date_field('birthday'), '<input id="person_birthday" name="person.birthday" type="date" value="1969-02-13"/>';
is $fb->date_field('birthday', {class=>'foo', errors_classes=>'err'}), '<input class="foo err" id="person_birthday" name="person.birthday" type="date" value="1969-02-13"/>';
is $fb->date_field('birthday', +{
  min => DateTime->new(year=>1900, month=>1, day=>1),
  max => DateTime->new(year=>2030, month=>1, day=>1),
}), '<input id="person_birthday" max="2030-01-01" min="1900-01-01" name="person.birthday" type="date" value="1969-02-13"/>';


is $fb->datetime_local_field('due'), '<input id="person_due" name="person.due" type="datetime-local" value="1969-02-13T10:45:11"/>';
is $fb->time_field('due'), '<input id="person_due" name="person.due" type="time" value="10:45:11.500"/>';
is $fb->time_field('due', +{include_seconds=>0}), '<input id="person_due" name="person.due" type="time" value="10:45"/>';

is $fb->submit, '<input id="commit" name="commit" type="submit" value="Submit Person"/>';
is $fb->submit('fff', {class=>'foo'}), '<input class="foo" id="commit" name="commit" type="submit" value="fff"/>';

is $fb->button('type'), '<button id="person_type" name="person.type" type="submit" value="admin">Button</button>';
is $fb->button('type', {class=>'foo'}), '<button class="foo" id="person_type" name="person.type" type="submit" value="admin">Button</button>';
is $fb->button('type', "Press Me"), '<button id="person_type" name="person.type" type="submit" value="admin">Press Me</button>';
is $fb->button('type', sub { "Press Me" }), '<button id="person_type" name="person.type" type="submit" value="admin">Press Me</button>';

is $fb->legend, '<legend>New Person</legend>';
is $fb->legend({class=>'foo'}), '<legend class="foo">New Person</legend>';
is $fb->legend("Person"), '<legend>Person</legend>';
is $fb->legend("Persons", {class=>'foo'}), '<legend class="foo">Persons</legend>';
is $fb->legend(sub { shift . " Info"}), '<legend>New Person Info</legend>';
is $fb->legend({class=>'foo'}, sub {"Person"}), '<legend class="foo">Person</legend>';

is $fb->fields_for('profile', sub {
  my $view = shift;
  my $fb_profile = shift;
  return  $fb_profile->input('address'),
          $fb_profile->errors_for('address'),
          $fb_profile->input('zip');

}), '<input id="person_profile_address" name="person.profile.address" type="text" value="ab"/><div data-error-param="1" id="person_profile_address_errors">Address is too short (minimum is 3 characters)</div><input id="person_profile_zip" name="person.profile.zip" type="text" value="78621"/>';

is $fb->fields_for('credit_cards', sub {
  my $view = shift;
  my $fb_cc = shift;
  return  $fb_cc->input('number'),
          $fb_cc->date_field('expiration'),
          $fb_cc->errors_for('expiration');
}, sub {
  my $view = shift;
  my $fb_finally = shift;
  return  $fb_finally->button('add', +{value=>1}, 'Add a New Credit Card');
}), '<input id="person_credit_cards_0_number" name="person.credit_cards[0].number" type="text" value="234234223444"/><input id="person_credit_cards_0_expiration" name="person.credit_cards[0].expiration" type="date" value="'.$person->credit_cards->[0]->expiration->ymd.'"/><input id="person_credit_cards_1_number" name="person.credit_cards[1].number" type="text" value="342342342322"/><input id="person_credit_cards_1_expiration" name="person.credit_cards[1].expiration" type="date" value="'.$person->credit_cards->[1]->expiration->ymd.'"/><input id="person_credit_cards_2_number" name="person.credit_cards[2].number" type="text" value="111112222233"/><input id="person_credit_cards_2_expiration" name="person.credit_cards[2].expiration" type="date" value="'.$person->credit_cards->[2]->expiration->ymd.'"/><div data-error-param="1" id="person_credit_cards_2_expiration_errors">Expiration chosen date can&#39;t be earlier than '.DateTime->now->ymd.'</div><button id="person_credit_cards_3_add" name="person.credit_cards[3].add" type="submit" value="1">Add a New Credit Card</button>';

is $fb->select('state_id', [11,22,33], +{class=>'foo'} ), '<select class="foo" id="person_state_id" name="person.state_id"><option value="11">11</option><option value="22">22</option><option value="33">33</option></select>';


is $fb->select('state_id', [10,20,30], +{class=>'foo'} ), '<select class="foo" id="person_state_id" name="person.state_id"><option selected value="10">10</option><option value="20">20</option><option value="30">30</option></select>';

is $fb->select('state_id', [10,20,30], +{selected=>[30], disabled=>[10],class=>'foo'} ), '<select class="foo" id="person_state_id" name="person.state_id"><option disabled value="10">10</option><option value="20">20</option><option selected value="30">30</option></select>';

is $fb->select('state_id', [map { [$_->name, $_->id] } $states_collection->all], +{include_blank=>1} ), '<select id="person_state_id" name="person.state_id"><option label=" " value=""></option><option selected value="10">TX</option><option value="20">NY</option><option value="30">CA</option></select>';

is $fb->select('state_id', sub {
  my ($model, $attribute, $value) = @_;
  return map {
    my $selected = $_->id eq $value ? 1:0;
    $fb->tag_helpers->option_tag($_->name, +{class=>'foo', selected=>$selected, value=>$_->id}); 
  } $states_collection->all;
}), '<select id="person_state_id" name="person.state_id"><option class="foo" selected value="10">TX</option><option class="foo" value="20">NY</option><option class="foo" value="30">CA</option></select>';

is $fb->select('state_id', +{multiple=>1}, sub {
  my ($model, $attribute, $value) = @_;
  return map {
    my $selected = $_->id eq $value ? 1:0;
    $fb->tag_helpers->option_tag($_->name, +{class=>'foo', selected=>$selected, value=>$_->id}); 
  } $states_collection->all;
}),
  '<select id="person_state_id" multiple name="person.state_id[]">'.
    '<option class="foo" selected value="10">TX</option>'.
    '<option class="foo" value="20">NY</option>'.
    '<option class="foo" value="30">CA</option>'.
  '</select>';


is $fb->select({roles => 'id'}, [map { [$_->label, $_->id] } $roles_collection->all]), 
  '<input id="person_roles_id_hidden" name="person.roles[0]._nop" type="hidden" value="1"/>'.
  '<select id="person_roles_id" multiple name="person.roles[].id">'.
    '<option selected value="1">user</option>'.
    '<option selected value="2">admin</option>'.
    '<option value="3">guest</option>'.
  '</select>';

is $fb->select('state_ids', [map { [$_->label, $_->id] } $roles_collection->all], {unselected_value=>-1} ),
  '<input id="person_state_ids_hidden" name="person.state_ids[0]" type="hidden" value="-1"/>'.
  '<select id="person_state_ids" multiple name="person.state_ids[]">'.
    '<option value="1">user</option>'.
    '<option value="2">admin</option>'.
    '<option value="3">guest</option>'.
  '</select>';

is $fb->collection_select('state_id', $states_collection, id=>'name'),
  '<select id="person_state_id" name="person.state_id"><option selected value="10">TX</option><option value="20">NY</option><option value="30">CA</option></select>';

is $fb->collection_select('state_id', $states_collection, id=>'name', {class=>'foo', include_blank=>1}),
  '<select class="foo" id="person_state_id" name="person.state_id"><option label=" " value=""></option><option selected value="10">TX</option><option value="20">NY</option><option value="30">CA</option></select>';

is $fb->collection_select('state_id', $states_collection, id=>'name', {selected=>[30], disabled=>[10]}),
  '<select id="person_state_id" name="person.state_id"><option disabled value="10">TX</option><option value="20">NY</option><option selected value="30">CA</option></select>';

# default_selected doesn't override when there's a value
is $fb->collection_select('state_id', $states_collection, id=>'name', {default_selected=>[30]}),
  '<select id="person_state_id" name="person.state_id"><option selected value="10">TX</option><option value="20">NY</option><option value="30">CA</option></select>';

is $fb->collection_select('state_id2', $states_collection, id=>'name', {default_selected=>[30]}),
  '<select id="person_state_id2" name="person.state_id2"><option value="10">TX</option><option value="20">NY</option><option selected value="30">CA</option></select>';



is $fb->collection_select({roles => 'id'}, $roles_collection, id=>'label'), 
  '<input id="person_roles_id_hidden" name="person.roles[0]._nop" type="hidden" value="1"/>'.
  '<select id="person_roles_id" multiple name="person.roles[].id">'.
    '<option selected value="1">user</option>'.
    '<option selected value="2">admin</option>'.
    '<option value="3">guest</option>'.
  '</select>';

is $fb->collection_radio_buttons('state_id', $states_collection, id=>'name'),
  '<div id="person_state_id"><input id="person_state_id_hidden" name="person.state_id" type="hidden" value=""/>'.
  '<label for="person_state_id_10">TX</label>'.
  '<input checked id="person_state_id_10" name="person.state_id" type="radio" value="10"/>'.
  '<label for="person_state_id_20">NY</label>'.
  '<input id="person_state_id_20" name="person.state_id" type="radio" value="20"/>'.
  '<label for="person_state_id_30">CA</label>'.
  '<input id="person_state_id_30" name="person.state_id" type="radio" value="30"/></div>';

is $fb->collection_radio_buttons('state_id', $states_collection, id=>'name', {include_hidden=>0}),
  '<div id="person_state_id"><label for="person_state_id_10">TX</label>'.
  '<input checked id="person_state_id_10" name="person.state_id" type="radio" value="10"/>'.
  '<label for="person_state_id_20">NY</label>'.
  '<input id="person_state_id_20" name="person.state_id" type="radio" value="20"/>'.
  '<label for="person_state_id_30">CA</label>'.
  '<input id="person_state_id_30" name="person.state_id" type="radio" value="30"/></div>';

is $fb->collection_radio_buttons('state_id', $states_collection, id=>'name', sub {
  my $fb_states = shift;
  return  $fb_states->radio_button({class=>'form-check-input'}),
          $fb_states->label({class=>'form-check-label'});  
}), '<div id="person_state_id"><input id="person_state_id_hidden" name="person.state_id" type="hidden" value=""/><input checked class="form-check-input" id="person_state_id_10" name="person.state_id" type="radio" value="10"/><label class="form-check-label" for="person_state_id_10">TX</label><input class="form-check-input" id="person_state_id_20" name="person.state_id" type="radio" value="20"/><label class="form-check-label" for="person_state_id_20">NY</label><input class="form-check-input" id="person_state_id_30" name="person.state_id" type="radio" value="30"/><label class="form-check-label" for="person_state_id_30">CA</label></div>';


is $fb->collection_checkbox({roles => 'id'}, $roles_collection, id=>'label'), 
  '<div id="person_roles">'.
    '<input id="person_roles_hidden" name="person.roles" type="hidden" value="&#123;&quot;_nop&quot;:&quot;&quot;&#125;"/>'.
    '<label for="person_roles_1">User</label>'.
    '<input checked id="person_roles_1" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:1&#125;"/>'.
    '<label for="person_roles_2">Admin</label>'.
    '<input checked id="person_roles_2" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:2&#125;"/>'.
    '<label for="person_roles_3">Guest</label>'.
    '<input id="person_roles_3" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:3&#125;"/>'.
    '</div>';

is $fb->collection_checkbox({roles => 'id'}, $roles_collection, id=>'label', {include_hidden=>0}), 
  '<div id="person_roles">'.
    '<label for="person_roles_1">User</label>'.
    '<input checked id="person_roles_1" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:1&#125;"/>'.
    '<label for="person_roles_2">Admin</label>'.
    '<input checked id="person_roles_2" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:2&#125;"/>'.
    '<label for="person_roles_3">Guest</label>'.
    '<input id="person_roles_3" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:3&#125;"/>'.
    '</div>';


is $fb->collection_checkbox({roles => 'id'}, $roles_collection, id=>'label', sub {
  my $fb_roles = shift;
  return  $fb_roles->checkbox({class=>'form-check-input'}),
          $fb_roles->label({class=>'form-check-label'});
}),
  '<div id="person_roles">'.
    '<input id="person_roles_hidden" name="person.roles" type="hidden" value="&#123;&quot;_nop&quot;:&quot;&quot;&#125;"/>'.
    '<input checked class="form-check-input" id="person_roles_1" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:1&#125;"/>'.
    '<label class="form-check-label" for="person_roles_1">User</label>'.
    '<input checked class="form-check-input" id="person_roles_2" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:2&#125;"/>'.
    '<label class="form-check-label" for="person_roles_2">Admin</label>'.
    '<input class="form-check-input" id="person_roles_3" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:3&#125;"/>'.
    '<label class="form-check-label" for="person_roles_3">Guest</label>'.
  '</div>';


is $fb->collection_checkbox('state_ids', $states_collection, id=>'name'), '<div id="person_state_ids"><input id="person_state_ids_hidden" name="person.state_ids" type="hidden" value=""/><label for="person_state_ids_10">TX</label><input checked id="person_state_ids_10" name="person.state_ids" type="checkbox" value="10"/><label for="person_state_ids_20">NY</label><input id="person_state_ids_20" name="person.state_ids" type="checkbox" value="20"/><label for="person_state_ids_30">CA</label><input checked id="person_state_ids_30" name="person.state_ids" type="checkbox" value="30"/></div>';
is $fb->collection_checkbox({roles => 'id'}, $roles_collection, id=>'label'), '<div id="person_roles"><input id="person_roles_hidden" name="person.roles" type="hidden" value="&#123;&quot;_nop&quot;:&quot;&quot;&#125;"/><label for="person_roles_1">User</label><input checked id="person_roles_1" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:1&#125;"/><label for="person_roles_2">Admin</label><input checked id="person_roles_2" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:2&#125;"/><label for="person_roles_3">Guest</label><input id="person_roles_3" name="person.roles" type="checkbox" value="&#123;&quot;id&quot;:3&#125;"/></div>';

done_testing;
