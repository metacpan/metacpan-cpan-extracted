package Yote::Server;

use strict;
use warnings;

no warnings 'uninitialized';
no warnings 'numeric';

use Lock::Server;
use Yote;

use bytes;
use IO::Socket::SSL;
use JSON;
use Time::HiRes qw(time);
use URI::Escape;
use UUID::Tiny;


use vars qw($VERSION);

$VERSION = '1.26';

our $DEBUG = 0;

sub new {
    my( $pkg, $args ) = @_;
    my $class = ref( $pkg ) || $pkg;
    my $server = bless {
        args                 => $args || {},

        # the following are the args currently used
        yote_root_dir        => $args->{yote_root_dir},
        yote_host            => $args->{yote_host} || '127.0.0.1',
        yote_port            => $args->{yote_port} || 8881,
        pids                 => [],
        _locker              => new Lock::Server( {
            port                 => $args->{lock_port},
            host                 => $args->{lock_host} || '127.0.0.1',
            lock_attempt_timeout => $args->{lock_attempt_timeout},
            lock_timeout         => $args->{lock_timeout},
                                                  } ),
        STORE                => Yote::ServerStore->_new( { root => $args->{yote_root_dir} } ),
    }, $class;
    $server->{STORE}{_locker} = $server->{_locker};
    $server;
} #new

sub store {
    shift->{STORE};
}

sub load_options {

    my( $yote_root_dir ) = @_;

    my $confile = "$yote_root_dir/yote.conf";

    #
    # set up default options
    #
    my $options = {
        yote_root_dir        => $yote_root_dir,
        yote_host            => '127.0.0.1',
        yote_port            => 8881,
        lock_port            => 8004,
        lock_host            => '127.0.0.1',
        lock_attempt_timeout => 12,
        lock_timeout         => 10,
        use_ssl              => 0,
        SSL_cert_file        => '',
        SSL_key_file         => '',
    };

    #
    # override base defaults with those from conf file
    #
    if( -f $confile && -r $confile ) {
        # TODO - create conf with defaults and make it part of the install
        open( IN, "<$confile" ) or die "Unable to open config file $@ $!";
        while( <IN> ) {
            chomp;
            s/\#.*//;
            if( /^\s*([^=\s]+)\s*=\s*([^\s].*)\s*$/ ) {
                if( defined $options->{$1} ) {
                    $options->{$1} = $2 if defined $options->{$1};
                } else {
                    print STDERR "Warning: encountered '$1' in file. Ignoring";
                }
            }
        }
        close IN;
    } #if config file is there

    return $options;
} #load_options

sub ensure_locker {
    my $self = shift;
    # if running as the server, this will not be called. 
    # if something else is managing forking ( like the CGI )
    # this should be run to make sure the locker socket
    # opens and closes
    $SIG{INT} = sub {
        _log( "$0 got INT signal. Shutting down." );
        $self->{_locker}->stop if $self->{_locker};
        exit;
    };

    if( ! $self->{_locker}->ping(1) ) {
        $self->{_locker}->start;
    }
} #ensure_locker

sub start {
    my $self = shift;

    $self->{_locker}->start;

    my $listener_socket = $self->_create_listener_socket;
    die "Unable to open socket " unless $listener_socket;

    if( my $pid = fork ) {
        # parent
        $self->{server_pid} = $pid;
        return $pid;
    }

    # in child
    $0 = "YoteServer process";
    $self->_run_loop( $listener_socket );

} #start

sub stop {
    my $self = shift;
    if( my $pid = $self->{server_pid} ) {
        $self->{error} = "Sending INT signal to lock server of pid '$pid'";
        kill 'INT', $pid;
        return 1;
    }
    $self->{error} = "No Yote server running";
    return 0;
}



=head2 run

    Runs the lock server.

=cut
sub run {
    my $self = shift;
    my $listener_socket = $self->_create_listener_socket;
    die "Unable to open socket " unless $listener_socket;
    $self->_run_loop( $listener_socket );
}

