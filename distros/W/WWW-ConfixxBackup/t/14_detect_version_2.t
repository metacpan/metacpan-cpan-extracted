#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use WWW::ConfixxBackup::Confixx;

my $content = do{ local $/, <DATA> };
my $obj     = WWW::ConfixxBackup::Confixx->new;
$obj->_detect_version( $content );

is $obj->confixx_version, 'confixx2.0';

__DATA__
<HTML>
<HEAD>
<META content="text/html; charset=iso-8859-1" http-equiv=Content-Type>
<LINK href="/skins/skin_1/style.css" rel=stylesheet type=text/css>
</HEAD>

<BODY bgColor=#ffffff bottomMargin=0 leftMargin=0 topMargin=0 MARGINHEIGHT="0" MARGINWIDTH="0">
<br><script>
function doChange(){
  document.forms[0].submit();
}
</script>
<table class="tblbgcolor" align="left" border="1" cellpadding="3" cellspacing="0" 
       bordercolorlight="#CCCCCC" bordercolordark="#FFFFFF">

<form method="post" action="tools_backup2.php">
  <input type="hidden" name="backup_id" value="">
  <input type="hidden" name="backup_html" value="">

  <input type="hidden" name="backup_files" value="">
  <input type="hidden" name="backup_mysql" value="">

  <tr> 
    <td>html</td>
    <td> 
      <input type=checkbox checked name=html value="1"  >
    </td>
  </tr>
  <tr> 
    <td>files</td>

    <td> 
      <input type=checkbox checked name=files value="1"  >
    </td>
  </tr>
  <tr> 
    <td>mysql</td>
    <td> 
      <input type=checkbox checked name=mysql value="1"  >
    </td>
  </tr>

  <tr> 
    <td colspan=2><table cellpadding="0" cellspacing="0" border="0">
<tr>
<td><input type=image border=0 src="/skins/skin_1/pics/buttons/bt_img_left.gif" onclick="javascript:doChange(); return false"></td>
<td background="/skins/skin_1/pics/buttons/bt_img_middle.jpg"><a href="javascript:doChange()" class="button-1">Abschicken</a></td>
<td><input type=image border=0 src="/skins/skin_1/pics/buttons/bt_changepass.gif" onclick="javascript:doChange(); return false"></td>
</tr>
</table></td>
  </tr>
</form>

</TABLE>
</BODY>
</HTML>