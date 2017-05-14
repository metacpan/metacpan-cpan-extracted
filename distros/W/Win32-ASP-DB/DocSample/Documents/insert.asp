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
  $Document->insert;
  Win32::ASP::Redirect('Documents/view.asp', 'DocID' => $Document->{edit}->{DocID});
%>
</body>
</html>
