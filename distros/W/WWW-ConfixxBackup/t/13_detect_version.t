#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use WWW::ConfixxBackup::Confixx;

my $content = do{ local $/, <DATA> };
my $obj     = WWW::ConfixxBackup::Confixx->new;
$obj->_detect_version( $content );

is $obj->confixx_version, 'confixx3.0';

__DATA__
<HTML>
<HEAD>
<META content="text/html; charset=ISO-8859-1" http-equiv=Content-Type>
<link rel="stylesheet" type="text/css" href="/skins/skin_1/style.css">
<link rel="stylesheet" type="text/css" href="/skins/skin_1/css/images.css"/>


<script>
loaded = false;
</script>
<script src="../../js/paged_form.js"></script>
</HEAD>

<BODY bgColor=#ffffff bottomMargin=0 leftMargin=0 topMargin=0 MARGINHEIGHT="0" MARGINWIDTH="0" onload="loaded=true;">
<br>
<script>
var canSubmit = 1;
function doChange( formIndex ){
	if(canSubmit){
		canSubmit = 0;
		if ( formIndex > 0 ) {
			document.forms[formIndex].submit();
		} else {
			document.forms[0].submit();
		}
	}else{
		//		alert ("Can't submit");
	}
}

 function goPrevPage(prevpage, formIndex){
	 if ( formIndex > 0 ) {
		 document.forms[formIndex].action = prevpage;
		 document.forms[formIndex].submit();
	 }else{
		 document.forms[0].action = prevpage;
		 document.forms[0].submit();
	 }
 }
</script>	

<fieldset ><legend >Backup</legend>
<form action="tools_backup2.php" method="post" name="form1" ><table class="InputTable" ><tr class="datacell" ><th >Status</th>
<th class="datalabel" >Quelle</th>
<th >Ziel</th>
<th >Datum</th>
<th >Grö&szlig;e</th>
<th align="center" ><input onclick="javascript:checkedAll('backup',this.checked,0)" name="selectAll" value="1" checked type="checkbox" >
</th></tr>
<tr class="datacell" ><td align="center" >inaktiv</td>

<td class="datalabel" >html</td>
<td >&nbsp;</td>
<td >Jan 02 17:32</td>
<td align="right" >1'596'486</td>
<td align="center" ><input name="backup[]" value="html" checked type="checkbox" >
</td></tr>
<tr class="datacell" ><td align="center" >inaktiv</td>
<td class="datalabel" >files</td>
<td >&nbsp;</td>
<td >Jan 02 17:32</td>
<td align="right" >56'647'536</td>

<td align="center" ><input name="backup[]" value="files" checked type="checkbox" >
</td></tr>
<tr class="datacell" ><td align="center" >inaktiv</td>
<td class="datalabel" >mysql</td>
<td >&nbsp;</td>
<td >Jan 02 17:32</td>
<td align="right" >121'668</td>
<td align="center" ><input name="backup[]" value="mysql" checked type="checkbox" >
</td></tr></table>
<table class="formArea" ><tr ><td ><table class="StdButton" border="0" cellspacing="0" cellpadding="0">
<tr >
<td  ><input type=image border=0 src="/skins/skin_1/pics/buttons/bt_img_left.gif" onclick="javascript:doChange(0); return false"></td>
<td  background="/skins/skin_1/pics/buttons/bt_img_middle.jpg"><a href="#" onclick="javascript:doChange(0); return false" class="button-1">Übernehmen</a></td>

<td  ><input type=image border=0 src="/skins/skin_1/pics/buttons/bt_changepass.gif" onclick="javascript:doChange(0); return false"></td>
</tr>
</table></td></tr></table>


<input name="action" value="backup" type="hidden" >


<input name="destination" value="/backup" type="hidden" ></form>
</fieldset><p></BODY>
</HTML>	