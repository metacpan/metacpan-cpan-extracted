package WWW::OneAll;

use strict;
use warnings;
use Carp qw/croak/;
use Mojo::UserAgent;
use Mojo::Util qw(b64_encode);

our $VERSION = '0.02';

use vars qw/$errstr/;
sub errstr { return $errstr }

sub new {    ## no critic (ArgUnpacking)
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    for (qw/subdomain public_key private_key/) {
        $args{$_} || croak "Param $_ is required.";
    }

    $args{endpoint} ||= "https://" . $args{subdomain} . ".api.oneall.com";
    $args{timeout}  ||= 60;                                                  # for ua timeout

    return bless \%args, $class;
}

sub __ua {
    my $self = shift;

    return $self->{ua} if exists $self->{ua};

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);
    $ua->inactivity_timeout($self->{timeout});
    $ua->proxy->detect;    # env proxy
                           # $ua->cookie_jar(0);
    $ua->max_connections(100);
    $self->{ua} = $ua;

    return $ua;
}

sub connections {
    return (shift)->request('GET', "/connections");
}

sub connection {
    my ($self, $connection_token) = @_;

    return $self->request('GET', "/connection/$connection_token");
}

sub request {
    my ($self, $method, $url, %params) = @_;

    $errstr = '';    # reset

    my $ua = $self->__ua;
    my $header = {Authorization => 'Basic ' . b64_encode($self->{public_key} . ':' . $self->{private_key}, '')};
    $header->{'Content-Type'} = 'application/json' if %params;
    my @extra = %params ? (json => \%params) : ();
    my $tx = $ua->build_tx($method => $self->{endpoint} . $url . '.json' => $header => @extra);
    $tx->req->headers->accept('application/json');

    $tx = $ua->start($tx);
    if ($tx->res->headers->content_type and $tx->res->headers->content_type =~ 'application/json') {
        return $tx->res->json;
    }
    if (!$tx->success) {
        $errstr = "Failed to fetch $url: " . $tx->error->{message};
        return;
    }

    $errstr = "Unknown Response.";
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::OneAll - OneAll API

=head1 SYNOPSIS

    use WWW::OneAll;
    my $connection_token;
    my $oneall = WWW::OneAll->new(
        subdomain   => 'your_subdomain',
        public_key  => 'pubkey12-629b-4020-83fe-38af46e27b06',
        private_key => 'prikey12-a7ec-48f5-b9bc-737eb74146a4',
    );
    my $data = $oneall->connection($connection_token) or die $oneall->errstr;

=head1 DESCRIPTION

OneAll provides web-applications with a unified API for 30+ social networks.

=head1 METHODS

=head2 new

=over

=item * subdomain

=item * public_key

=item * private_key

all required. get from API Settings L<https://app.oneall.com/applications/application/settings/api/>

=back

=head2 connections

=head2 connection

Connection API L<http://docs.oneall.com/api/resources/connections/>

=head2 request

    my $res = $oneall->request('GET', "/connections");

native method to create your own API request.

=head2 errstr

=head1 AUTHOR

Fayland Lam E<lt>fayland@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
