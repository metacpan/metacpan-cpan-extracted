package MyTest;
use 5.012;
use warnings;
use Test::More;
use Time::HiRes();
use Test::Catch;
use UniEvent::HTTP;
use Scalar::Util 'weaken';

XS::Loader::load();

my $time_mark = Time::HiRes::time();;

if ($ENV{LOGGER}) {
    require XLog;
    XLog::set_logger(sub { say $_[0] });
    XLog::set_level(XLog::VERBOSE_DEBUG());
}

$SIG{PIPE} = 'IGNORE';

sub import {
    my ($class) = @_;

    my $caller = caller();
    foreach my $sym_name (qw/variate_catch fail_cb catch_run time_mark time_elapsed/) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = \&{$sym_name};
    }
    
    *main::test_catch = \&test_catch;
}

sub test_catch {
    chdir 'clib';
    catch_run(@_);
    chdir '../';
}

sub get_time {
    my $l = UniEvent::Loop::default;
    $l->update_time();
    return $l->now;
}

sub time_mark    { $time_mark = get_time() }
sub time_elapsed { return get_time() - $time_mark } 

sub variate {
    my $sub = pop;
    my @names = reverse @_ or return;
    
    state $valvars = {
        ssl => [0,1],
    };
    
    my ($code, $end) = ('') x 2;
    $code .= "foreach my \$${_}_val (\@{\$valvars->{$_}}) {\n" for @names;
    $code .= "variate_$_(\$${_}_val);\n" for @names;
    my $stname = 'variation '.join(', ', map {"$_=\$${_}_val"} @names);
    $code .= qq#subtest "$stname" => \$sub;\n#;
    $code .= "}" x @names;
    
    eval $code;
    die $@ if $@;
}

sub variate_catch {
    my ($catch_name, @names) = @_;
    variate(@names, sub {
        my $add = '';
        foreach my $name (@names) {
            $add .= "[v-$name]" if MyTest->can("variate_$name")->();
        }
        test_catch($catch_name.$add);
    });
}

sub fail_cb { fail("should not be called"); }

sub make_server {
    my ($loop, $cfg) = @_;
    my $server = new MyTest::TServer($loop);
    $cfg ||= {};
    $cfg->{locations} ||= [{host => "127.0.0.1"}];
    $cfg->{tcp_nodelay} = 1;
    $server->configure($cfg);
    $server->run;
    return $server;
}

{
    package MyTest::TServer;
    use parent 'UniEvent::HTTP::Server';
    use 5.012;
    
    sub new {
        my $self = shift->SUPER::new(@_);
        XS::Framework::obj2hv($self);
        return $self;
    }
    
    sub autorespond {
        my ($self, $res) = @_;
        my $queue = $self->{autores_queue} ||= [];
        unless ($self->{autores}++) {
            $self->request_event->add(sub {
                my $req = shift;
                return unless @$queue;
                $req->respond(shift @$queue);
            });
        }
        push @$queue, $res;
    }
    
    sub enable_echo {
        my $self = shift;
        $self->request_callback(sub {
            my $req = shift;
            my $h = $req->headers;
            delete @$h{qw/host accept-encoding user-agent content-encoding/};
            my $response = UE::HTTP::ServerResponse->new({
                code       => 200, 
                headers    => $h, 
                body       => $req->body || '',
                compressed => Protocol::HTTP::Compression::gzip,
            });
            $req->respond($response);
        });
    }
    
    sub location {
        my $sa = shift->sockaddr;
        return $sa->ip. ':' . $sa->port;
    }

    sub uri {
        my ($self, $secure) = @_;
        $secure //= 0;

        my $loc = $self->location;
        my $scheme = $secure ? 'https' : 'http';
        return "$scheme://$loc/";
    }
}

