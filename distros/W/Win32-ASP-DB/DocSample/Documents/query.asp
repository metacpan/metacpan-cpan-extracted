<!--#include file ="../Lib/header.inc"-->
<html>

<head>
<title></title>

</head>

<body>
<%
  use DocSample::DocumentGroup;

  my $title = $Request->querystring('title')->item;
  $title and $Response->Write("$title<P>");

  my $ref2constraints = {Win32::ASP::DBRecordGroup::get_QS_constraints};
  my $order = $Request->querystring('order')->item || 'DocID';
  my $columns = $Request->querystring('columns')->item;
  $columns and $columns = ",$columns";
  $columns = "Title".$columns;

  $DocumentGroup = DocSample::DocumentGroup->new;
  $DocumentGroup->query($ref2constraints, $order, "DocID,$columns");
  $Response->Write($DocumentGroup->gen_table("DocID_Active,$columns", 'orig', 'view'));
%>
<p>
<%=Win32::ASP::StampPage()%>
</body>
</html>
