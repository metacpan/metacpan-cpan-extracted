/* zxidwscprepdemo.java  -  Demonstrate calling web service using alternate API
 * Copyright (c) 2010 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id$
 * 21.3.2010, created --Sampo
 *
 * This servlet plays the role of "payload" servlet in ZXID SSO servlet
 * integration demonstration. It illustrates the steps
 * 1.  Detect that there is no session and redirect to zxidsrvlet; and
 * 7.  Access to protected resource, with attributes already populated
 *     to the HttpSession (JSESSION)
 * 9.  Making a web service call by directly calling zxid_call()
 *
 * See also: zxid-java.pd, zxidwspdemo.java for server side
 * http://sp.tas3.pt:8080/zxidservlet/sso/wscprepdemo
 * ./servlet/WEB-INF/web.xml
 */

import zxidjava.*;   // Pull in the zxidjni.az() API
import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.Enumeration;

public class zxidwscprepdemo extends HttpServlet {
    static final boolean verbose = false;
    static final Pattern idpnid_pat = Pattern.compile("idpnid:[ ]([^\\n]*)");
    static final Pattern nidfmt_pat = Pattern.compile("nidfmt:[ ]([^\\n]*)");
    static final Pattern affid_pat  = Pattern.compile("affid:[ ]([^\\n]*)");
    static final Pattern eid_pat    = Pattern.compile("eid:[ ]([^\\n]*)");
    static final Pattern cn_pat     = Pattern.compile("cn:[ ]([^\\n]*)");
    static final Pattern o_pat      = Pattern.compile("o:[ ]([^\\n]*)");
    static final Pattern ou_pat     = Pattern.compile("ou:[ ]([^\\n]*)");
    static final Pattern role_pat   = Pattern.compile("role:[ ]([^\\n]*)");
    static final Pattern boot_pat   = Pattern.compile("urn:liberty:disco:2006-08:DiscoveryEPR:[ ]([^\\n]*)");

    static final String conf = "URL=http://sp1.zxidsp.org:8080/sso&PATH=/var/zxid/";
    static zxidjava.zxid_conf cf;
    static {
	// CONFIG: You must have created /var/zxid directory hierarchy. See `make dir'
	// CONFIG: You must create edit the URL to match your domain name and port
	System.loadLibrary("zxidjni");
	cf = zxidjni.new_conf_to_cf(conf);
	zxidjni.set_opt(cf, 1, 1);
    }

//     public String zxid_dead_simple_call(String sid, String svctype, String url, String body)
//     {
// 	//System.loadLibrary("zxidjni");
// 	zxidjava.zxid_conf cf = zxidjni.new_conf_to_cf("PATH=/var/zxid/");
// 	zxidjni.set_opt(cf, 1, 1);
// 	zxid_ses zxses = zxidjni.fetch_ses(cf, ***sid);
	
// 	ret = zxidjni.call(cf, zxses,
// 			   svctype,
// 			   url,
// 			   null, null,
// 			   body);
// 	return ret;
//     }

