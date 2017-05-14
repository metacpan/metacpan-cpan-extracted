<!--#include file ="Lib/header.inc"-->

<%
  $main::TheDB->retrieve_user_info() and
      Win32::ASP::Redirect(Win32::ASP::GetPassURL() || 'user_info.asp');
%>
<html>

<head>
<title></title>

</head>

<body>

<p>You failed to login for some reason.&nbsp; Sorry.</p>
<%
  my $user_info = Win32::ASP::Get('user_info');
  $Response->Write("Username: $user_info->{username}<BR>\n");
  $Response->Write("SQL Errors:<BR>\n".$main::TheDB->get_sql_errors());
%>
</body>
</html>
