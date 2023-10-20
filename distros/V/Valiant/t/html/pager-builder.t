use Test::Most;
use Valiant::HTML::Util::View;
use Valiant::HTML::PagerBuilder;

ok my $view = Valiant::HTML::Util::View->new(aaa=>1,bbb=>2);
#ok my $pb = Valiant::HTML::Util::PagerBuilder->new(view=>$view);

done_testing;