sub _create_listener_socket {
    my $self = shift;

    my $listener_socket;
    my $count = 0;

    if( $self->{use_ssl} && ( ! $self->{SSL_cert_file} || ! $self->{SSL_key_file} ) ) {
        die "Cannot start server. SSL selected but is missing filename for SSL_cert_file and/or SSL_key_file";
    }
    while( ! $listener_socket && ++$count < 10 ) {
        if( $self->{args}{use_ssl} ) {
            my $cert_file = $self->{args}{SSL_cert_file};
            my $key_file  = $self->{args}{SSL_key_file};
            if( index( $cert_file, '/' ) != 0 ) {
                $cert_file = "$self->{yote_root_dir}/$cert_file";
            }
            if( index( $key_file, '/' ) != 0 ) {
                $key_file = "$self->{yote_root_dir}/$key_file";
            }
            $listener_socket = new IO::Socket::SSL(
                Listen    => 10,
                LocalAddr => "$self->{yote_host}:$self->{yote_port}",
                SSL_cert_file => $cert_file,
                SSL_key_file => $key_file,
                );
        } else {
            $listener_socket = new IO::Socket::INET(
                Listen    => 10,
                LocalAddr => "$self->{yote_host}:$self->{yote_port}",
                );
        }
        last if $listener_socket;
        
        print STDERR "Unable to open the yote socket [$self->{yote_host}:$self->{yote_port}] ($!). Retry $count of 10\n";
        sleep 5 * $count;
    }

    unless( $listener_socket ) {
        $self->{error} = "Unable to open yote socket on port '$self->{yote_port}' : $! $@\n";
        $self->{_locker}->stop;
        _log( "unable to start yote server : $@ $!." );
        return 0;
    }

    print STDERR "Starting yote server\n";

    unless( $self->{yote_root_dir} ) {
        eval('use Yote::ConfigData');
        $self->{yote_root_dir} = $@ ? '/opt/yote' : Yote::ConfigData->config( 'yote_root' );
        undef $@;
    }

    # if this is cancelled, make sure all child procs are killed too
    $SIG{INT} = sub {
        _log( "got INT signal. Shutting down." );
        $listener_socket && $listener_socket->close;
        for my $pid ( @{ $self->{_pids} } ) {
            kill 'HUP', $pid;
        }
        $self->{_locker}->stop;
        exit;
    };

    $SIG{CHLD} = 'IGNORE';

    return $listener_socket;
} #_create_listener_socket

sub _run_loop {
    my( $self, $listener_socket ) = @_;
    while( my $connection = $listener_socket->accept ) {
        $self->_process_request( $connection );
    }
}

sub _log {
    my( $msg, $sev ) = @_;
    $sev //= 1;
    if( $sev <= $DEBUG ) {
        print STDERR "Yote::Server : $msg\n";
        open my $out, ">>/opt/yote/log/yote.log" or return;
        print $out "$msg\n";
        close $out;
    }
}

sub _find_ids_in_data {
    my $data = shift;
    my $r = ref( $data );
    if( $r eq 'ARRAY' ) {
        return grep { $_ && index($_,'v')!=0 } map { ref( $_ ) ? _find_ids_in_data($_) : $_ } @$data;
    }
    elsif( $r eq 'HASH' ) {
        return grep { $_ && index($_,'v')!=0} map { ref( $_ ) ? _find_ids_in_data($_) : $_ } values %$data;
    }
    elsif( $r ) {
        die "_find_ids_in_data encountered a non ARRAY or HASH reference";
    }
} #_find_ids_in_data

# EXPERIMETNAL - this will return the entire public tree. The idea is to program
# without having to explicitly shove data across. This errs on the side of much
# more data, so relies on private data and method calls (encapsulation) to
# mitigate this

