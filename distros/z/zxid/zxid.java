// zxid.java  -  Java CGI script that calls libzxid using JNI
// Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
// Author: Sampo Kellomaki (sampo@iki.fi)
// This is confidential unpublished proprietary source code of the author.
// NO WARRANTY, not even implied warranties. Contains trade secrets.
// Distribution prohibited unless authorized in writing.
// Licensed under Apache License 2.0, see file COPYING.
// $Id: zxid.java,v 1.13 2009-11-29 12:23:06 sampo Exp $
// 12.1.2007, created --Sampo

import zxidjava.*;

public class zxid {
  static { System.loadLibrary("zxidjni"); }

  public static void main(String argv[]) throws java.io.IOException
  {
      int ret;
      zx_str rets;
      zxid_conf cf;
      System.err.print("Start...\n");
      
      cf = zxidjni.new_conf("/var/zxid/");
      String url = "https://sp1.zxidsp.org:8443/zxid-java.sh";
      String cdc_url = "https://sp1.zxidcommon.org:8443/zxid-java.sh";
      zxidjni.url_set(cf, url);
      zxidjni.set_opt(cf, 1, 1);

      String qs = System.getenv("QUERY_STRING");  // Deprecation warnings about this are bogus and indicative of Java designer's disregard of their user base - indeed disconnect from reality, see http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4199068
      zxid_cgi cgi = zxidjni.new_cgi(cf, qs);
      char op = cgi.getOp();

      if (op == 'P') {
	  int len = Integer.parseInt(System.getenv("CONTENT_LENGTH"));
	  byte[] b = new byte[len];
	  int got = System.in.read(b, 0, len);
	  qs = new String(b, 0, got);
	  System.err.print("post\n");
	  zxidjni.parse_cgi(cgi, qs);
	  op = cgi.getOp();
      }
      
      if (op == 0)
	  op = 'M';

      zxid_ses ses;
      String sid = cgi.getSid();
      if (sid != null && sid.length() > 0) {
	  ses = zxidjni.fetch_ses(cf, sid);
	  if (ses != null) {
	      if (mgmt_screen(cf, cgi, ses, op) != 0)
		  System.exit(0);
	  }
      }
      ses = zxidjni.fetch_ses(cf, "");  // Just allocate an empty one

      System.err.println("Not logged in case op="+op+" qs:"+qs);

      switch (op) {
      case 'M':       // Invoke LECP or redirect to CDC reader.
	  //if (zxidjni.lecp_check(cf, cgi) != 0) System.exit(0);
	  System.out.print("Location: " + cdc_url + "?o=C\r\n\r\n");
	  System.exit(0);
      case 'C':  // CDC Read: Common Domain Cookie Reader
	  zxidjni.cdc_read(cf, cgi);
	  System.exit(0);
      case 'E':  // Return from CDC read, or start here to by-pass CDC read.
	  //if (zxidjni.lecp_check(cf, cgi) != 0) System.exit(0);
	  if (zxidjni.cdc_check(cf, cgi) != 0)
	      System.exit(0);
	  break;
      case 'L':
	  System.err.print("Start login\n");
	  url = zxidjni.start_sso_url(cf, cgi).getS();
	  if (url.length() > 0) {
	      System.err.print("login redir\n");
	      System.out.print("Location: " + url + "\r\n\r\n");
	      System.exit(0);
	  }
	  System.err.print("Login trouble");
	  break;
      case 'A':
	  ret = zxidjni.sp_deref_art(cf, cgi, ses);
	  System.err.println("deref art ret="+ret);
	  if (ret == zxidjniConstants.ZXID_REDIR_OK)
	      System.exit(0);
	  if (ret == zxidjniConstants.ZXID_SSO_OK)
	      if (mgmt_screen(cf, cgi, ses, op) != 0)
		  System.exit(0);
	  break;
      case 'P':
	  // *** broken with newer swig generated -noproxy code
	  rets = zxidjni.sp_dispatch(cf, cgi, ses);
	  System.err.println("saml_resp ret=" + rets);
	  if (rets.getS() == "O")
	      System.exit(0);
	  if (rets.getS() == "K")
	      if (mgmt_screen(cf, cgi, ses, op) != 0)
		  System.exit(0);
	  break;
      case 'Q':
	  rets = zxidjni.sp_dispatch(cf, cgi, ses);
	  if (rets.getS() == "O")
	      System.exit(0);
	  if (rets.getS() == "K")
	      if (mgmt_screen(cf, cgi, ses, op) != 0)
		  System.exit(0);
	  break;
      case 'B':
	  System.out.print("CONTENT-TYPE: text/xml\r\n\r\n");
	  String md = zxidjni.sp_meta(cf, cgi).getS();
	  System.out.print(md);
	  System.exit(0);
      default:
	  System.err.println("Unknown op="+op);
      }

      System.out.print("CONTENT-TYPE: text/html\r\n\r\n");


      System.out.print("<title>ZXID SP Java SSO</title>\n");
      System.out.print("<link rel=\"shortcut icon\" href=\"/favicon.ico\" type=\"image/x-icon\" />\n");
      System.out.print("<body bgcolor=\"#330033\" text=\"#ffaaff\" link=\"#ffddff\" vlink=\"#aa44aa\" alink=\"#ffffff\">\n");
      System.out.print("<font face=sans><h1>ZXID SP Java Federated SSO (user NOT logged in, no session.)</h1><pre>\n");
      System.out.print("</pre><form method=post action=\"zxid-java.sh?o=P\">\n");
      
      System.out.print("<h3>Login Using New IdP</h3>\n");
      
      System.out.print("<i>A new IdP is one whose metadata we do not have yet. We need to know\n");
      System.out.print("the Entity ID in order to fetch the metadata using the well known\n");
      System.out.print("location method. You will need to ask the adminstrator of the IdP to\n");
      System.out.print("tell you what the EntityID is.</i>\n");
      
      System.out.print("<p>IdP EntityID URL <input name=e size=100>\n");
      System.out.print("<input type=submit name=l1 value=\" Login (SAML20:Artifact) \">\n");
      System.out.print("<input type=submit name=l2 value=\" Login (SAML20:POST) \">\n");

      zxid_entity idp = zxidjni.load_cot_cache(cf);
      if (idp != null) {
	  System.out.print("<h3>Login Using Known IdP</h3>\n");
	  while (idp != null) {
	      String eid = idp.getEid();
	      int eid_len = idp.getEid_len();
	      //eid = substr($eid, 0, $eid_len);
	      //warn "eid_len($eid_len) eid($eid)";
	      System.out.print("<input type=submit name=\"l1" + eid + "\" value=\" Login to " + eid + " (SAML20:Artifact) \">\n");
	      System.out.print("<input type=submit name=\"l2" + eid + "\" value=\" Login to " + eid + " (SAML20:POST) \">\n");
	      idp = idp.getN();
	  }
      }

      String version_str = zxidjni.version_str();
      
      System.out.print("<h3>CoT configuration parameters your IdP may need to know</h3>\n");

      System.out.print("Entity ID of this SP: <a href=\""+url+"?o=B\">"+url+"?o=B</a> (Click on the link to fetch SP metadata.)\n");

      System.out.print("<h3>Technical options (typically hidden fields on production site)</h3>\n");

      System.out.print("<input type=checkbox name=fc value=1 checked> Allow new federation to be created<br>\n");
      System.out.print("<input type=checkbox name=fp value=1> Do not allow IdP to interact (e.g. ask password) (IsPassive flag)<br>\n");
      System.out.print("<input type=checkbox name=ff value=1> IdP should reauthenticate user (ForceAuthn flag)<br>\n");

      System.out.print("NID Format: <select name=fn><option value=prstnt>Persistent<option value=trnsnt>Transient<option value=\"\">(none)</select><br>\n");
      System.out.print("Affiliation: <select name=fq><option value=\"\">(none)</select><br>\n");

      System.out.print("Consent: <select name=fy><option value=\"\">(empty)\n");
      System.out.print("<option value=\"urn:liberty:consent:obtained\">obtained\n");
      System.out.print("<option value=\"urn:liberty:consent:obtained:prior\">obtained:prior\n");
      System.out.print("<option value=\"urn:liberty:consent:obtained:current:implicit\">obtained:current:implicit\n");
      System.out.print("<option value=\"urn:liberty:consent:obtained:current:explicit\">obtained:current:explicit\n");
      System.out.print("<option value=\"urn:liberty:consent:unavailable\">unavailable\n");
      System.out.print("<option value=\"urn:liberty:consent:inapplicable\">inapplicable\n");
      System.out.print("</select><br>\n");
      System.out.print("Authn Req Context: <select name=fa><option value=\"\">(none)\n");
      System.out.print("<option value=pw>Password\n");
      System.out.print("<option value=pwp>Password with Protected Transport\n");
      System.out.print("<option value=clicert>TLS Client Certificate</select><br>\n");
      System.out.print("Matching Rule: <select name=fm><option value=exact>Exact\n");
      System.out.print("<option value=minimum>Min\n");
      System.out.print("<option value=maximum>Max\n");
      System.out.print("<option value=better>Better\n");
      System.out.print("<option value=\"\">(none)</select><br>\n");
      System.out.print("</form><hr><a href=\"http://zxid.org/\">zxid.org</a> " + version_str);
  }
  
