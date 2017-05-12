package WWW::Vimeo::Download;
use Moose;
use HTTP::Tiny;
#use HTTP::Request;
#use Perl6::Form;
use utf8;

our $VERSION = '0.06';
my $VER = $VERSION;

has video_id => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has download_url => (
    is  => 'rw',
    isa => 'Str',
);

has [
    qw/caption width height duration thumbnail totalComments totalLikes totalPlays url_clean url uploader_url uploader_portrait uploader_display_name nodeId isHD privacy isPrivate isPassword isNobody embed_code filename nfo filename_nfo/
  ] => (
    is  => 'rw',
    isa => 'Any',
  );

has browser => (
    is      => 'ro',
#   isa     => 'LWP::UserAgent',
    default => sub {
        my $ua = HTTP::Tiny->new(
          agent => 'Mozilla/5.0 (X11; Windux x86_64; rv:21.0) Gecko/20100101 Firefox/20.0'
        );
        return $ua;
    },
);

has res => (    #browser response
    is  => 'rw',
    isa => 'Any',
);

has target_dir => (
    is      => 'rw',
    isa     => 'Str',
    default => './',
);

sub load_video {
    my ( $self, $video_id_or_url ) = @_;
    if ( defined $video_id_or_url ) {
        if ( $video_id_or_url =~ m{http://www\.vimeo\.com/([^/]+)}i || $video_id_or_url =~ m{http://vimeo\.com/([^/]+)}i) {
            $self->video_id($1);
        }
        elsif ( $video_id_or_url =~
            m{http://vimeo.com/groups/([^/]+)/videos/([^/]+)}i )
        {
            $self->video_id($2);
        }
        else {
            $self->video_id($video_id_or_url);
        }
        $self->set_download_url();
    }
    else {
        warn "Example usage: \$self->load_video( 'VIMEO_VIDEO_ID' ) "
          and return 0;
    }
}

sub download {
    my ( $self, $args ) = @_;
    warn
"Please set a video url first. ex: \$vimeo->load_video( 'http://www.vimeo.com/27855315' ) "
      and return
      if !$self->download_url;
    $self->res( $self->browser->get( $self->download_url ) );
    if ( defined $self->res and $self->res->{success} ) {
        if ( !exists $args->{filename} ) {
           #$self->prepare_nfo;
           #$self->save_nfo;
            $self->save_video( $self->res->{content} );
        }
        else {
            $self->save_video( $self->res->{content}, $args );
        }
    }
}

sub save_video {
    my ( $self, $video_data, $args ) = @_;
    my $filename;
    if ( !exists $args->{filename} ) {
        $filename =
          $self->filename( $self->target_dir . '/' . $self->filename . '.mp4' );
    }
    else {
        $filename =
          $self->filename( $self->target_dir . '/' . $args->{filename} );
    }
    open FH, ">$filename";
    print FH $video_data;
    close FH;
}

sub save_nfo {
    my ($self) = @_;
    $self->filename_nfo( $self->target_dir . '/' . $self->filename . '.nfo' );
    my $filename = $self->filename_nfo;
    open FH, ">$filename";
    print FH $self->nfo;
    close FH;
}

sub prepare_nfo {
    my ($self) = @_;

#   my $info = form
#   "===============================================================================",
#   "--[ WWW::Vimeo::Download ]-----------------------------------------------------",
#   "                                                                               ",
#   "  {||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||} ",
#         "[" . $self->caption . "]",
#   "                                                                               ",
#   "  .............Title: {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} ",
#         $self->caption,
#   "  .........Video Url: {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} ",
#         $self->url,
#   "  ............Author: {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} ",
#         $self->uploader_display_name,
#   "  ........Author Url: {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} ",
#         $self->uploader_url,
#   "                                                                               ",
#   "                                [ REVIEW ]                                     ",
#   "                                                                               ",
#   "  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} ",
#         $self->thumbnail,
#   "                                                                               ",
#   "---------------------------------------------------[ version $VER by HERNAN ]--",
#   "==============================================================================="
#     ,;
#   $self->nfo($info);
}

sub title_to_filename {
    my ( $self, $title ) = @_;
    $title =~ s/\W/-/ig;
    $title =~ s/-{2,}/-/ig;
    $title =~ s/^-|-$//ig;
    $title =~
tr/àáâãäçèéêëìíîïñòóôõöùúûüýÿÀÁÂÃÄÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ/aaaaaceeeeiiiinooooouuuuyyAAAAACEEEEIIIINOOOOOUUUUY/;
    return $title;
}

sub set_download_url {
    my ($self) = @_;

    my $res = $self->browser->get( 'http://www.vimeo.com/' . $self->video_id );
    my ( $signature ) = $res->{content} =~ m/"signature":"([^"]+)"/g;
    my ( $timestamp ) = $res->{content} =~ m/"timestamp":(\d+)/g;
    my ( $caption )   = $res->{content} =~ m/meta property="og:title" content="([^"]+)"/g;
    $self->caption( $caption );
    $self->filename( $self->title_to_filename( $caption ) ); #default filename
    my ( $is_hd )     = $res->{content} =~ m/meta itemprop="videoQuality" content="(HD)"/g;
    $is_hd = 'sd' if ! $is_hd;
    $is_hd = lc $is_hd;

    my $video_id      = $self->video_id;
    my $url_download  = "http://player.vimeo.com/play_redirect?clip_id=${video_id}&sig=${signature}&time=${timestamp}&quality=${is_hd}&codecs=H264,VP8,VP6&type=moogaloop_local&embed_location=";

    $self->download_url( $url_download );
}

=head1 NAME

    WWW::Vimeo::Download - interface to download vimeo videos

=head1 SYNOPSIS

    use WWW::Vimeo::Download;
    my $vimeo = WWW::Vimeo::Download->new();
    $vimeo->load_video( 'XYZ__ID_VIDEO' );        #REQ videoid or video url
    $vimeo->target_dir( '/home/catalyst/tmp/' );  #OPTIONAL target dir
    $vimeo->download();                           #start download
    $vimeo->download( { filename =>'file.mp4'} ); #start download custom filename
    print $vimeo->download_url;                   #print the url for download

=head1 DESCRIPTION


=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    hernanlopes < @t > gmail
    https://github.com/hernan604

=head1 COPYRIGHT

    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

    The full text of the license can be found in the
    LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;

