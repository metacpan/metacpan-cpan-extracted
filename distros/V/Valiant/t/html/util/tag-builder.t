use Test::Most;
use Valiant::HTML::Util::TagBuilder;
use Valiant::HTML::Util::View;
use Valiant::HTML::Util::Collection;
use HTML::Escape qw/escape_html/;

ok my $view = Valiant::HTML::Util::View->new(aaa=>1,bbb=>2);
ok my $tb = Valiant::HTML::Util::TagBuilder->new(view=>$view);

is $tb->tag('hr'), '<hr/>';
is $tb->tag('hr', +{id=>'foo', class=>'bar', required=>1}), '<hr class="bar" id="foo" required/>';
is $tb->tag('hr', +{id=>'foo', class=>['foo', 'bar'], data=>{aa=>1, bb=>2}, required=>1}), '<hr class="foo bar" data-aa="1" data-bb="2" id="foo" required/>';

is $tb->tag('hr', +{id=>'foo', data=>{user_id=>100, locator=>'main'}}), '<hr data-locator="main" data-user-id="100" id="foo"/>';
is $tb->tag('img', +{value=>'</img><script>evilshit</script'}), '<img value="&lt;/img&gt;&lt;script&gt;evilshit&lt;/script"/>';

ok my $block = $tb->content_tag(div => +{id=>'top'}, sub {
  $tb->tag('hr'),
  "Content with evil <a href>aaa</a>",
  $tb->tag('input', +{type=>'text', name=>'user'}),
  $tb->content_tag(div => +{id=>'inner'}, sub { "stuff" }),
});
is $block, '<div id="top"><hr/>Content with evil &lt;a href&gt;aaa&lt;/a&gt;<input name="user" type="text"/><div id="inner">stuff</div></div>';

ok $block = $tb->content_tag(div => +{id=>'top'}, [
  $tb->tag('hr'),
  "Content with evil <a href>aaa</a>",
  $tb->tag('input', +{type=>'text', name=>'user'}),
  $tb->content_tag(div => +{id=>'inner'}, sub { "stuff" }),
]);
is $block, '<div id="top"><hr/>Content with evil &lt;a href&gt;aaa&lt;/a&gt;<input name="user" type="text"/><div id="inner">stuff</div></div>';

is $tb->content_tag('a', 'the link<script>evil</script>', +{href=>'a.html'}), '<a href="a.html">the link&lt;script&gt;evil&lt;/script&gt;</a>';
is $tb->join_tags($tb->content_tag(a => 'link1'), $tb->content_tag(a => 'link2')), '<a>link1</a><a>link2</a>';
is $tb->join_tags( $tb->tag('hr'), $tb->tag('hr')), '<hr/><hr/>';

ok $block = $tb->content_tag(div => +{id=>'top'},
  $tb->tag('hr'),
  "Content with evil <a href>aaa</a>",
  $tb->tag('input', +{type=>'text', name=>'user'}),
  $tb->content_tag(div => +{id=>'inner'}, sub { "stuff" }),
);
is $block, '<div id="top"><hr/>Content with evil &lt;a href&gt;aaa&lt;/a&gt;<input name="user" type="text"/><div id="inner">stuff</div></div>';

is $tb->tags->hr({id=>'top'}), '<hr id="top"/>';
is $tb->tags->hr(), '<hr/>';
is $tb->join_tags($tb->tags->hr({id=>'top'}), $tb->tags->input({name=>'bb'})), '<hr id="top"/><input name="bb"/>';
is $tb->tags->div(), '<div></div>';
is $tb->tags->div("stuff"), '<div>stuff</div>';
is $tb->tags->div("stuff", "more stuff"), '<div>stuff</div>';
is $tb->tags->div({id=>1},"<a>stuff"), '<div id="1">&lt;a&gt;stuff</div>';
is $tb->tags->div({id=>1}, sub { 'stuff'}), '<div id="1">stuff</div>';

is $tb->join_tags($tb->tags->hr, $tb->tag('hr'), $tb->tag('hr')), '<hr/><hr/><hr/>';
is $tb->text('a','b', 'c'), 'abc';
is $tb->safe($tb->text('a','b')), 'ab';
is $tb->safe($tb->tag('hr', +{id=>1})), '<hr id="1"/>';
is $tb->tags->a(sub {$tb->tags->hr, 'text'}), '<a><hr/>text</a>';