  public static int mgmt_screen(zxid_conf cf, zxid_cgi cgi, zxid_ses ses, char op)
  {
      int ret;
      String msg;
      zx_str rets;
      System.err.print("mgmt op=" + op);
      switch (op) {
      case 'l':
	  zxidjni.del_ses(cf, ses);
	  msg = "Local logout Ok. Session terminated.";
	  return 0;  // Simply abandon local session. Falls thru to login screen.
      case 'r':
	  zxidjni.sp_slo_redir(cf, cgi, ses);
	  zxidjni.del_ses(cf, ses);
	  return 1;  // Redirect already happened. Do not show login screen.
      case 's':
	  zxidjni.sp_slo_soap(cf, cgi, ses);
	  zxidjni.del_ses(cf, ses);
	  msg = "SP Initiated logout (SOAP). Session terminated.";
	  return 0;  // Falls thru to login screen.
      case 't':
	  zxidjni.sp_mni_redir(cf, cgi, ses, null);
	  return 1;  // Redirect already happened. Do not show login screen.
      case 'u':
	  zxidjni.sp_mni_soap(cf, cgi, ses, null);
	  msg = "SP Initiated defederation (SOAP).";
	  break;
      case 'P':
	  rets = zxidjni.sp_dispatch(cf, cgi, ses);
	  if (rets.getS() == "O") return 0;
	  if (rets.getS() == "K") return 1; // REDIR OK
	  break;
      case 'Q':
	  rets = zxidjni.sp_dispatch(cf, cgi, ses);
	  if (rets.getS() == "O") return 0;
	  if (rets.getS() == "K") return 1; // REDIR OK
	  break;
      }
      
      String sid = ses.getSid();
      String nid = ses.getNid();

      System.out.print("CONTENT-TYPE: text/html\r\n\r\n");
      System.out.print("<title>ZXID SP Mgmt</title>\n");
      System.out.print("<link rel=\"shortcut icon\" href=\"/favicon.ico\" type=\"image/x-icon\" />\n");
      System.out.print("<body bgcolor=\"#330033\" text=\"#ffaaff\" link=\"#ffddff\" vlink=\"#aa44aa\" alink=\"#ffffff\"><font face=sans>\n");

      System.out.print("<h1>ZXID SP Java Management (user logged in, session active)</h1><pre>\n</pre><form method=post action=\"zxid-java.sh?o=P\">\n");
      System.out.print("<input type=hidden name=s value=\""+sid+"\">\n");
      System.out.print("<input type=submit name=gl value=\" Local Logout \">\n");
      System.out.print("<input type=submit name=gr value=\" Single Logout (Redir) \">\n");
      System.out.print("<input type=submit name=gs value=\" Single Logout (SOAP) \">\n");
      System.out.print("<input type=submit name=gt value=\" Defederate (Redir) \">\n");
      System.out.print("<input type=submit name=gu value=\" Defederate (SOAP) \">\n");

      System.out.print("<h3>Technical options (typically hidden fields on production site)</h3>\n");

      System.out.print("sid("+sid+") nid("+nid+") <a href=\"zxid-java.sh?s="+sid+"\">Reload</a>\n");
      System.out.print("</form><hr>\n");
      System.out.print("<a href=\"http://zxid.org/\">zxid.org</a>\n");
      return 1;
  }
}

/* EOF */
