package WWW::Stickam::API;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use XML::Simple;
use UNIVERSAL::require;
use JSON::XS ;
use Time::HiRes;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw/data content error tv_interval/);

sub call {
    my ( $s , $pkg , $args ) = @_;
    my $t0 = [ Time::HiRes::gettimeofday() ];
    $pkg =~ s/\//::/g;
    $pkg = 'WWW::Stickam::API::' . $pkg ;
    $pkg->require or die "The API call[$pkg] is not available...[$@]";

    my $api = $pkg->new();

    if( $api->call( $args ) ) {
        $s->{content} = $api->content;
        $s->{tv_interval} = Time::HiRes::tv_interval( $t0 );
        return 1;
    }
    else {
        $s->{error} = $api->error;
        $s->{tv_interval} = Time::HiRes::tv_interval( $t0 );
        return ;
    }
}

sub get {
    my $s = shift;
    return XMLin( $s->{content} );
}

sub get_XML {
    my $s = shift;
    return $s->{content};
}

sub get_JSON {
    my $s = shift;
    my $data = $s->get();
    return JSON::XS->new->utf8->pretty(1)->encode( $data );;
}

1;

=head1 NAME

WWW::Stickam::API - Perl implementation of Stickam API

=head1 SYNOPSYS

 my $api = WWW::Stickam::API->new();
 if( $api->call('User/Profile' , { user_name => 'stickam' } ) ) {
    print Dumper $api->get();
    print $api->get_XML();
    print $api->get_JSON();
 }
 else {
    print $api->error ;
 }

=head1 DESCRIPTION

Perl implementation of Stickam API. See http://labs.stickam.jp/api/ 

=head1 METHOD

=head2 new

=head2 call

This method call stickam API , take API name and parameters.
Return true for success , false for fail.

=head2 get

get result in hash array format.

=head2 get_XML

get result in XML

=head2 get_JSON

get result in JSON 

=head2 error

get error message

=head2 tv_interval

get tv_interval. SEE L<Time::HiRes> 

=head2 SEE ALSO

L<WWW::Stickam::API::User::Audio>

L<WWW::Stickam::API::User::Image>

L<WWW::Stickam::API::User::Profile>

L<WWW::Stickam::API::User::Video>

L<WWW::Stickam::API::Media::Information>

L<WWW::Stickam::API::Search::Media>

L<WWW::Stickam::API::Search::User>

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=cut


