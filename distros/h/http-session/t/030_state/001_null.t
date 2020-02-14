use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Session::State::Null;

my $state = HTTP::Session::State::Null->new();
is $state->get_session_id(), undef;
$state->response_filter(); # nop.

