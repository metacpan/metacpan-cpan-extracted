package Twiggy::Prefork::Server;

use strict;
use warnings;
use parent qw/Twiggy::Server/;
use Parallel::Prefork;

use constant DEBUG => $ENV{TWIGGY_DEBUG};

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);

    $self->{max_workers} = $args{max_workers} || 10;
    $self->{max_reqs_per_child} = defined $args{max_reqs_per_child} ? $args{max_reqs_per_child} : 100;
    $self->{min_reqs_per_child} = $args{min_reqs_per_child} || 0;

    $self;
}

sub _run_app {
    my($self, $app, $env, $sock) = @_;
    $env->{'psgix.exit_guard'} = $self->{exit_guard};
    $self->SUPER::_run_app($app, $env, $sock);
}

sub _accept_handler {
    my $self = shift;

    my $cb = $self->SUPER::_accept_handler( @_ );
    return $self->{max_reqs_per_child} == 0 ? $cb : sub {
        my ( $sock, $peer_host, $peer_port ) = @_;
        $self->{reqs_per_child}++;
        $cb->( $sock, $peer_host, $peer_port );

        if ( $self->{reqs_per_child} > $self->{max_reqs_per_child} ) {
            DEBUG && warn "[$$] reach max reqs per child\n";
            my $listen_guards = delete $self->{listen_guards};
            undef $listen_guards;    #block new accept
            $self->{exit_guard}->end;
        }
    };
}

sub run {
    my $self = shift;
    $self->register_service(@_);
    my $pm = Parallel::Prefork->new({
        max_workers => $self->{max_workers},
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
        before_fork => sub {
            if ( $self->{min_reqs_per_child} ) {
                $self->{max_reqs_per_child} = $self->{min_reqs_per_child}
                    + int(rand( $self->{max_reqs_per_child} - $self->{min_reqs_per_child}));
            }
        },
    });

    while ($pm->signal_received ne 'TERM') {
        $pm->start and next;
        DEBUG && warn "[$$] start child";
        my $exit = $self->{exit_guard};
        delete $SIG{TERM};
        my $w; $w = AE::signal TERM => sub { 
            warn "[$$] recieved signal TERM" if DEBUG; 
            $exit->end;
            undef $w
        };
        $exit->recv;
        DEBUG && warn "[$$] end child";
        $pm->finish;
    }
    $pm->wait_all_children;
}

1;

__END__


