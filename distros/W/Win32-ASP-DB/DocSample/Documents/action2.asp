<!--#include file ="../Lib/header.inc"-->
<html>

<head>
<title></title>

</head>

<body>
<%
  use DocSample::Document;

  $Document = DocSample::Document->new;
  $Document->action_effect_from_asp;
%>

<%=$Document->action_disp_success%>

</body>
</html>
