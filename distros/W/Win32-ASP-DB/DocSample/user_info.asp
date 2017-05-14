<!--#include file ="Lib/header.inc"-->
<html>

<head>
<title>User Information</title>

</head>

<body>

<p>You have been successfully logged in.&nbsp; Your properties are:</p>

<table border="0">
  <tr>
    <td>Property</td>
    <td>Value</td>
  </tr>
<%
  my $user_info = Win32::ASP::Get('user_info');
  foreach my $i (sort keys %{$user_info}) {
    $Response->Write(<<ENDSTR);
  <tr>
    <td>$i</td>
    <td>$user_info->{$i}</td>
  </tr>
ENDSTR
  }
%>
</table>
</body>
</html>