sub _unroll_ids {
    my( $store, $ids, $seen ) = @_;
    $seen  //= {};

    my( @items ) = ( map { $store->fetch($_) } @$ids );

    my @outids;
    for my $item( @items ) {
        my $iid = $store->_get_id($item);
        my $r = ref( $item );
        $seen->{$iid}++;
        if( $r eq 'ARRAY' ) {
            push @outids, grep { ! $seen->{$_}++ } map { $store->_get_id($_)  } grep { ref($_) } @$item;
        }
        elsif( $r eq 'HASH' ) {
            push @outids, grep { ! $seen->{$_}++ } map { $store->_get_id($_)  } grep { ref($_) } values %$item;
        }
        else {
            my $data = $item->{DATA};
            push @outids, map { $data->{$_} } grep { /^[^_]/ && $data->{$_} != /^v/ && ! $seen->{$data->{$_}}++ } keys %$data;
        }
    }

    _unroll_ids( $store, \@outids, $seen ) if @outids;


    [ keys %$seen ];
} #_unroll_ids

sub _process_request {
    #
    # Reads incomming request from the socket, parses it, performs it and
    # prints the result back to the socket.
    #
    my( $self, $sock ) = @_;


    if ( my $pid = fork ) {
        # parent
        push @{$self->{_pids}},$pid;
    } else {
#      use Devel::SimpleProfiler;Devel::SimpleProfiler::start;
        my( $self, $sock ) = @_;
        #child
        $0 = "YoteServer processing request";
        $SIG{INT} = sub {
            _log( " process $$ got INT signal. Shutting down." );
            $sock->close;
            exit;
        };
        
        
        my $req = <$sock>;
        $ENV{REMOTE_HOST} = $sock->peerhost;
        my( %headers, %cookies );
        while( my $hdr = <$sock> ) {
            $hdr =~ s/\s*$//s;
            last if $hdr !~ /[a-zA-Z]/;
            my( $key, $val ) = ( $hdr =~ /^([^:]+):(.*)/ );
            $headers{$key} = $val;
        }

        for my $cookie ( split( /\s*;\s*/, $headers{Cookie} ) ) {
           $cookie =~ s/^\s*|^\s*$//g;
            my( $key, $val ) = split( /\s*=\s*/, $cookie, 2 );
            $cookies{ $key } = $val;
        }
        
        # 
        # read certain length from socket ( as many bytes as content length )
        #
        my $content_length = $headers{'Content-Length'};
        my $data;
        if ( $content_length > 0 && ! eof $sock) {
            read $sock, $data, $content_length;
        }
        my( $verb, $path ) = split( /\s+/, $req );

        # escape for serving up web pages
        # the thought is that this should be able to be a stand alone webserver
        # for testing and to provide the javascript
        if ( $path =~ m!/__/! ) {
            # TODO - make sure install script makes the directories properly
            my $filename = "$self->{yote_root_dir}/html/" . substr( $path, 4 );
            if ( -e $filename ) {
                my @stat = stat $filename;

                my $content_type = $filename =~ /css$/ ? 'text/css' : 'text/html';
                my @headers = (
                    "Content-Type: $content_type; charset=utf-8",
                    'Server: Yote',
                    "Content-Length: $stat[7]",
                );

                open( IN, "<$filename" );

                $sock->print( "HTTP/1.1 200 OK\n" . join ("\n", @headers). "\n\n" );

                while ( $data = <IN> ) {
                    $sock->print( $data );
                }
                close IN;
            } else {
                $sock->print( "HTTP/1.1 404 FILE NOT FOUND\n\n" );
            }
            $sock->close;
            exit;
        }
        

        # data has the input parmas in JSON format.
        # POST /

        if ( $verb ne 'POST' ) {
            $sock->print( "HTTP/1.1 400 BAD REQUEST\n\n" );
            $sock->close;
        }

        $data =~ s/^p=//;
        my $out_json;
        eval {
            $out_json = $self->invoke_payload( $data );
        };

        if( ref $@ eq 'HASH' ) {
            $out_json = encode_json( $@ );
        } 
        elsif( $@ ) {
            $out_json = encode_json( {
                err => $@,
                                 } );
        }
        my @headers = (
            'Content-Type: text/json; charset=utf-8',
            'Server: Yote',
            'Access-Control-Allow-Headers: accept, content-type, cookie, origin, connection, cache-control',
            'Access-Control-Allow-Origin: *', #TODO - have this configurable
            'Content-Length: ' . bytes::length( $out_json ),
            );
        
        $sock->print( "HTTP/1.1 200 OK\n" . join ("\n", @headers). "\n\n$out_json\n" );
        
        $sock->close;

        exit;

    } #child
} #_process_request
sub invoke_payload {
    my( $self, $raw_req_data, $file_uploads ) = @_;

    my $req_data = decode_json( $raw_req_data );
    
    my( $obj_id, $token, $action, $params ) = @$req_data{ 'i', 't', 'a', 'pl' };
    
    my $server_root = $self->{STORE}->fetch_server_root;
    my $server_root_id = $server_root->{ID};
    

    my $id_to_last_update_time;
    my $session = $token && $token ne '_' ? $server_root->_fetch_session( $token ) : undef;

    if( $session ) {
        $id_to_last_update_time = $session->get__has_ids2times;
    }

    unless( $obj_id eq '_' ||                    # either the object id that is acted upon is
            $obj_id eq $server_root_id ||        # the server root or is known to the session
            ( $id_to_last_update_time->{$obj_id} ) ) { 
        # tried to do an action on an object it wasn't handed. do a 404
        die( "client with token [$token] and session ($session) tried to invoke on obj id '$obj_id' which it does not have" );
    }
    if( substr( $action, 0, 1 ) eq '_' || $action =~ /^[gs]et$/ ) {
        die( "Private method called" );
    }

    if ( $params && ref( $params ) ne 'ARRAY' ) {
        die( "Bad Req Param Not Array : $params" );
    }

    my $store = $self->{STORE};

    # now things are getting a bit more complicated. The params passed in
    # are always a list, but they may contain other containers that are not
    # yote objects. So, transform the incomming parameter list and check all
    # yote objects inside for may. Use a recursive helper function for this.
    my $in_params = $store->__transform_params( $params, $session, $file_uploads );

    #
    # This obj is the object that the method call is on
    #
    my $obj = $obj_id eq '_' ? $server_root :
        $store->fetch( $obj_id );

    unless( $obj->can( $action ) ) {
        die( "Bad Req : invalid method :'$action'" );
    }

    # if there is a session, attach it to the object
    if( $session ) {
        $obj->{SESSION} = $session;
        $obj->{SESSION}{SERVER_ROOT} = $server_root;

    }

    #
    # <<------------- the actual method call --------------->>
    #
    my(@res) = ($obj->$action( @$in_params ));

    #
    # this is included in what is  returned to the client
    #
    my $out_res = $store->_xform_in( \@res, 'allow datastructures' );

    #
    # in case the method generated a new session, (re)set that now
    #
    $session = $obj->{SESSION};
    if( $session ) {
        $id_to_last_update_time = $session->get__has_ids2times;
    }
    
    # the ids that were referenced explicitly in the
    # method call.
    my @out_ids = _find_ids_in_data( $out_res );

    #
    # Based on the return value of the method call,
    #   these ids are ones that the client should have.
    #   We will check to see if these need updates
    #
    my @should_have = ( @{ _unroll_ids( $store, [@out_ids, keys %$id_to_last_update_time] ) } );
    my( @updates, %methods );

    #
    # check if existing are in the session
    #
    for my $should_have_id ( @should_have, keys %$id_to_last_update_time ) {
        my $needs_update = 1;
        
        if( $session)  {
            #
            # check if the client of this session needs an update, otherwise assume that it does
            #
            my( $client_s, $client_ms )  = @{ $id_to_last_update_time->{$should_have_id} || [] };
            my( $server_s, $server_ms )  = $store->_last_updated( $should_have_id );

            $needs_update = $client_s == 0 || $server_s > $client_s || ($server_s == $client_s && $server_ms > $client_ms );
        }

        if( $needs_update ) {
            my $should_have_obj = $store->fetch( $should_have_id );
            my $ref = ref( $should_have_obj );
            my $data;
            if( $ref eq 'ARRAY' ) {
                $data = [ map { $store->_xform_in( $_ ) } @$should_have_obj ];
            } elsif(  $ref eq 'HASH' ) {
                $data = { map { $_ =>  $store->_xform_in( $should_have_obj->{$_} ) } keys %$should_have_obj };
            } else {
                my $d = $should_have_obj->{DATA};
                $data = { map { $_ => $d->{$_} } grep { index($_,"_") != 0 } keys %$d },
                $methods{$ref} ||= $should_have_obj->_callable_methods;
            }
            my $update = {
                id    => $should_have_id,
                cls   => $ref,
                data  => $data,
            };
            push @updates, $update;
            if( $session ) {
                $id_to_last_update_time->{$should_have_id} = [Time::HiRes::gettimeofday];
            }
        } # if this needs an update
        
    } #each object the client should have


    my $out_json = to_json( { result  => $out_res,
                              updates => \@updates,
                              methods => \%methods,
                            } );

    delete $obj->{SESSION};
    $self->{STORE}->stow_all;
    
    return $out_json;
} #invoke_payload

