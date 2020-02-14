use strict;
use warnings;
use Test::More tests => 5;
use HTTP::Session;
use HTTP::Session::State::Null;
use HTTP::Session::Store::Null;
use CGI;

my $session = HTTP::Session->new(
    state => HTTP::Session::State::Null->new,
    store => HTTP::Session::Store::Null->new,
    request => CGI->new(),
);
$session->set('foo' => 'bar');
is $session->get('foo'), 'bar', 'get/set';
$session->set('hoge' => 'fuga');
is_deeply $session->as_hashref, {'foo' => 'bar', 'hoge' => 'fuga'}, 'as_hashref';
is join(',', sort $session->keys), 'foo,hoge', 'keys';
$session->as_hashref->{'foo'} = 'boo';
is $session->get('foo'), 'bar', 'as_hashref uses copy';
$session->remove('foo');
is $session->get('foo'), undef, 'remove';

