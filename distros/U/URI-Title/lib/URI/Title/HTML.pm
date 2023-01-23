package URI::Title::HTML;
$URI::Title::HTML::VERSION = '1.903';
use warnings;
use strict;
use HTML::Entities;
use utf8;

our $CAN_USE_ENCODE;
BEGIN {
  eval { require Encode; Encode->import('decode') };
  $CAN_USE_ENCODE = !$@;
}

sub types {(
  'text/html',
  'default',
)}

sub title {
  my ($class, $url, $data, $type, $cset) = @_;

  my $title;
  my $special_case;

  my $default_match = '<title.*?>(.+?)</title';

  # special case for the iTMS.
  if ( $INC{'URI/Title/iTMS.pm'} and $url =~ m!phobos.apple.com! and $data =~ m!(itms://[^']*)! ) {
    return URI::Title::iTMS->title($1);
  }

  # TODO - work this out from the headers of the HTML
  if ($data =~ /charset=\"?([\w-]+)/i) {
    $cset = lc($1);
  }

  if ( $CAN_USE_ENCODE ) {
    $data = eval { decode('utf-8', $data, 1) } ||  eval { decode($cset, $data, 1) } || $data;
  }

  my $found_title;

  if ($url) {
    if ($url =~ /use\.perl\.org\/~([^\/]+).*journal\/\d/i) {
      $special_case = '<FONT FACE="geneva,verdana,sans-serif" SIZE="1"><B>(.+?)<';
      $title = "use.perl journal of $1 - ";

    } elsif ($url =~ /(pants\.heddley\.com|dailychump\.org).*#(.*)$/i) {
      my $id = $2;
      $special_case = 'id="a'.$id.'.*?></a>(.+?)<';
      $title = "pants daily chump - ";

    } elsif ($url =~ /paste\.husk\.org/i) {
      $special_case = 'Summary: (.+?)<';
      $title = "paste - ";

    } elsif ($url =~ /twitter.com\/(.*?)\/status(es)?\/\d+/i) {
      $special_case = '<p class="js-tweet-text tweet-text">([^\<]+)';
      $title = "twitter - ";

    } elsif ($url =~ /independent\.co\.uk/i) {
      $special_case = '<h1 class=head1>(.+?)<';

    } elsif ($url =~ /www\.hs\.fi\/english\/article/i) {
      $special_case = '<h1>(.+?)</h1>';

    } elsif ($url =~ /google.com/i and $data =~ /calc_img/) {
      # google can be used as a calculator. Try to find the result.
      $special_case = 'calc_img.*<td nowrap>(.+?)</td';


    }
  }

  if (!$found_title and $special_case) {
    ($found_title) = $data =~ /$special_case/ims;
  }
  if (!$found_title) {
    ($found_title) = $data =~ /$default_match/ims;
  }
  return unless $found_title;

  $found_title =~ s/<sup>(.+?)<\/sup>/^$1/g; # for the google math output
  $found_title =~ s/<.*?>//g;
  $title .= $found_title;


  $title =~ s/\s+$//;
  $title =~ s/^\s+//;
  $title =~ s/\n+//g;
  $title =~ s/\s+/ /g;

  #use Devel::Peek;
  #Dump( $title );

  $title = decode_entities($title);

  #Dump( $title );

  # decode nasty number-encoded entities. Mostly works
  $title =~ s/(&\#(\d+);?)/chr($2)/eg;

  return $title;
}

1;

__END__

=for Pod::Coverage::TrustPod types title

=head1 NAME

URI::Title::HTML - get titles of html files

=head1 VERSION

version 1.903

=cut
