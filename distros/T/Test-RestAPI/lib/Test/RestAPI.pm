package Test::RestAPI;
use Moo;

our $VERSION = '0.1.6';

use Types::Standard qw(ArrayRef InstanceOf Int Str);
use Test::RestAPI::Endpoint qw(convert_path_to_filename);
use Test::RestAPI::MojoGenerator;
use Port::Selector;
use Path::Tiny;
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;

use constant WINDOWS => ($^O eq 'MSWin32');

BEGIN {
    if (WINDOWS) {
        ## no critic (ProhibitStringyEval)
        eval q{
            use Win32::Process qw(NORMAL_PRIORITY_CLASS);
        };

        die $@ if $@;
    }
}

=head1 NAME

Test::RestAPI - Real mock of REST API

=head1 SYNOPSIS

    my $api = Test::RestAPI->new(
        endpoints => [
            Test::RestAPI::Endpoint->new(
                path => '/a',
                method   => 'any',
            )
        ],
    );

    $api->start();

    HTTP::Tiny->new->get($api->uri.'/test');


=head1 DESCRIPTION

In many (test) case you need mock some REST API. One way is mock your REST-API class abstraction or HTTP client.
This module provides other way - start generated L<Mojolicious> server and provides pseudo-real your defined API.

=head1 METHODS

=head2 new(%attribute)

=head3 %attribute

=head4 endpoints

I<ArrayRef> of instances L<Test::RestAPI::Endpoint>

default is I</> (root) 200 OK - hello:

    Test::RestAPI::Endpoint->new(
        path   => '/',
        method => 'any',
        render => {text => 'Hello'},
    );

=cut
has 'endpoints' => (
    is  => 'ro',
    isa => ArrayRef [ InstanceOf ['Test::RestAPI::Endpoint'] ],
    default => sub {
        return [
            Test::RestAPI::Endpoint->new(
                path   => '/',
                method => 'any',
                render => {text => 'Hello'},
            )
        ];
    }
);

=head4 mojo_app_generator

This attribute is used for generating mojo application.

default is L<Test::RestAPI::MojoGenerator>

=cut
has 'mojo_app_generator' => (
    is      => 'ro',
    isa     => InstanceOf ['Test::RestAPI::MojoGenerator'],
    default => sub {
        return Test::RestAPI::MojoGenerator->new();
    }
);

has 'pid' => (
    is  => 'rw',
    isa => Int,
);

has 'uri' => (
    is  => 'rw',
    isa => Str,
);

has 'mojo_home' => (
    is      => 'ro',
    default => sub {
        my $mojo_home = Path::Tiny->tempdir();

        path($mojo_home, 'log')->mkpath();

        return $mojo_home;
    }
);  

=head3 start

Start REST API (L<Mojolicious>) application on some random unused port
and wait to initialize.

For start new process is used C<fork-exec> on non-windows machines and L<Win32::Process> for windows machines.

For generating L<Mojolicious> application is used L<Test::RestAPI::MojoGenerator> in C<mojo_app_generator> attribute - is possible set own generator.

=cut
sub start {
    my ($self) = @_;

    my $app_path = $self->mojo_app_generator->create_app($self->endpoints);

    $self->pid($self->_start($app_path));
}

sub _start {
    my ($self, $app_path) = @_;

    $self->_create_uri();

    my $pid;
    if (WINDOWS) {
        $pid = $self->_start_win($app_path);
    }
    else {
        $pid = $self->_start_fork($app_path);
    }

    $self->_wait_to_start();

    return $pid;
}

sub _create_uri {
    my ($self) = @_;

    my $port = Port::Selector->new->port();

    $self->uri("http://localhost:$port");
}

sub _start_win {
    my ($self, $app_path) = @_;

    #This trick is copied from IPC::System::Simple
    #If is check in this sub to non-Win32 system,
    #perl don't check NORMAL_PRIORITY_CLASS constant in compilation phase.
    if (!WINDOWS) {
        die '_start_win ca be called only anna Windows';
    }
    else {
        my $args = 'perl '.$app_path->canonpath().' '.join ' ', $self->_mojo_args();

        Win32::Process::Create(
            my $proc,
            $^X,
            $args,
            0,
            NORMAL_PRIORITY_CLASS,
            "."
        ) || die "Process $args start fail $^E";

        return $proc->GetProcessID();
    }
}

sub _start_fork {
    my ($self, $app_path) = @_;

    my @args = ($^X, $app_path->stringify, $self->_mojo_args());

    my $pid = fork;

    if ($pid) {
        return $pid
    }
    elsif ($pid == 0) {
        exec {$args[0]} @args;
        exit 1;
    }
    else {
        die "Fork problem: $!";
    }
}

sub _mojo_args {
    my ($self) = @_;

    return ('daemon', '-l', $self->uri, '-m', 'production', '--home', $self->mojo_home->canonpath());
}

sub _wait_to_start {
    my ($self) = @_;

    while (1) {
        if (Mojo::UserAgent->new->get($self->uri.'/app_mojo_healtcheck')->res->body() eq 'OK') {
            return 1;
        }
        sleep 1;
    }
}

=head2 count_of_requests($path)

return count of request to C<$path> endpoint

=cut
sub count_of_requests {
    my ($self, $path) = @_;

    $path = '/' if !defined $path;

    my $fh = path($self->mojo_home, convert_path_to_filename($path))->filehandle();

    my $lines = 0;
    while (<$fh>) {
        $lines++;
    }

    return $lines;
}

=head2 list_of_requests_body($path)

return list (ArrayRef) of requests body to C<$path> endpoint

=cut
sub list_of_requests_body {
    my ($self, $path) = @_;

    $path = '/' if !defined $path;

    my $fh = path($self->mojo_home, convert_path_to_filename($path))->filehandle();

    my @lines;
    while (my $line = <$fh>) {
        chomp $line;

        push @lines, decode_json($line);
    }

    return \@lines;
}


sub DESTROY {
    my ($self) = @_;

    if ($^O eq 'MSWin32') {
        Win32::Process::KillProcess($self->pid, 0);
    }
    else {
        kill 'SIGTERM', $self->pid;
    }
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
