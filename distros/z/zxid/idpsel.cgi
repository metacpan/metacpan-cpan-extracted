#!/bin/sh
echo Content-Type: text/html
echo

cat <<HTML
<html><head><title>ZXID SP SSO: Choose IdP</title></head>
<body alink="#ffffff" bgcolor="#330033" link="#ffddff" text="#ffaaff" vlink="#aa44aa">

<font face="sans"></font><h1><font face="sans">IdP Selection (custome page for strong)</font></h1>

<form method="get" action="https://sp1.zxidsp.org:5443/protected/saml">
<font face="sans"><input name="o" value="G" type="hidden"></font>

Destination: $QUERY_STRING

<h3><font face="sans">Login Using Known IdP</font></h3>
<select name="d">
<option value="http://idp.ssocircle.com"> http://idp.ssocircle.com 
</option><option value="http://auth.orange.fr"> http://auth.orange.fr 
</option><option value="http://auth-int.orange.fr"> http://auth-int.orange.fr 
</option><option value="https://s-idp.liberty-iop.org:8881/idp.xml"> https://s-idp.liberty-iop.org:8881/idp.xml 
</option><option value="https://idp.symdemo.com:8880/idp.xml"> https://idp.symdemo.com:8880/idp.xml 
</option></select><font face="sans"><input name="l0" value=" Login " type="submit">

<h3><font face="sans">Login Using New IdP</font></h3>
<font face="sans"><i>A new IdP is one whose metadata we do not have
yet. We need to know the IdP URL (aka Entity ID) in order to fetch the
metadata using the well known location method. You will need to ask the
adminstrator of the IdP to tell you what the EntityID is.</i>
</font><p><font face="sans">IdP URL <input name="e" size="80"><input name="l0" value=" Login " type="submit"><br>
Entity ID of this SP (click on the link to fetch the SP metadata): <a href="https://sp1.zxidsp.org:5443/protected/saml?o=B">https://sp1.zxidsp.org:5443/protected/saml?o=B</a><br></font></p>

<input name="fr" value="$QUERY_STRING" type="hidden">
<input name="fc" value="1" type="hidden">
<input name="fn" value="prstnt" type="hidden">
<input name="fq" value="" type="hidden">
<input name="fy" value="" type="hidden">
<input name="fa" value="urn:oasis:names:tc:SAML:2.0:ac:classes:Strong" type="hidden">
<input name="fm" value="" type="hidden">
<input name="fp" value="0" type="hidden">
<input name="ff" value="0" type="hidden">
<!-- ZXID built-in defaults, see IDP_SEL_TECH_SITE in zxidconf.h --><input name="fr" value="" type="hidden"></font><hr><font face="sans"><a href="http://zxid.org/">zxid.org</a>, 0.27 1221659482 libzxid (zxid.org)<!-- EOF --->
</form></body></html>

HTML