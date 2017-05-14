<!--#include file ="../Lib/header.inc"-->
<html>

<head>
<title></title>

</head>

<body>
<%
  use DocSample::Document;

  $Document = DocSample::Document->new;
  $Document->init;
  $Document->edit;
  $data = 'edit';
  $viewtype = 'edit';
%>
<form NAME="Document" METHOD="POST" ACTION="insert.asp">
<!--#include file ="edit.inc"-->
</body>
</html>
