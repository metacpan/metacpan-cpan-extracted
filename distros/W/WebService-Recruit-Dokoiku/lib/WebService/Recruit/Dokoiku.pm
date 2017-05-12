package WebService::Recruit::Dokoiku;
use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.11';

use WebService::Recruit::Dokoiku::SearchPOI;
use WebService::Recruit::Dokoiku::GetLandmark;
use WebService::Recruit::Dokoiku::GetStation;

my $PARAMS = [qw( key pagesize )];
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

sub searchPOI {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Dokoiku::SearchPOI->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub getLandmark {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Dokoiku::GetLandmark->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub getStation {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Dokoiku::GetStation->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

=head1 NAME

WebService::Recruit::Dokoiku - A Interface for Dokoiku Web Service Beta

=head1 SYNOPSIS

    use WebService::Recruit::Dokoiku;

    my $doko = WebService::Recruit::Dokoiku->new();
    $doko->key( 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' );

    my $param = {
        lat_jgd =>  '35.6686',
        lon_jgd =>  '139.7593',
        name    =>  'ATM',
    };
    my $res = $doko->searchPOI( %$param );
    my $list = $res->root->poi;
    foreach my $poi ( @$list ) {
        print "name: ", $poi->name, "\n";
        print "addr: ", $poi->address, "\n";
        print "web:  ", $poi->dokopcurl, "\n";
        print "map:  ", $poi->dokomapurl, "\n";
        print "\n";
    }

=head1 DESCRIPTION

This module is a interface for the Dokoiku Web Service I<Beta>,
provided by Recruit Co., Ltd., Japan.
It provides three API methods: L</searchPOI>, L</getLandmark>
and L</getStation>.
With these methods, you can find almost all of shops, restaurants
and many other places in Japan.

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $doko = WebService::Recruit::Dokoiku->new();

This accepts optional parameters.

    my $conf = { key => 'your_auth_key', utf8_flag => 1 };
    my $doko = WebService::Recruit::Dokoiku->new( %$conf );

=head2 key

A valid developer key is required to make a request.

    $doko->key( 'your_auth_key' );

=head2 searchPOI

This makes a request for C<searchPOI> API.
See L<WebService::Recruit::Dokoiku::SearchPOI> for details.

    my $res = $doko->searchPOI( lmcode => 4212, name => 'ATM' );

=head2 getLandmark

This makes a request for C<getLandmark> API.
See L<WebService::Recruit::Dokoiku::GetLandmark> for details.

    my $res = $doko->getLandmark( name => 'SHIBUYA 109' );

=head2 getStation

This makes a request for C<getStation> API.
See L<WebService::Recruit::Dokoiku::GetStation> for details.

    my $res = $doko->getStation( lon_jgd => 139.758, lat_jgd => 35.666 );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $doko->utf8_flag( 1 );
    $doko->user_agent( 'Foo-Bar/1.0 ' );
    $doko->lwp_useragent( LWP::UserAgent->new() );
    $doko->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://www.doko.jp/api/

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

This module is unofficial and released by the authour in person.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