    public void hilite_fields(ServletOutputStream out, String ret, int n)
	throws IOException
    {
	int i;
	try {
	    Matcher matcher = idpnid_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>idpnid</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher2 = nidfmt_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher2.find();
	    out.print("<b>nidfmt</b>: " + matcher2.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher3 = affid_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher3.find();
	    out.print("<b>affid</b>: " + matcher3.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher = eid_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>eid</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher = cn_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>cn</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher = o_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>o</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher = ou_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>ou</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher = role_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>role</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

	try {
	    Matcher matcher = boot_pat.matcher(ret);
	    for (i = n; i > 0; --i)
		matcher.find();
	    out.print("<b>urn:liberty:disco:2006-08:DiscoveryEPR</b>: " + matcher.group(1) + "<br>\n");
	} catch(IllegalStateException e) { }

    }

    public void doGet(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	String fullURL = req.getRequestURI();
	String qs = req.getQueryString();
	if (qs != null)
	    fullURL += "?" + req.getQueryString();
	else
	    qs = "";
	System.err.print("Start ZXID App Demo GET("+fullURL+")...\n");
	HttpSession ses = req.getSession(false);  // Important: do not allow automatic session.
	if (ses == null) {                        // Instead, redirect to sso servlet.
	    res.sendRedirect("sso?o=E&fr=" + fullURL);
	    return;
	}
	ServletOutputStream out = res.getOutputStream();
	
	res.setContentType("text/html");
	out.print("<title>ZXID Demo App Protected Content</title><body>\n");
	out.print("<table align=right><tr><td>");
	out.print("<a href=\"http://www.tas3.eu/\"><img src=\"tas3-logo.jpg\" height=64 border=0></a>");
	out.print("<a href=\"http://zxid.org/\"><img src=\"logo-zxid-128x128.png\" height=64 border=0></a>");
	out.print("</td></tr></table>");
	out.print("<h1>ZXID Demo App Protected Content</h1>\n");
	//out.print("<h1>ZXID Demo App Protected Content</h1> at " + fullURL + "\n");

	// Render logout buttons (optional)

	out.print("[<a href=\"sso?gl=1&s="+ses.getAttribute("sesid")+"\">Local Logout</a> | <a href=\"sso?gr=1&s="+ses.getAttribute("sesid")+"\">Single Logout</a>]\n");

	out.print("<table align=right><tr><td>");
	out.print("<img src=\"tas3-recurs-demo.png\" border=0>");
	out.print("</td></tr></table>");

	// Render protected content page (your application starts working)

	out.print("<h4>HttpSession dump:</h4>");
	Enumeration val_names = ses.getAttributeNames();
	while (val_names.hasMoreElements()) {
	    String name = (String)val_names.nextElement();
	    if (name.equals("cn")
		|| name.equals("role")
		|| name.equals("o")
		|| name.equals("ou")
		|| name.equals("idpnid")
		|| name.equals("nidfmt")
		|| name.equals("affid")
		|| name.equals("eid")
		|| name.equals("urn:liberty:disco:2006-08:DiscoveryEPR")) {
		out.print("<b>" + name + "</b>: " + ses.getAttribute(name) + "<br>\n");
	    } else {
		if (verbose)
		    out.print(name + ": " + ses.getAttribute(name) + "<br>\n");
	    }
	}
	out.print("<p>");
	out.print("[ <a href=\"?leaf\">zxid_call(leaf)</a>");
	out.print(" | [ <a href=\"?leafprep\">zxid_wsc_prepare_call(leaf)</a>");
	out.print(" | <a href=\"?all\">All</a>");
	out.print(" | <a href=\"?exit\">Exit Java</a>");
	out.print("]<p>");

	// Demo web service call to zxidhrxmlwsp

	String ret;
	String sid = ses.getAttribute("sesid").toString();
	zxid_ses zxses = zxidjni.fetch_ses(cf, sid);
	
	// Demo another web service call, this time the service by zxidwspdemo.java

	if (qs.equals("leaf") || qs.equals("all")) {
	    ret = zxidjni.call(cf, zxses, "x-recurs", null, null, null,
			       "<foobar>Do it!</foobar>");
	    
	    ret = zxidjni.extract_body(cf, ret);
	    if (ret.indexOf("code=\"OK\"") == -1) {
		out.print("<p>Error from call:<br>\n<textarea cols=80 rows=20>");
		out.print(ret);
		out.print("</textarea>\n");
	    } else {
		out.print("<p>Output from Leaf web services call:<br>\n");
		hilite_fields(out, ret, 1);
		if (true || verbose) {
		    out.print("<textarea cols=80 rows=20>");
		    out.print(ret);
		    out.print("</textarea>\n");
		}
	    }
	}
	if (qs.equals("leafprep") || qs.equals("all")) {
	    //SWIGTYPE_p_zx_a_EndpointReference_s epr = zxidjni.get_epr(cf, zxses, "x-recurs", null, null, null, 1);
	    zxid_epr epr = zxidjni.get_epr(cf, zxses, "x-recurs", null, null, null, 1);
	    if (epr != null) {
		String url = zxidjni.get_epr_address(cf, epr);
		System.err.print("URL("+url+")\n");
		String req_soap = zxidjni.wsc_prepare_call(cf, zxses, epr, null,
							   "<foobar>Do it!</foobar>");
		//System.err.print("CALL("+url+") req_soap("+req_soap+")\n");
		String resp_soap = zxidjni.http_cli(cf, -1, url, -1, req_soap, null, null, 0);
		if (zxidjni.wsc_valid_resp(cf, zxses, null, resp_soap) == 1) {
		    if (resp_soap.indexOf("code=\"OK\"") == -1) {
			out.print("<p>Error from call:<br>\n<textarea cols=80 rows=20>");
			out.print(resp_soap);
			out.print("</textarea>\n");
		    } else {
			out.print("<p>Output from Leaf web services call (prep):<br>\n");
			hilite_fields(out, resp_soap, 1);
			if (true || verbose) {
			    out.print("<textarea cols=80 rows=20>");
			    out.print(resp_soap);
			    out.print("</textarea>\n");
			}
		    }
		} else {
		    out.print("<p>Invalid response:<br>\n<textarea cols=80 rows=20>");
		    out.print(resp_soap);
		    out.print("</textarea>\n");
		}
	    } else {
		out.print("<p>No EPR found<br>\n");
	    }
	}

	if (qs.equals("exit")) {
	    System.err.print("Controlled exit forced (can be used to cause __gcov_flush())\n");
	    zxidjni.set_opt(cf, 5, 0);
	}

	out.print("<p>Done.\n");
    }
}

/* EOF */
