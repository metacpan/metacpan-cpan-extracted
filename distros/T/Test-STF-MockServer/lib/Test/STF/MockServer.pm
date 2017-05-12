package Test::STF::MockServer;
use strict;
use Test::TCP;
use URI;
use Class::Accessor::Lite
    ro => [ qw(impl) ]
;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my %args  = @_;

    my $impl = $args{impl};
    my $plack_args = $args{plack_args};

    my $server = Test::TCP->new(code => sub {
        my $port = shift;

        # require is in this scope because it would be used
        # in the child process.
        if (! $impl) {
            require STF::Dispatcher::Impl::Hash;
            $impl = STF::Dispatcher::Impl::Hash->new;
        }

        require STF::Dispatcher::PSGI;
        my $dispatcher = STF::Dispatcher::PSGI->new(
            impl => $impl
        );

        require Plack::Runner;
        my $runner = Plack::Runner->new;
        $runner->parse_options('--port' => $port, $plack_args ? @$plack_args : ());
        $runner->run($dispatcher->to_app);
    });

    my $url = URI->new("http://127.0.0.1");
    $url->port( $server->port );
    bless [ $server, $url ], $class;
}

sub url {
    return $_[0]->[1]->clone;
}

sub url_for {
    my $self = shift;
    my $url  = $self->url;
    $url->path("@_");
    return $url;
}

__END__

=head1 NAME

Test::STF::MockServer - Mock STF Server For Testing

=head1 SYNOPSIS

    use Test::STF::MockSerer;

    my $server = Test::STF::MockServer->new();
    my $lwp = LWP::UserAgent->new;
    my $bucket = $server->url_for("/bucket");
    my $object = $server->url_for("/bucket/path/to/object.txt")

    $lwp->put($bucket);
    $lwp->put($object, Content => "Hello, World!");
    $lwp->get($object);

=head1 DESCRIPTION

C<Test::STF::MockServer> is a simple object that represents a mock STF
server for testing.

The STF server instance is automatically spawned via C<Test::TCP> and
is automatically destroyed when the server object is desroyed.

=head1 METHODS

=head2 C<new(%args)>

Creates a new Test::STF::MockServer instance. C<%args> can be:

=over 4

=item impl (Object)

Optional object capable of fulfilling STF::Dispatcher::PSGI's specification.
If not specified, STF::Dispatcher::Impl::Hash will be used.

=item plack_args (ArrayRef)

Optional list to be passed to Plack::Runner.

=back

=head2 C<url()>

Returns a URI object representing the root STF server.

=head2 C<url_for($string)>

Returns a URI object representing the given bucket/object.

    $uri = $server->url_for("/path/to/bucket");

=head1 AUTHOR

Daisuke Maki

original idea by tokuhirom (http://blog.64p.org/entry/2012/12/14/193936)

=head1 SEE ALSO

L<STF> (http://github.com/stf-storage/stf)

L<STF::Dispatcher::PSGI>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut