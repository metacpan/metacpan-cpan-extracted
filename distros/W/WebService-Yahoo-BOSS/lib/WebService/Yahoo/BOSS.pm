package WebService::Yahoo::BOSS;

=head1 NAME

WebService::Yahoo::BOSS - Interface to the Yahoo BOSS Search API

=head1 SYNOPSIS

    use WebService::Yahoo::BOSS;

    $boss = WebService::Yahoo::BOSS->new( ckey => $ckey, csecret => $csecret );

    $response = $boss->Web( q => 'microbrew award winner 2010', ... );

    $response = $boss->PlaceFinder( q => 'Fleet Street, London', ... );

    
    foreach my $result (@{ $response->results }) {
        print $result->title, "\n";
    }


=head1 DESCRIPTION

Provides an interface to the Yahoo BOSS (Build Your Own Search) web service API.

Mad props to Yahoo for putting out a premium search api which encourages
innovative use.

This is a work in progress, so patches welcome!

=head2 Interaction

Each service has a corresponding method call. The call takes the same
parameters as described in the Yahoo BOSS documentation.

Each method returns a L<WebService::Yahoo::BOSS::Response> object that has the
following methods:

    $response->totalresults; # total number of available results
    $response->count;        # number of results in this set
    $response->start;        # typically same as start argument in request
    $response->results;      # reference to array of result objects

The result objects accessed via the C<results> methods are instances of
a C<WebService::Yahoo::BOSS::Response::*> class that corresponds to the method
called.

=head1 METHODS

=cut

use Moo;

use Any::URI::Escape;
use LWP::UserAgent;
use URI;
use Net::OAuth;
use Data::Dumper;
use Data::UUID;
use Carp qw(croak);

use WebService::Yahoo::BOSS::Response;


our $VERSION = '1.03';

my $Ug = Data::UUID->new;

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;


=head2 new

    $boss = WebService::Yahoo::BOSS->new(

        # required
        ckey => $ckey,
        csecret => $csecret,

        # optional
        url => 'http://yboss.yahooapis.com',
        ua => LWP::UserAgent->new(...),
    );

=cut

has 'ckey'    => ( is => 'ro', required => 1 );
has 'csecret' => ( is => 'ro', required => 1 );

has 'url'     => (
    is       => 'ro',
    default  => "http://yboss.yahooapis.com",
);

has 'ua' => (
    is => 'ro',
    default => sub {
        LWP::UserAgent->new(
            agent => __PACKAGE__ . '_' . $VERSION,
            keep_alive => 1, # cache connection
        );
    }
);

# last HTTP::Response e.g. to enable introspection of error details
has 'http_response' => (
    is => 'rw'
);


sub _create_boss_request {
    my ($self, $api_path, $args) = @_;

    # Create request
    my $request = Net::OAuth->request("request token")->new(
        consumer_key     => $self->ckey,
        consumer_secret  => $self->csecret,
        request_url      => $self->url . $api_path,
        request_method   => 'GET',
        signature_method => 'HMAC-SHA1',
        timestamp        => time,
        nonce            => $Ug->to_string( $Ug->create ),
        extra_params     => $args,
        callback         => '',
    );

    $request->sign;

    return $request;
}


sub _perform_boss_request {
    my ($self, $request) = @_;

    my $res = $self->ua->get( $request->to_url );
    $self->http_response($res);
    unless ( $res->is_success ) {
        die sprintf "%s requesting %s: %s",
            $res->status_line, $request->to_url, Dumper($res);
    }
    return $res->decoded_content;
}


sub _parse_boss_response {
    my ($self, $response_content, $result_class) = @_;
    return WebService::Yahoo::BOSS::Response->parse( $response_content, $result_class );
}


sub ask_boss {
    my ($self, $api_path, $args, $result_class) = @_;

    my $request = $self->_create_boss_request($api_path, $args);
    my $response_content = $self->_perform_boss_request($request);
    my $response = $self->_parse_boss_response($response_content, $result_class);

    return $response;
}

=head2 Web

Yahoo web search index results with basic url, title, and abstract data.

    $response = $boss->Web( q       => 'microbrew award winner 2010',
                            start   => 0,
                            exclude => 'pilsner', );

For more information about the arguments and result attributes see
L<http://developer.yahoo.com/boss/search/boss_api_guide/webv2_service.html>

The results are L<WebService::Yahoo::BOSS::Response::Web> objects.

=cut

sub Web {
    my ( $self, %args ) = @_;

    croak "q parameter not defined"
        unless defined $args{q};

    $args{count} ||= 10;
    $args{filter} ||= '-porn';
    $args{format} ||= 'json';
    croak 'only json format supported'
        unless $args{format} eq 'json';

    return $self->ask_boss('/ysearch/web', \%args, 'WebService::Yahoo::BOSS::Response::Web');
}

=head2 Images

Image search. Image Search includes images from the Yahoo Image Search index and Flickr.

    $response = $boss->Images( q       => 'microbrew award winner 2010',
                            start   => 0,
                            exclude => 'pilsner', );

For more information about the arguments and result attributes see
L<https://developer.yahoo.com/boss/search/boss_api_guide/image.html>

The results are L<WebService::Yahoo::BOSS::Response::Images> objects.

=cut

sub Images {
    my ( $self, %args ) = @_;

    croak "q parameter not defined"
        unless defined $args{q};

    $args{count} ||= 10;
    $args{filter} ||= '-porn';
    $args{format} ||= 'json';
    croak 'only json format supported'
        unless $args{format} eq 'json';

    return $self->ask_boss('/ysearch/images', \%args, 'WebService::Yahoo::BOSS::Response::Images');
}

=head2 PlaceFinder

    $response = $boss->PlaceFinder(
        q => '701 First Ave., Sunnyvale, CA 94089',
    );

For more information about the arguments and result attributes see
L<http://developer.yahoo.com/boss/geo/docs/requests-pf.html>

The results are L<WebService::Yahoo::BOSS::Response::PlaceFinder> objects.

=cut

sub PlaceFinder {
    my ( $self, %args ) = @_;

    $args{flags} .= "J"; # JSON

    return $self->ask_boss('/geo/placefinder', \%args, 'WebService::Yahoo::BOSS::Response::PlaceFinder');
}


1;

=head1 SEE ALSO

L<http://developer.yahoo.com/search/boss/boss_api_guide>

L<Google::Search>

=head1 SOURCE CODE

Development version of the source code is available at L<https://github.com/runarbu/WebService-Yahoo-BOSS>. Patches are welcome.

=head1 AUTHOR

"Fred Moyer", E<lt>fred@slwifi.comE<gt>

The PlaceFinder service, and general refactoring and optimization, by Tim Bunce. Image search by Runar Buvik.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Silver Lining Networks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
