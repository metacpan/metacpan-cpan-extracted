/* zxidhlo.java  -  Hello World Java/Tomcat servlet script that calls libzxid using JNI
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidhlo.java,v 1.8 2009-10-16 13:36:33 sampo Exp $
 * 12.1.2007, created --Sampo
 *
 * See also: README-zxid section 10 "zxid_simple() API"
 */

import zxidjava.*;
import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

public class zxidhlo extends HttpServlet {
    static { System.loadLibrary("zxidjni"); }
    
    // CONFIG: You must have created /var/zxid directory hierarchy. See `make dir'
    // CONFIG: You must edit the URL to match your domain name and port
    static final String conf = "URL=http://sp1.zxidsp.org:8080/zxidservlet/zxidHLO&PATH=/var/zxid/";
    
    //public static void main(String argv[]) throws java.io.IOException  {  }
    public void do_zxid(HttpServletRequest req, HttpServletResponse res, String qs)
	throws ServletException, IOException
    {
	String ret = zxidjni.simple(conf, qs, 0x1d54);
	System.err.print(ret);
	switch (ret.charAt(0)) {
	case 'L':  /* Redirect: ret == "LOCATION: urlCRLF2" */
	    res.sendRedirect(ret.substring(10, ret.length() - 4));
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
	case 'd': /* Logged in case */
	    //my_parse_ldif(ret);
	    int x = ret.indexOf("\nsesid: ");
	    int y = ret.indexOf('\n', x + 8);
	    String sid = ret.substring(x + 8, y);
	    System.err.print("Logged in. sid="+sid+"\n");
	    res.setContentType("text/html");
	    res.getOutputStream().print(zxidjni.fed_mgmt(conf, sid, 0xd54));
	    break;
	default:
	    System.err.print("Unknown zxid_simple() response.\n");
	}
    }

    public void doGet(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	System.err.print("Start GET...\n");
	// LECP/ECP PAOS header checks
	do_zxid(req, res, req.getQueryString());
    }

    public void doPost(HttpServletRequest req, HttpServletResponse res)
	throws ServletException, IOException
    {
	System.err.print("Start POST...\n");
	String qs;
	int len = req.getContentLength();
	byte[] b = new byte[len];
	int here, got;
	for (here = 0; here < len; here += got)
	    got = req.getInputStream().read(b, here, len - here);
	qs = new String(b, 0, len);
	do_zxid(req, res, qs);
    }
}

/* EOF */
