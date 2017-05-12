package WebService::Recruit::Shingaku;

use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.0.1';

use WebService::Recruit::Shingaku::School;
use WebService::Recruit::Shingaku::Subject;
use WebService::Recruit::Shingaku::Work;
use WebService::Recruit::Shingaku::License;
use WebService::Recruit::Shingaku::Pref;
use WebService::Recruit::Shingaku::Category;


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

sub school {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Shingaku::School->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub subject {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Shingaku::Subject->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub work {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Shingaku::Work->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub license {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Shingaku::License->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub pref {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Shingaku::Pref->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}

sub category {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::Shingaku::Category->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}


=head1 NAME

WebService::Recruit::Shingaku - An Interface for Recruit Shingaku net Web Service

=head1 SYNOPSIS

    use WebService::Recruit::Shingaku;
    
    my $service = WebService::Recruit::Shingaku->new();
    
    my $param = {
        'key' => $ENV{'WEBSERVICE_RECRUIT_KEY'},
        'keyword' => '数学',
        'pref_cd' => '12',
    };
    my $res = $service->school( %$param );
    my $root = $res->root;
    printf("api_version: %s\n", $root->api_version);
    printf("results_available: %s\n", $root->results_available);
    printf("results_returned: %s\n", $root->results_returned);
    printf("results_start: %s\n", $root->results_start);
    printf("school: %s\n", $root->school);
    print "...\n";

=head1 DESCRIPTION

リクルート進学ネットに掲載されている学校および各種学問・仕事・資格を様々な軸で検索できるAPIです。

=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $service = WebService::Recruit::Shingaku->new();

This accepts optional parameters.

    my $conf = {
        utf8_flag => 1,
        param => {
            # common parameters of this web service 
        },
    };
    my $service = WebService::Recruit::Shingaku->new( %$conf );

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

=head2 school

This makes a request for C<school> API.
See L<WebService::Recruit::Shingaku::School> for details.

    my $res = $service->school( %$param );

=head2 subject

This makes a request for C<subject> API.
See L<WebService::Recruit::Shingaku::Subject> for details.

    my $res = $service->subject( %$param );

=head2 work

This makes a request for C<work> API.
See L<WebService::Recruit::Shingaku::Work> for details.

    my $res = $service->work( %$param );

=head2 license

This makes a request for C<license> API.
See L<WebService::Recruit::Shingaku::License> for details.

    my $res = $service->license( %$param );

=head2 pref

This makes a request for C<pref> API.
See L<WebService::Recruit::Shingaku::Pref> for details.

    my $res = $service->pref( %$param );

=head2 category

This makes a request for C<category> API.
See L<WebService::Recruit::Shingaku::Category> for details.

    my $res = $service->category( %$param );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $service->utf8_flag( 1 );
    $service->user_agent( 'Foo-Bar/1.0 ' );
    $service->lwp_useragent( LWP::UserAgent->new() );
    $service->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://webservice.recruit.co.jp/shingaku/

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
