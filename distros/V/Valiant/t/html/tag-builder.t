use Test::Most;
use Valiant::HTML::TagBuilder 'tag', 'content_tag', 'capture';

is tag('hr'), '<hr/>';
is tag('hr', +{id=>'foo', class=>'bar', required=>1}), '<hr class="bar" id="foo" required/>';
is tag('hr', +{id=>'foo', data=>{user_id=>100, locator=>'main'}}), '<hr data-locator="main" data-user-id="100" id="foo"/>';
is tag('img', +{value=>'</img><script>evilshit</script'}), '<img value="&lt;/img&gt;&lt;script&gt;evilshit&lt;/script"/>';
is ref(tag 'hr'), 'Valiant::HTML::SafeString';

is content_tag('a', 'the link<script>evil</script>', +{href=>'a.html'}), '<a href="a.html">the link&lt;script&gt;evil&lt;/script&gt;</a>';
is ref(content_tag 'a'), 'Valiant::HTML::SafeString';

my $block = content_tag div => +{id=>'top'}, sub {
  tag('hr'),
  "Content with evil <a href>aaa</a>",
  tag('input', +{type=>'text', name=>'user'}),
  content_tag div => +{id=>'inner'}, sub { "stuff" },
};

is ref($block), 'Valiant::HTML::SafeString';
is $block, '<div id="top"><hr/>Content with evil &lt;a href&gt;aaa&lt;/a&gt;<input name="user" type="text"/><div id="inner">stuff</div></div>';

my $capture = capture sub {
  if(shift) {
    return content_tag 'a', 'Profile', +{ href=>'profile.html' };
  } else {
    return content_tag 'a', 'Login', +{ href=>'login.html' };
  }
}, 1;

is $capture, '<a href="profile.html">Profile</a>';

done_testing;
