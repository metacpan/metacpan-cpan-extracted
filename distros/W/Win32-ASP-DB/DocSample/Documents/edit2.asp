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
  $Document->edit;
  $data = 'edit';
  $viewtype = 'edit';
%>

<form NAME="Document" METHOD="POST" ACTION="update.asp">
<!--#include file ="edit.inc"-->

</body>
</html>
