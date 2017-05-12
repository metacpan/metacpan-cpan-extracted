package WebService::Recruit::AbRoad;

use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.0.1';

use WebService::Recruit::AbRoad::Tour;
use WebService::Recruit::AbRoad::Area;
use WebService::Recruit::AbRoad::Country;
use WebService::Recruit::AbRoad::City;
use WebService::Recruit::AbRoad::Hotel;
use WebService::Recruit::AbRoad::Airline;
use WebService::Recruit::AbRoad::Kodawari;
use WebService::Recruit::AbRoad::Spot;
use WebService::Recruit::AbRoad::TourTally;


my $TPPCFG = [qw( user_agent lwp_useragent http_lite utf8_flag )];
__PACKAGE__->mk_accessors( @$TPPCFG, 'param' );

sub new {
    my $package = shift;
    my $self    = {@_};
    $self->{user_agent} ||= __PACKAGE__."/$VERSION ";
    bless $self, $package;
    $self;
}

sub add_param {
    my $self = shift;
    my $param = $self->param() || {};
    %$param = ( %$param, @_ ) if scalar @_;
    $self->param($param);
}

sub get_param {
    my $self = shift;
    my $key = shift;
    my $param = $self->param() or return;
    $param->{$key} if exists $param->{$key};
}

sub init_treepp_config {
    my $self = shift;
    my $api  = shift;
    my $treepp = $api->treepp();
    foreach my $key ( @$TPPCFG ) {
        next unless exists $self->{$key};
        next unless defined $self->{$key};
        $treepp->set( $key => $self->{$key} );
    }
}

sub init_query_param {
    my $self = shift;
    my $api  = shift;
    my $param = $self->param();
    foreach my $key ( keys %$param ) {
        next unless defined $param->{$key};
        $api->add_param( $key => $param->{$key} );
    }
}

sub tour {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Tour->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub area {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Area->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub country {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Country->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub city {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::City->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub hotel {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Hotel->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub airline {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Airline->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub kodawari {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Kodawari->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub spot {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::Spot->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub tour_tally {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::AbRoad::TourTally->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}


=head1 NAME

WebService::Recruit::AbRoad - An Interface for AB-ROAD Web Service

=head1 SYNOPSIS

    use WebService::Recruit::AbRoad;
    
    my $service = WebService::Recruit::AbRoad->new();
    
    my $param = {
        'area' => 'EUR',
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
    };
    my $res = $service->tour( %$param );
    my $root = $res->root;
    printf("api_version: %s\n", $root->api_version);
    printf("results_available: %s\n", $root->results_available);
    printf("results_returned: %s\n", $root->results_returned);
    printf("results_start: %s\n", $root->results_start);
    printf("tour: %s\n", $root->tour);
    print "...\n";

=head1 DESCRIPTION

エイビーロードWebサービスを使うことで、エイビーロード(AB-ROAD)に掲載されている、海外旅行ツアー情報にアクセスして、アプリケーションを構築することができます。

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $service = WebService::Recruit::AbRoad->new();

This accepts optional parameters.

    my $conf = {
        utf8_flag => 1,
        param => {
            # common parameters of this web service 
        },
    };
    my $service = WebService::Recruit::AbRoad->new( %$conf );

=head2 add_param

Add common parameter of tihs web service.

    $service->add_param( param_key => param_value );

You can add multiple parameters by calling once.

    $service->add_param( param_key1 => param_value1,
                         param_key2 => param_value2,
                         ...);

=head2 get_param

Returns common parameter value of the specified key.

    my $param_value = $service->get( 'param_key' );

=head2 tour

This makes a request for C<tour> API.
See L<WebService::Recruit::AbRoad::Tour> for details.

    my $res = $service->tour( %$param );

=head2 area

This makes a request for C<area> API.
See L<WebService::Recruit::AbRoad::Area> for details.

    my $res = $service->area( %$param );

=head2 country

This makes a request for C<country> API.
See L<WebService::Recruit::AbRoad::Country> for details.

    my $res = $service->country( %$param );

=head2 city

This makes a request for C<city> API.
See L<WebService::Recruit::AbRoad::City> for details.

    my $res = $service->city( %$param );

=head2 hotel

This makes a request for C<hotel> API.
See L<WebService::Recruit::AbRoad::Hotel> for details.

    my $res = $service->hotel( %$param );

=head2 airline

This makes a request for C<airline> API.
See L<WebService::Recruit::AbRoad::Airline> for details.

    my $res = $service->airline( %$param );

=head2 kodawari

This makes a request for C<kodawari> API.
See L<WebService::Recruit::AbRoad::Kodawari> for details.

    my $res = $service->kodawari( %$param );

=head2 spot

This makes a request for C<spot> API.
See L<WebService::Recruit::AbRoad::Spot> for details.

    my $res = $service->spot( %$param );

=head2 tour_tally

This makes a request for C<tour_tally> API.
See L<WebService::Recruit::AbRoad::TourTally> for details.

    my $res = $service->tour_tally( %$param );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $service->utf8_flag( 1 );
    $service->user_agent( 'Foo-Bar/1.0 ' );
    $service->lwp_useragent( LWP::UserAgent->new() );
    $service->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://webservice.recruit.co.jp/ab-road/

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
