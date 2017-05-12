package Ubic::Watchdog;
$Ubic::Watchdog::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: watchdog code


use POSIX;
use IO::Handle;
use Params::Validate qw(:all);
use Try::Tiny;
use List::MoreUtils qw(any);
use Ubic;

use Ubic::Logger;

sub run {
    my $class = shift;
    my $options = validate(@_, {
        glob_filter => { type => ARRAYREF, default => [] },
        compile_timeout => { type => SCALAR, regex => qr/^\d+$/ },
        verbose => { type => SCALAR|UNDEF },
    });

    my @filter;
    {
        for my $arg (@{ $options->{glob_filter} }) {
            $arg =~ /^[*\w.-]+$/ or die "Invalid argument '$arg', expected service name or shell-style glob";
            $arg =~ s/\./\\./g;
            $arg =~ s/\*/.*/g;
            push @filter, qr/^$arg$/;
        }
    }
    $options->{filter} = \@filter if @filter;
    delete $options->{glob_filter};

    my $self = bless $options => $class;

    my @services = $self->load_services(Ubic->root_service);
    $self->check_all(@services);
}

sub match($$) {
    my ($name, $filter) = @_;
    do {
        return 1 if $name =~ $filter;
    } while ($name =~ s/\.[^.]+$//);
    return;
}

sub load_services {
    my $self = shift;
    my ($parent) = @_;
    alarm($self->{compile_timeout});
    $SIG{ALRM} = sub {
        die "Couldn't compile $parent services in $self->{compile_timeout} seconds";
    };
    my @services = $parent->services;
    alarm(0);
    return @services;
}

sub check_all {
    my $self = shift;
    my @services = @_;
    for my $service (@services) {
        my $name = $service->full_name;
        if ($service->isa('Ubic::Multiservice')) {
            INFO("$name is multiservice, checking subservices") if $self->{verbose};
            $self->check_all($self->load_services($service));
            next;
        }
        if ($self->{filter}) {
            next unless any { match($name, $_) } @{ $self->{filter} };
        }

        # trying to get logs a little bit more ordered
        STDOUT->flush;
        STDERR->flush;

        my $child = fork;
        unless (defined $child) {
            die "fork failed";
        }
        unless ($child) {
            POSIX::setsid; # so we could kill this watchdog and its children safely later
            $self->check($service);
            exit;
        }
    }
    1 while wait() > 0;
    return;
}

sub check($) {
    my $self = shift;
    my $service = shift;
    my $name = $service->full_name;
    if ($self->{verbose}) {
        INFO("Checking $name");
    }
    $0 = "ubic-watchdog $name";

    try {
        alarm($service->check_timeout);

        # TODO - do additional fork, so that if service code overrides SIG{ALRM} or resets alarm(), watchdog still will finish in time
        $SIG{ALRM} = sub {
            ERROR("$name check_timeout exceeded");
            STDOUT->flush;
            STDERR->flush;
            kill -9 => $$; # suicide
            ERROR "kill sent, still alive"; # should never happen, we called setsid earlier
        };

        # permanently use service credentials
        # this line optimizes the number of fork calls - future status/restart calls would perform forked_call() otherwise
        Ubic::Credentials->new( service => $service )->set;

        # so we don't need access guard for this lock
        my $watchdog_lock = Ubic::SingletonLock->new(Ubic->get_data_dir()."/watchdog/lock/".$name, { blocking => 0 });

        unless ($watchdog_lock) {
            if ($self->{verbose}) {
                INFO "$name is locked by another watchdog process";
            }
            return;
        }

        my $lock = Ubic->lock($name);
        unless (Ubic->is_enabled($name)) {
            INFO("$name disabled") if $self->{verbose};
            return;
        }

        my $cached_status = Ubic->cached_status($name);
        my $status = Ubic->status($name);
        unless ($status->status eq 'running') {
            # following code can throw an exception, so we want to cache invalid status immediately
            Ubic->set_cached_status($name, $status);

            if ($cached_status eq "autostarting") {
                INFO("$name is autostarting");
            }
            else {
                ERROR("$name status is '$status', restarting");
            }

            Ubic->restart($name);

            # This is a precaution against services with wrong start/status logic.
            $status = Ubic->status($name);
            if ($status->status ne 'running') {
                INFO("$name started, but status is still '$status'");
            }
        }

        alarm(0);
        Ubic->set_cached_status($name, $status); # if service's start implementation is invalid, ubic-watchdog will restart it every minute, so be careful
    }
    catch {
        ERROR("Failed to revive $name: $_");
    };

    INFO("$name checked") if $self->{verbose};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Watchdog - watchdog code

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::Watchdog;
    Ubic::Watchdog->run(...);

=head1 DESCRIPTION

This module contains most of the code needed by L<ubic-watchdog> script.

=head1 INTERFACE SUPPORT

This is considered to be a non-public class. Its interface is subject to change without notice.

=head1 METHODS

=over

=item B<< run($options) >>

Run watchdog.

Options:

=over

=item I<glob_filter>

Arrayref with shell-style glob filters.

If this option is given and non-empty, only services matching these filters will be checked.

=item I<compile_timeout>

Compilation timeout for every service (see load_services() method for details).

=item I<verbose>

Enable verbose logging.

=back

=item B<< match($name, $filter) >>

Check if service name matches name filter.

=item B<< load_services($multiservice) >>

Load subservices of given multiservice, using safe compilation timeouts.

(relatively safe, since it doesn't do fork, only sets alarm).

=item B<< check_all(@services) >>

Check all services in the list.

It will traverse to subservices if any of given services are multiservices.

It will fork on every service and check them in parallel fashion.

=item B<< check($service) >>

Check one service.

=back

=head1 SEE ALSO

L<ubic-watchdog> - main watchdog script.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
