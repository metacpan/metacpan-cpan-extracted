<!--#include file ="../Lib/header.inc"-->
<html>

<head>
<title></title>

</head>

<body>
<%
  use DocSample::Document;

  $Document = DocSample::Document->new;
  $Document->post;
  $Document->update;
  Win32::ASP::Redirect('Documents/view.asp', docid => $Document->{edit}->{DocID});
%>

</body>
</html>
