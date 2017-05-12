package WebService::Recruit::HotPepperBeauty;

use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.0.1';

use WebService::Recruit::HotPepperBeauty::Salon;
use WebService::Recruit::HotPepperBeauty::ServiceArea;
use WebService::Recruit::HotPepperBeauty::MiddleArea;
use WebService::Recruit::HotPepperBeauty::SmallArea;
use WebService::Recruit::HotPepperBeauty::HairImage;
use WebService::Recruit::HotPepperBeauty::HairLength;
use WebService::Recruit::HotPepperBeauty::Kodawari;
use WebService::Recruit::HotPepperBeauty::KodawariSetsubi;
use WebService::Recruit::HotPepperBeauty::KodawariMenu;


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

sub salon {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::Salon->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub service_area {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::ServiceArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub middle_area {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::MiddleArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub small_area {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::SmallArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub hair_image {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::HairImage->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub hair_length {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::HairLength->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub kodawari {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::Kodawari->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub kodawari_setsubi {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::KodawariSetsubi->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub kodawari_menu {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepperBeauty::KodawariMenu->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}


=head1 NAME

WebService::Recruit::HotPepperBeauty - An Interface for HotPepperBeauty Web Service

=head1 SYNOPSIS

    use WebService::Recruit::HotPepperBeauty;
    
    my $service = WebService::Recruit::HotPepperBeauty->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'name' => 'サロン',
        'order' => '3',
    };
    my $res = $service->salon( %$param );
    my $root = $res->root;
    printf("api_version: %s\n", $root->api_version);
    printf("results_available: %s\n", $root->results_available);
    printf("results_returned: %s\n", $root->results_returned);
    printf("results_start: %s\n", $root->results_start);
    printf("salon: %s\n", $root->salon);
    print "...\n";

=head1 DESCRIPTION

ホットペッパーBeauty Webサービスを使うことで、ホットペッパーBeautyに掲載されている、サロン情報にアクセスして、アプリケーションを構築することができます。

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $service = WebService::Recruit::HotPepperBeauty->new();

This accepts optional parameters.

    my $conf = {
        utf8_flag => 1,
        param => {
            # common parameters of this web service 
        },
    };
    my $service = WebService::Recruit::HotPepperBeauty->new( %$conf );

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

=head2 salon

This makes a request for C<salon> API.
See L<WebService::Recruit::HotPepperBeauty::Salon> for details.

    my $res = $service->salon( %$param );

=head2 service_area

This makes a request for C<service_area> API.
See L<WebService::Recruit::HotPepperBeauty::ServiceArea> for details.

    my $res = $service->service_area( %$param );

=head2 middle_area

This makes a request for C<middle_area> API.
See L<WebService::Recruit::HotPepperBeauty::MiddleArea> for details.

    my $res = $service->middle_area( %$param );

=head2 small_area

This makes a request for C<small_area> API.
See L<WebService::Recruit::HotPepperBeauty::SmallArea> for details.

    my $res = $service->small_area( %$param );

=head2 hair_image

This makes a request for C<hair_image> API.
See L<WebService::Recruit::HotPepperBeauty::HairImage> for details.

    my $res = $service->hair_image( %$param );

=head2 hair_length

This makes a request for C<hair_length> API.
See L<WebService::Recruit::HotPepperBeauty::HairLength> for details.

    my $res = $service->hair_length( %$param );

=head2 kodawari

This makes a request for C<kodawari> API.
See L<WebService::Recruit::HotPepperBeauty::Kodawari> for details.

    my $res = $service->kodawari( %$param );

=head2 kodawari_setsubi

This makes a request for C<kodawari_setsubi> API.
See L<WebService::Recruit::HotPepperBeauty::KodawariSetsubi> for details.

    my $res = $service->kodawari_setsubi( %$param );

=head2 kodawari_menu

This makes a request for C<kodawari_menu> API.
See L<WebService::Recruit::HotPepperBeauty::KodawariMenu> for details.

    my $res = $service->kodawari_menu( %$param );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $service->utf8_flag( 1 );
    $service->user_agent( 'Foo-Bar/1.0 ' );
    $service->lwp_useragent( LWP::UserAgent->new() );
    $service->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://webservice.recruit.co.jp/beauty/

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
