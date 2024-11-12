use Test::Most;
use Valiant::HTML::Util::View;
use Valiant::HTML::Util::Form;

{
  package Local::Person;

  use Moo;
  use Valiant::Validations;

  has first_name => (is=>'ro');
  has last_name => (is=>'ro');
  has persisted => (is=>'rw', required=>1, default=>0);
  
  validates ['first_name', 'last_name'] => (
    length => {
      maximum => 10,
      minimum => 3,
    }
  );
}

my $person = Local::Person->new(first_name => 'aa', last_name => 'napiorkowski');
my $view = Valiant::HTML::Util::View->new(aaa=>1,bbb=>2, person=>$person);
my $f = Valiant::HTML::Util::Form->new(view=>$view);

ok !$person->valid;

{
  # Test case 1: empty input
  my $html_options = {};
  my $options = {};
  $f->_merge_attrs($html_options, $options, ());
  is_deeply($html_options, {}, 'empty input');

  # Test case 2: no common elements in @list
  $html_options = {foo => 'bar'};
  $options = {baz => 'qux'};
  $f->_merge_attrs($html_options, $options, ('quux'));
  is_deeply($html_options, {foo => 'bar'}, 'no common elements in @list');

  # Test case 3: some common elements in @list
  $html_options = {foo => 'bar'};
  $options = {foo => 'baz', qux => 'quux'};
  $f->_merge_attrs($html_options, $options, ('foo', 'qux'));
  is_deeply($html_options, {foo => 'bar', qux => 'quux'}, 'some common elements in @list');

  # Test case 4: all elements in @list
  $html_options = {foo => 'bar'};
  $options = {foo => 'baz', qux => 'quux'};
  $f->_merge_attrs($html_options, $options, ('foo', 'qux'));
  is_deeply($html_options, {foo => 'bar', qux => 'quux'}, 'all elements in @list');

}

{
  my $form = $f->form_for($person, sub {
    my ($view, $fb, $person) = @_;

    ok $view->isa('Valiant::HTML::Util::View');
    ok $fb->isa('Valiant::HTML::FormBuilder');
    ok $person->isa('Local::Person');

    return $fb->label('first_name'),
    $fb->input('first_name'),
    $fb->errors_for('first_name'),
    $fb->label('last_name'),
    $fb->input('last_name'),
    $fb->errors_for('last_name');
  });

  ok $form->isa('Valiant::HTML::SafeString');
  is $form, 
    '<form accept-charset="UTF-8" class="new_local_person" enctype="application/x-www-form-urlencoded" id="new_local_person" method="post">' .
      '<label for="local_person_first_name">First Name</label>' .
      '<input id="local_person_first_name" name="local_person.first_name" type="text" value="aa"/>' .
      '<div data-error-param="1" id="local_person_first_name_errors">First Name is too short (minimum is 3 characters)</div>' .
      '<label for="local_person_last_name">Last Name</label>' .
      '<input id="local_person_last_name" name="local_person.last_name" type="text" value="napiorkowski"/>' .
      '<div data-error-param="1" id="local_person_last_name_errors">Last Name is too long (maximum is 10 characters)</div>' .
    '</form>'; 
}

{
  $person->persisted(1);
  my $form = $f->form_for($person, +{url=>'person'}, sub {
    my ($view, $fb, $person) = @_;

    ok $fb->isa('Valiant::HTML::FormBuilder');
    ok $person->isa('Local::Person');

    return $fb->label('first_name'),
    $fb->input('first_name'),
    $fb->errors_for('first_name'),
    $fb->label('last_name'),
    $fb->input('last_name'),
    $fb->errors_for('last_name');
  });
  $person->persisted(0);

  ok $form->isa('Valiant::HTML::SafeString');
  is $form, 
    '<form accept-charset="UTF-8" action="person?x-tunneled-method=patch" class="edit_local_person" data-tunneled-method="patch" enctype="application/x-www-form-urlencoded" id="edit_local_person" method="post">' .
      '<label for="local_person_first_name">First Name</label>' .
      '<input id="local_person_first_name" name="local_person.first_name" type="text" value="aa"/>' .
      '<div data-error-param="1" id="local_person_first_name_errors">First Name is too short (minimum is 3 characters)</div>' .
      '<label for="local_person_last_name">Last Name</label>' .
      '<input id="local_person_last_name" name="local_person.last_name" type="text" value="napiorkowski"/>' .
      '<div data-error-param="1" id="local_person_last_name_errors">Last Name is too long (maximum is 10 characters)</div>' .
    '</form>'; 
}

