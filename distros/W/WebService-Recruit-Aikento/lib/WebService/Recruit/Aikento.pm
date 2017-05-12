package WebService::Recruit::Aikento;

use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.0.1';

use WebService::Recruit::Aikento::Item;
use WebService::Recruit::Aikento::LargeCategory;
use WebService::Recruit::Aikento::SmallCategory;


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

sub item {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Aikento::Item->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub large_category {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Aikento::LargeCategory->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub small_category {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Aikento::SmallCategory->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}


=head1 NAME

WebService::Recruit::Aikento - An Interface for Aikento Web Service

=head1 SYNOPSIS

    use WebService::Recruit::Aikento;
    
    my $service = WebService::Recruit::Aikento->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'large_category' => '202',
    };
    my $res = $service->item( %$param );
    my $root = $res->root;
    printf("api_version: %s\n", $root->api_version);
    printf("results_available: %s\n", $root->results_available);
    printf("results_returned: %s\n", $root->results_returned);
    printf("results_start: %s\n", $root->results_start);
    printf("item: %s\n", $root->item);
    print "...\n";

=head1 DESCRIPTION

アイケントに掲載されている商品をさまざまな検索軸で探せる商品情報APIです。

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $service = WebService::Recruit::Aikento->new();

This accepts optional parameters.

    my $conf = {
        utf8_flag => 1,
        param => {
            # common parameters of this web service 
        },
    };
    my $service = WebService::Recruit::Aikento->new( %$conf );

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

=head2 item

This makes a request for C<item> API.
See L<WebService::Recruit::Aikento::Item> for details.

    my $res = $service->item( %$param );

=head2 large_category

This makes a request for C<large_category> API.
See L<WebService::Recruit::Aikento::LargeCategory> for details.

    my $res = $service->large_category( %$param );

=head2 small_category

This makes a request for C<small_category> API.
See L<WebService::Recruit::Aikento::SmallCategory> for details.

    my $res = $service->small_category( %$param );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $service->utf8_flag( 1 );
    $service->user_agent( 'Foo-Bar/1.0 ' );
    $service->lwp_useragent( LWP::UserAgent->new() );
    $service->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://webservice.recruit.co.jp/aikento/

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
