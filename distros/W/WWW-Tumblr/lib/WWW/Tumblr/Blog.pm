package WWW::Tumblr::Blog;
use Moose;
use Carp;
use Data::Dumper;
use JSON;

use WWW::Tumblr::API;
extends 'WWW::Tumblr';

has 'base_hostname', is => 'rw', isa => 'Str', required => 1;

tumblr_api_method info                  => [ 'GET',  'apikey' ];
tumblr_api_method avatar                => [ 'GET',  'none', undef, 'size' ];
tumblr_api_method likes                 => [ 'GET',  'apikey'];
tumblr_api_method followers             => [ 'GET',  'oauth' ];

tumblr_api_method posts                 => [ 'GET',  'apikey', undef, 'type' ];
tumblr_api_method posts_queue           => [ 'GET',  'oauth' ];
tumblr_api_method posts_draft           => [ 'GET',  'oauth' ];
tumblr_api_method posts_submission      => [ 'GET',  'oauth' ];

tumblr_api_method post_delete           => [ 'POST', 'oauth' ];

# posting methods!

my %post_required_params = (
    text        => 'body',
    photo       => { any => [qw(source data)] },
    quote       => 'quote',
    link        => 'url',
    chat        => 'conversation',
    audio       => { any => [qw(external_url data)] },
    video       => { any => [qw(embed data)] },
);

sub post {
    my $self = shift;
    my %args = @_;

    $self->_post( %args );
}

sub _post {
    my $self = shift;
    my %args = @_;

    my $subr = join('/', split( /_/, [ split '::', [ caller( 1 ) ]->[3] ]->[-1] ) );

    Carp::croak "no type specified when trying to post"
        unless $args{ type };

    # check for required params per type:

    if ( $post_required_params{ $args{ type } } ) {
        my $req = $post_required_params{ $args{ type } };
        if ( ref $req && ref $req eq 'HASH' && defined $req->{any} ) {
            Carp::croak "Trying to post type ".$args{type}." without any of: " .
                join( ' ', @{ $req->{any} } )
            if scalar( grep { $args{ $_ } } @{ $req->{any} } ) == 0;
        } else {
            Carp::croak "Trying to post type ".$args{type}." without: $req"
                unless defined $args{ $req };
        }
    }

    my $response = $self->_tumblr_api_request({
        auth => 'oauth',
        http_method => 'POST',
        url_path => 'blog/' . $self->base_hostname . '/' . $subr,
        extra_args => \%args,
    });

    if ( $response->is_success ) {
        return decode_json( $response->decoded_content)->{response};
    } else {
        $self->error( WWW::Tumblr::ResponseError->new(
            response => $response
        ));
        return
    }
}

sub post_edit {
    my $self = shift;
    my %args = @_;
    Carp::croak "no id specified when trying to edit a post!"
        unless $args{ id };

    $self->_post( %args );
}

sub post_reblog {
    my $self = shift;
    my %args = @_;

    Carp::croak "no id specified when trying to reblog a post!"
        unless $args{ id };
    Carp::croak "no reblog_key specified when trying to reblog a post!"
        unless $args{ reblog_key };

    # Reblog doesn't go through _post() as it doesn't need a type
    my $response = $self->_tumblr_api_request({
        auth => 'oauth',
        http_method => 'POST',
        url_path => 'blog/' . $self->base_hostname . '/post/reblog',
        extra_args => \%args,
    });

    if ( $response->is_success ) {
        return decode_json( $response->decoded_content)->{response};
    } else {
        $self->error( WWW::Tumblr::ResponseError->new(
            response => $response
        ));
        return;
    }
}

sub blog { Carp::croak "Unsupported" }

1;

=pod

=head1 NAME

WWW::Tumblr::Blog

=head1 SYNOPSIS

  my $blog = $t->blog('stuff.tumblr.com');
  # or the domain name:
  # my $blog = $t->blog('myblogontumblrandstuff.com');

  # as per http://www.tumblr.com/docs/en/api/v2#blog-info
  my $info = $blog->info;

  # as per http://www.tumblr.com/docs/en/api/v2#blog-likes
  my $likes = $blog->likes;
  my $likes = $blog->likes(
      limit => 5,
      offset => 10,
  );

  # as per http://www.tumblr.com/docs/en/api/v2#photo-posts
  my $posts = $blog->posts(
      type => 'photo',
      ... # etc
  );

  # Posting to the blog:

  # using the source param:
  my $post = $blog->post(
      type => 'photo',
      source => 'http://someserver.com/photo.jpg',
  );

  # using local files with the data param
  # which needs to be an array reference
  my $post = $blog->post(
      type => 'photo',
      data => [ '/home/david/larry.jpg' ],
  );

  # you can post multiple files, as per the Tumblr API:
  my $post = $blog->post(
      type => 'photo',
      data => [ '/file1.jpg', 'file2.jpg', ... ],
  );

  # if the result was false (empty list), then do something with the
  # error:
  do_something_with_the_error( $tumblr->error ) unless $post;
                                                       # or $likes
                                                       # or $info
                                                       # or anything else

  # Reblogging a post (photosets, text, anything):
  # First get the post you want to reblog to obtain its reblog_key
  my $source = $t->blog('someblog.tumblr.com');
  my $posts = $source->posts(limit => 1);
  my $original = $posts->{posts}[0];

  # Then reblog it to your blog:
  my $reblog = $blog->post_reblog(
      id         => $original->{id},
      reblog_key => $original->{reblog_key},
      comment    => 'Nice post!',  # optional
  );

=head1 CAVEATS

=over

=item *

I never really tried posting audios or videos.

=item *

B<Image format limitations:> This module uses Tumblr's legacy posting API which
only supports B<JPEG, PNG, and GIF> images. Formats like B<WebP are not supported>
by the legacy API. If you try to upload a webp file, you'll get:

  Error 400: Mime type "image/webp" not supported from file

This is a Tumblr API limitation, not a bug in this module. Tumblr's web interface
uses their newer NPF (Neue Post Format) which supports more formats. NPF support
would require significant changes to this module and is tracked as a future
enhancement. See L<https://www.tumblr.com/docs/npf> for NPF documentation.

=item *

B<Video uploads:> Direct video file uploads have similar limitations. The legacy
API primarily supports video via embed URLs (YouTube, Vimeo, etc.) rather than
direct file uploads.

=back

=head1 BUGS

Please refer to L<WWW::Tumblr>.

=head1 AUTHOR(S)

The same folks as L<WWW::Tumblr>.

=head1 SEE ALSO

L<WWW::Tumblr>, L<WWW::Tumblr::ResponseError>.

=head1 COPYRIGHT and LICENSE

Same as L<WWW::Tumblr>.

=cut