{
  $person->persisted(1);
  my $form = $f->form_for('foo', $person, +{url=>'person'}, sub {
    my ($view, $fb, $person) = @_;

    ok $fb->isa('Valiant::HTML::FormBuilder');
    ok $person->isa('Local::Person');

    return $fb->label('first_name'),
    $fb->input('first_name'),
    $fb->errors_for('first_name'),
    $fb->label('last_name'),
    $fb->input('last_name'),
    $fb->errors_for('last_name');
  });
  $person->persisted(0);

  ok $form->isa('Valiant::HTML::SafeString');
  is $form, 
    '<form accept-charset="UTF-8" action="person?x-tunneled-method=patch" class="edit_foo" data-tunneled-method="patch" enctype="application/x-www-form-urlencoded" id="edit_foo" method="post">' .
      '<label for="foo_first_name">First Name</label>' .
      '<input id="foo_first_name" name="foo.first_name" type="text" value="aa"/>' .
      '<div data-error-param="1" id="foo_first_name_errors">First Name is too short (minimum is 3 characters)</div>' .
      '<label for="foo_last_name">Last Name</label>' .
      '<input id="foo_last_name" name="foo.last_name" type="text" value="napiorkowski"/>' .
      '<div data-error-param="1" id="foo_last_name_errors">Last Name is too long (maximum is 10 characters)</div>' .
    '</form>'; 
}

{
  # check for edit detection and string model name matches a view attribute
  $person->persisted(1);
  my $form = $f->form_for('person', +{url=>'person'}, sub {
    my ($view, $fb, $person) = @_;

    return $fb->label('first_name'),
    $fb->input('first_name'),
    $fb->errors_for('first_name'),
    $fb->label('last_name'),
    $fb->input('last_name'),
    $fb->errors_for('last_name');
  });
  $person->persisted(0);

  ok $form->isa('Valiant::HTML::SafeString');
  is $form, 
    '<form accept-charset="UTF-8" action="person?x-tunneled-method=patch" class="edit_person" data-tunneled-method="patch" enctype="application/x-www-form-urlencoded" id="edit_person" method="post">'.
      '<label for="person_first_name">First Name</label>'.
      '<input id="person_first_name" name="person.first_name" type="text" value="aa"/>'.
        '<div data-error-param="1" id="person_first_name_errors">First Name is too short (minimum is 3 characters)</div>'.
      '<label for="person_last_name">Last Name</label>'.
      '<input id="person_last_name" name="person.last_name" type="text" value="napiorkowski"/>'.
        '<div data-error-param="1" id="person_last_name_errors">Last Name is too long (maximum is 10 characters)</div>'.
    '</form>'
}

