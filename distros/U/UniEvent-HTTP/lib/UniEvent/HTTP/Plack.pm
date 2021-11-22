package UniEvent::HTTP::Plack;
use 5.012;
use warnings;
use XLog;
use UniEvent::HTTP;

# see Plack.xsi

sub make_config {
    my $p = shift;
    return $p->{config} if $p->{config} && ref($p->{config}) eq 'HASH';
    
    my $config = {
        locations => my $locations = [],
    };

    my $ssl_ctx;    
    if (my $cert_file = $p->{ssl_cert_file}) {
        die "ssl_key_file must be defined with ssl_cert_file" unless $p->{ssl_key_file};
        $ssl_ctx = ssl_ctx_from_cert($p->{ssl_cert_file}, $p->{ssl_key_file});
    }
    
    my $backlog = $p->{backlog};
    
    my $listen = $p->{listen} ||= [];
    if (!@$listen and $p->{host} and defined($p->{port})) {
        push @$listen, "$p->{host}:$p->{port}";
    }
    
    foreach my $row (@$listen) {
        my ($host, $port) = split ':', $row;
        my $loc = {};
        if (defined $port) {
            # host:port
            $loc->{host} = $host || '*';
            $loc->{port} = $port;
        } else {
            # path for unix socket / name for windows named pipe
            $loc->{path} = $row;
        }
        $loc->{backlog} = $backlog if $backlog;
        $loc->{ssl_ctx} = $ssl_ctx if $ssl_ctx;
        push @$locations, $loc;
    }

    foreach my $name (qw/idle_timeout max_headers_size max_body_size tcp_nodelay max_keepalive_requests/) {
        $config->{$name} = $p->{$name} if defined $p->{$name};
    }
    
    return $config;
}

sub read_real_fh {
    my $fh = shift;
    local $/ = undef;
    my $ret = <$fh>;
    close $fh;
    return $ret;
}


package UniEvent::HTTP::Plack::ErrorHandle;

our $xlog_module = XLog::Module->new("Plack");
$xlog_module->set_formatter("%m");

sub print {
    XLog::error($xlog_module, $_[1]);
}

1;