{
    package MyTest::ServerPair;
    use 5.012;
    use Protocol::HTTP::Message;
    use Protocol::HTTP::Request;

    sub new {
        my ($class, $loop, $cfg) = @_;
        my $self = bless {}, $class;
        
        $self->{server} = MyTest::make_server($loop, $cfg);
        $self->{conn}   = new UE::Tcp($loop);
        
        $self->{conn}->connect_callback(sub {
            my ($conn, $err) = @_;
            die $err if $err;
            $conn->loop->stop();
        });
        
        $self->{conn}->connect_addr($self->{server}->sockaddr);
        $loop->run;
            
        return $self;
    }
    
    sub server {shift->{server}}
    sub conn   {shift->{conn}}
    
    sub get_response {
        my ($self, $send_str) = @_;
        my $conn = $self->{conn};
        $conn->write($send_str) if $send_str;
        
        my $queue = $self->{respone_queue} ||= [];
        unless (@$queue) {
            my $parser = $self->{parser} ||= new Protocol::HTTP::ResponseParser();
            my $source_request = $self->{source_request};
            my $eofref = \$self->{eof};
            $conn->read_callback(sub {
                my ($conn, $str, $err) = @_;
                die $err if $err;
                while ($str) {
                    $parser->set_context_request($source_request ? $source_request : new Protocol::HTTP::Request({method => METHOD_GET}))
                        unless $parser->context_request;
                    my ($res, $state, $err) = $parser->parse_shift($str);
                    die $err if $err;
                    return unless $state == STATE_DONE;
                    push @$queue, $res;
                }
                $conn->loop->stop if @$queue;
            });
            $conn->eof_callback(sub {
                my $conn = shift;
                $$eofref = 1;
                my ($res, $state, $err) = $parser->eof;
                die $err if $err;
                push @$queue, $res if $res;
                $conn->loop->stop;
            });
            $conn->loop->run;
    
            $conn->read_event->remove_all;
            $conn->eof_event->remove_all;
        }
    
        die "no response" unless @$queue;
        return shift @$queue;
    }
    
    sub wait_eof {
        my ($self, $tmt) = @_;
        return $self->{eof} if $self->{eof};
        my $conn = $self->{conn};
    
        my $timer;
        $timer = UE::Timer->once($tmt, sub { $conn->loop->stop }, $conn->loop) if $tmt;
    
        $conn->eof_callback(sub {
            $self->{eof} = 1;
            $conn->loop->stop;
        });
    
        $conn->loop->run;
        $conn->eof_event->remove_all;
        return $self->{eof};
    }
}

{
    package MyTest::TClient;
    use parent 'UniEvent::HTTP::Client';
    use 5.012;
    
    sub new {
        my $self = shift->SUPER::new(@_);
        XS::Framework::obj2hv($self);
        return $self;
    }
    
    sub request {
        my ($self, $req) = @_;
        $self->set_nodelay(1);
        if (my $sa = $self->{sa}) {
            $req->uri->host($sa->ip);
            $req->uri->port($sa->port);
        }
        $req->uri->scheme("https") if ($req->ssl_ctx);
        return $self->SUPER::request($req);
    }

    sub get_response {
        my ($self, $req) = @_;
        $req = new UE::HTTP::Request($req) if ref($req) eq 'HASH';
        my $loop = $self->loop;
        my $response;
        $req->response_event->add(sub {
            my (undef, $res, $err) = @_;
            die $err if $err;
            $response = $res;
            $loop->stop;
        });

        $self->request($req);
        $loop->run;

        return $response;
    }

    sub await_response {
        my ($self, $req) = @_;
        $req = new UE::HTTP::Request($req) if ref($req) eq 'HASH';
        my $loop = $self->loop;
        my $response;
        $req->response_event->add(sub {
            my (undef, $res, $err) = @_;
            die $err if $err;
            $response = $res;
            $loop->stop;
        });

        $loop->run;

        return $response;
    }
    
    sub get_error {
        my ($self, $req) = @_;
        $req = new UE::HTTP::Request($req) if ref($req) eq 'HASH';
        my $loop = $self->loop;
        my $error;
    
        $req->response_event->add(sub {
            my (undef, undef, $err) = @_;
            $error = $err;
            $loop->stop;
        });
    
        $self->request($req);
        $loop->run;
    
        return $error;
    }
}

{
    package MyTest::ClientPair;
    use 5.012;
    
    sub new {
        my ($class, $loop) = @_;
        my $self = bless {}, $class;
        $self->{server} = MyTest::make_server($loop);
        $self->{client} = new MyTest::TClient($loop);
        $self->{client}{sa} = $self->{server}->sockaddr;
        return $self;
    }

    sub server {shift->{server}}
    sub client {shift->{client}}
}

{
    package MyTest::TPool;
    use parent 'UniEvent::HTTP::Pool';
    use 5.012;
    
    sub request {
        my $client = shift->SUPER::request(@_);
        if ($client) {
            XS::Framework::obj2hv($client);
            bless $client, 'MyTest::TClient';
        }
        return $client;
    }
}

{
    package MyTest::TUserAgent;
    use parent 'UniEvent::HTTP::UserAgent';
    use 5.012;

    sub request {
        my $client = shift->SUPER::request(@_);
        if ($client) {
            XS::Framework::obj2hv($client);
            bless $client, 'MyTest::TClient';
        }
        return $client;
    }
}

1;
