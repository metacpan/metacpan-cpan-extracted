/* zxidwspdemo.java  -  Demonstrate server side of handling a web service call (middle)
 * Copyright (c) 2012-2016 Synergetics (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidappdemo.java,v 1.3 2009-11-20 20:27:13 sampo Exp $
 * 16.10.2009, created --Sampo
 * 16.2.2010, fixed virtual hosting --Sampo
 * 7.2.2012,  new virtual hosting with <init-param> supplied config --Sampo
 * 19.2.2016, improved visualization of the Az steps --Sampo
 *
 * See also: zxid-java.pd, zxidappdemo.java for client side
 *
 * Discovery registration:
 *   ./zxcot -e http://sp.tas3.pt:8080/zxidservlet/wspdemo 'TAS3 WSP Demo' http://sp.tas3.pt:8080/zxidservlet/wspdemo?o=B urn:x-foobar | ./zxcot -d -b /var/zxid/idpdimd
 *   touch /var/zxid/idpuid/.all/.bs/urn_x-foobar,l9O3xlWWi9kLZm-yQYRytpf0lqw
 */

import zxidjava.*;   // Pull in the zxidjni.az() API
import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

public class zxidwspdemo extends HttpServlet {
    static zxidjava.zxid_conf cf;
    static { System.loadLibrary("zxidjni"); }

    public void init_zxid_vhost(HttpServletRequest req)
	throws ServletException
    {
	// CONFIG: You must have created /var/zxid directory hierarchy. See `make dir'
	// CONFIG: To set config string, edit web.xml (hope you know where it is) and
	// add to your servlets sections like
        //  <servlet>
	//    <servlet-name>zxidsrvlet</servlet-name><servlet-class>zxidsrvlet</servlet-class>
	//    <init-param>
	//      <param-name>ZXIDConf</param-name><param-value>PATH=/var/zxid/</param-value>
	//    </init-param>
	//  </servlet>
	// CONFIG: You must edit the URL to match your domain name and port, usually you
	// CONFIG: would create and edit /var/zxid/zxid.conf and override the URL there.
	// CONFIG: However, this program sets the URL dynamically, see calls to zxidjni.url_set()
	if (cf == null) {
	    String conf = getServletConfig().getInitParameter("ZXIDConf"); 
	    cf = zxidjni.new_conf_to_cf(conf);
	    zxidjni.set_opt(cf, 1, 1);
	}
	String scheme = req.getScheme();
	String host_hdr = req.getHeader("HOST");
	String fullURL = req.getRequestURI();
	String url = scheme + "://" + host_hdr + fullURL;
	System.err.print("url("+url+")\n");  // URL=http://sp.tas3.pt:8080/zxidservlet/wspdemo
	zxidjni.url_set(cf, url);  // Virtual host support
    }

    // Only reason why a pure WSP would handle GET is supporting WKL metadata
    // exchange (o=B). However, a hybrid frontend SP plus WSP would handle its SSO here.

    public void doGet(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	System.err.print("Start GET...\n");
	init_zxid_vhost(req);
	String qs = req.getQueryString();
	if (qs != null && (qs.equals("o=B") || qs.equals("o=d"))) {  // Metadata check
	    String ret = zxidjni.simple_cf(cf, -1, qs, null, 0x3d54);  // QS response requested
	    System.err.print(ret);
	    switch (ret.charAt(0)) {
	    case 'L':  /* Redirect: ret == "LOCATION: urlCRLF2" */
		res.sendRedirect(ret.substring(10, ret.length() - 4));
		return;
	    case '<':
		switch (ret.charAt(1)) {
		case 's': case 'm': res.setContentType("text/xml"); break; /* <m20: metadata ... */
		default:	    res.setContentType("text/html"); break;
		}
		res.setContentLength(ret.length());
		res.getOutputStream().print(ret);
		break;
	    default:
		System.err.print("Unhandled zxid_simple() response("+ret+").\n");
	    }
	    return;
	}
	
	res.setContentType("text/html");
	res.getOutputStream().print("<title>ZXID Demo WSP</title><body><h1>ZXID Demo WSP does not offer web GUI (" + req.getRequestURI() + ")</H1>\n<pre>"+qs+"</pre>");
    }

    // Handle a SOAP call, which is always a POST

