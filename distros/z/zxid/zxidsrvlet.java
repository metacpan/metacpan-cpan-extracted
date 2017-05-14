/* zxidsrvlet.java  -  SAML SSO Java/Tomcat servlet script that calls libzxid using JNI
 * Copyright (c) 2012 Synergetics (sampo@synergetics.be), All Rights Reserved.
 * Copyright (c) 2010-2011 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidsrvlet.java,v 1.3 2009-11-20 20:27:13 sampo Exp $
 * 12.1.2007,  created --Sampo
 * 16.10.2009, refined from zxidhlo example to truly useful servlet that populates session --Sampo
 * 6.2.2012,   added use of ZXIDConf <init-param> --Sampo
 * 17.10.2012, added passing ZXID cookies --Sampo
 *
 * See also: README-zxid section 10 "zxid_simple() API"
 * http://www.easywms.com/easywms/?q=en/read-parameters-web-xml-servlet-release-work-programmer
 */

import zxidjava.*;
import java.io.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

public class zxidsrvlet extends HttpServlet {
    //static final String conf = "URL=http://sp1.zxidsp.org:8080/sso&PATH=/var/zxid/";
    static zxidjava.zxid_conf cf;
    static { System.loadLibrary("zxidjni"); }
    
    // setptmcookie=SYNPTM%3Dhttps%3A%2F%2Fpds%2Epersonaldata%2Eeu%3A4444%2Fptm%2Fptm%2Ecgi%3Fl0https%3A%2F%2Fidp%2Ei%2Ddent%2Eeu%2Fsynidp%3D1%3B%20path%3D%2F%3B%20secure
    // setcookie=SYNSES%3DS8M3juzHFe2NbZE%2DTJC10qw1W%3B%20path%3D%2F%3B%20secure
    // SYNPTM=https://pds.personaldata.eu:4444/ptm/ptm.cgi?l0https://idp.i-dent.eu/synidp=1; path=/; secure
    // SYNSES=S8M3juzHFe2NbZE-TJC10qw1W; path=/; secure

    private void pass_cookie_from_str(String setcookie, HttpServletResponse res)
    {
	if (setcookie == null)
	    return;
	System.err.print("setcookie("+setcookie+")\n");
	int eq = setcookie.indexOf('=');
	int semi = setcookie.indexOf(';', eq+1);
	if (eq != -1 && semi != -1) {
	    Cookie cookie = new Cookie(setcookie.substring(0, eq),
				       setcookie.substring(eq+1, semi));
	    eq = setcookie.indexOf("path=", semi);
	    if (eq == -1) {
		cookie.setPath("/");
		cookie.setSecure(setcookie.indexOf("secure", semi) != -1);
	    } else {
		semi = setcookie.indexOf(';', eq+5);
		cookie.setPath(setcookie.substring(eq+5, semi));
		cookie.setSecure(setcookie.indexOf("secure", semi) != -1);
	    }
	    res.addCookie(cookie);
	}
    }

