package WWW::YouTube::Info::Simple;

use 5.008;
use strict;
use warnings;

require Exporter;
require WWW::YouTube::Info;

our @ISA = qw(
  Exporter
  WWW::YouTube::Info
);

our @EXPORT = qw(
);

our $VERSION = '0.08';

use Carp;
use Data::Dumper;

=head1 NAME

WWW::YouTube::Info::Simple - simple interface to WWW::YouTube::Info

=head1 SYNOPSIS

=head2 Perhaps a little code snippet?

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use WWW::YouTube::Info::Simple;
  
  # id taken from YouTube video URL
  my $id = 'foobar';
  
  my $yt = WWW::YouTube::Info::Simple->new($id);
  
  # hash reference holds values gained via http://youtube.com/get_video_info?video_id=foobar
  my $info = $yt->get_info();
  # this is basically an inheritance to get_info() at WWW::YouTube::Info
  # $info->{title}          # e.g.: Foo+bar+-+%27Foobar%27
  # $info->{author}         # e.g.: foobar
  # $info->{keywords}       # e.g.: Foo%2Cbar%2CFoobar
  # $info->{length_seconds} # e.g.: 60
  # $info->{fmt_map}        # e.g.: 22%2F1280x720%2F9%2F0%2F115%2C35%2F854x480%2F9%2F0%2F115%2C34%2F640x360%2F9%2 ..
  # $info->{fmt_url_map}    # e.g.: 22%7Chttp%3A%2F%2Fv14.lscache1.c.youtube.com%2Fvideoplayback%3Fip%3D131.0.0.0 ..
  # $info->{fmt_stream_map} # e.g.: 22%7Chttp%3A%2F%2Fv14.lscache1.c.youtube.com%2Fvideoplayback%3Fip%3D131.0.0.0 ..
  
  # array reference holds values keywords
  my $keys = $yt->get_keywords();
  # $keys->[0] # e.g.: Foo
  # $keys->[1] # e.g.: bar
  # ..
  
  # hash reference holds values quality -> resolution
  my $res = $yt->get_resolution();
  # $res->{35} # e.g.: 854x480
  # $res->{22} # e.g.: 1280x720
  # ..
  
  # URL and masquerading decoded title
  my $title = $yt->get_title(); # e.g.: Foo bar - 'Foobar'
  
  # hash reference holds values quality -> url
  my $url = $yt->get_url();
  # $url->{35} e.g.: http://v14.lscache1.c.youtube.com/videoplayback?ip=131.0.0.0 ..
  # $url->{22} e.g.: http://v14.lscache1.c.youtube.com/videoplayback?ip=131.0.0.0 ..
  # ..
  
  # URL decoded RTMPE URL
  my $conn = $yt->get_conn(); # e.g.: rtmpe://cp59009.edgefcs.net/youtube?auth=daEcaboc8dvawbcbxazdobDcZajcDdgcfae ..
  
  # Remark:
  # You might want to check $info->{status} before further workout,
  # as some videos have copyright issues indicated, for instance, by
  # $info->{status} ne 'ok'.

=head1 DESCRIPTION

I guess its pretty much self-explanatory ..

=head1 METHODS

=cut

=head2 get_keywords

Returns undef if status ne 'ok'.
Croaks if not available.

=cut

sub get_keywords {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  my $keywords = $self->{info}->{'keywords'};
  croak "no keywords found!" unless $keywords;

  my @keywords_parts = split /%2C/, $keywords;
  foreach my $item ( @keywords_parts ) {
    next unless $item;
    $item = _url_decode($item);
    push @{$self->{keywords}}, $item;
  }

  return $self->{keywords};
}

=head2 get_resolution

Returns undef if status ne 'ok'.
Croaks if not available.

=cut

sub get_resolution {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  # quality and resolution
  my $fmt_map = $self->{info}->{'fmt_map'};
  unless ( $fmt_map ) {
    # fallback to fmt_list
    # as fmt_map doesnt't seem to be supported any more
    croak "no resolutions found!" unless $self->_fmt_list();
  }
  else {
    # process fmt_map
    my @fmt_map_parts = split /%2F9%2F0%2F115%2C/, $fmt_map;
    foreach my $item ( @fmt_map_parts ) {
      my ($quality, $resolution) = split /%2F/, $item;
      next unless $quality and $resolution;
      $self->{resolution}->{$quality} = $resolution;
    }
  }

  return $self->{resolution};
}

=head2 get_title

Returns undef if status ne 'ok'.
Croaks if not available.

=cut

sub get_title {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  my $title = $self->{info}->{'title'};
  croak "no title found!" unless $title;

  $title = _url_decode($title);
  $title =~ s/\+/ /g;
  $self->{title} = $title;

  return $self->{title};
}

=head2 get_url

