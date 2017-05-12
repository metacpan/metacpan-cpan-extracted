package WebService::Recruit::HotPepper;
use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.03';

use WebService::Recruit::HotPepper::GourmetSearch;
use WebService::Recruit::HotPepper::ShopSearch;
use WebService::Recruit::HotPepper::LargeServiceArea;
use WebService::Recruit::HotPepper::ServiceArea;
use WebService::Recruit::HotPepper::LargeArea;
use WebService::Recruit::HotPepper::MiddleArea;
use WebService::Recruit::HotPepper::SmallArea;
use WebService::Recruit::HotPepper::Genre;
use WebService::Recruit::HotPepper::Food;
use WebService::Recruit::HotPepper::Budget;

my $PARAMS = [qw( key Count Start )];
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
        next unless exists $self->{$key};
        next unless defined $self->{$key};
        $treepp->set( $key => $self->{$key} );
    }
}

sub init_query_param {
    my $self = shift;
    my $api  = shift;
    foreach my $key ( @$PARAMS ) {
        next unless exists $self->{$key};
        next unless defined $self->{$key};
        $api->add_param( $key => $self->{$key} );
    }
}

sub GourmetSearch {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::GourmetSearch->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub ShopSearch {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::ShopSearch->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub LargeServiceArea {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::LargeServiceArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub ServiceArea {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::ServiceArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub LargeArea {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::LargeArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub MiddleArea {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::MiddleArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub SmallArea {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::SmallArea->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub Genre {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::Genre->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub Food {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::Food->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub Budget {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::HotPepper::Budget->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

=head1 NAME

WebService::Recruit::HotPepper - perl interface for HotPepper Web Service

=head1 SYNOPSIS

    use WebService::Recruit::HotPepper;

    my $api = WebService::Recruit::HotPepper->new();
    $api->key( 'xxxxxxxxxxxxxxxx' );

    my $param = {
        ServiceAreaCD => 'SA11',
        GenreCD       => 'G002',
    };
    my $res = $api->GourmetSearch( %$param );
    my $list = $res->root->Shop;
    foreach my $shop ( @$list ) {
        print "name:  ", $shop->ShopName, "\n";
        print "addr:  ", $shop->ShopAddress, "\n";
        print "photo: ", $shop->PictureUrl->PcLargeImg, "\n";
        print "\n";
    }

=head1 DESCRIPTION

This module is a perl interface for the HotPepper Web Service
(L<http://api.hotpepper.jp>), provided by Recruit Co., Ltd., Japan.  It provides API methods: L</GourmetSearch>, L</ShopSearch>, L</LargeServiceArea>, L</ServiceArea>, L</LargeArea>, L</MiddleArea>, L</SmallArea>, L</Genre>, L</Food>, and L</Budget>.  With these methods, you can find restaurants and their discount coupons in Japan.

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $api = WebService::Recruit::HotPepper->new();

This accepts optional parameters.

    my $conf = { key => 'your_auth_key', utf8_flag => 1 };
    my $api = WebService::Recruit::HotPepper->new( %$conf );

=head2 key

A valid developer key is required to make a request.

    $api->key( 'your_auth_key' );

=head2 GourmetSearch

This makes a request for C<GourmetSearch> API.
See L<WebService::Recruit::HotPepper::GourmetSearch> for details.

    my $res = $api->GourmetSearch( ServiceAreaCD=>'SA11' );

=head2 ShopSearch

This makes a request for C<ShopSearch> API.
See L<WebService::Recruit::HotPepper::ShopSearch> for details.

    my $res = $api->ShopSearch( Keyword=>'pizza' );

=head2 LargeServiceArea

This makes a request for C<LargeServiceArea> API.
See L<WebService::Recruit::HotPepper::LargeServiceArea> for details.

    my $res = $api->LargeServiceArea();

=head2 ServiceArea

This makes a request for C<ServiceArea> API.
See L<WebService::Recruit::HotPepper::ServiceArea> for details.

    my $res = $api->ServiceArea();

=head2 LargeArea

This makes a request for C<LargeArea> API.
See L<WebService::Recruit::HotPepper::LargeArea> for details.

    my $res = $api->LargeArea();

=head2 MiddleArea

This makes a request for C<MiddleArea> API.
See L<WebService::Recruit::HotPepper::MiddleArea> for details.

    my $res = $api->MiddleArea();

=head2 SmallArea

This makes a request for C<SmallArea> API.
See L<WebService::Recruit::HotPepper::SmallArea> for details.

    my $res = $api->SmallArea();

=head2 Genre 

This makes a request for C<Genre> API.
See L<WebService::Recruit::HotPepper::Genre> for details.

    my $res = $api->Genre();

=head2 Food 

This makes a request for C<Food> API.
See L<WebService::Recruit::HotPepper::Food> for details.

    my $res = $api->Food();

=head2 Budget 

This makes a request for C<Budget> API.
See L<WebService::Recruit::HotPepper::Budget> for details.

    my $res = $api->Budget();

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
The following methods are available to configure it.

    $api->utf8_flag( 1 );
    $api->user_agent( 'Foo-Bar/1.0 ' );
    $api->lwp_useragent( LWP::UserAgent->new() );
    $api->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://api.hotpepper.jp/

=head1 AUTHOR

Toshimasa Ishibashi L<http://iandeth.dyndns.org/>

This module is unofficial and released by the author in person.

=head1 THANKS TO

Yusuke Kawasaki L<http://www.kawa.net/>

For creating/preparing all the base modules and stuff.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Toshimasa Ishibashi. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
