use strict;
use warnings;

use Future;
use Test::More;
use Test::Fatal;
use Tickit::Widget::Breadcrumb;

# I'd rather be using a CPAN module here but I really
# don't have the patience for the search+evaluation
# process right now.
sub is_called {
	my ($obj, $method, $code) = @_;
	my $f = Future->new;
	my $prev = $obj->can($method);
	is(exception {
		no strict 'refs';
		no warnings 'redefine';
		die "$method not found on $obj" unless $prev;
		local *{join '::', ref($obj) || $obj, $method} = sub {
			$f->done(@_);
			goto &$prev;
		};
		$code->();
		$f->fail('no ' . $method . ' call') unless $f->is_ready;
		$f->get
	}, undef, $method . ' called as expected');
}

subtest '->adapter accessor' => sub {
	my $w = new_ok('Tickit::Widget::Breadcrumb');
	isa_ok(my $adapter = $w->adapter, 'Adapter::Async::OrderedList');
	is($w->adapter(undef), $w, 'clear adapter, return $self');
	isa_ok($w->adapter, 'Adapter::Async::OrderedList');
	isnt($adapter, $w->adapter, 'new adapter is different');
	is_called($w, 'update_crumbs', sub {
		$w->adapter(undef)
	});
};

subtest 'adapter events' => sub {
	my $w = new_ok('Tickit::Widget::Breadcrumb');
	is_called($w, 'on_splice_event', sub {
		$w->adapter->push(['xxx'])->get;
	});
	is_called($w, 'on_clear_event', sub {
		$w->adapter->clear->get;
	});
};

done_testing;

