package WWW::YouTube::Info;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(
  Exporter
);

our @EXPORT = qw(
);

our $VERSION = '0.05';

use Carp;
use Data::Dumper;
use LWP::Simple;

=head1 NAME

WWW::YouTube::Info - gain info on YouTube video by VIDEO_ID

=head1 SYNOPSIS

=head2 Perhaps a little code snippet?

  #!/usr/bin/perl
  
  use strict;
  use warnings;
  
  use WWW::YouTube::Info;
  
  # id taken from YouTube video URL
  my $id = 'foobar';
  
  my $yt = WWW::YouTube::Info->new($id);
  
  my $info = $yt->get_info();
  
  # hash reference holds values gained via http://youtube.com/get_video_info?video_id=foobar
  # $info->{title}          # e.g.: Foo+bar+-+%27Foobar%27
  # $info->{author}         # e.g.: foobar
  # $info->{keywords}       # e.g.: Foo%2Cbar%2CFoobar
  # $info->{length_seconds} # e.g.: 60
  # $info->{fmt_map}        # e.g.: 22%2F1280x720%2F9%2F0%2F115%2C35%2F854x480%2F9%2F0%2F115%2C34%2F640x360%2F9%2 ..
  # $info->{fmt_url_map}    # e.g.: 22%7Chttp%3A%2F%2Fv14.lscache1.c.youtube.com%2Fvideoplayback%3Fip%3D131.0.0.0 ..
  # $info->{fmt_stream_map} # e.g.: 22%7Chttp%3A%2F%2Fv14.lscache1.c.youtube.com%2Fvideoplayback%3Fip%3D131.0.0.0 ..
  # ..
  
  # Remark:
  # You might want to check $info->{status} before further workout,
  # as some videos have copyright issues indicated, for instance, by
  # $info->{status} ne 'ok'.

=head1 DESCRIPTION

I guess its pretty much self-explanatory ..

=head1 METHODS

=cut

sub new {
  my ($class, $id) = @_;

  my $self = {};
  $self->{_id} = $id || croak "no VIDEO_ID given!";
  bless($self, $class);

  return $self;
}

=head2 get_info

See synopsis for how/what/why. You might also want to use L<Data::Dumper> ..
Croaks if C<LWP::Simple::get> fails.

=cut

sub get_info {
  my ($self) = @_;

  my $id = $self->{_id};

  my $info_url = "http://youtube.com/get_video_info?video_id=$id";

  my $video_info = get($info_url)
    or croak "no get at $info_url - $!";

  my @info = split /&/, $video_info;

  for ( @info ) {
    my ($key, $value) = split /=/;
    $self->{info}->{$key} = $value;
  }

  return $self->{info};
}

1;

__END__

=head1 HINTS

Searching the internet regarding 'fmt_url_map' and/or 'get_video_info'
might gain hints/information to improve L<WWW::YouTube::Info>.

=head1 BUGS

Please report bugs and/or feature requests to
C<bug-WWW-YouTube-Info at rt.cpan.org>,
alternatively by means of the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-YouTube-Info>.

=head1 AUTHOR

east E<lt>east@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by east

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

