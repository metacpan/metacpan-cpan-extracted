package WebService::Recruit::CarSensor;

use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.0.2';

use WebService::Recruit::CarSensor::Usedcar;
use WebService::Recruit::CarSensor::Catalog;
use WebService::Recruit::CarSensor::Brand;
use WebService::Recruit::CarSensor::Country;
use WebService::Recruit::CarSensor::LargeArea;
use WebService::Recruit::CarSensor::Pref;
use WebService::Recruit::CarSensor::Body;
use WebService::Recruit::CarSensor::Color;


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

sub usedcar {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Usedcar->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub catalog {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Catalog->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub brand {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Brand->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub country {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Country->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub large_area {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::LargeArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub pref {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Pref->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub body {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Body->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub color {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::CarSensor::Color->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}


=head1 NAME

WebService::Recruit::CarSensor - An Interface for CarSensor.net Web Service

=head1 SYNOPSIS

    use WebService::Recruit::CarSensor;
    
    my $service = WebService::Recruit::CarSensor->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'pref' => '13',
    };
    my $res = $service->usedcar( %$param );
    my $root = $res->root;
    printf("api_version: %s\n", $root->api_version);
    printf("results_available: %s\n", $root->results_available);
    printf("results_returned: %s\n", $root->results_returned);
    printf("results_start: %s\n", $root->results_start);
    printf("usedcar: %s\n", $root->usedcar);
    print "...\n";

=head1 DESCRIPTION

カーセンサーnetに掲載されている中古車情報及び新車カタログ情報を様々な軸で検索できるAPIです。

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $service = WebService::Recruit::CarSensor->new();

This accepts optional parameters.

    my $conf = {
        utf8_flag => 1,
        param => {
            # common parameters of this web service 
        },
    };
    my $service = WebService::Recruit::CarSensor->new( %$conf );

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

=head2 usedcar

This makes a request for C<usedcar> API.
See L<WebService::Recruit::CarSensor::Usedcar> for details.

    my $res = $service->usedcar( %$param );

=head2 catalog

This makes a request for C<catalog> API.
See L<WebService::Recruit::CarSensor::Catalog> for details.

    my $res = $service->catalog( %$param );

=head2 brand

This makes a request for C<brand> API.
See L<WebService::Recruit::CarSensor::Brand> for details.

    my $res = $service->brand( %$param );

=head2 country

This makes a request for C<country> API.
See L<WebService::Recruit::CarSensor::Country> for details.

    my $res = $service->country( %$param );

=head2 large_area

This makes a request for C<large_area> API.
See L<WebService::Recruit::CarSensor::LargeArea> for details.

    my $res = $service->large_area( %$param );

=head2 pref

This makes a request for C<pref> API.
See L<WebService::Recruit::CarSensor::Pref> for details.

    my $res = $service->pref( %$param );

=head2 body

This makes a request for C<body> API.
See L<WebService::Recruit::CarSensor::Body> for details.

    my $res = $service->body( %$param );

=head2 color

This makes a request for C<color> API.
See L<WebService::Recruit::CarSensor::Color> for details.

    my $res = $service->color( %$param );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $service->utf8_flag( 1 );
    $service->user_agent( 'Foo-Bar/1.0 ' );
    $service->lwp_useragent( LWP::UserAgent->new() );
    $service->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://webservice.recruit.co.jp/carsensor/

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
