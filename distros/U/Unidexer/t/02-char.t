use Test::More;
use Unidexer;

my $list = Unidexer->new(
	26,
	[
	'a',
	'z',
	'ones',
	'one',
	'two',
	'three',
	'four',
	'five',
	'six',
	'seven',
	]
);


my $word = $list->search('three');

is($word, 'three');
is($list->search('one'), 'one');
is($list->search('ones'), 'ones');
ok(!eval { $list->search('notexists') });
like ($@, qr/Index cannot be found/);

done_testing();
