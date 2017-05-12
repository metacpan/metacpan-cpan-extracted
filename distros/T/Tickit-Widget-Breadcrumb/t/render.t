use strict;
use warnings;

use Test::More;
use Tickit::Test;
use Tickit::Widget::Breadcrumb;

my $win = mk_window;

my $widget = Tickit::Widget::Breadcrumb->new(
);

$widget->set_window( $win );
flush_tickit;

is_display([ "Please wait..." ], 'Loading message shown on startup');

ok(my $adapter = $widget->adapter, 'ping adapter');
flush_tickit;

ok($widget->{crumbs}, 'have local cache');

is_display([ "" ], 'Now empty after update');

$adapter->push(['first']);
flush_tickit;
is_display([ "first" ], 'have an entry after update');

$adapter->push(['second']);
flush_tickit;
is_display([ "first | second" ], 'have another entry after update');

$adapter->push(['third']);
flush_tickit;
is_display([ "first | second > third" ], 'yet another entry');
$adapter->pop->get;
flush_tickit;
is_display([ "first | second" ], 'and drop the last one again');
done_testing;