# ------- END Yote::Server

package Yote::ServerStore;

use Data::RecordStore;

use base 'Yote::ObjStore';

sub _new { #Yote::ServerStore
    my( $pkg, $args ) = @_;
    $args->{store} = "$args->{root}/DATA_STORE";
    my $self = $pkg->SUPER::_new( $args );

    # keeps track of when any object had been last updated.
    # use like $self->{OBJ_UPDATE_DB}->put_record( $obj_id, [ time ] );
    # or my( $time ) = @{ $self->{OBJ_UPDATE_DB}->get_record( $obj_id ) };
    $self->{OBJ_UPDATE_DB} = Data::RecordStore::FixedStore->open( "LL", "$args->{root}/OBJ_META" );

    my( $m, $ms ) = ( Time::HiRes::gettimeofday  );
    $self->{OBJ_UPDATE_DB}->put_record( $self->{ID}, [ $m, $ms ] );

    $self;
} #_new

sub _dirty {
    my( $self, $ref, $id ) = @_;
    $self->SUPER::_dirty( $ref, $id );
    $self->{OBJ_UPDATE_DB}->ensure_entry_count( $id );

    my( $m, $ms ) = ( Time::HiRes::gettimeofday  );
    $self->{OBJ_UPDATE_DB}->put_record( $id, [ $m, $ms ] );
}

