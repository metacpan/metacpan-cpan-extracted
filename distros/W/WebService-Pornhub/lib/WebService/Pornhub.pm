package WebService::Pornhub;
use v5.14.0;
use Moo;
use namespace::clean;
use Function::Parameters;
use URI;
use HTML::Entities qw/decode_entities/;
use LWP::UserAgent;

with 'WebService::Client';

our $VERSION = "0.02";

has '+base_url' => (
    default => 'https://www.pornhub.com/webmasters',
);

has '+ua' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        LWP::UserAgent->new(
            agent => 'WebService::Pornhub/' . $VERSION,
            timeout => shift->timeout,
        );
    },
);

method search(%params) {
    my $res = $self->get( $self->_uri( '/search', %params ) );
    return $res ? $res->{videos} : undef;
}

method get_video(%params) {
    my $res = $self->get( $self->_uri( '/video_by_id', %params ) );
    return $res ? $res->{video} : undef;
}

method get_embed_code(%params) {
    my $res = $self->get( $self->_uri( '/video_embed_code', %params ) );
    return undef unless $res;
    my $embed = $res->{embed} or return undef;
    $embed->{code} = decode_entities( $embed->{code} );
    return $embed;
}

method get_deleted_videos(%params) {
    $params{page} ||= 1;
    my $res = $self->get( $self->_uri( '/deleted_videos', %params ) );
    return $res ? $res->{videos} : undef;
}

method is_video_active(%params) {
    my $res = $self->get( $self->_uri( '/is_video_active', %params ) );
    return $res ? $res->{active} : undef;
}

method get_categories() {
    my $res = $self->get('/categories');
    return $res ? $res->{categories} : undef;
}

method get_tags(%params) {
    my $res = $self->get( $self->_uri( '/tags', %params ) );
    return $res ? $res->{tags} : undef;
}

method get_stars() {
    my $res = $self->get('/stars');
    return $res ? $res->{stars} : undef;
}

method get_stars_detailed() {
    my $res = $self->get('/stars_detailed');
    return $res ? $res->{stars} : undef;
}

method _uri( $path, %params ) {
    my $uri = URI->new($path);
    for my $key ( keys %params ) {
        if ( ref $params{$key} eq 'ARRAY' ) {
            my $v = delete $params{$key};
            $params{$key} = join ',', @$v;
        }
    }
    $uri->query_form(%params);
    return $uri->as_string;
}

1;

__END__

=encoding utf8

=head1 NAME

WebService::Pornhub - Perl interface to the Pornhub.com API.

=head1 SYNOPSIS

    use WebService::Pornhub;
    
    my $pornhub = WebService::Pornhub->new;
    
    # Search videos from Pornhub API
    my $videos = $pornhub->search(
        search => 'hard',
        'tags[]' => ['asian', 'young'],
        thumbsizes => 'medium',
    );
    
    # Response is Array reference, Perl data structures
    for my $video (@$videos) {
        say $video->{title};
        say $video->{url};
    }


=head1 DESCRIPTION

WebService::Pornhub provides bindings for the Pornhub.com API. This module build with  role L<WebService::Client>.

=head1 METHODS

=head2 new

    my $pornhub = WebService::Pornhub->new(
        timeout => 20, # optional, defaults to 10
        logger => Log::Fast->new(...), # optinal, defaults to none
        log_method => 'DEBUG', #  optional, default to 'DEBUG'
    );

Prameters:

=over

=item *

timeout: (Optional) Integer. Defaults to C<10>

=item *

retries: (Optional) Integer. Defaults to C<0>

=item *

logger: (Optional) Log module instance, such modules as L<Log::Tiny>, L<Log::Fast>, etc.

=item *

log_method: (Optional) Text. Defaults to C<DEBUG>

=back


=head2 search

    my $videos = $pornhub->search(
        search => 'hard',
        'tags[]' => ['asian', 'young'],
        thumbsizes => 'medium',
    );

Parameters:

=over

=item *

category: (Optional)

=item *

page: (Optional) Integer

=item *

search: (Optional) Text

=item *

phrase[]: (Optional) Array. Used as pornstars filter.

=item *

tags[]: (Optional) Array

=item *

ordering: (Optional) Text. Possible values are featured, newest, mostviewed and rating

=item *

period: (Optional) Text. Only works with ordering parameter. Possible values are weekly, monthly, and alltime

=item *

thumbsize: (Required). Possible values are small,medium,large,small_hd,medium_hd,large_hd

=back


=head2 get_video

    my $video = $pornhub->get_video(
        id => '44bc40f3bc04f65b7a35',
        thumbsize => 'medium',
    );

Parameters:

=over

=item *

id: (Required) Integer

=item *

thumbsize: (Optional) If set, provides additional thumbnails in different formats. Possible values are small,medium,large,small_hd,medium_hd,large_hd

=back

=head2 get_embed_code

    my $embed = $pornhub->get_embed_code(
        id => '44bc40f3bc04f65b7a35',
    );

Parameters:

=over

=item *

id: (Required) Integer

=back


=head2 get_deleted_videos

    my $videos = $pornhub->get_deleted_videos(
        page => 3,
    );

Parameters:

=over

=item *

page: (Required) Integer

=back


=head2 is_video_active

    my $active = $pornhub->is_video_active(
        is => '44bc40f3bc04f65b7a35',
    );

Parameters:

=over

=item *

id: (Required) Integer

=back


=head2 get_categories

    my $categories = $pornhub->get_categories();

There are no parameters for this method.


=head2 get_tags

    my $tags = $pornhub->get_tags(
        list => 'a',
    );

Parameters:

=over

=item *

list: a-z for tag starting letter, 0 for other.

=back


=head2 get_stars

    my $stars = $pornhub->get_stars();

There are no parameters for this method.


=head2 get_stars_detailed

    my $stars = $pornhub->get_stars_detailed();

There are no parameters for this method.


=head1 SEE ALSO

=over

=item *

L<WebService::Client>

=item *

L<pornhub-api - npm|https://www.npmjs.com/package/pornhub-api>

=back


=head1 LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

Yusuke Wada <yusuke@kamawada.com>