Returns undef if status ne 'ok'.
Croaks if not available.

  use WWW::YouTube::Info::Simple;
  
  # id taken from YouTube video URL
  my $id = 'foobar';
  
  my $yt = WWW::YouTube::Info::Simple->new($id);
  
  # hash reference holds values quality -> url
  my $url = $yt->get_url();
  # $url->{35} e.g.: http://v14.lscache1.c.youtube.com/videoplayback?ip=131.0.0.0 ..
  # $url->{22} e.g.: http://v14.lscache1.c.youtube.com/videoplayback?ip=131.0.0.0 ..
  # ..

YouTube videos can be downloaded in given qualities by means of these URLs and the usual suspects (C<wget>, ..).

=cut

sub get_url {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  # quality and URL
  my $fmt_url_map = $self->{info}->{'fmt_url_map'};
  unless ( $fmt_url_map ) {
    # fallback to url_encoded_fmt_stream_map
    # as fmt_url_map doesnt't seem to be supported any more
    croak "no URLs found!" unless $self->_url_encoded_fmt_stream_map();
  }
  else {
    # process fmt_url_map
    my @fmt_url_map_parts = split /%2C/, $fmt_url_map;
    foreach my $item ( @fmt_url_map_parts ) {
      my ($quality, $url) = split /%7C/, $item;
      next unless $quality and $url;
      $url = _url_decode($url);
      $self->{url}->{$quality} = $url;
    }
  }

  return $self->{url};
}

=head2 get_conn

Returns undef if status ne 'ok'.
Croaks if not available.

  use WWW::YouTube::Info::Simple;
  
  # id taken from YouTube video URL
  my $id = 'foobar';
  
  my $yt = WWW::YouTube::Info::Simple->new($id);
  
  # URL decoded RTMPE URL
  my $conn = $yt->get_conn(); # e.g.: rtmpe://cp59009.edgefcs.net/youtube?auth=daEcaboc8dvawbcbxazdobDcZajcDdgcfae ..

A YouTube RTMPE stream can be accessed via this URL and downloaded by
means of the usual suspects (C<rtmpdump>, ..).
The URL looses its validity after approx. 30 seconds (experimental value).
Gathering a fresh RTMPE URL regarding the same VIDEO_ID and the
C<rtmpdump .. --resume> capability might circumvent this inconvenience.

=cut

sub get_conn {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  my $conn = $self->{info}->{'conn'};
  croak "no conn found!" unless $conn;

  $self->{conn} = _url_decode($conn);

  return $self->{conn};
}


sub _url_encoded_fmt_stream_map {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  # quality and URL
  my $url_encoded_fmt_stream_map = $self->{info}->{'url_encoded_fmt_stream_map'};
  return unless $url_encoded_fmt_stream_map;

  my @url_encoded_fmt_stream_map_parts = split /%2C/, $url_encoded_fmt_stream_map;
  foreach my $item ( @url_encoded_fmt_stream_map_parts ) {
    $item = _url_decode($item);
    (my $url = $item) =~ s/.*url=(.*)&fallback_host=.*/$1/;
    $url = _url_decode($url);
    (my $quality = $url) =~ s/.*&itag=(\d+)&.*/$1/;
    (my $signature = $item) =~ s/.*&sig=([\d\w.]+)&.*/$1/;
    next unless $quality and $url and $signature;
    $self->{url}->{$quality} = $url.'&signature='.$signature;
  }

  return $self->{url};
}

sub _fmt_list {
  my ($self) = @_;

  $self->get_info() unless exists($self->{info});
  return if ( $self->{info}->{status} ne 'ok' );

  # quality and resolution
  my $fmt_list = $self->{info}->{'fmt_list'};
  return unless $fmt_list;

  my @fmt_list_parts = split /%2C/, $fmt_list;
  foreach my $item ( @fmt_list_parts ) {
    my ($quality, $resolution, @rest) = split /%2F/, $item;
    next unless $quality and $resolution;
    $self->{resolution}->{$quality} = $resolution;
  }

  return $self->{resolution};
}

sub _url_encode {
  my $string = shift;

  # URLencode
  $string =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

  return $string;
}

sub _url_decode {
  my $string = shift;

  # URLdecode
  $string =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;

  return $string;
}

1;

__END__

=head1 SEE ALSO

You might want to have a look at the C<./examples> folder within this
distribution, or at L<WWW::YouTube::Info>.

=head1 HINTS

Searching the internet regarding 'fmt_url_map', 'url_encoded_fmt_stream_map'
and/or 'get_video_info' might gain hints/information to improve
L<WWW::YouTube::Info> and L<WWW::YouTube::Info::Simple> as well.

=head1 BUGS

Please report bugs and/or feature requests to
C<bug-WWW-YouTube-Info-Simple at rt.cpan.org>,
alternatively by means of the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-YouTube-Info-Simple>.

=head1 AUTHOR

east E<lt>east@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by east

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