sub stow_all {
    my $self = $_[0];
    for my $obj (values %{$self->{_DIRTY}} ) {
        my $obj_id = $self->_get_id( $obj );
        $self->{OBJ_UPDATE_DB}->ensure_entry_count( $obj_id );
    }
    $self->SUPER::stow_all;
} #stow_all

sub _last_updated {
    my( $self, $obj_id ) = @_;
    my( $s, $ms ) = @{ $self->{OBJ_UPDATE_DB}->get_record( $obj_id ) };
    $s, $ms;
}

sub _log {
    Yote::Server::_log(shift);
}


sub __transform_params {
    #
    # Recursively transforms incoming parameters into values, yote objects, or non yote containers.
    # This checks to make sure that the parameters are allowed by the given token.
    # Throws execptions if the parametsr are not allowed, or if a reference that is not a hash or array
    # is encountered.
    #
    my( $self, $param, $session, $files ) = @_;

    if( ref( $param ) eq 'HASH' ) {
        return { map { $_ => $self->__transform_params($param->{$_}, $session, $files) } keys %$param };
    } 
    elsif( ref( $param ) eq 'ARRAY' ) {
        return [ map { $self->__transform_params($_, $session, $files) } @$param ];
    } elsif( ref( $param ) ) {
        die "Transforming Params: got weird ref '" . ref( $param ) . "'";
    }
    if( ( index( $param, 'v' ) != 0 && index($param, 'f' ) != 0 ) && !$session->get__has_ids2times({})->{$param} ) {
        # obj id given, but the client should not have that id
        if( $param ) {
            die { err => 'Sync Error', needs_resync => 1 };
        }
        return undef;
    }
    return $self->_xform_out( $param, $files );
} #__transform_params

