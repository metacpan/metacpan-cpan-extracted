# -*- mode: perl; coding: utf-8 -*-

package WWW::NicoVideo::URL;

use strict;
use warnings;
use Carp;
use URI;
use URI::Escape;
use base qw[Exporter];

our @EXPORT = qw[nicoURL];

our %NICO_URL = (top => "http://www.nicovideo.jp/",
		 base => "http://www.nicovideo.jp/",
		 recent => "http://www.nicovideo.jp/recent",
		 newarrival => "http://www.nicovideo.jp/newarrival",
		 img => "http://res.nicovideo.jp/img/tpl/head/logo/rc.gif",
		 login => "https://secure.nicovideo.jp/secure/login?site=niconico",
		 fmt => "http://www.nicovideo.jp/%s/%s");

sub nicoURL
{
  my $type = shift;
  my @keys = @_;

  $type = "top" if(!$type and !@keys);

  if(defined $type and @keys) {
    my $keys = join " ", @keys;
    utf8::encode($keys) if(utf8::is_utf8($keys));
    return new URI(sprintf($NICO_URL{fmt}, $type, uri_escape($keys)));
  } elsif(defined $type and defined $NICO_URL{$type}) {
    return new URI($NICO_URL{$type});
  } else {
    confess "Invalid type: $type (keys = @keys)";
  }
}

"Ritsuko";
