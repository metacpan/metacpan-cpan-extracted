/* zxidwspleaf.java  -  Demonstrate server side of handling a web service call
 * Copyright (c) 2012 Synergetics (sampo@synergetics.be), All Rights Reserved.
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
 * 7.2.2012, new virtual hosting with <init-param> supplied config --Sampo
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

public class zxidwspleaf extends HttpServlet {
    static zxidjava.zxid_conf cf = null;
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
	    zxidjni.set_opt(cf, 1, 1);  // Debug on
	    zxidjni.set_opt(cf, 7, 3);  // Cause glibc malloc/free to dump core on error
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
	if (qs != null && qs.equals("o=B")) {  // Metadata check
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
	res.getOutputStream().print("<title>ZXID Leaf WSP</title><body><h1>ZXID Leaf WSP does not offer web GUI (" + req.getRequestURI() + ")</H1>\n<pre>"+qs+"</pre>");
    }

    // Handle a SOAP call, which is always a POST

    public void doPost(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	String ret;
	System.err.print("\n============ LEAF WSP Start SOAP POST ============\n");
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

	// Simulate deny

	System.err.print("HERE1\n");	
	zxidjni.set_tas3_status(cf, ses, zxidjni.mk_tas3_status(cf, null, "urn:tas3:ctlpt:app", "urn:tas3:status:deny", null, null, null));
	System.err.print("HERE 2\n");

	// Check the input for correct ID-WSF compliance

	zxidjni.set_opt(cf, 7, 3);  // Cause glibc malloc/free to dump core on error
	//System.err.print("Validating buf("+buf+")\n");	
	String nid  = zxidjni.wsp_validate(cf, ses, "Resource=leaf", buf);
	System.err.print("VALID3 nid("+nid+")\n");	
	if (nid == null) {
	    System.err.print("Validate fail buf("+buf+")\n");	
	    ret = zxidjni.wsp_decorate(cf, ses, "Resource=leaf:fail",
				       "<recursed>"
				       + "<lu:Status code=\"Fail\" comment=\"INVALID. Token replay?\"></lu:Status>" +
				       "</recursed>");
	    res.getOutputStream().print(ret);
	    System.err.print("^^^^^^^^^^^^^ WSP inval ("+ret.length()+" chars output) ^^^^^^^^^^^^^\n\n");
	    return;
	}
	String ldif = zxidjni.ses_to_ldif(cf, ses);
	System.err.print("\n===== Leaf Doing work for user nid("+nid+").\nLDIF: "+ldif+"\n");

	ret = zxidjni.wsp_decorate(cf, ses, "Resource=leaf",
				   "<recursed>"
				   + "<lu:Status code=\"OK\">ok</lu:Status>"
				   + "<data>nid="+nid+"\n"+ldif+"\n</data>" +
				   "</recursed>");
	
	res.getOutputStream().print(ret);
	System.err.print("^^^^^^^^^^^^^ LEAF WSP Done ("+ret.length()+" chars output) ^^^^^^^^^^^^^\n\n");
    }
}

/* EOF */
