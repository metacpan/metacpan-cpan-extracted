package Ubic::Service::InitScriptWrapper;
{
  $Ubic::Service::InitScriptWrapper::VERSION = '0.02';
}

# ABSTRACT: represent any /etc/init.d/ script as ubic service


use strict;
use warnings;

use parent qw(Ubic::Service::Skeleton);
use autodie qw(:all);
use IPC::System::Simple; # force system() support for autodie

sub new {
    my $class = shift;
    my ($init) = @_;
    die "Invalid parameters" unless @_ == 1;

    if ($init !~ m{/}) {
        $init = "/etc/init.d/$init";
    }

    unless (-e $init) {
        die "Init script $init not found";
    }

    return bless { init => $init } => $class;
}

sub start_impl {
    my $self = shift;
    system("$self->{init} start >/dev/null");
}

sub stop_impl {
    my $self = shift;
    system("$self->{init} stop >/dev/null");
}

sub reload {
    my $self = shift;
    system("$self->{init} reload >/dev/null");
    return 'reloaded'; # we expect system() to fail if reload is not implemented
}

sub status_impl {
    my $self = shift;
    no autodie;
    my $code = system("$self->{init} status >/dev/null");
    if ($code == 0) {
        return 'running';
    }
    else {
        return 'not running'; # TODO - distinguish 'not running' and 'broken'
    }
}

1;

__END__
=pod

=head1 NAME

Ubic::Service::InitScriptWrapper - represent any /etc/init.d/ script as ubic service

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    # in /etc/ubic/service/my-nginx
    use Ubic::Service::InitScriptWrapper;
    Ubic::Service::InitScriptWrapper->new('nginx'); # map /etc/init.d/nginx to 'my-nginx' ubic service

=head1 DESCRIPTION

This module lets you turn any LSB-compliant init script into ubic service.

Note that this is completely different from L<Ubic::Run>. C<Ubic::Run> lets you
turn ubic service to init script. This module does the reverse thing.

=head1 WHY?

There are several reasons why this module can be useful.

First, it allows you to use all ubic features (watchdog, pretty CLI interface,
persistent service states) without changing any of your code.

Second, some daemons don't provide a way not to detach them from a terminal.
Classic init scripts usually use C<start-stop-daemon> to start these daemons.
C<Ubic::Daemon> and C<Ubic::Service::SimpleDaemon> can't be used to start such
processes.
You could write C<system('start-stop-daemon ...')> in your ubic service code,
but if you already got a working init script, why bother?

=head1 CAVEATS

=over

=item *

Init script must conform to LSB specification
(L<http://refspecs.linuxbase.org/LSB_4.0.0/LSB-Core-generic/LSB-Core-generic/iniscrptact.html>).

At the very least, it must exit with zero exit code on successful start, stop
and status commands, and with non-zero exit code on unsuccessful status command.

=item *

This module doesn't distinguish C<broken> and C<not running> states yet.
It interprets any non-zero status code as C<not running>.

=back

=head1 CONSTRUCTOR

=over

=item B<new($init_script_name)>

If C<$init_script_name> contains C</>, it'll be interpreted as a filename.

Otherwise, C</etc/init.d/$init_script_name> will be used.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