# Test form_for with a new model and default options
{
  my $result = $f->form_with(+{url=>'post'}, sub {
    my ($view,$fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result,
    '<form accept-charset="UTF-8" action="post" enctype="application/x-www-form-urlencoded" method="post">'.
      '<input id="first_name" name="first_name" type="text" value=""/>'.
    '</form>'
}

{
  my $result = $f->form_with(+{}, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result,
    '<form accept-charset="UTF-8" enctype="application/x-www-form-urlencoded" method="post">'.
      '<input id="first_name" name="first_name" type="text" value=""/>'.
    '</form>'
}

{
  my $result = $f->form_with(+{url=>'posts', scope=>'post'}, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result,
    '<form accept-charset="UTF-8" action="posts" enctype="application/x-www-form-urlencoded" method="post">'.
      '<input id="post_first_name" name="post.first_name" type="text" value=""/>'.
    '</form>'
}

{
  my $result = $f->form_with(+{url=>'posts', namespace=>'foo', id=>'form1', scope=>'post'}, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result,
    '<form accept-charset="UTF-8" action="posts" enctype="application/x-www-form-urlencoded" id="form1" method="post">'.
      '<input id="foo_post_first_name" name="post.first_name" type="text" value=""/>'.
    '</form>'
}

{
  my $result = $f->form_with(+{url=>'posts', model=>$person}, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result,
    '<form accept-charset="UTF-8" action="posts" enctype="application/x-www-form-urlencoded" method="post">'.
      '<input id="local_person_first_name" name="local_person.first_name" type="text" value="aa"/>'.
    '</form>'
}

{
  $person->persisted(1);
  my $result = $f->form_with(+{url=>'posts', model=>$person}, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });
  $person->persisted(0);

  is $result,
    '<form accept-charset="UTF-8" action="posts?x-tunneled-method=patch" enctype="application/x-www-form-urlencoded" method="post">'.
      '<input id="local_person_first_name" name="local_person.first_name" type="text" value="aa"/>'.
    '</form>'
}

{
  {
    package Local::FormBuilder;
    use Moo;
    extends 'Valiant::HTML::FormBuilder';
  }
  my $result = $f->form_with(+{url=>'posts', csrf_token=>'toke', class=>['bbb','ccc'], builder=>'Local::FormBuilder', model=>$person, html=>+{class=>'aaa'}}, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    ok $fb->isa('Local::FormBuilder'); 
    return $fb->input('fake'),
  });

  is $result,
    '<form accept-charset="UTF-8" action="posts" class="aaa bbb ccc" data-csrf-token="toke" enctype="application/x-www-form-urlencoded" method="post">'.
      '<input id="csrf_token" name="csrf_token" type="hidden" value="toke"/>'.
      '<input id="local_person_fake" name="local_person.fake" type="text" value=""/>'.
    '</form>'
}

{
  my $result = $f->fields_for($person, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result, '<input id="local_person_first_name" name="local_person.first_name" type="text" value="aa"/>';
}

{
  my $result = $f->fields_for('person', sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result, '<input id="person_first_name" name="person.first_name" type="text" value="aa"/>';
}

{
  my $result = $f->fields_for('foo', $person, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result, '<input id="foo_first_name" name="foo.first_name" type="text" value="aa"/>';
}

{
  my $result = $f->fields_for('foo', sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result, '<input id="foo_first_name" name="foo.first_name" type="text" value=""/>';
}

{
  my $result = $f->fields_for('foo', $person, sub {
    my ($view, $fb) = @_;
    ok $fb->isa('Valiant::HTML::FormBuilder');
    return $fb->input('first_name'),
  });

  is $result, '<input id="foo_first_name" name="foo.first_name" type="text" value="aa"/>';
}

{
  my $form = $f->form_for($person, {url=>'ddd'}, sub {
    my ($view, $fb, $person) = @_;
    return '';
  });

  is $form, '<form accept-charset="UTF-8" action="ddd" class="new_local_person" enctype="application/x-www-form-urlencoded" id="new_local_person" method="post"></form>';  
}

{
  my $form = $f->form_for($person, 
  { url => sub { my ($view, $model) = @_; is scalar(@$model), 0; 'aa' } }, 
  sub {
    my ($view, $fb, $person) = @_;
    return '';
  });

  is $form, '<form accept-charset="UTF-8" action="aa" class="new_local_person" enctype="application/x-www-form-urlencoded" id="new_local_person" method="post"></form>';  
}

{
  $person->persisted(1);
  my $form = $f->form_for($person, 
  { url => sub { my ($view, $model) = @_; is scalar(@$model), 1; 'aa' } }, 
  sub {
    my ($view, $fb, $person) = @_;
    return '';
  });
  $person->persisted(0);

  is $form, '<form accept-charset="UTF-8" action="aa?x-tunneled-method=patch" class="edit_local_person" data-tunneled-method="patch" enctype="application/x-www-form-urlencoded" id="edit_local_person" method="post"></form>';  
}

{
  my $form = $f->form_for($person, 
  { new_url => sub { my ($view, $model) = @_; is scalar(@$model), 0; 'bb' } }, 
  sub {
    my ($view, $fb, $person) = @_;
    return '';
  });
  is $form, '<form accept-charset="UTF-8" action="bb" class="new_local_person" enctype="application/x-www-form-urlencoded" id="new_local_person" method="post"></form>';
}

{
  $person->persisted(1);
  my $form = $f->form_for($person, 
  { edit_url => sub { my ($view, $model) = @_; is scalar(@$model), 1; 'cc' } }, 
  sub {
    my ($view, $fb, $person) = @_;
    return '';
  });
  $person->persisted(0);
  is $form, '<form accept-charset="UTF-8" action="cc?x-tunneled-method=patch" class="edit_local_person" data-tunneled-method="patch" enctype="application/x-www-form-urlencoded" id="edit_local_person" method="post"></form>';
}

{
  # valid
  my $person = Local::Person->new(first_name => 'aaa', last_name => 'bbb');
  my $view = Valiant::HTML::Util::View->new(aaa=>1,bbb=>2, person=>$person);
  my $f = Valiant::HTML::Util::Form->new(view=>$view);

  ok $person->valid;

  my $form = $f->form_for($person, sub {
    my ($view, $fb, $person) = @_;
    return $fb->label('first_name'),
    $fb->input('first_name'),
    $fb->errors_for('first_name', {show_empty=>1}),
  });

  is $form, '<form accept-charset="UTF-8" class="new_local_person" enctype="application/x-www-form-urlencoded" id="new_local_person" method="post"><label for="local_person_first_name">First Name</label><input id="local_person_first_name" name="local_person.first_name" type="text" value="aaa"/><ol data-error-list="1" id="local_person_first_name_errors"><li data-error-param="1"></li></ol></form>'
}

done_testing;
