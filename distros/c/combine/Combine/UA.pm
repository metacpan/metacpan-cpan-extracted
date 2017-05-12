# Copyright (c) 1996-1998 LUB NetLab
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 
# 
# 			    NO WARRANTY
# 
# BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
# FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
# OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
# PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
# OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
# TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
# PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
# REPAIR OR CORRECTION.
# 
# IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
# WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
# REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
# INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
# OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
# TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
# YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
# PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGES.
# 
# Copyright (c) 1996-1998 LUB NetLab

# $Id: UA.pm 257 2008-09-03 08:23:32Z anders $


# COMB/XWI/UA.pm - harvesting robots with XWI interface
# v0.01 by Yong Cao, 1997-08-08

package Combine::UA;

use strict;
use Combine::Config;
use LWP::UserAgent;
use HTTP::Date;

my $expGar;
my $userAgentGetIfModifiedSince;

sub TruncatingUserAgent {

  # This function returns an LWP::UserAgent that truncates incoming data
  # when a number of bytes, that's dictated by Combine's configuration set,
  # has been received.
  #
  # Experiments (1999-02-02) have shown that the truncation is approximate
  # in that the resulting document size may vary up or down a few percents
  # or kilobytes.

  my $ua = new LWP::UserAgent();
#  $ua->max_size(COMB::Config::GetMaxDocSize()); #Problem with webservers returning 206 partial content in a multipart
  $ua->timeout(Combine::Config::Get('UAtimeout'));
  $ua->agent("Combine/3 http://combine.it.lth.se/");
  $ua->from(Combine::Config::Get('Operator-Email'));
  $ua->default_header('Accept-Encoding' => 'gzip');
  if (Combine::Config::Get('httpProxy')) {
    $ua->proxy(['http', 'https'], Combine::Config::Get('httpProxy'));
  }
  $expGar = Combine::Config::Get('WaitIntervalExpirationGuaranteed');
  $userAgentGetIfModifiedSince = Combine::Config::Get('UserAgentGetIfModifiedSince');
  return $ua;
}


sub fetch { # use get-if-modified-since
    my ($xwi, $since) = @_;
    my ($url_str, $ua, $req, $resp, $code, $msg, $method, $type, $ext);
    $ua = TruncatingUserAgent();
#FIX!    $since = $jcf->ftime unless $since; 
    $since = time - $expGar unless $since;
    $url_str = $xwi->url;
    $type = ''; #FIX $jcf->typ;
    $method = "GET";
    if ( $type ) {
       $method = "HEAD" unless defined(${Combine::Config::Get('converters')}{$type});
    } else {
       if ( $url_str =~ m/\.([^\/\s\.]+)\s*$/ ) {
         $ext = $1;
	 $ext =~ tr/A-Z/a-z/;
         $method = "HEAD" if  defined(${Combine::Config::Get('binext')}{$ext});
       }
    }
    if ( $method eq "HEAD" ) {
      $req = new HTTP::Request 'HEAD'=> $url_str;
      $req->header('If-Modified-Since' => &time2str($since))
	if $userAgentGetIfModifiedSince;
      if (Combine::Config::Get('UserAgentFollowRedirects')) { $resp = $ua->request($req); }
      else { $resp = $ua->simple_request($req); }
      $code = $resp->code;
      $msg = $resp->message();
      $method = "";
      if ( $code eq "200" ) {
         $type = $resp->header("content-type");
         $method = "GET" if $type and defined(${Combine::Config::Get('converters')}{$type}); 
      }
    }
    if ( $method eq "GET" ) {
      $req = new HTTP::Request 'GET'=> $url_str;
      $req->header('If-Modified-Since' => &time2str($since))
	if $userAgentGetIfModifiedSince;
      if (Combine::Config::Get('UserAgentFollowRedirects')) { $resp = $ua->request($req); }
      else { $resp = $ua->simple_request($req); }
      $code = $resp->code;
      $msg = $resp->message();
#      print "$url_str; " . &time2str($since) ."; $code; $msg\n";
    }

    my @cs=$resp->header('Content-Type');
    foreach my $c (@cs) {
	$xwi->meta_add('content-type',$c);
    }

    $xwi->stat($code);
#BEHÖVS???    $xwi->url($url_str);
    $xwi->server($resp->header("server"));
    $xwi->etag($resp->header("etag"));
    my $t = $resp->content_type;
    $xwi->type($t);
    $t = $resp->content_language;
    if (defined($t)) {$xwi->meta_add('content-language',$t);}
    $xwi->length($resp->header("content-length"));
    $xwi->location($resp->header("location"));
    $xwi->base($resp->base);
#Numeric gives error message '... too small'
#    $xwi->expiryDate(&check_date($resp->expires));
    $xwi->modifiedDate(&check_date($resp->header("last-modified")));
    $xwi->expiryDate(&check_date($resp->header("expires")));
#?    $xwi->checkedDate(&check_date($resp->header("date")));
    $xwi->checkedDate(time) unless $xwi->checkedDate;
    if ($code eq "200" or $code eq "206") {
        if ( $method eq "GET" and length($resp->content_ref) > 0 ) {
	  $xwi->truncated($resp->headers()->header('X-Content-Range'));
        }
        if ($resp->decoded_content( 'ref' => 1 )) {
	  $xwi->content($resp->decoded_content( 'ref' => 1 ));
        } else {
          $xwi->content($resp->content_ref);
#CHECK if gzip encoded anyhow?
        }
    }
    return ($code, $msg); 
}

sub check_date { # makes sure the date is in a correct format (UnixTime)
   my ($str) = @_;
   my $tim = undef;
   if ( $str ) {
      eval { $tim = &str2time( $str ) };
      return $tim;
   }
}

1;
