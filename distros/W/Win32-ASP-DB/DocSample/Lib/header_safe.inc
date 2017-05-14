<%@ LANGUAGE = PerlScript%>
<%
  BEGIN {
    unshift(@INC, "W:\\InetPub\\wwwroot\\DocSample\\Lib");
    $main::WEBROOT = '/DocSample';
  }

  use Win32::ASP::Extras;
  use Error qw/:try/;
%>


