use strict;
use warnings;
no warnings 'uninitialized';
no warnings 'numeric';

use lib '.';
use lib './t';


use Data::Dumper;
use File::Temp qw/ :mktemp tempdir /;
use JSON;
use Testy;
use Test::More;

use Carp;

BEGIN {
    use_ok( "Yote::Server" ) || BAIL_OUT( "Unable to load Yote::Server" );
    $Yote::Server::DEBUG = -1;
    no strict 'refs';
    *Yote::ServerRoot::test = sub {
        my( $self, @args ) = @_;
        return ( "FOOBIE", "BLECH", @args );
    };
    *Yote::ServerObj::someMethod = sub {
        my( $self, @args ) = @_;
        return ( "FOOBIE", "BLECH", @args );
    };
    use strict 'refs';    
}

#
# Set up the root with some data
#
my $dir = tempdir( CLEANUP => 1 );
my $server = new Yote::Server( { yote_root_dir => $dir, yote_port => 8881 } );
my $store = $server->{STORE};
my $otherO = $store->newobj;
my $root = $store->fetch_server_root;
$root->set_fooObj( $store->newobj( { innerfoo => [ 'innerbar', 'vinnercar', $otherO ] } ) );
my $fooHash = $root->set_fooHash( {  innerFooHash => $otherO, someTxt => "vvtxtyTxt"} );
my $fooArr = $root->set_fooArr( [ $otherO, 'vinner', 'winnyo'] );
$root->set_txt( "SOMETEXT" );
my $fooObj   = $root->get_fooObj;
my $innerfoo = $fooObj->get_innerfoo;
$store->stow_all;

#use Devel::SimpleProfiler;
#Devel::SimpleProfiler::init( '/tmp/foobar', qr/Yote::[^O]|Lock|Data|test_suite/ );
#Devel::SimpleProfiler::start;

my( $pid, $count );
until( $pid ) {
    $pid = $server->start;
    last if $pid;
    sleep 5;
    if( ++$count > 10 ) {
        my $err = $server->{error};
        $server->stop;
        BAIL_OUT( "Unable to start server '$err'" );
    }
} 

$SIG{ INT } = $SIG{ __DIE__ } =
    sub {
        $server->stop;
        Carp::confess( @_ );
};

sleep 1;

test_suite();

$server->stop;

done_testing;

#print Devel::SimpleProfiler::analyze('calls');

exit( 0 );

sub msg {  #returns resp code, headers, response pased from json 
    my( $obj_id, $token, $action, @params ) = @_;
    
    my $socket = new IO::Socket::INET( "127.0.0.1:8881" ) or die "Error contacting server : $@";
    my $payload = 'p=' . encode_json( {
        i => $obj_id,
        t => $token,
        a => $action,
        pl => [map { $_ > 1 || substr($_,0,1) eq 'v' ? $_ : "v$_" } @params],
                           } );
    $socket->print( "POST / HTTP/1.1\nContent-Type: text/json\nContent-Length: " . length( $payload ) ."\n\n$payload" );
    
    my $resp = <$socket>;
    
    my( $code ) = ( $resp =~ /^HTT[^ ]+ (\d+) / ) ;
    
    # headers
    my %hdr;
    while( $resp = <$socket> ) {
        chomp $resp;
        last unless $resp =~ /\S/s;
        my( $k, $v ) = ( $resp =~ /(.*)\s*:\s*(.*)/ );
        $hdr{$k} = $v;
    }
    my $ret;
    if( $hdr{'Content-Length'} ) {
        my $rtxt = '';
        while( $resp = <$socket> ) {
            $rtxt .= $resp;
        }
        $ret = decode_json( $rtxt );
    }
    return ( $code, \%hdr, $ret );
}

sub l2a {
    # converts a list to a hash ref
    my $params = ref( $_[0] ) ? $_[0] : [ @_ ];
    return { map { $_ => 1 } @$params };
}

