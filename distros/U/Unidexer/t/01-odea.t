use Test::More;
use Unidexer;

my $list = Unidexer->new(
	'a',
	'z',
	'one',
	'ones',
	'two',
	'three',
	'four',
	'five',
	'six',
	'seven',
	'† † †',
	{ index => 'lalala', description => 'random thing to extend' }
);

my $word = $list->search('three');

is($word, 'three');
is($list->search('one'), 'one');
is($list->search('ones'), 'ones');
ok(!eval { $list->search('notexists') });
like ($@, qr/Index cannot be found/);
is($list->search('† † †'), '† † †');
is_deeply($list->search('lalala'), { index => 'lalala', description => 'random thing to extend' });

done_testing();
