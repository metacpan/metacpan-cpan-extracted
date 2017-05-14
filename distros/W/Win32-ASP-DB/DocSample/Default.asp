<!--#include file ="Lib/header_safe.inc"-->
<%
  my $passurl = Win32::ASP::GetPassURL();
  if ($passurl) {
    $Session->{passurl} = $passurl;
    Win32::ASP::Redirect('Default.asp');
  } else {
    $passurl = $Session->{passurl};
    $Session->{passurl} = '';
    my %params;
    $passurl and $params{passurl} = $passurl;
    $destination = Win32::ASP::FormatURL('login.asp', %params);
  }
%>
<html>

<head>
<title>DocSample Database</title>

</head>

<frameset rows="70,10*">
  <frame name="banner" scrolling="no" target="contents" src="topBanner.htm">
  <frameset cols="167,10*">
    <frame name="contents" target="main" src="menu.htm" scrolling="auto">
    <frame name="main" src="<%="$destination"%>" scrolling="auto">
  </frameset>
  <noframes>
  <body>
  <p>This page uses frames, but your browser doesn't support them.</p>
  </body>
  </noframes>
</frameset>
</html>