sub _xform_out {
    my( $self, $val, $files ) = @_;
    return undef unless defined( $val );
    if( index($val,'f') == 0 ) {
        # convert to file object
        if( $val =~ /^f(\d+)_(\d+)$/ ) {
            my( $offset_start, $offset_end ) = ( $1, $2 );
            for( my $i=$offset_start; $i < $offset_end; $i++ ) {
                my $file = $files->[$i];
                if( $file ) {
                    my( $orig_filename ) = ( $file =~ /([^\/]*)$/ );
                    my( $extension ) = ( $orig_filename =~ /\.([^.\/]+)$/ );
                    
                    # TODO - cleanup, maybe use File::Temp or something
                    my $newname = "/tmp/".UUID::Tiny::create_uuid_as_string();
                    open (FILE, ">$newname");
                    my $fh = $file->fh;
                    while (read ($fh, my $Buffer, 1024)) {
                        print FILE $Buffer;
                    }
                    close FILE;
                    # create yote object here that wraps the file name
                    return $self->newobj( {
                        file_path => $newname,
                        file_extension => $extension,
                        file_name => $orig_filename,
                                          } );
                }
            } #finding the file
            return undef;
        }
    }
    return $self->SUPER::_xform_out( $val );
} #_xform_out


#
# Unlike the superclass version of this, this provides an arguemnt to
# allow non-yote datastructures to be returned. The contents of those
# data structures will all recursively be xformed in.
#
sub _xform_in {
    my( $self, $val, $allow_datastructures ) = @_;

    my $r = ref $val;
    if( $r ) {
        if( $allow_datastructures) {
            # check if this is a yote object
            if( ref( $val ) eq 'ARRAY' && ! tied( @$val ) ) {
                return [ map { ref $_ ? $self->_xform_in( $_, $allow_datastructures ) : "v$_" } @$val ];
            }
            elsif( ref( $val ) eq 'HASH' && ! tied %$val ) {
                return { map { $_ => ( ref( $val->{$_} ) ? $self->_xform_in( $val->{$_}, $allow_datastructures ) : "v$val->{$_}" ) } keys %$val };
            }
        }
        return $self->_get_id( $val );
    }

    return defined $val ? "v$val" : undef;
} #_xform_in

sub newobj {
    my( $self, $data, $class ) = @_;
    $class ||= 'Yote::ServerObj';
    $class->_new( $self, $data );
} #newobj

sub fetch_server_root {
    my $self = shift;

    return $self->{SERVER_ROOT} if $self->{SERVER_ROOT};

    my $system_root = $self->fetch_root;
    my $server_root = $system_root->get_server_root;
    unless( $server_root ) {
        $server_root = Yote::ServerRoot->_new( $self );
        $system_root->set_server_root( $server_root );
        $self->stow_all;
    }

    # some setup here? accounts/webapps/etc?
    # or make it simple. if the webapp has an account, then pass that account
    # with the rest of the arguments

    # then verify if the command can run on the app object with those args
    # or even : $myapp->run( 'command', @args );

    $self->{SERVER_ROOT} ||= $server_root;

    $server_root;
    
} #fetch_server_root

sub lock {
    my( $self, $key ) = @_;
    $self->{_lockerClient} ||= $self->{_locker}->client( $$ );
    $self->{_lockerClient}->lock( $key );
}

sub unlock {
    my( $self, $key ) = @_;
    $self->{_lockerClient}->unlock( $key );
}


# ------- END Yote::ServerStore

package Yote::ServerObj;

use base 'Yote::Obj';

sub _log {
    Yote::Server::_log(shift);
}

sub _err {
    shift; #self
    die { err => shift };
}

