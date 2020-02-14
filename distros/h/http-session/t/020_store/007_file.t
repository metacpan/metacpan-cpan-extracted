use strict;
use warnings;
use Test::More tests => 5;
use t::Exception;
use HTTP::Session;
use CGI;
use HTTP::Session::Store::File;
use HTTP::Session::State::Test;
use File::Temp;

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub {
    my $session = gen_session();
    is $session->session_id, 'haheeee';
    $session->set( 'foo' => 'bar' );
    $session->set( 'removed' => 'bar' );
    $session->remove('removed');
    $session->set( 'complex' => {'t' => 'k'} );
}->();
sub {
    my $session = gen_session();
    is $session->session_id, 'haheeee';
    is $session->get('foo'), 'bar';
    is $session->get('removed'), undef;
    is $session->get('complex')->{'t'}, 'k', 'fetch complex stuff';
}->();

sub gen_session {
    my $session = HTTP::Session->new(
        store => HTTP::Session::Store::File->new(
            dir => $dir,
        ),
        state   => HTTP::Session::State::Test->new(
            session_id => 'haheeee',
            permissive => 1,
        ),
        request => CGI->new,
    );
}

