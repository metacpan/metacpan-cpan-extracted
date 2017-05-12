package WebService::Recruit::FromA;

use strict;
use base qw( Class::Accessor::Fast );
use vars qw( $VERSION );
$VERSION = '0.0.1';

use WebService::Recruit::FromA::JobSearch;


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

sub jobSearch {
    my $self = shift or return;
    $self = $self->new() unless ref $self;
    my $api = WebService::Recruit::FromA::JobSearch->new();
    $self->init_treepp_config( $api );
    $self->init_query_param( $api );
    $api->add_param( @_ );
    $api->request();
    $api;
}


=head1 NAME

WebService::Recruit::FromA - An Interface for FromA Navi Web Service

=head1 SYNOPSIS

    use WebService::Recruit::FromA;
    
    my $service = WebService::Recruit::FromA->new();
    
    my $param = {
        'api_key' => $ENV{'WEBSERVICE_RECRUIT_FROMA_KEY'},
        'ksjcd' => '04',
        'shrt_indx_cd' => '1001',
    };
    my $res = $service->jobSearch( %$param );
    my $root = $res->root;
    printf("Code: %s\n", $root->Code);
    printf("TotalOfferAvailable: %s\n", $root->TotalOfferAvailable);
    printf("TotalOfferReturned: %s\n", $root->TotalOfferReturned);
    printf("PageNumber: %s\n", $root->PageNumber);
    printf("EditionName: %s\n", $root->EditionName);
    print "...\n";

=head1 DESCRIPTION

お仕事検索webサービスは、フロム・エー ナビ上に登録されているお仕事情報を取得できるAPI です。
リクエストURL にパラメータを付けたHTTP リクエストに対し、XML 形式でレスポンスを返します（REST 方式）。リクエストパラメータとしては、職種、勤務期間、勤務日数、勤務時間帯、検索パターン、取得件数、データ取得エリア（市区町村レベル）など様々なパラメータを備えています。
また、戻り値として返されるXMLには、お仕事に関する基本的な情報だけでなく、勤務地の郵便番号や勤務地の緯度・経度情報、写真画像のURLなども含まれており、様々な情報サービスへの展開が期待できる仕様となっています。


=head1 METHODS

=head2 new

This is the constructor method for this class.

    my $service = WebService::Recruit::FromA->new();

This accepts optional parameters.

    my $conf = {
        utf8_flag => 1,
        param => {
            # common parameters of this web service 
        },
    };
    my $service = WebService::Recruit::FromA->new( %$conf );

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

=head2 jobSearch

This makes a request for C<jobSearch> API.
See L<WebService::Recruit::FromA::JobSearch> for details.

    my $res = $service->jobSearch( %$param );

=head2 utf8_flag / user_agent / lwp_useragent / http_lite

This modules uses L<XML::TreePP> module internally.
Following methods are available to configure it.

    $service->utf8_flag( 1 );
    $service->user_agent( 'Foo-Bar/1.0 ' );
    $service->lwp_useragent( LWP::UserAgent->new() );
    $service->http_lite( HTTP::Lite->new() );

=head1 SEE ALSO

http://froma.yahoo.co.jp/s/contents/info/cont/web_service/index.html

=head1 AUTHOR

RECRUIT Media Technology Labs <mtl@cpan.org>

=head1 COPYRIGHT

Copyright 2008 RECRUIT Media Technology Labs

=cut
1;
