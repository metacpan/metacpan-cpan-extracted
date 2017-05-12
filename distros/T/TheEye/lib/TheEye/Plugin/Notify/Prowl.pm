package TheEye::Plugin::Notify::Prowl;

use 5.010;
use Mouse::Role;
use LWP::UserAgent;
use URI::Escape;
use XML::Simple;
use Data::Dumper;

# ABSTRACT: Plugin for TheEye to raise alerts via Prowl
#
our $VERSION = '0.5'; # VERSION

has 'prowl_apikeys' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    lazy     => 1,
    required => 1,
    default  => sub { [] },
);

has 'prowl_app' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'TheEye'
);

has 'prowl_prio' => (
    is       => 'rw',
    isa      => 'Int',
    lazy     => 1,
    required => 1,
    default  => 0
);

has 'prowl_event' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'alert'
);

has 'prowl_message' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => ''
);

has 'prowl_url' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'https://prowl.weks.net/publicapi/'
);

has 'prowl_downtime' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => '/tmp/theeye.downtime'
);

has 'prowl_err' => (
    is        => 'rw',
    isa       => 'Bool',
    required  => 0,
    default   => 0,
    predicate => 'has_prowl_err',
);

around 'notify' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @errors;
    foreach my $test (@{$tests}) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {
                my $message = 'we have a problem: ' . $test->{file} . "\n";
                $message .= $step->{message} . "\n";
                $message .= $step->{comment} if $step->{comment};
                push(@errors, $message);
            }
        }
    }
    if($errors[0]){
        $self->prowl_message(join("\n\n--~==##\n\n", @errors));
        $self->prowl_send();
    }
};

sub prowl_verify {
    my ( $self, $key ) = @_;
    my $path   = 'verify?apikey=' . $key;
    my $result = $self->_call($path);
    return $result;
}

sub prowl_add_key {
    my ( $self, $key ) = @_;
    if ( $self->prowl_verify($key) ) {
        push( @{ $self->prowl_apikeys }, $key );
    }
    else {
        warn $self->err;
    }
    return;
}

sub prowl_send {
    my $self = shift;
    print STDERR Dumper($self) if $self->is_debug;
    my @req;
    if ( length $self->prowl_message > 10000 ) {
        $self->prowl_message( substr( $self->prowl_message, 0, 10000 ) );
    }
    if ( length $self->prowl_event > 1024 ) {
        $self->prowl_event( substr( $self->prowl_event, 0, 1024 ) );
    }
    push( @req, "apikey=" . join( ',', @{ $self->prowl_apikeys } ) );
    push( @req, "description=" . uri_escape( $self->prowl_message ) );
    push( @req, "event=" . uri_escape( $self->prowl_event ) );
    push( @req, "priority=" . $self->prowl_prio );
    push( @req, "application=" . uri_escape( $self->prowl_app ) );
    my $path = 'add?' . join( '&', @req );
    print STDERR "Request: $path\n" if $self->is_debug;
    my $result;
    $result = $self->_call($path)
        unless -f $self->prowl_downtime;
    return $result;
}

sub _call {
    my ( $self, $path ) = @_;
    my $uri = $self->prowl_url . $path;
    print STDERR "URI: $uri\n" if $self->is_debug;

    my $req = HTTP::Request->new();
    $req->method('GET');
    $req->uri($uri);

    #$req->content( to_json($content) ) if ($content);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    print STDERR "Result: " . $res->decoded_content . "\n" if $self->is_debug;
    if ( $res->is_success ) {
        return XMLin( $res->decoded_content );
    }
    else {
        if ( my $_err = XMLin( $res->decoded_content ) ) {
            $self->prowl_err($_err);
        }
        else {
            $self->prowl_err( $res->status_line );
        }
    }
    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Notify::Prowl - Plugin for TheEye to raise alerts via Prowl

=head1 VERSION

version 0.5

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

=for Pod::Coverage prowl_verify prowl_add_key prowl_send