    //public static void main(String argv[]) throws java.io.IOException  {  }
    public void do_zxid(HttpServletRequest req, HttpServletResponse res, String qs)
	throws ServletException, IOException
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
	if (cf == null) {
	    String conf = getServletConfig().getInitParameter("ZXIDConf"); 
	    System.err.print("SSO servlet conf("+conf+")\n");
	    cf = zxidjni.new_conf_to_cf(conf);
	}
	if (req.getParameter("gr") != null || req.getParameter("gl") != null)
	    req.getSession(true).invalidate();  // Invalidate local ses in case of SLO
	System.err.print("----- Calling zxid_simple\n");
	String ret = zxidjni.simple_cf(cf, -1, qs, null, 0x3d54);  // QS response requested
	System.err.print("----- ret(" + ret + ")\n");
	switch (ret.charAt(0)) {
	case 'L':  /* Redirect: ret == "LOCATION: urlCRLF2" */
	    res.sendRedirect(ret.substring(10, ret.length() - 4));
	    System.err.print("^^^^^^^^^^^^ SSO Servlet Redirect ^^^^^^^^^^^^\n");
	    return;
	case '<':
	    switch (ret.charAt(1)) {
	    case 's':  /* <se:  SOAP envelope */
	    case 'm':  /* <m20: metadata */
		res.setContentType("text/xml");
		break;
	    default:
		res.setContentType("text/html");
		break;
	    }
	    res.setContentLength(ret.length());
	    res.getOutputStream().print(ret);
	    break;
        case 'z': /* Authorization denied case (if PDP_URL was configured) */
	    System.err.print("Deny (z)\n");
	    res.sendError(403, "Denied. Authorization to rs("+req.getParameter("RelayState")+") was refused by a PDP.");
	    System.err.print("^^^^^^^^^^^^ SSO Servlet DENIED ^^^^^^^^^^^^\n");
	    return;
	case 'd': /* Logged in case (both LDIF and QS will start by "dn") */
	    HttpSession ses = req.getSession(true);
	    String[] avs = ret.split("&");
	    for (int i = 0; i < avs.length; ++i) {
		String av[] = avs[i].split("=", 2);
		ses.setAttribute(av[0], URLDecoder.decode(av.length > 1 ? av[1] : "", "UTF-8"));
	    }

	    /* Make sure cookie is visible to other servlets on the same server.
	     * Alternately you could add emptySessionPath="true" to tomcat conf/server.xml */
	    Cookie[] cookies = req.getCookies();
	    if (cookies != null) {
		for (int i = 0; i < cookies.length; i++) {
		    if (cookies[i].getName().equals("JSESSIONID")) {  // MUST match cookie name
			cookies[i].setPath("/");
			break;
		    }
		}
	    }
	    
	    pass_cookie_from_str(ses.getAttribute("setcookie").toString(), res);
	    pass_cookie_from_str(ses.getAttribute("setptmcookie").toString(), res);
	    
	    System.err.print("Logged in. jses("+ses.getId()+") rs("+ses.getAttribute("rs")+")\n");
	    //String rs = URLDecoder.decode(ses.getAttribute("rs").toString(), "UTF-8");
	    /* N.B. RelayState was set by app servlet by setting fr query string
	     * parameter when it redirected to SSO servlet. The fr qs param was
	     * then deflated and safe base64 encoded and sent to IdP as RelayState.
	     * It then came back from IdP and was decoded as one of the SSO attributes.
	     * The decoding is controlled by <<tt: rsrc$rs$unsb64-inf$$ >>  rule in OUTMAP. */
	    String rs = ses.getAttribute("rs").toString();
	    if (rs != null && rs.length() > 0 && rs.charAt(rs.length()-1) != '-')
		res.sendRedirect(rs);

	    /* Redirect was not viable. Just show the management screen. */
	    
	    ret = zxidjni.fed_mgmt_cf(cf, null, -1, ses.getAttribute("sesid").toString(), 0x3d54);
	    res.setContentType("text/html");
	    res.setContentLength(ret.length());
	    res.getOutputStream().print(ret);
	    break;
	default:
	    System.err.print("Unknown zxid_simple() response("+ret+").\n");
	}
	System.err.print("^^^^^^^^^^^^ SSO Servlet Done ^^^^^^^^^^^^\n");
    }

    public void doGet(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	System.err.print("\n============ SSO Servlet GET ============\n");
	// LECP/ECP PAOS header checks
	do_zxid(req, res, req.getQueryString());
    }

    public void doPost(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	System.err.print("\n============ SSO Servlet POST ============\n");
	String qs;
	int len = req.getContentLength();
	//System.err.print("Got Content-Length="+len+"\n");
	byte[] b = new byte[len];
	int here, got;
	for (here = 0; here < len; here += got)
	    got = req.getInputStream().read(b, here, len - here);
	qs = new String(b, 0, len);
	//System.err.print("Got "+len+" bytes qs("+qs+")\n");
	do_zxid(req, res, qs);
    }
}

/* EOF - zxidsrvlet.java */
