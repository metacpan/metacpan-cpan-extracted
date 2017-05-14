package org.zxid;

/* zxidsrvlet.java  -  SAML SSO Java/Tomcat servlet script that calls libzxid using JNI
 * Copyright (c) 2007-2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidsrvlet.java,v 1.3 2009-11-20 20:27:13 sampo Exp $
 * 12.1.2007, created --Sampo
 * 16.10.2009, refined from zxidhlo example to truly useful servlet that populates session --Sampo
 *
 * See also: README-zxid section 10 "zxid_simple() API"
 */

/*
 * 8.10.2010 , Modified slightly by Stijn Lievens to avoid having to compile 
 * in the configuration string.
 * Updated to conform (better) to Java conventions. 
 * Removed use of deprecated methods.
 */

import java.io.IOException;
import java.net.URLDecoder;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import zxidjava.zxidjni;

public class ZxidServlet extends HttpServlet {
  
  
  private static final long serialVersionUID = 1L;
  
  /**
   * The ZXID configuration String.
   */
  // Maybe this one can be removed.
  private String conf;  // e.g. "URL=http://zxid-sp.tas3.kent.ac.uk:8080/zxid/sso&PATH=/var/zxid/";
  
  /**
   * The ZXID configuration object.
   */
  private zxidjava.zxid_conf cf;
  
  /**
   * Load the ZXID native library.
   */
  static {   
    System.loadLibrary("zxidjni");    
  }

  /**
   * Does the actual calling of the ZXID native code through {@code zxidjni.simple_cf}.
   * 
   * @param req
   * @param res
   * @param qs
   * @throws ServletException
   * @throws IOException
   */
  private void doZxid(HttpServletRequest req, HttpServletResponse res, String qs)
      throws ServletException, IOException {
    if (req.getParameter("gr") != null || req.getParameter("gl") != null) {
      req.getSession(true).invalidate(); // Invalidate local ses in case of SLO
    }
    String ret = zxidjni.simple_cf(cf, -1, qs, null, 0x3d54); // QS response
                                                              // requested
    System.err.println(ret);
    switch (ret.charAt(0)) {
    case 'L': /* Redirect: ret == "LOCATION: urlCRLF2" */
      res.sendRedirect(ret.substring(10, ret.length() - 4));
      return;
    case '<':
      switch (ret.charAt(1)) {
      case 's': /* <se: SOAP envelope */
      case 'm': /* <m20: metadata */
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
      System.err.println("Deny (z)");
      res.sendError(403, "Denied. Authorization to rs(" + req.getParameter("RelayState")
          + ") was refused by a PDP.");
      return;
    case 'd': /* Logged in case (both LDIF and QS will start by "dn") */
      HttpSession ses = req.getSession(true);
      String[] avs = ret.split("&");
      for (int i = 0; i < avs.length; ++i) {
        String[] av = avs[i].split("=");
        ses.setAttribute(av[0], URLDecoder.decode(av.length > 1 ? av[1] : "", "UTF-8"));
      }

      /*
       * Make sure cookie is visible to other servlets on the same server.
       * Alternately you could add emptySessionPath="true" to tomcat
       * conf/server.xml
       */
      Cookie[] cookies = req.getCookies();
      if (cookies != null) {
        for (int i = 0; i < cookies.length; i++) {
          if (cookies[i].getName().equals("JSESSIONID")) { // MUST match cookie
                                                            // name
            cookies[i].setPath("/");
            break;
          }
        }
      }

      System.err.println("Logged in. jses(" + ses.getId() + ") rs(" + ses.getAttribute("rs") + ")");
      String rs = URLDecoder.decode(ses.getAttribute("rs").toString(), "UTF-8");
      if (rs != null && rs.length() > 0 && rs.charAt(rs.length() - 1) != '-') {
        res.sendRedirect(rs);
      }

      /* Redirect was not viable. Just show the management screen. */

      ret = zxidjni.fed_mgmt_cf(cf, null, -1, ses.getAttribute("sesid").toString(), 0x3d54);
      res.setContentType("text/html");
      res.setContentLength(ret.length());
      res.getOutputStream().print(ret);
      break;
    default:
      System.err.println("Unknown zxid_simple() response(" + ret + ").");
    }
  }

    //@Override
  public void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException,
      IOException {
    System.err.print("Start GET...\n");
    // LECP/ECP PAOS header checks
    doZxid(req, res, req.getQueryString());
  }

    //@Override
  public void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException,
      IOException {
    System.err.println("Start POST...");   
    int len = req.getContentLength();
    byte[] b = new byte[len];
    int here, got;
    for (here = 0; here < len; here += got) {
      got = req.getInputStream().read(b, here, len - here);
    }
    String qs = new String(b, 0, len);
    doZxid(req, res, qs);
  }
  
    //@Override
  public void init(ServletConfig config) throws ServletException {
    if (config.getInitParameter("zxid-configuration") != null) {
      System.err.println("The zxid-configuration parameter is:" 
          + config.getInitParameter("zxid-configuration"));
      conf = config.getInitParameter("zxid-configuration");
    }
    cf = zxidjni.new_conf_to_cf(conf);
  }
}
