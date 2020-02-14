use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Session;
use CGI;
use HTTP::Session::Store::Null;
use HTTP::Session::State::Null;

my $session = HTTP::Session->new(
    store   => HTTP::Session::Store::Null->new(),
    state   => HTTP::Session::State::Null->new(),
    request => CGI->new,
);
$session->store->select();
$session->store->update();
$session->store->delete();
$session->store->insert();
ok $session;
