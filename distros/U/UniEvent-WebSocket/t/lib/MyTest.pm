package MyTest;
use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use UniEvent::WebSocket;

XS::Loader::load();

require MyTestLogger if $ENV{LOGGER};

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

sub make_server {
    my $loop = UniEvent::Loop->default_loop;

    my $s = new UniEvent::Tcp();
    $s->bind('127.0.0.1',0);
    my $adr = $s->sockaddr;
    my $port = $adr->port();

    my $server = new UniEvent::WebSocket::Server({
            locations => [{
                    host => '127.0.0.1',
                    port => $port,
            }],
    });
    return ($server, $port);
}

sub make_client {
    my ($port) = @_;
    my $client = new UniEvent::WebSocket::Client();
    my $scheme = UniEvent::WebSocket::ws_scheme();
    $client->connect({
        uri => "$scheme://127.0.0.1:$port",
        ws_key => "dGhlIHNhbXBsZSBub25jZQ==",
    });
    #$client->connect("127.0.0.1", 0, $port);
	
    return $client;
}

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

1;
