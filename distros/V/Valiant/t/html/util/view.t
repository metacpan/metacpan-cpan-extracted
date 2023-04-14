use Test::Most;
use Valiant::HTML::Util::View;

ok my $view = Valiant::HTML::Util::View->new(aaa=>1,bbb=>2);
is $view->read_attribute_for_html('aaa'), 1;
is $view->read_attribute_for_html('bbb'), 2;
is $view->attribute_exists_for_html('aaa'), 1;

done_testing;
