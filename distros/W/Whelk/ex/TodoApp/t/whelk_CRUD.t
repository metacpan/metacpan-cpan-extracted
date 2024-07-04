use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common qw(GET POST PUT DELETE);
use Whelk;

my $app = Whelk->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

$t->request(GET '/todos')
	->code_is(200)
	->json_cmp([]);

$t->request(GET '/todos/1')
	->code_is(404);

$t->request(
	PUT '/todos',
	Content_Type => 'application/json',
	Content => $app->json->encode({name => 't1', content => 't1 content'})
	)
	->code_is(200)
	->json_cmp({id => 1});

$t->request(
	PUT '/todos',
	Content_Type => 'application/json',
	Content => $app->json->encode({name => 't2', content => 't2 content', date => '01/01/2025'})
	)
	->code_is(200)
	->json_cmp({id => 2});

$t->request(GET '/todos/1')
	->code_is(200)
	->json_cmp({name => 't1', content => 't1 content', date => ignore()});

$t->request(GET '/todos/2')
	->code_is(200)
	->json_cmp({name => 't2', content => 't2 content', date => '01/01/2025'});

$t->request(GET '/todos')
	->code_is(200)
	->json_cmp(bag({id => 1, data => ignore()}, {id => 2, data => ignore()}));

$t->request(
	POST '/todos/1',
	Content_Type => 'application/json',
	Content => $app->json->encode({date => 'NOW'})
	)
	->code_is(204);

$t->request(GET '/todos/1')
	->code_is(200)
	->json_cmp({name => 't1', content => 't1 content', date => 'NOW'});

$t->request(DELETE '/todos/2')
	->code_is(204);

$t->request(GET '/todos')
	->code_is(200)
	->json_cmp([{id => 1, data => ignore()}]);

done_testing;

