use Test::Most;
use Valiant::HTML::SafeString ':all';

{
  my $escaped = escape_html '<img src="test"/>';
  is $escaped, '&lt;img src=&quot;test&quot;/&gt;';
}

{
  my $raw = raw 'aaa';
  is ref($raw), 'Valiant::HTML::SafeString';
  is $raw->to_string, 'aaa';
  ok is_safe($raw);

  my @raw = raw 'aaa', '<a href="javascript:betterBeSure()">bbb</a>';
  is scalar(@raw), 2;
  is $raw[0]->to_string, 'aaa';
  is $raw[1]->to_string, '<a href="javascript:betterBeSure()">bbb</a>';

  my $flat = flattened_raw 'aaa', '<a href="javascript:betterBeSure()">bbb</a>';
  is $flat->to_string, 'aaa<a href="javascript:betterBeSure()">bbb</a>';
}

{
  my $safe = safe 'aaa';
  is ref($safe), 'Valiant::HTML::SafeString';
  is $safe->to_string, 'aaa';
  ok is_safe($safe);

  my @safe = safe 'aaa', '<a href="javascript:betterBeSure()">bbb</a>';
  is scalar(@safe), 2;
  is $safe[0]->to_string, 'aaa';
  is $safe[1]->to_string, '&lt;a href=&quot;javascript:betterBeSure()&quot;&gt;bbb&lt;/a&gt;';

  my $flat = flattened_safe 'aaa', '<a href="javascript:betterBeSure()">bbb</a>';
  is $flat->to_string, 'aaa&lt;a href=&quot;javascript:betterBeSure()&quot;&gt;bbb&lt;/a&gt;';
}

{
  my $safe = safe 'test';
  my $new_safe = $safe->concat('<img src="test"/>', $safe, 'more');
  ok is_safe($new_safe);
  is $new_safe->to_string, 'test&lt;img src=&quot;test&quot;/&gt;testmore';
  is $new_safe, 'test&lt;img src=&quot;test&quot;/&gt;testmore', 'stringification works';
}

{
  my $safe = Valiant::HTML::SafeString->new("<a>","b","c");
  ok is_safe($safe);
  is $safe->to_string, '&lt;a&gt;bc';
}

done_testing;
