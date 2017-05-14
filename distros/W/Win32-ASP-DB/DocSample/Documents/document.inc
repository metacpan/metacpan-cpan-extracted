<table border="1" style="border: medium none" cellpadding="3" bordercolordark="#000000" bordercolorlight="#000000">
  <tr>
    <td nowrap style="border: medium none">Doc ID:</td>
    <td nowrap><%=$Document->field('DocID', $data , $viewtype)%></td>
    <td nowrap width="20"><%=''%></td>
    <td nowrap style="border: medium none">Category:</td>
    <td nowrap><%=$Document->field('Category', $data , $viewtype)%></td>
  </tr>
  <tr>
    <td nowrap colspan="5" height="10"></td>
  </tr>
  <tr>
    <td nowrap style="border: medium none">Title:</td>
    <td colspan="4"><%=$Document->field('Title', $data , $viewtype)%></td>
  </tr>
  <tr>
    <td nowrap colspan="5" height="10"></td>
  </tr>
  <tr>
    <td nowrap style="border: medium none">Author:</td>
    <td nowrap><%=$Document->field('Author', $data, $viewtype)%></td>
    <td nowrap width="20"><%=''%></td>
    <td nowrap style="border: medium none">Create Time:</td>
    <td nowrap><%=$Document->field('CreateTS', $data , $viewtype)%></td>
  </tr>
  <tr>
    <td nowrap style="border: medium none">Last Editor:</td>
    <td nowrap><%=$Document->field('LastEditor', $data , $viewtype)%></td>
    <td nowrap width="20"><%=''%></td>
    <td nowrap style="border: medium none">Last Edit Time:</td>
    <td nowrap><%=$Document->field('LastEditTS', $data , $viewtype)%></td>
  </tr>
  <tr>
    <td nowrap colspan="5" height="10"></td>
  </tr>
  <tr>
    <td nowrap style="border: medium none">Hidden:</td>
    <td nowrap><%=$Document->field('Hidden', $data , $viewtype)%></td>
    <td nowrap width="20"><%=''%></td>
    <td nowrap style="border: medium none">Locked:</td>
    <td nowrap><%=$Document->field('Locked', $data , $viewtype)%></td>
  </tr>
  <tr>
    <td nowrap colspan="5" style="border: medium none"><%=$Document->gen_docentries_table($data, $viewtype)%></td>
  </tr>
  <tr>
    <td nowrap colspan="5" style="border: medium none"><%
if ($viewtype eq 'edit') {
  my $url = $Request->ServerVariables('URL')->item;
  $url =~ s/^.*\///;
  $url =~ s/2?\.asp$//;
  $Response->Write(<<ENDHTML);
<INPUT TYPE="BUTTON" VALUE="Get More Blank Legs" ONCLICK="this.form.action='${url}2.asp'; this.form.submit();"
onMouseOver="window.status='Click this button if you need more entry spaces.  It will give you at least two empty spaces.';return true;" onMouseOut="window.status='';return true;">
ENDHTML
}
%></td>
  </tr>

</table>
