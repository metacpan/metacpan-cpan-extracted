package Plack::Handler::UniEvent::HTTP;
use 5.012;
use XLog;
use UniEvent::HTTP::Plack;
use UniEvent::HTTP::Manager;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    
    my $config = $self->{config} = make_config($self);
    $self->{manager} = UniEvent::HTTP::Manager->new($config, $self->{loop} || $self->{master_loop}, $self->{worker_loop});
    
    $self->{server_software} ||= 'UniEvent::HTTP';
    
    return $self;
}

sub manager { return shift->{manager} }
sub loop    { return shift->{manager}->loop }

sub make_config {
    my $p = shift;
    return $p->{config} if $p->{config} && ref($p->{config}) eq 'HASH';
    
    my $config = {
        server => UniEvent::HTTP::Plack::make_config($p),
    };

    if (defined(my $worker_model = $p->{worker_model})) {
        $config->{worker_model} = UniEvent::HTTP::Manager::WORKER_PREFORK if lc($worker_model) eq 'prefork'; 
        $config->{worker_model} = UniEvent::HTTP::Manager::WORKER_THREAD  if lc($worker_model) eq 'thread'; 
    }

    if (defined(my $bind_model = $p->{bind_model})) {
        $config->{bind_model} = UniEvent::HTTP::Manager::BIND_DUPLICATE  if lc($bind_model) eq 'duplicate'; 
        $config->{bind_model} = UniEvent::HTTP::Manager::BIND_REUSE_PORT if lc($bind_model) eq 'reuse_port'; 
    }    
    
    foreach my $name (qw/
        min_servers max_servers min_spare_servers max_spare_servers min_load max_load load_average_period max_requests
        min_worker_ttl check_interval activity_timeout termination_timeout worker_model bind_model
    /)
    {
        $config->{$name} = $p->{$name} if defined $p->{$name};
    }

    return $config;
}

sub run {
    my ($self, $app) = @_;
    
    #TODO support Server::Starter
    
    my $mgr = $self->{manager};

    unless ($self->{no_signals}) {
        $self->{sigint}  = UE::Signal->watch(UE::Signal::SIGINT,  sub { $mgr->stop }, $mgr->loop);
        $self->{sigterm} = UE::Signal->watch(UE::Signal::SIGTERM, sub { $mgr->stop }, $mgr->loop);
        $self->{$_}->weak(1) for qw/sigint sigterm/;
    }
    
    $mgr->start_event->add(sub {
        $self->{server_ready}->($self) if $self->{server_ready};
    });
    
    my $mt = $self->{config}{worker_model} == UniEvent::HTTP::Manager::WORKER_THREAD;
    
    $mgr->spawn_event->add(sub {
        my $server = shift;
        
        unless ($mt) { # release master resources
            $self->{sigint}->reset;
            $self->{sigterm}->reset;
        }
        
        $self->{plack} = UniEvent::HTTP::Plack->new({
            multiprocess => $mt ? 0 : 1,
            multithread  => $mt ? 1 : 0,
        });
        $self->{plack}->bind($server, $app);
        
        $server->stop_event->add(sub {
            if (my $finish_profile = DB->can('finish_profile')) {
               $finish_profile->();
            }
        });
    });
    

    $mgr->run;
    
    if (my $finish_profile = DB->can('finish_profile')) {
        $finish_profile->();
    }
}

sub stop { shift->{manager}->stop }

1;
