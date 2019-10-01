package URI::Title::MP3;
$URI::Title::MP3::VERSION = '1.902';
use warnings;
use strict;

use MP3::Info;
use File::Temp qw(tempfile);

sub types {(
  'audio/mp3',
)}

sub _get_tag {
  my $data = shift;
  my (undef, $temp) = tempfile();
  open FILE, ">$temp" or die $!;
  print FILE $data;
  close FILE;
  my $tag = get_mp3tag($temp);
  if ($tag) {
    my $info = get_mp3info($temp);
    $tag->{info} = $info;
  }
  unlink($temp);
  return $tag;
}

sub title {
  my ($class, $url, $data, $type) = @_;
  my $tag;
  if (-f $url) {
    $tag = get_mp3tag($url);
    if ($tag) {
      my $info = get_mp3info($url);
      $tag->{info} = $info;
    }

  } else {
    $tag = _get_tag( $data . URI::Title::_get_end($url) );
  }
  return unless $tag;
  return unless ($tag->{ARTIST} or $tag->{TITLE});
  
  $tag->{ARTIST} ||= "Unknown Artist";
  $tag->{TITLE} ||= "Unknown Title";
  my $title = "$tag->{ARTIST} - $tag->{TITLE}";

  if (my $total = $tag->{info}{SECS} and -f $url) {
    my $m = $total / 60;
    my $s = $total % 60;
    $title .= sprintf(" (%d:%02d)", $m, $s);
  }

  return $title;
}

1;

__END__

=for Pod::Coverage::TrustPod types title

=head1 NAME

URI::Title::MP3 - get titles of MP3 files

=head1 VERSION

version 1.902

=cut
