use strict;
use warnings;
use Test::More tests => 5;
use t::Exception;
use HTTP::Session;
use CGI;
use HTTP::Session::Store::DBM;
use HTTP::Session::State::Test;
use File::Temp;

my (undef, $fname) = File::Temp::tempfile(UNLINK => 1);
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

unlink "${fname}.$_" for qw/pag dir/;

sub gen_session {
    my $session = HTTP::Session->new(
        store => HTTP::Session::Store::DBM->new(
            file      => $fname,
            dbm_class => 'SDBM_File',
        ),
        state   => HTTP::Session::State::Test->new(
            session_id => 'haheeee',
            permissive => 1,
        ),
        request => CGI->new,
    );
}