sub test_suite {
    
    my( @pids );

    # try no token, and with token
    my( $retcode, $hdrs, $ret ) = msg( '_', '_', 'test' );

    is( $retcode, 200, "root node can call test" );
    is_deeply( $hdrs, {
        'Content-Length' => '57',
        'Access-Control-Allow-Headers' => 'accept, content-type, cookie, origin, connection, cache-control',
        'Server' => 'Yote',
        'Access-Control-Allow-Origin' => '*',
        'Content-Type' => 'text/json; charset=utf-8'
        }, 'correct headers returned' );


    ( $retcode, $hdrs, $ret ) = msg( '_', '_', 'noMethod' );
    is( $retcode, 200, "root node has no noMethod call" );
    ok( $ret->{err}, "nothing returned for error case noMethod" );

    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, '_', 'test' );
    is( $retcode, 200, "no access without token when calling by id for server root only" );
    is_deeply( $ret->{methods}, {}, 'correct methods (none) for server root with non fetch_root call (called test)' );
    is_deeply( $ret->{updates}, [], "no updates without token" );

    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, '_', 'fetch_root' );
    is( $retcode, 200, "no access without token when calling by id for server root only" );

    ok( $ret->{methods}{'Yote::ServerRoot'}, "has methods for server root" );
    is_deeply( l2a( $ret->{methods}{'Yote::ServerRoot'} ),
               l2a( qw(  create_token
                         fetch_app
                         fetch_root
                         fetch_session
                         init_root
                         test
                         update
                  ) ), 'correct methods for fetched server root' );

    is_deeply( [sort { $a->{id} <=> $b->{id} } @{$ret->{updates}}], 
               [ sort { $a->{id} <=> $b->{id} } (
                     {
                         cls  => 'Yote::ServerRoot', 
                         id   => $root->{ID}, 
                         data => {
                             txt     => 'vSOMETEXT',
                             fooObj  => $store->_get_id( $fooObj ),
                             fooHash => $store->_get_id( $fooHash ),
                             fooArr  => $store->_get_id( $fooArr ),
                         } 
                     },

                     {
                         cls  => 'Yote::ServerObj', 
                         id   => $store->_get_id( $fooObj ),
                         data => {
                             innerfoo => $store->_get_id( $fooObj->get_innerfoo ),
                         }
                     },

                     {
                         cls  => 'HASH', 
                         id   => $store->_get_id( $fooHash ),
                         data => {
                             innerFooHash => $store->_get_id( $otherO ),
                             someTxt      => 'vvvtxtyTxt',
                         }
                     },

                     {
                         cls  => 'ARRAY', 
                         id   => $store->_get_id( $fooArr ),
                         data => [
                             $store->_get_id( $otherO ),
                             'vvinner',
                             'vwinnyo',
                         ]
                     },

                     {
                         cls  => 'ARRAY', 
                         id   => $store->_get_id( $fooObj->get_innerfoo ),
                         data => [
                             'vinnerbar',
                             'vvinnercar',
                             $store->_get_id( $otherO ),
                         ]
                     },

                     {
                         cls  => 'Yote::ServerObj', 
                         id   => $store->_get_id( $otherO ),
                         data => {
                         }
                     },

                 ) ], "updates for fetch_root by id, no token" );

    # now try with a token
    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, '_', 'create_token' );
    is( $retcode, 200, "token was returned" );
    my( $token ) = map { substr( $_, 1 ) }  @{ $ret->{result} };
    cmp_ok( $token, '>', 0, "Got token" );
    is_deeply( $ret->{updates}, [], "no updates when calling create token" );
    is_deeply( $ret->{methods}, {}, 'no methods returned for creat token ' );

    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, $token, 'fetch_root' );
    is( $retcode, 200, "able to return with token" );

    ok( $ret->{methods}{'Yote::ServerRoot'}, "has methods for server root" );
    is( scalar( keys %{$ret->{methods}} ), 2, "root methods and serverobj methods methods returned" );
    is_deeply( l2a( $ret->{methods}{'Yote::ServerRoot'} ),
               l2a( qw( create_token
                        fetch_app
                        fetch_root
                        fetch_session
                        init_root
                        test
                        update
                    ) ), 'correct methods for server root' );



    # make sure no prive _ method is called.
    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, $token, '_updates_needed' );
    ok( $ret->{err}, "cannot call underscore method" );

    # make sure no nonexistant method is called.
    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, $token, 'slurpyfoo' );
    ok( $ret->{err}, "cannot call nonexistant method" );


    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, $token, 'update' );

    $root->set_extra( "WOOF" );
#
    sleep 2;
    $store->stow_all;

# ok, server root wasn't reloaded because it doesn't do that. Maybe that is bad. set an other extra?

    # get the 'foo' object off of the root
    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, $token, 'update' );
    is( $retcode, 200, "able to fetch allowed object" );
    is_deeply( $ret->{updates}, [{cls  => 'Yote::ServerRoot', 
                                  id   => $root->{ID}, 
                                  data => {
                                      extra   => 'vWOOF',
                                      txt     => 'vSOMETEXT',
                                      fooObj  => $store->_get_id( $fooObj ),
                                      fooHash => $store->_get_id( $fooHash ),
                                      fooArr  => $store->_get_id( $fooArr ),
                                  } } ], "updates for fetch_root by id token after change and save" );

    # now try some objects that are more than just server root objects
    ( $retcode, $hdrs, $ret ) = msg( $root->{ID}, $token, 'fetch_app', 'Testy' );

    is( $retcode, 200, "able to fetch allowed object" );

    is_deeply( $ret->{methods}, {
        'Yote::ServerObj' =>  [ qw( absorb someMethod ) ],
        'Yote::ServerSession' => [ qw( fetch getid ) ],
        Testy => [qw( create_account login logout test tickle )] },
               
               "methods for testy app" );
    my( $testyobjid, $testyLogin ) = @{$ret->{result}};
    is( $testyLogin, 'v', "no login for testy obj " );
    
    # hash of id -> update
    my $id2up = { map { $_->{id} => $_ } @{$ret->{updates}}};
    my $testobjup = $id2up->{$testyobjid};
    my $attached_objid = $testobjup->{data}{obj};
    ok( $attached_objid, "testyobj has its attached obj" );
    is_deeply( $id2up->{$attached_objid}{data}, {}, "attached obj has no data yet" );

    ok( ! $id2up->{$root->{ID}}, "Server Obj not returned as it was in the session" );

    # now call a method on testy that changes the attached obj
    # but does not return it
    ( $retcode, $hdrs, $ret ) = msg( $testyobjid, $token, 'tickle' );

    is( $retcode, 200, "tickle worked" );
    my $updates = { map { $_->{id} => $_ } @{$ret->{updates}} };
    is_deeply( $updates->{$attached_objid}, {
        id   => $attached_objid,
        cls  => 'Yote::ServerObj',
        data => { tickled => 'v1' },
                                  }, "attached obj updated" );
    
    is_deeply( $ret->{methods}, {
        'Yote::ServerObj' =>  [ qw( absorb someMethod ) ],
               }, "methods returned" );


    # test the following :
    #   fetch_app returns app update and app methods
    #   fetch_app returns loging update and login methods when there is a login in the return
    #   fetch_app also registers the app with the user token
    #   fetch_app also registers the login with the user token when there is a login
    #

    # make sure that when arrays and hashes are part of the return, they are returned properly

    
    while( @pids ) { 
        my $pid = shift @pids;
        waitpid $pid, 0;

        # XXX
        fail("Killing pid failed : $@") if $?;
    }
    
} #test suite

__END__

