package WebService::Recruit::Jalan;
use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.10';

use WebService::Recruit::Jalan::HotelSearchLite;
use WebService::Recruit::Jalan::HotelSearchAdvance;
use WebService::Recruit::Jalan::AreaSearch;
use WebService::Recruit::Jalan::OnsenSearch;
use WebService::Recruit::Jalan::StockSearch;

my $PARAMS = [qw( key )];
my $TPPCFG = [qw( user_agent lwp_useragent http_lite utf8_flag )];
__PACKAGE__->mk_accessors( @$PARAMS, @$TPPCFG );

sub new {
    my $package = shift;
    my $self    = {@_};
    $self->{user_agent} ||= __PACKAGE__."/$VERSION ";
    bless $self, $package;
    $self;
}

sub init_treepp_config {
    my $self = shift;
    my $api  = shift;
    my $treepp = $api->treepp();
    foreach my $key ( @$TPPCFG ) {
        $treepp->set( $key => $self->{$key} ) if exists $self->{$key};
    }
}

sub init_query_param {
    my $self = shift;
    my $api  = shift;
    foreach my $key ( @$PARAMS ) {
        $api->add_param( $key => $self->{$key} ) if exists $self->{$key};
    }
}

sub HotelSearchLite {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Jalan::HotelSearchLite->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub HotelSearchAdvance {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Jalan::HotelSearchAdvance->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub AreaSearch {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Jalan::AreaSearch->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub OnsenSearch {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Jalan::OnsenSearch->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub StockSearch {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Jalan::StockSearch->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

=head1 NAME

WebService::Recruit::Jalan - A Interface for Jalan Web Service

=head1 SYNOPSIS

    use WebService::Recruit::Jalan;

    my $jalan = WebService::Recruit::Jalan->new();
    $jalan->key( 'xxxxxxxxxxxxxx' );

    my $res = $jalan->HotelSearchAdvance( s_area => '260502' );
    my $list = $res->root->Hotel;
    foreach my $hotel ( @$list ) {
        print "HotelID: ",   $hotel->HotelID, "\n";
        print "HotelName: ", $hotel->HotelName, "\n";
    }

=head1 DESCRIPTION

This module is a interface for the Jalan Web Service,
produced by Recruit Co., Ltd., Japan.
It provides five API methods: L</HotelSearchLite>, L</HotelSearchAdvance>,
L</AreaSearch>, L</OnsenSearch> and L</StockSearch>.

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $jalan = WebService::Recruit::Jalan->new();

This accepts optional parameters.

    my $conf = { key => 'your_auth_key', utf8_flag => 1 };
    my $jalan = WebService::Recruit::Jalan->new( %$conf );

=head2 key

A valid developer key is required to make a request.

    $jalan->key( 'your_auth_key' );

=head2 HotelSearchLite

This makes a request for C<HotelSearchLite> API.
See L<WebService::Recruit::Jalan::HotelSearchLite> for details.

    my $res = $jalan->HotelSearchLite( s_area => '162612' );

=head2 HotelSearchAdvance

This makes a request for C<HotelSearchAdvance> API.
See L<WebService::Recruit::Jalan::GetLandmark> for details.

    my $res = $jalan->HotelSearchAdvance( s_area => '260502' );

=head2 AreaSearch

This makes a request for C<AreaSearch> API.
See L<WebService::Recruit::Jalan::AreaSearch> for details.

    my $res = $jalan->AreaSearch( reg => 15 );

=head2 OnsenSearch

This makes a request for C<OnsenSearch> API.
See L<WebService::Recruit::Jalan::OnsenSearch> for details.

    my $res = $jalan->OnsenSearch( s_area => '141602' );

=head2 StockSearch

This makes a request for C<StockSearch> API.
See L<WebService::Recruit::Jalan::StockSearch> for details.

    my $res = $jalan->StockSearch( lon_jgd => 139.758, lat_jgd => 35.666 );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $jalan->utf8_flag( 1 );
    $jalan->user_agent( 'Foo-Bar/1.0 ' );
    $jalan->lwp_useragent( LWP::UserAgent->new() );
    $jalan->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://jws.jalan.net/

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

This module is unofficial and released by the author in person.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
