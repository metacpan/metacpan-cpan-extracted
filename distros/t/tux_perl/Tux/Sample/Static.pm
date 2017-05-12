# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: Static.pm,v 1.2 2002/11/11 11:16:08 yaleh Exp $

package Tux::Sample::Static;

use strict;
use Tux;
use Tux::Constants qw/:all/;

my $data;
my $data_len;

BEGIN{
  $data="HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nTransfer-Encoding: chunked\r\n\r\n";
  $data.=Tux->http_chunk(<< 'EOT'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
  <title>Static Content for tux_perl</title>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Quanta Plus">
</head>
<body>
<h1>Static Content for tux_perl</h1>
<hr>
Congratulation! Your tux_perl is working now!
</body>
</html>
EOT
			);
  $data.=Tux->http_chunk_eof;

  $data_len=length($data);
}

sub handler{
  my($r)=@_;

  $r->event(TUX_EVENT_FINISH_REQ);
  $r->http_status(200);
  $r->object_addr($data,$data_len);
  return $r->tux(TUX_ACTION_SEND_BUFFER);
}

1;
