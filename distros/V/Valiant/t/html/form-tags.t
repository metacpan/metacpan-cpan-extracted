use Test::Most;
use Valiant::HTML::FormTags ':all';
use Valiant::HTML::SafeString ':all';
use Valiant::HTML::Util::Collection;

is button_tag(), '<button name="button">Button</button>';
is button_tag('hello'), '<button name="button">hello</button>';
is button_tag('hello' => {id=>123123}), '<button id="123123" name="button">hello</button>';
is button_tag(sub { 'butttttton' }), '<button name="button">butttttton</button>';
is button_tag({id=>123123}, sub { 'butttttton' }), '<button id="123123" name="button">butttttton</button>';

is checkbox_tag('ggg'), '<input id="ggg" name="ggg" type="checkbox" value="1"/>';
is checkbox_tag('ggg', +{class=>123}), '<input class="123" id="ggg" name="ggg" type="checkbox" value="1"/>';
is checkbox_tag('user', 100), '<input id="user" name="user" type="checkbox" value="100"/>';
is checkbox_tag('user#ff', 100, 1), '<input checked id="user_ff" name="user#ff" type="checkbox" value="100"/>';
is checkbox_tag('user', 100, 1, {class=>'foo'}), '<input checked class="foo" id="user" name="user" type="checkbox" value="100"/>';

is fieldset_tag('Info<a href="">click</a>', +{class=>'foo'}, sub {
  button_tag 'username', +{class=>'aaa'};
}), '<fieldset class="foo"><legend>Info&lt;a href=&quot;&quot;&gt;click&lt;/a&gt;</legend><button class="aaa" name="button">username</button></fieldset>';

is fieldset_tag('Info<a href="">click</a>', sub {
  button_tag 'username', +{class=>'aaa'};
}), '<fieldset><legend>Info&lt;a href=&quot;&quot;&gt;click&lt;/a&gt;</legend><button class="aaa" name="button">username</button></fieldset>';

is fieldset_tag(sub {
  button_tag 'username', +{class=>'aaa'};
}), '<fieldset><button class="aaa" name="button">username</button></fieldset>';

is fieldset_tag(+{id=>100},sub {
  button_tag 'username', +{class=>'aaa'};
}), '<fieldset id="100"><button class="aaa" name="button">username</button></fieldset>';

is form_tag('/user', +{ class=>'form' }, sub {
    checkbox_tag 'person[1]username', +{class=>'aaa'};
  }), '<form accept-charset="UTF-8" action="/user" class="form" method="post"><input class="aaa" id="person_1username" name="person[1]username" type="checkbox" value="1"/></form>';

is label_tag('user_name'), '<label for="user_name">User name</label>';
is label_tag('name', 'Info'), '<label for="name">Info</label>';
is label_tag('name', +{ class=>'fff' }), '<label class="fff" for="name">Name</label>';
is label_tag(user => +{ class=>'fff' }, sub {
  checkbox_tag 'person', +{class=>'aaa'};
}), '<label class="fff" for="user"><input class="aaa" id="person" name="person" type="checkbox" value="1"/></label>';
is label_tag('user_name', sub {
  'User Name',
  checkbox_tag 'active', 'yes', 1;
}), '<label for="user_name">User Name<input checked id="active" name="active" type="checkbox" value="yes"/></label>';

is radio_button_tag('role', 'admin', 0, +{ class=>'radio' }), '<input class="radio" id="role_admin" name="role" type="radio" value="admin"/>';
is radio_button_tag('role', 'user', 1, +{ class=>'radio' }), '<input checked class="radio" id="role_user" name="role" type="radio" value="user"/>';

is input_tag('username', 'jjn', +{class=>'aaa'}), '<input class="aaa" id="username" name="username" type="text" value="jjn"/>';
is input_tag('username', 'jjn'), '<input id="username" name="username" type="text" value="jjn"/>';
is input_tag('username'), '<input id="username" name="username" type="text"/>';
is input_tag('username', +{class=>'foo'}), '<input class="foo" id="username" name="username" type="text"/>';
is input_tag(+{class=>'foo'}), '<input class="foo" type="text"/>';
is input_tag(+{class=>'aaa', name=>'foo'}), '<input class="aaa" id="foo" name="foo" type="text"/>';
is input_tag('test', 'holiday <a href>aa</a>', class=>'form-input'), '<input id="test" name="test" type="text" value="holiday &lt;a href&gt;aa&lt;/a&gt;"/>';

is option_tag('test', +{class=>'foo'}), '<option class="foo" value="test">test</option>';
is option_tag('test', +{value=>'foo'}), '<option value="foo">test</option>';
is option_tag('test'), '<option value="test">test</option>';

is text_area_tag("user", "hello<a href>EVIL</a>"), '<textarea id="user" name="user">hello&lt;a href&gt;EVIL&lt;/a&gt;</textarea>';
is text_area_tag("user", "hello", +{ class=>'foo' }), '<textarea class="foo" id="user" name="user">hello</textarea>';
is text_area_tag("user",  +{ class=>'foo' }), '<textarea class="foo" id="user" name="user"></textarea>';

