package Test::WWW::WebKit::Catalyst;

=head1 NAME

Test::WWW::WebKit::Catalyst - Perl extension for using an embedding WebKit engine for Catalyst tests

=head1 SYNOPSIS

    use Test::WWW::WebKit::Catalyst;

    my $webkit = Test::WWW::WebKit::Catalyst->new(app => 'TestApp', xvfb => 1);
    $webkit->init;

    $webkit->open_ok("http://localhost:$ENV{CATALYST_PORT}/index");
    $webkit->type_ok("q", "hello world");
    $webkit->click_ok("xpath=//button");
    $webkit->wait_for_page_to_load_ok(5000);
    $webkit->title_is("foo");

=head1 DESCRIPTION

Test::WWW::WebKit::Catalyst is a drop-in replacement for Test::WWW::Selenium::Catalyst using Gtk3::WebKit as browser instead of relying on an external Java server and an installed browser.

=head2 EXPORT

None by default.

=cut

use 5.10.0;
use Moose;
use IO::Socket::INET;
use Catalyst::EngineLoader;

extends 'Test::WWW::WebKit' => { -version => 0.03 };

our $VERSION = '0.02';

has app => (
    is       => 'ro',
    isa      => 'ClassName',
    required => 1,
);

has server_pid => (
    is  => 'rw',
    isa => 'Int',
);

has server => (
    is => 'rw',
);

before DESTROY => sub {
    my ($self) = @_;
    return unless $self->server_pid;

    local $SIG{PIPE} = 'IGNORE';
    kill 15, $self->server_pid;
    close $self->server;
};

sub test_port {
    my ($port) = @_;
    return IO::Socket::INET->new(
        Listen    => 5,
        Proto     => 'tcp',
        Reuse     => 1,
        LocalPort => $port
    ) ? 1 : 0;
}

sub start_catalyst_server {
    my ($self) = @_;

    my $pid;
    if (my $pid = open my $server, '-|') {
        $self->server_pid($pid);
        $self->server($server);
        my $port = <$server>;
        chomp $port;
        return $port;
    }
    else {
        local $SIG{TERM} = sub {
            exit 0;
        };

        my ($port, $catalyst);
        while (1) {
            $port = 1024 + int(rand(65535 - 1024));
            next unless test_port($port);

            my $loader = Catalyst::EngineLoader->new(application_name => $self->app);
            eval {
                $catalyst = $self->load_application($loader, $port);
            };
            warn $@ if $@;
            last unless $@;
            warn "retrying...";
        }
        say $port;
        $self->app->run($port, 'localhost', $catalyst);

        exit 1;
    }
}

sub load_application {
    my ($self, $loader, $port) = @_;

    return $loader->auto(port => $port, host => 'localhost');
}

before init => sub {
    my ($self) = @_;

    $ENV{CATALYST_PORT} = $self->start_catalyst_server;
};

1;

=head1 SEE ALSO

L<WWW::Selenium> and L<Test::WWW::Selenium> for the base packages.
See L<Test::WWW::Selenium> for API documentation.

=head1 AUTHOR

Stefan Seifert, E<lt>nine@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stefan Seifert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