is ref($tb->tag('hr')), 'Valiant::HTML::SafeString';
is ref($tb->content_tag(a => 'link')), 'Valiant::HTML::SafeString';
is ref($tb->tags->hr), 'Valiant::HTML::SafeString';
is ref($tb->tags->a(sub {$tb->tags->hr, 'text'})), 'Valiant::HTML::SafeString';

is $tb->tag('hr', +{id=>1, omit=>1}), '';
is $tb->content_tag('div', +{id=>1, omit=>1}, 'Hello World'), 'Hello World';

is $tb->sf('This {:aaa} is {:bbb} a test', aaa=>'foo', bbb=>'bar'), 'This foo is bar a test';
is ref($tb->sf('This {:aaa} is {:bbb} a test', aaa=>'foo', bbb=>'bar')), 'Valiant::HTML::SafeString';

my $tags = $tb->tags;

is $tags->div({id=>'one', with=>'two'}, sub {
  my ($view, $var) = @_;
  $tags->p($var);
}), '<div id="one"><p>two</p></div>';

is $tags->div({id=>'one', with=>sub {'two'}}, sub {
  my ($view, $var) = @_;
  $tags->p($var);
}), '<div id="one"><p>two</p></div>';

is $tags->div({id=>'one', if=>1}, sub {
  my ($view) = @_;
  $tags->p('hello');
}), '<div id="one"><p>hello</p></div>';
is $tags->div({id=>'one', if=>sub{1}}, sub {
  my ($view) = @_;
  $tags->p('hello');
}), '<div id="one"><p>hello</p></div>';
is $tags->div({id=>'one', if=>0}, sub {
  my ($view) = @_;
  $tags->p('hello');
}), '';
is $tags->div({id=>'one', if=>sub{0}}, sub {
  my ($view) = @_;
  $tags->p('hello');
}), '';

ok my $collection = Valiant::HTML::Util::Collection->new(1,2,3);

is $tags->div({id=>'one', repeat=>$collection}, sub {
  my ($view) = @_;
  $tags->p('hello');
}), '<div id="one"><p>hello</p><p>hello</p><p>hello</p></div>';

is $tags->div({id=>'one', repeat=>[1,2,3]}, sub {
  my ($view, $item, $idx) = @_;
  $tags->p("hello[$idx] $item");
}), '<div id="one"><p>hello[0] 1</p><p>hello[1] 2</p><p>hello[2] 3</p></div>';

is $tags->div({id=>sub {"one_${_}"}, map=>$collection}, sub {
  my ($view) = @_;
  $tags->p('hello');
}), '<div id="one_1"><p>hello</p></div><div id="one_2"><p>hello</p></div><div id="one_3"><p>hello</p></div>';

is $tags->div({id=>"aaa{:label}bbb{:value}ccc", map=>[1,2,3]}, sub {
  my ($view, $item, $idx) = @_;
  $tags->p("hello[$idx] $item");
}), '<div id="aaa1bbb1ccc"><p>hello[0] 1</p></div><div id="aaa2bbb2ccc"><p>hello[1] 2</p></div><div id="aaa3bbb3ccc"><p>hello[2] 3</p></div>';

is $tags->li({id=>"aaa1{:label}bbb{:value}ccc", map=>[1,2,3]},sub {}), '<li id="aaa11bbb1ccc"></li><li id="aaa12bbb2ccc"></li><li id="aaa13bbb3ccc"></li>';
is $tags->li({id=>"aaa2{:label}bbb{:value}ccc", map=>[1,2,3]}), '<li id="aaa21bbb1ccc"></li><li id="aaa22bbb2ccc"></li><li id="aaa23bbb3ccc"></li>';
is $tags->hr({id=>"aaa2{:label}bbb{:value}ccc", map=>[1,2,3]}), '<hr id="aaa21bbb1ccc"/><hr id="aaa22bbb2ccc"/><hr id="aaa23bbb3ccc"/>';

is $tags->div({id=>'one', given=>'one'}, sub {
  my ($view) = @_;
  is $tags->{tb}{_given}{val}, 'one';
  $tags->p({when=>'one'}, "hello one"),
  $tags->p({when=>'two'}, "hello two"),
  $tags->hr({when=>'three'}),
  $tags->p({when_default=>1}, "hello four")
}), '<div id="one"><p>hello one</p></div>';
ok !exists($tags->{tb}{_given}{val}), 'given went out of scope';
ok !exists($tags->{tb}{_given}{gone}), 'given went out of scope';

