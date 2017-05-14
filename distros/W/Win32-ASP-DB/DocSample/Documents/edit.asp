<!--#include file ="../Lib/header.inc"-->
<html>

<head>
<title></title>

</head>

<body>
<%
  use DocSample::Document;

  my $docid = $Request->querystring('DocID')->item;

  $Document = DocSample::Document->new;
  $Document->read_deep($docid);
  $Document->edit;
  $data = 'edit';
  $viewtype = 'edit';
%>

<form NAME="Document" METHOD="POST" ACTION="update.asp">
<!--#include file ="edit.inc"-->

</body>
</html>
