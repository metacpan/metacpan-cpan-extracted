package MyTest;
use 5.012;
use warnings;
use UniEvent;
use Test::More;
use Test::Deep;
use Test2::IPC;
use Test::Catch;
use Net::SSLeay;
use Test::Exception;

XS::Loader::load('MyTest');

$SIG{PIPE} = 'IGNORE';

my $rdir = "t/var/$$";
my $have_time_hires = eval "require Time::HiRes; 1;";
my $last_time_mark;
my %used_mtimes;

init();

sub init {
    if ($ENV{LOGGER}) {
        require XLog;
        XLog::set_logger(XLog::Console->new);
        XLog::set_level(XLog::WARNING());
        XLog::set_level(XLog::DEBUG(), "UniEvent");
        XLog::set_level(XLog::DEBUG(), "UniEvent::Resolver");
    }
    
    # for file tests
    UniEvent::Fs::remove_all($rdir) if -d $rdir;
    UniEvent::Fs::mkpath($rdir);
    
    # if something goes wrong, loop hangs. Make tests fail with SIGALRM instead of hanging forever.
    # each test must not last longer than 10 seconds. If needed, set alarm(more_than_10s) in your test
    alarm(15) unless defined $DB::header;
    
    *main::test_catch   = \&test_catch;
    *main::done_testing = \&done_testing;
}

sub test_catch {
    chdir 'clib';
    catch_run(@_);
    chdir '../';
}

sub import {
    my ($class) = @_;

    my $caller = caller();
    foreach my $sym_name (qw/
        linux freebsd win32 darwin winWSL netbsd openbsd dragonfly
        is cmp_deeply ok done_testing skip isnt time_mark check_mark pass fail cmp_ok like isa_ok unlike diag plan
        var pipe create_file create_dir move change_file_mtime change_file unlink_file remove_dir subtest new_ok dies_ok throws_ok catch_run any
    /) {
        no strict 'refs';
        *{"${caller}::$sym_name"} = \&{$sym_name};
    }
}

sub linux     { $^O eq 'linux' }
sub freebsd   { $^O eq 'freebsd' }
sub win32     { $^O eq 'MSWin32' }
sub darwin    { $^O eq 'darwin' }
sub netbsd    { $^O eq 'netbsd' }
sub openbsd   { $^O eq 'openbsd' }
sub dragonfly { $^O eq 'dragonfly' }
sub winWSL    { linux() && `egrep "(Microsoft|WSL)" /proc/version` }

sub time_mark {
    return unless $have_time_hires;
    $last_time_mark = Time::HiRes::time();
}

sub check_mark {
    return unless $have_time_hires;
    my ($approx, $msg) = @_;
    my $delta = Time::HiRes::time() - $last_time_mark;
    cmp_ok($delta, '>=', $approx*0.75, $msg);
}

sub var ($) { return "$rdir/$_[0]" }

sub pipe ($) {
    if (win32()) {
        return "\\\\.\\pipe\\$_[0]";
    } else {
        return var "pipe_$_[0]";
    }
}

sub get_ssl_ctx {
    my $SERV_CERT = "t/cert/ca.pem";
    my $serv_ctx = Net::SSLeay::CTX_new();
    Net::SSLeay::CTX_use_certificate_file($serv_ctx, $SERV_CERT, &Net::SSLeay::FILETYPE_PEM) or sslerr();
    Net::SSLeay::CTX_use_PrivateKey_file($serv_ctx, "t/cert/ca.key", &Net::SSLeay::FILETYPE_PEM) or sslerr();
    Net::SSLeay::CTX_check_private_key($serv_ctx) or die Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
    return $serv_ctx unless wantarray();
    
    my $client_ctx = Net::SSLeay::CTX_new();
    Net::SSLeay::CTX_load_verify_locations($client_ctx, $SERV_CERT, '') or die "something went wrong";
    
    return ($serv_ctx, $client_ctx);
}

sub make_basic_server {
    my ($loop, $sa) = @_;
    $sa = Net::SockAddr::Inet4->new("127.0.0.1", 0) unless $sa;
    my $server = UE::Tcp->new($loop);
    $server->bind_addr($sa);
    $server->listen(1);
    return $server;
}

sub make_ssl_server {
    my ($loop, $sa) = @_;
    my $server = make_basic_server($loop, $sa);
    $server->use_ssl(get_ssl_ctx());
    return $server;
}

sub make_server {
    my ($loop, $sa) = @_;
    $sa = Net::SockAddr::Inet4->new("127.0.0.1", 0) unless $sa;
    my $server = UE::Tcp->new($loop);
    $server->bind_addr($sa);
    #if (variation.ssl) server->use_ssl(get_ssl_ctx());
    $server->listen(10000);
    return $server;
}

sub make_client {
    my $loop = shift;
    my $client = UE::Tcp->new($loop, AF_INET);
    #if (variation.ssl) client->use_ssl();
    #if (variation.buf) {
    #    client->recv_buffer_size(1);
    #    client->send_buffer_size(1);
    #}
    return $client;
}

sub make_tcp_pair {
    my ($loop, $sa) = @_;
    my $ret = {};
    $ret->{server} = make_server($loop, $sa);
    $ret->{client} = make_client($loop);
    $ret->{client}->connect_addr($ret->{server}->sockaddr);
    return $ret;
}

sub make_p2p {
    my ($loop, $sa) = @_;
    my $ret = make_tcp_pair($loop, $sa);
    $ret->{server}->connection_callback(sub {
        my (undef, $sconn, $err) = @_;
        die $err if $err;
        $ret->{sconn} = $sconn;
        $loop->stop();
    });
    $loop->run();
    die unless $ret->{sconn};
    return $ret;
}

END { # clean up after file tests
    UniEvent::Fs::remove_all($rdir) if -d $rdir;
}

1;