$Yote::ServerObj::PKG2METHS = {};
sub __discover_methods {
    my $pkg = shift;
    my $meths = $Yote::ServerObj::PKG2METHS->{$pkg};
    if( $meths ) {
        return $meths;
    }

    no strict 'refs';
    my @m = grep { $_ !~ /::/ } keys %{"${pkg}\::"};
    if( $pkg eq 'Yote::ServerObj' ) { #the base, presumably
        return [ sort grep { $_ !~ /^(_|[gs]et_|(can|[sg]et|VERSION|AUTOLOAD|DESTROY|CARP_TRACE|BEGIN|isa|import|PKG2METHS|ISA|add_to_|remove_from)$)/ } @m ];
    }

    my %hasm = map { $_ => 1 } @m;
    for my $class ( @{"${pkg}\::ISA" } ) {
        next if $class eq 'Yote::ServerObj' || $class eq 'Yote::Obj';
        my $pm = __discover_methods( $class );
        push @m, @$pm;
    }
    
    my $base_meths = __discover_methods( 'Yote::ServerObj' );
    my( %base ) = map { $_ => 1 } 'AUTOLOAD', @$base_meths;
    $meths = [ sort grep { $_ !~ /^(_|[gs]et_|(can|[sg]et|VERSION|AUTOLOAD|DESTROY|BEGIN|isa|import|PKG2METHS|ISA|add_to_|remove_from)$)/ && ! $base{$_} } @m ];
    $Yote::ServerObj::PKG2METHS->{$pkg} = $meths;
    
    $meths;
} #__discover_methods

# when sending objects across, the format is like
# id : { data : { }, methods : [] }
# the methods exclude all the methods of Yote::Obj
sub _callable_methods {
    my $self = shift;
    my $pkg = ref( $self );
    __discover_methods( $pkg );
} # _callable_methods


sub _get {
    my( $self, $fld, $default ) = @_;
    if( ! defined( $self->{DATA}{$fld} ) && defined($default) ) {
        if( ref( $default ) ) {
            $self->{STORE}->_dirty( $default, $self->{STORE}->_get_id( $default ) );
        }
        $self->{STORE}->_dirty( $self, $self->{ID} );
        $self->{DATA}{$fld} = $self->{STORE}->_xform_in( $default );
    }
    $self->{STORE}->_xform_out( $self->{DATA}{$fld} );
} #_get


# ------- END Yote::ServerObj

package Yote::ServerRoot;

use base 'Yote::ServerObj';

sub _init {
    my $self = shift;
    $self->set__doesHave_Token2objs({});
    $self->set__apps({});
    $self->set__token_timeslots([]);
    $self->set__token_timeslots_metadata([]);
    $self->set__token_mutex([]);
}

sub _log {
    Yote::Server::_log(shift);
}

#
# fetches or creates session which has a _token field
#
sub fetch_session {
    my( $self, $token ) = @_;
    my $session = $self->_fetch_session( $token ) || $self->_create_session;
    $self->{SESSION} = $session;
    $session;
}

sub _fetch_session {
    my( $self, $token ) = @_;
    
    $self->{STORE}->lock( 'token_mutex' );
    my $slots = $self->get__token_timeslots();

    for( my $i=0; $i<@$slots; $i++ ) {
        if( my $session = $slots->[$i]{$token} ) {
            if( $i > 0 ) {
                # make sure this is in the most current 'boat'
                $slots->[0]{ $token } = $session;
            }
            $self->{STORE}->unlock( 'token_mutex' );
            return $session;
        }
    }
    $self->{STORE}->unlock( 'token_mutex' );
    0;
} #_fetch_sesion

