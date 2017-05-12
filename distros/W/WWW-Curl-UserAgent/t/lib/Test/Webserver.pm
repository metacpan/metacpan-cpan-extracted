package Test::Webserver;

use Dancer;
use Daemon::Daemonize qw//;
use Digest::MD5 qw(md5_hex);

any [ 'get', 'put', 'post', 'delete' ] => '/code/:code' => sub {
    status int params->{code};
};

get '/sleep/:time' => sub {
    my $time = int params->{time};
    sleep $time;
    status 204;
};

get '/redirect/:times' => sub {
    my $times = int params->{times};
    if ($times) {
        header Location => 'http://localhost:3000/redirect/' . ( $times - 1 );
        status 301;
    }
    else {
        status 204;
    }
};

any [ 'put', 'post' ] => '/content_md5' => sub {
    return md5_hex(request->body);
};


my $pid = "$0.pid";

sub start_webserver_daemon {
    Daemon::Daemonize->daemonize(
        chdir => undef,
        run   => sub {
            Daemon::Daemonize->write_pidfile($pid);
            $SIG{TERM} = sub { Daemon::Daemonize->delete_pidfile($pid); exit };
            dance;
        }
    );
}

sub stop_webserver_daemon {
    my $child_pid = Daemon::Daemonize->read_pidfile($pid);
    kill 15, $child_pid;
}

1;
