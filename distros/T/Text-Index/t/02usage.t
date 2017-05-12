use warnings;
use strict;
use Params::Util qw/_ARRAY/;
use Test::More tests => 11;

use Text::Index;

my $i = Text::Index->new;
isa_ok($i, 'Text::Index');

# method chaining support
isa_ok($i->add_page("Hello this is a test page\nFoo!\n"), 'Text::Index');
isa_ok($i->add_pages("Hello this is another test page\nBar!\n", "And a third testing page (bogus derivate). (Hi!)"), 'Text::Index');

my @p = $i->pages;
ok(@p == 3 and (grep {defined $_} @p) == 3);

isa_ok($i->add_keyword("Foo"), 'Text::Index');
isa_ok($i->add_keyword("test page", "testing page"), 'Text::Index');
isa_ok($i->add_keywords(["Bar"], ["Hello", "Hi"]), 'Text::Index');

my @k = $i->keywords;
ok(@k == 4 and (grep {_ARRAY($_)} @k) == 4);


my @page_list = $i->find_keyword('page');
ok(@page_list == 3 and (grep {$page_list[$_] == $_+1} 0..2) == 3);

@page_list = $i->find_keyword('test page', 'testing page');
ok(@page_list == 3 and (grep {$page_list[$_] == $_+1} 0..2) == 3);


my $index = $i->generate_index;
#$index is hash ref:
#{ KEYWORD => [PAGENUMBERS], KEYWORD2 => [PAGENUMBERS2] }

is_deeply(
	$index,
	{
		'Bar' => [2],
		'Foo' => [1],
		'test page' => [1,2,3],
		'Hello' => [1,2,3],
	}
);