is submit_tag, '<input id="commit" name="commit" type="submit" value="Save changes"/>';
is submit_tag('person'), '<input id="commit" name="commit" type="submit" value="person"/>';
is submit_tag('Save', +{name=>'person'}), '<input id="person" name="person" type="submit" value="Save"/>';
is submit_tag(+{class=>'person'}), '<input class="person" id="commit" name="commit" type="submit" value="Save changes"/>';

is hidden_tag('user_id', 100, +{class=>'foo'}), '<input class="foo" id="user_id" name="user_id" type="hidden" value="100"/>';
is hidden_tag('user_id', 100), '<input id="user_id" name="user_id" type="hidden" value="100"/>';
is hidden_tag('user_id'), '<input id="user_id" name="user_id" type="hidden"/>';
is hidden_tag({class=>'foo'}), '<input class="foo" type="hidden"/>';

is password_tag('user_id', 100, +{class=>'foo'}), '<input class="foo" id="user_id" name="user_id" type="password" value="100"/>';
is password_tag('user_id', 100), '<input id="user_id" name="user_id" type="password" value="100"/>';
is password_tag('user_id'), '<input id="user_id" name="user_id" type="password"/>';
is password_tag({class=>'foo'}), '<input class="foo" type="password"/>';

is select_tag("people", raw("<option>David</option>")),
  '<select id="people" name="people"><option>David</option></select>';

is select_tag("people", raw("<option>David</option>"), +{include_blank=>1}),
  '<select id="people" name="people"><option label=" " value=""></option><option>David</option></select>';

is select_tag("people", raw("<option>David</option>"), +{include_blank=>'empty'}),
  '<select id="people" name="people"><option value="">empty</option><option>David</option></select>';
  
is select_tag("prompt", raw("<option>David-prompt</option>"), +{prompt=>'empty-prompt', class=>'foo'}),
  '<select class="foo" id="prompt" name="prompt"><option value="">empty-prompt</option><option>David-prompt</option></select>';

is options_for_select(['A','B','C']), '<option value="A">A</option><option value="B">B</option><option value="C">C</option>';
is options_for_select(['A','B','C'], 'B'), '<option value="A">A</option><option selected value="B">B</option><option value="C">C</option>';
is options_for_select(['A','B','C'], ['A', 'C']), '<option selected value="A">A</option><option value="B">B</option><option selected value="C">C</option>';
is options_for_select(['A','B','C'], ['A', 'C']), '<option selected value="A">A</option><option value="B">B</option><option selected value="C">C</option>';

# [label=>value]
is options_for_select([[a=>'A'],[b=>'B'], [c=>'C']]), '<option value="A">a</option><option value="B">b</option><option value="C">c</option>';
is options_for_select([[a=>'A'],[b=>'B'], [c=>'C']], 'B'), '<option value="A">a</option><option selected value="B">b</option><option value="C">c</option>';
is options_for_select(['A',[b=>'B', {class=>'foo'}], [c=>'C']], ['A','C']), '<option selected value="A">A</option><option class="foo" value="B">b</option><option selected value="C">c</option>';

is options_for_select(['A','B','C'], +{selected=>['A','C'], disabled=>['B'], class=>'foo'}),
  '<option class="foo" selected value="A">A</option><option class="foo" disabled value="B">B</option><option class="foo" selected value="C">C</option>';

is select_tag("state", options_for_select(['A','B','C'], 'A'), +{include_blank=>1}), '<select id="state" name="state"><option label=" " value=""></option><option selected value="A">A</option><option value="B">B</option><option value="C">C</option></select>';
is select_tag("state", options_for_select([ ['A'=>'aaa'],'B','C'], ['aaa','C'])), '<select id="state" name="state"><option selected value="aaa">A</option><option value="B">B</option><option selected value="C">C</option></select>';

ok my $collection = Valiant::HTML::Util::Collection->new([label=>'value'], [A=>'a'], [B=>'b'], [C=>'c']);

is options_from_collection_for_select($collection, 'value', 'label'),
  '<option value="value">label</option><option value="a">A</option><option value="b">B</option><option value="c">C</option>';

is options_from_collection_for_select($collection, 'value', 'label', 'a'),
  '<option value="value">label</option><option selected value="a">A</option><option value="b">B</option><option value="c">C</option>';

is options_from_collection_for_select($collection, 'value', 'label', ['a', 'c']),
  '<option value="value">label</option><option selected value="a">A</option><option value="b">B</option><option selected value="c">C</option>';

is options_from_collection_for_select($collection, 'value', 'label', +{selected=>['a','c'], disabled=>['b'], class=>'foo'}),
  '<option class="foo" value="value">label</option><option class="foo" selected value="a">A</option><option class="foo" disabled value="b">B</option><option class="foo" selected value="c">C</option>';

is options_from_collection_for_select($collection, 'value', 'label', sub { shift->value eq 'a'} ),
  '<option value="value">label</option><option selected value="a">A</option><option value="b">B</option><option value="c">C</option>';

is legend_tag('test', +{class=>'foo'}), '<legend class="foo">test</legend>';
is legend_tag('test'), '<legend>test</legend>';
is legend_tag({class=>'foo'}, sub { 'test' }), '<legend class="foo">test</legend>';
is legend_tag(sub { 'test' }), '<legend>test</legend>';

done_testing;
