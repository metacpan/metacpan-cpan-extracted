package Plack::Handler::Thrall;

=head1 NAME

Plack::Handler::Thrall - Plack adapter for Thrall

=head1 SYNOPSIS

=for markdown ```perl

    use Plack::Loader;

    my $loader = Plack::Loader->load('Thrall', port => 80);
    $loader->run(sub { [200, ['Content-Type', 'text/plain'], ['PSGI app']] });

=for markdown ```

=head1 DESCRIPTION

This is a stub module that allows Thrall to be loaded up under L<plackup>
and other L<Plack> tools. Set C<$ENV{PLACK_SERVER}> to C<'Thrall'> or use
the -s parameter to L<plackup> to use Thrall under L<Plack>.

See L<plackup> and L<thrall> (lower case) for available command line
options.

=cut

use strict;
use warnings;

our $VERSION = '0.0405';

use base qw(Thrall::Server);

use threads;

use Config ();
use English '-no_match_vars';
use Fcntl ();
use File::Spec;
use POSIX ();
use Plack::Util;

use constant DEBUG => $ENV{PERL_THRALL_DEBUG};

sub new {
    my ($class, %args) = @_;

    # setup before instantiation
    my $max_workers = 10;
    for (qw(max_workers workers)) {
        $max_workers = delete $args{$_}
            if defined $args{$_};
    }

    # instantiate and set the variables
    my $self = $class->SUPER::new(%args);

    $self->{is_multithread} = Plack::Util::TRUE;
    $self->{is_multiprocess} = Plack::Util::FALSE;

    $self->{max_workers} = $max_workers;

    $self->{main_thread} = threads->tid;
    $self->{processes} = +{};

    $self->{_kill_stalled_processes_delay} = 10;

    $self;
}

sub run {
    my ($self, $app) = @_;

    $self->_daemonize();

    # EV does not work with threads
    $ENV{PERL_ANYEVENT_MODEL} = 'Perl';
    $ENV{PERL_ANYEVENT_IO_MODEL} = 'Perl';

    warn "*** starting main thread ", threads->tid if DEBUG;
    $self->setup_listener();

    $self->_setup_privileges();

    # Threads don't like simple 'IGNORE'
    local $SIG{PIPE} = sub { 'IGNORE' };

    my $sigint = $self->{_sigint};
    my $sigterm = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

    if ($self->{max_workers} != 0) {
        if ($self->{thread_stack_size}) {
            threads->set_stack_size($self->{thread_stack_size});
        }
        local $SIG{$sigint} = local $SIG{TERM} = sub {
            my ($sig) = @_;
            warn "*** SIG$sig received in thread ", threads->tid if DEBUG;
            $self->{term_received}++;
            if (threads->tid) {
                $self->{main_thread}->kill('TERM');
                foreach my $thr (threads->list(threads::running)) {
                    $thr->kill('TERM') if $thr->tid != threads->tid;
                }
            }
        };
        foreach my $n (1 .. $self->{max_workers}) {
            $self->_create_thread($app);
            $self->_sleep($self->{spawn_interval});
        }
        while (not $self->{term_received}) {
            warn "*** running ", scalar threads->list, " threads" if DEBUG;
            foreach my $thr (threads->list(threads::joinable)) {
                warn "*** wait for thread ", $thr->tid if DEBUG;
                eval { $thr->detach; };
                warn $@ if $@;
                $self->_create_thread($app);
                $self->_sleep($self->{spawn_interval});
            }

            # slow down main thread
            $self->_sleep($self->{main_thread_delay});
        }
        foreach my $thr (threads->list) {
            $thr->detach;
        }
        warn "*** stopping main thread ", threads->tid if DEBUG;
        exit 0;
    } else {

        # run directly, mainly for debugging
        local $SIG{$sigint} = local $SIG{TERM} = sub {
            my ($sig) = @_;
            warn "*** SIG$sig received in thread ", threads->tid if DEBUG;
            exit 0;
        };
        while (1) {
            $self->accept_loop($app, $self->_calc_reqs_per_child());
            $self->_sleep($self->{spawn_interval});
        }
    }
}

1;

__END__

=head1 SEE ALSO

L<thrall>,
L<Thrall>,
L<Plack>,
L<Plack::Runner>.

=head1 LICENSE

Copyright (c) 2013-2016, 2023 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
