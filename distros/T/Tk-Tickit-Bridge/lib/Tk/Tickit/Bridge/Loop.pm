package Tk::Tickit::Bridge::Loop;

use v5.36;
use Carp qw(croak);
use Scalar::Util qw(blessed weaken);
use Tk ();

our $VERSION = '0.001';

sub new ($class, %args) {
    my $widget = $args{widget} // croak 'widget is required';
    my $loop = $args{loop} // croak 'loop is required';
    croak 'widget must be a Tk widget'
        unless blessed($widget) && $widget->isa('Tk::Widget');
    croak 'loop must provide loop_once()'
        unless blessed($loop) && $loop->can('loop_once');
    my $interval = $args{interval} // 10;
    croak 'interval must be a positive integer in milliseconds'
        unless $interval =~ /\A[1-9][0-9]*\z/;
    my $self = bless {
        widget => $widget, loop => $loop, interval => $interval,
    }, $class;
    weaken($self->{widget});
    return $self;
}

sub start ($self) {
    return $self if $self->{running};
    croak 'Tk widget has been destroyed' unless Tk::Exists($self->{widget});
    $self->{running} = 1;
    $self->_schedule;
    return $self;
}

sub stop ($self) {
    $self->{running} = 0;
    my $timer = delete $self->{timer};
    $timer->cancel if $timer;
    return $self;
}

sub running ($self) { !!$self->{running} }

sub _schedule ($self) {
    return if $self->{timer} || !$self->{running};
    my $widget = $self->{widget};
    return $self->stop unless Tk::Exists($widget);
    my $weak = $self;
    weaken($weak);
    $self->{timer} = $widget->after($self->{interval}, sub {
        my $self = $weak or return;
        delete $self->{timer};
        return unless $self->{running};
        my $ok = eval { $self->{loop}->loop_once(0); 1 };
        unless ($ok) {
            my $error = $@;
            $self->stop;
            die $error;
        }
        $self->_schedule if $self->{running};
    });
    return;
}

sub DESTROY ($self) { local $@; eval { $self->stop } }

1;

__END__

=head1 NAME

Tk::Tickit::Bridge::Loop - service an IO::Async loop from Perl/Tk

=head1 SYNOPSIS

    my $pump = Tk::Tickit::Bridge::Loop->new(
        widget => $mw, loop => $loop, interval => 10,
    )->start;
    Tk::MainLoop();
    $pump->stop;

=head1 DESCRIPTION

Runs one nonblocking C<loop_once(0)> every C<interval> milliseconds (default 10)
using Tk's timers. Add your C<Tickit::Async> object to this IO::Async loop before
starting. Keep the pump object alive. No IO::Async dependency is loaded here;
any loop implementing C<loop_once(0)> can be supplied.

C<start> and C<stop> are idempotent and return the pump. C<running> reports
whether it is active. C<stop> cancels the outstanding timer, and may safely be
called from an IO::Async callback. Destroying the pump cancels its timer;
destroying its Tk widget cancels Tk's associated timer, after which callers
should call C<stop> to reset the reported running state.

Exceptions from C<loop_once> stop the pump and propagate to Tk's error handler.
The application owns both loops, Tickit setup, terminal restoration, and exit
policy. Request shutdown in callbacks and perform final cleanup after returning
to the outer event dispatcher. Do not recursively pump the same IO::Async loop.

Polling introduces up to about one interval of extra latency when callbacks
are short. It is not sample-accurate synchronization. Long callbacks block
both interfaces. There are no threads or child processes in this helper.

=head1 AUTHOR AND LICENSE

Copyright (c) 2026 Joel Roth. Same terms as Perl itself.

=cut