    public void doPost(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	String ret;
	System.err.print("\n============ WSP Start SOAP POST ============\n");
	init_zxid_vhost(req);
	zxidjava.zxid_ses ses = zxidjni.alloc_ses(cf);

	// Java / Servlet complicated way of reading in the POST input

	String buf;
	int len = req.getContentLength();
	byte[] b = new byte[len];
	int here, got;
	for (here = 0; here < len; here += got)
	    got = req.getInputStream().read(b, here, len - here);
	buf = new String(b, 0, len);

	// Check the input for correct ID-WSF compliance

	System.err.print("Validating buf("+buf+")\n");	
	String nid  = zxidjni.wsp_validate(cf, ses, "Resource=demo", buf);
	if (nid == null) {
	    System.err.print("Validate fail buf("+buf+")\n");	
	    ret = zxidjni.wsp_decorate(cf, ses, "Resource=demo:fail",
				       "<barfoo>"
				       + "<lu:Status code=\"Fail\" comment=\"INVALID. Token replay?\"></lu:Status>" +
				       "</barfoo>");
	    res.getOutputStream().print(ret);
	    System.err.print("^^^^^^^^^^^^^ WSP inval ("+ret.length()+" chars output) ^^^^^^^^^^^^^\n\n");
	    return;
	}
	String ldif = zxidjni.ses_to_ldif(cf, ses);
	System.err.print("\n===== Doing work for user nid("+nid+").\nAttribute dump: "+ldif+"\n");
	ldif = "<img src=\"green-check-20x20.png\">WSP2 Authorized by PDP (B).<br>\n"+ldif+"<img src=\"green-check-20x20.png\">WSP3 Authorized by PDP (B).<br>\n";

	// Perform a application dependent authorization step and ship the response

	if (zxidjni.az_cf_ses(cf, "Action=Call", ses) == null) {
	    System.err.print("Explicit Az fail\n");		
	    ret = zxidjni.wsp_decorate(cf, ses, "Resource=demo:fail",
				       "<barfoo>"
				       + "<lu:Status code=\"Fail\" comment=\"Denied\"></lu:Status>"
				       + "<data>Denied: nid="+nid+"</data>" +
				       "</barfoo>");
	} else {
	    String recurse = "";
	    if (buf.indexOf("STOP") == -1) {
		// "http://sp.tas3.pt:8080/zxidservlet/wspleaf?o=B"
	ldif = "<img src=\"green-check-20x20.png\">WSP2 Authorized by PDP (B).<br>\n"+ldif+"<img src=\"green-check-20x20.png\">WSP3 Authorized by PDP (B).<br>\n";
	        recurse = zxidjni.call(cf, ses, "x-recurs", null, null, "Resource=leaf", "<recursing>STOP</recursing>");
	        //recurse = zxidjni.call(cf, ses, "urn:x-foobar", "http://sp.tas3.pt:8080/zxidservlet/wspdemo?o=B", null, null, "<recursing>STOP</recursing>");
		System.err.print("Recursive out("+recurse+")\n");
		recurse = zxidjni.extract_body(cf, recurse);
		recurse += "<img src=\"green-check-20x20.png\">WSC4 Authorized by PDP (B).<br>\n"+ldif+"<img src=\"green-check-20x20.png\">WSP3 Authorized by PDP (B).<br>\n";
	    } else {
		System.err.print("Recursive STOP\n");		
	    }

	ldif = "<img src=\"green-check-20x20.png\">WSP2 Authorized by PDP (B).<br>\n"+ldif+"<img src=\"green-check-20x20.png\">WSP3 Authorized by PDP (B).<br>\n";
	    
	    ret = zxidjni.wsp_decorate(cf, ses, "Resource=demo",
				       "<barfoo>"
				       + "<lu:Status code=\"OK\" comment=\"Permit\"></lu:Status>"
				       + "<data>nid="+nid+"\n"+ldif+"\n\nRECURSE OUT:\n"+recurse+"\n</data>" +
				       "</barfoo>");
	}
	
	res.getOutputStream().print(ret);
	System.err.print("^^^^^^^^^^^^^ WSP Done ("+ret.length()+" chars output) ^^^^^^^^^^^^^\n\n");
    }
}

/* EOF */
	//String proto = req.getProtocol();
	//String servername = req.getServerName();
	//int serverport = req.getServerPort();
	//String qs = req.getQueryString();
	//System.err.print("proto("+proto+")\n");	
	//System.err.print("scheme("+scheme+")\n");	
	//System.err.print("servername("+servername+")\n");	
	//System.err.print("serverport("+serverport+")\n");	
	//System.err.print("host_hdr("+host_hdr+")\n");	
	//System.err.print("fullURL("+fullURL+")\n");	
	//System.err.print("qs("+qs+")\n");	
	//String url = scheme + "://" + servername
	//    + (serverport != 80 && serverport != 443 ? ":"+serverport : "")
	//    + fullURL;
