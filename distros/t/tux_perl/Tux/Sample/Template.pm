# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: Template.pm,v 1.2 2002/11/11 11:16:10 yaleh Exp $

package Tux::Sample::Template;

use strict;

use Tux;
use Tux::Constants qw/:event/;

my $html_content;

BEGIN{
  $html_content = << 'EOT';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
  <title>tux_perl Template</title>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="GENERATOR" content="Quanta Plus">
</head>
<body>
<h1>tux_perl Template</h1>
<hr>
Congratulation! Your tux_perl is working now!
</body>
</html>
EOT
}

sub handler{
  my($r)=@_;

 SWITCH:
  {
    ($r->event==0) && do{
      $r->event(1);
      $r->http_status(200);
      return $r->tux_print_header('Content-Type' => 'text/html');
    };

    ($r->event==1) && do{
      $r->event(2);
      return $r->tux_print($html_content);
    };

    ($r->event==2) && do{
      $r->event(TUX_EVENT_FINISH_REQ);
      return $r->tux_print_http_chunk_eof;
    };

  }
  return 0;
}

1;
