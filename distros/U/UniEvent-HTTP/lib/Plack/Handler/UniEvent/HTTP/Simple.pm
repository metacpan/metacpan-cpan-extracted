package Plack::Handler::UniEvent::HTTP::Simple;
use 5.012;
use Scalar::Util 'weaken';
use UniEvent::HTTP::Plack;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;

    $self->{server} = UniEvent::HTTP::Server->new($self->{loop});
    $self->{server}->configure(UniEvent::HTTP::Plack::make_config($self));
    
    $self->{plack} = UniEvent::HTTP::Plack->new();
    
    $self->{server_software} ||= 'UniEvent::HTTP';
    
    return $self;
}

sub server { return shift->{server} }
sub loop   { return shift->{server}->loop }
sub stop   { shift->{server}->stop }

sub run {
    my ($self, $app) = @_;
    
    #TODO support Server::Starter
    
    my $server = $self->{server};
    
    $self->{plack}->bind($server, $app);
    
    $server->run;
    
    $self->{server_ready}->($self) if $self->{server_ready};
    
    unless ($self->{no_signals}) {
        $self->{sigint}  = UE::Signal->watch(UE::Signal::SIGINT,  sub { $server->stop }, $server->loop);
        $self->{sigterm} = UE::Signal->watch(UE::Signal::SIGTERM, sub { $server->stop }, $server->loop);
        $self->{$_}->weak(1) for qw/sigint sigterm/;
    }

    $server->loop->run;
    
    if (my $finish_profile = DB->can('finish_profile')) {
        $finish_profile->();
    }
}

sub CLONE_SKIP {1}

1;
