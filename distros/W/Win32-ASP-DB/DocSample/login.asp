<!--#include file ="Lib/header_safe.inc"-->
<%
  unless (Win32::ASP::Get('user_info')) {
    my $auth_username = uc($Request->ServerVariables('REMOTE_USER')->item);
    $auth_username =~ s/^.*\\//;
    my $user_info = { username => $auth_username };

    Win32::ASP::Set('user_info', $user_info);
    $Session->{Timeout} = 30;
  }
  Win32::ASP::Redirect('login2.asp', Win32::ASP::PassURLPair());
%>
<html>

<head>
<title></title>

</head>

<body>
</body>
</html>