is $tags->div({id=>'one', given=>'onex'}, sub {
  my ($view) = @_;
  is $tags->{tb}{_given}{val}, 'onex';
  $tags->p({when=>'one'}, "hello one"),
  $tags->p({when=>'two'}, "hello two"),
  $tags->p({when=>'three'}, "hello three"),
  $tags->p({when_default=>1}, "hello four")
}), '<div id="one"><p>hello four</p></div>';
ok !exists($tags->{tb}{_given}{val}), 'given went out of scope';
ok !exists($tags->{tb}{_given}{gone}), 'given went out of scope';

is $tags->div({id=>'one', given=>sub {'two'}}, sub {
  my ($view) = @_;
  is $tags->{tb}{_given}{val}, 'two';
  $tags->p({when=>'one'}, "hello one"),
  $tags->p({when=>sub {'two'}}, "hello two"),
  $tags->p({when=>'three'}, "hello three"),
  $tags->p({when_default=>1}, "hello four")
}), '<div id="one"><p>hello two</p></div>';
ok !exists($tags->{tb}{_given}{val}), 'given went out of scope';
ok !exists($tags->{tb}{_given}{gone}), 'given went out of scope';

is $tags->div({id=>'one', given=>'one'}, sub {
  my ($view) = @_;
  is $tags->{tb}{_given}{val}, 'one';
  $tags->p({when=>'one', given=>'xxx'}, sub {
    is $tags->{tb}{_given}{val}, 'xxx';
    $tags->p({when=>'aaa'}, "hello aaa"),
    $tags->p({when=>'xxx'}, "hello xxx"),
    $tags->p({when_default=>1}, "hello default")  
  }),
  $tags->p({when=>'two'}, "hello two"),
  $tags->p({when=>'three'}, "hello three"),
  $tags->p({when_default=>1}, "hello four")
}), '<div id="one"><p><p>hello xxx</p></p></div>';
ok !exists($tags->{tb}{_given}{val}), 'given went out of scope';
ok !exists($tags->{tb}{_given}{gone}), 'given went out of scope';

is $tags->div({id=>'one', given=>'three'}, sub {
  my ($view) = @_;
  $tags->p({when=>'one'}, "hello one"),
  $tags->p({when=>'two'}, "hello two"),
  $tags->hr({when=>'three'}),
  $tags->p({when_default=>1}, "hello four")
}), '<div id="one"><hr/></div>';

{
  # Test 1: link_to with URL only
  my $url = 'http://example.com';
  my $expected_output = '<a href="' . escape_html($url) . '">' . escape_html($url) . '</a>';
  is($tb->link_to($url), $expected_output, 'link_to with URL only');

  # Test 2: link_to with URL and content
  my $content = 'Link Text';
  $expected_output = '<a href="' . escape_html($url) . '">' . escape_html($content) . '</a>';
  is($tb->link_to($url, $content), $expected_output, 'link_to with URL and content');

  # Test 3: link_to with URL, content, and additional attributes
  my $attrs = { class => 'link', target => '_blank' };
  $expected_output = '<a class="link" href="' . escape_html($url) . '" target="_blank">' . escape_html($content) . '</a>';
  is($tb->link_to($url, $attrs, $content), $expected_output, 'link_to with URL, content, and additional attributes');
}

is  $tags->hr({omit=>1}) +
    $tags->div({omit=>1}, 'Hello World!'), 'Hello World!';

is  $tags->hr({omit=>sub {1}}) +
    $tags->div({omit=>sub{shift}}, 'Hello World!'), 'Hello World!';

is $tags->input({value=>'&amp;'}), '<input value="&amp;amp;"/>';
is $tags->input({value=>$tb->raw('&amp;')}), '<input value="&amp;"/>';

done_testing;

__END__

$resultset->$table(%attrs)
  ->head(%attrs, sub ($tr) {
    $tr->th(%attrs, sub ($th) {
      $th->text('foo');
    });
  })




<table>
  <thead>
    <tr>
      <th>id</th>
      <th>name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>foo</td>
    </tr>
    <tr>
      <td>2</td>
      <td>bar</td>
    </tr>
  </tbody>
</table>

