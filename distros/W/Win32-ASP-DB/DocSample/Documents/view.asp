<!--#include file ="../Lib/header.inc"-->
<html>

<head>
<title></title>

</head>

<body>
<%
  use DocSample::Document;

  my $docid = $Request->querystring('docid')->item;

  $Document = DocSample::Document->new;
  $Document->read_deep($docid);
  $data = 'orig';
  $viewtype = 'view';
%>
<!--#include file ="document.inc"-->
<p>

<b>Actions:</b>&nbsp;
<%=$Document->action_disp_all_triggers%>
<p>

<%=Win32::ASP::StampPage()%>
</body>
</html>
