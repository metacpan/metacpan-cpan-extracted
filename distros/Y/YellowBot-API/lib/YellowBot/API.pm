package YellowBot::API;
$YellowBot::API::VERSION = '0.97';
use warnings;
use strict;
use Moose;
use UNIVERSAL::require;
use LWP::UserAgent;

use namespace::clean -except => 'meta';

use YellowBot::API::Request;

has 'api_key' => (
    isa => 'Str',
    is  => 'ro',
    required => 1,
);

has 'api_secret' => (
    isa => 'Str',
    is  => 'ro',
    required => 1,
);

has 'server' => (
    isa => 'Str',
    is  => 'rw',
    default => 'http://www.yellowbot.com',
);

has 'req_method' => (
    isa => 'Str',
    is  => 'rw',
    default => 'post',    # or 'j-post'
);

has 'ua' => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    lazy_build => 1,
);

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy;
    return $ua;
}

my %REQ_CLASS = (
    'post' => 'YellowBot::API::Request',
    'j-post' => 'YellowBot::API::Request::JSON',
);

sub _request {
    my ($self, $method, %args) = @_;

    my $request_class = $REQ_CLASS{$self->req_method};
    $request_class->require;

    return $request_class->new(
        method => $method,
        args   => \%args,
        api    => $self,
    );

}

sub call {
    my $self = shift;
    my $http_response = $self->ua->request( $self->_request(@_)->http_request );
    return YellowBot::API::Response->new(http => $http_response)->data;
}

sub signin_url {
    my $self   = shift;
    my %args   = @_;
    my $domain = $args{domain} ? "https://$args{domain}" : $self->server;
    my $uri    = URI->new("$domain/signin/partner");

    %args = YellowBot::API::Request::_query(
        %args,
        api_key    => $self->api_key,
        api_secret => $self->api_secret,
    );

    $uri->query_form( %args );
    return $uri->as_string;
}

__PACKAGE__->meta->make_immutable;

local ($YellowBot::API::VERSION) = ('devel') unless defined $YellowBot::API::VERSION;

1;

__END__

=pod

=encoding utf8

=head1 NAME

YellowBot::API - The great new YellowBot::API!

=head1 SYNOPSIS

    use YellowBot::API;

    my $api = YellowBot::API->new
       (api_key    => $api_key,
        api_secret => $api_secret,
       );

    # if you are in Canada...
    # $api->server('http://www.weblocal.ca/');

    my $data = $api->call('location/details',
                          id           => '/solfo-burbank-ca.html'
                          api_version  => 1,
                          get_pictures => 10,
                         );
    print $data->{name}, "\n";
    for my $p ( @{ $data->{pictures} } ) {
       print $p->{url}, "\n";
    }


    my $signin_url = $api->signin_url(
       domain => 'reputation.example.com',
       api_user_identifier => 'abc123',
       brand => 'yellowbot',
    );


=head1 METHODS

=head2 call( $endpoint, %args )

Calls the endpoint (see the YellowBot API documentation) with the
specified arguments.  Returns a hash data structure with the API
results.

=head2 signin_url( %options )

Generate a URL for the "silent partner login" feature.  See example
above and API documentation for details.

=head1 DEBUGGING

If the API_DEBUG environment variable is set to a true value (1 for
example) the request query and the response will be printed to STDERR.

See also the ybapi utility, L<ybapi>. 

=head1 AUTHOR

Ask Bjørn Hansen, C<< <ask at develooper.com> >>

=head1 BUGS

Please report any bugs or feature requests to the issue tracker at 
L<http://github.com/solfo/YellowBot-API-perl/issues>.

The Git repository is available at
L<http://github.com/solfo/YellowBot-API-perl> (Clone with C<git clone
http://github.com/solfo/YellowBot-API-perl.git>).


=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Solfo, Inc, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