sub _create_session {
    my $self = shift;
    my $tries = shift;

    if( $tries > 3 ) {
        die "Error creating token. Got the same random number 4 times in a row";
    }

    my $token = int( rand( 1_000_000_000 ) ); #TODO - find max this can be for long int
    
    # make the token boat. tokens last at least 10 mins, so quantize
    # 10 minutes via time 10 min = 600 seconds = 600
    # or easy, so that 1000 seconds ( ~ 16 mins )
    # todo - make some sort of quantize function here
    my $current_time_chunk         = int( time / 100 );  
    my $earliest_valid_time_chunk  = $current_time_chunk - 7;

    $self->{STORE}->lock( 'token_mutex' );

    #
    # A list of slot 'boats' which store token -> ip
    #
    my $slots     = $self->get__token_timeslots();
    #
    # a list of times. the list index of these times corresponds
    # to the slot 'boats'
    #
    my $slot_data = $self->get__token_timeslots_metadata();
    
    #
    # Check if the token is already used ( very unlikely ).
    # If already used, try this again :/
    #
    for( my $i=0; $i<@$slot_data; $i++ ) {
        return $self->_create_session( $tries++ ) if $slots->[ $i ]{ $token };
    }

    #
    # See if the most recent time slot is current. If it is behind, create a new current slot
    # create a new most recent boat.
    #
    my $session = $self->{STORE}->newobj( {
        _has_ids2times => {},
        _token => $token }, 'Yote::ServerSession' );
    
    if( $slot_data->[ 0 ] == $current_time_chunk ) {
        $slots->[ 0 ]{ $token } = $session;
    } else {
        unshift @$slot_data, $current_time_chunk;
        unshift @$slots, { $token => $session };
    }
    
    #
    # remove this token from old boats so it doesn't get purged
    # when in a valid boat.
    #
    for( my $i=1; $i<@$slot_data; $i++ ) {
        delete $slots->[$i]{ $token };
    }

    $self->{STORE}->_stow( $slots );
    $self->{STORE}->_stow( $slot_data );
    $self->{STORE}->unlock( 'token_mutex' );


    $session;

} #_create_session

sub _destroy_session {
    my( $self, $token ) = @_;
    
    $self->{STORE}->lock( 'token_mutex' );
    my $slots = $self->get__token_timeslots();
    for( my $i=0; $i<@$slots; $i++ ) {
        delete $slots->[$i]{ $token };
    }
    $self->{STORE}->_stow( $slots );
    $self->{STORE}->unlock( 'token_mutex' );
    1;
} #_destroy_session

#
# Needed for when no logins are going to happen
#
sub create_token {
    shift->_create_session->get__token;
}

#
# Returns the app and possibly a logged in account
#
sub fetch_app {
    my( $self, $app_name ) = @_;
    my $apps = $self->get__apps;
    my $app  = $apps->{$app_name};

    unless( $app ) {
        eval("require $app_name");
        if( $@ ) {
            # TODO - have/use a good logging system with clarity and stuff
            # warnings, errors, etc
            return undef;
        }
        $app = $app_name->_new( $self->{STORE} );
        $apps->{$app_name} = $app;
    }
    my $acct = $self->{SESSION} ? $self->{SESSION}->get_acct : undef;

    return $app, $acct, $self->{SESSION};
} #fetch_app

sub fetch_root {
    return shift;
}

sub init_root {
    my $self = shift;
    my $session = $self->{SESSION} || $self->_create_session;
    $self->{SESSION} = $session;
    $session->set__has_ids2times({});
    my $token = $session->get__token;
    return $self, $token;
}

# while this is a non-op, it will cause any updated contents to be 
# transfered to the caller automatically
sub update {

}

# ------- END Yote::ServerRoot

package Yote::ServerSession;

use base 'Yote::ServerObj';

sub fetch {  # fetch scrambled id
    my( $self, $in_sess_id ) = @_;
    $self->get__ids([])->[$in_sess_id-1];
}

sub getid { #scramble id for object
    my( $self, $obj ) = @_;
    my $o2i = $self->get__obj2id({});
    if( $o2i->{$obj} ) {
        return $o2i->{$obj};
    }
    my $ids = $self->get__ids([]);
    push @$ids, $obj;
    my $id = scalar @$ids;
    $o2i->{$obj} = $id;
    $id;
} #id

# ------- END Yote::ServerSession

1;

__END__

=head1 NAME

Yote::Server - Serve up marshaled perl objects in javascript

=head1 DESCRIPTION

=cut





okey, this is going to have something like

my $server = new Yote::Server( { args } );

$server->start; #doesnt block
$server->run; #blocks

This is just going to serve yote objects.

_______________________

now for requests :

 they can be on the root object, specified by '_'

 root will have a method : _can_access( $obj, /%headers, methodname )
