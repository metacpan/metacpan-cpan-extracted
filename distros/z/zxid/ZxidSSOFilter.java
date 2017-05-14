/*
 * Copyright (c) 2010, University of Kent
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this 
 * list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright notice, 
 * this list of conditions and the following disclaimer in the documentation 
 * and/or other materials provided with the distribution. 
 *
 * 1. Neither the name of the University of Kent nor the names of its 
 * contributors may be used to endorse or promote products derived from this 
 * software without specific prior written permission. 
 *
 * 2. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS  
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
 * PURPOSE ARE DISCLAIMED. 
 *
 * 3. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * 4. YOU AGREE THAT THE EXCLUSIONS IN PARAGRAPHS 2 AND 3 ABOVE ARE REASONABLE
 * IN THE CIRCUMSTANCES.  IN PARTICULAR, YOU ACKNOWLEDGE (1) THAT THIS
 * SOFTWARE HAS BEEN MADE AVAILABLE TO YOU FREE OF CHARGE, (2) THAT THIS
 * SOFTWARE IS NOT "PRODUCT" QUALITY, BUT HAS BEEN PRODUCED BY A RESEARCH
 * GROUP WHO DESIRE TO MAKE THIS SOFTWARE FREELY AVAILABLE TO PEOPLE WHO WISH
 * TO USE IT, AND (3) THAT BECAUSE THIS SOFTWARE IS NOT OF "PRODUCT" QUALITY
 * IT IS INEVITABLE THAT THERE WILL BE BUGS AND ERRORS, AND POSSIBLY MORE
 * SERIOUS FAULTS, IN THIS SOFTWARE.
 *
 * 5. This license is governed, except to the extent that local laws
 * necessarily apply, by the laws of England and Wales.
 */
package org.zxid;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Checks whether a session has been established yet. If not the 
 * user will be redirected to the SSO servlet, requesting it to 
 * authenticate the user.
 * 
 * @author Stijn Lievens
 *
 */
public class ZxidSSOFilter implements Filter {
  
  /**
   * The location of the ZXID SSO servlet.
   * Can be set with an init-parameter.
   */
  private String ssoServletLocation = "sso";

  // @Override // commented out for Java 1.5
  public void destroy() {   
  }

  /**
   * Checks whether a session is already established. If it is then the filter does 
   * nothing but call the next one in the chain. Otherwise, the user is redirected
   * to the ZXID SSO servlet.
   */
  //@Override // commented out for Java 1.5
  public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
      throws IOException, ServletException {    
    HttpServletRequest req = (HttpServletRequest) request;
    HttpSession ses = req.getSession(false);  // Important: do not allow automatic session.
    if (ses != null) { // user was logged in. Continue
      chain.doFilter(request, response); 
      return;
    } else {
    // No session was established yet, redirect to SSO servlet   
    ((HttpServletResponse) response).sendRedirect(ssoServletLocation + "?o=E&fr=" 
        + getReturnURL(req));   
    }       
  }

  /**
   * Sets the location of the SSO servlet.
   */
  //@Override // commented out for Java 1.5
  public void init(FilterConfig config) throws ServletException {
    if (config.getInitParameter("sso-servlet-location") != null) {
      ssoServletLocation = config.getInitParameter("sso-servlet-location");
    }   
  }

  /** 
   * Recreates the full URL that originally got the web client to the given 
   * request.  This takes into account changes to the request due to request 
   * dispatching.
   *
   * <p>Note that if the protocol is HTTP and the port number is 80 or if the
   * protocol is HTTPS and the port number is 443, then the port number is not 
   * added to the return string as a convenience.</p>
   */  
  // taken from: https://issues.apache.org/bugzilla/show_bug.cgi?id=28222
  private final static String getReturnURL(HttpServletRequest request) {
      if (request == null){
          throw new IllegalArgumentException("Cannot take null parameters.");
      }
      
      String scheme = request.getScheme();
      String serverName = request.getServerName();
      int serverPort = request.getServerPort();
      
      /* 
       * Try to get the forwarder value first, only if it's empty fall back to the
       * current value
       */
      String requestUri = (String) request.getAttribute("javax.servlet.forward.request_uri");
      requestUri = (requestUri == null) ? request.getRequestURI() : requestUri;
   
      /*
       * Try to get the forwarder value first, only if it's empty fall back to the
       * current value. 
       */
      String queryString = (String) request.getAttribute("javax.servlet.forward.query_string");
      queryString = (queryString == null) ? request.getQueryString() : queryString;

      StringBuffer buffer = new StringBuffer();
      buffer.append(scheme);
      buffer.append("://");
      buffer.append(serverName);
      
      //if not http:80 or https:443, then add the port number
      if (!(scheme.equalsIgnoreCase("http") && serverPort == 80) &&
          !(scheme.equalsIgnoreCase("https") && serverPort == 443)) {
          buffer.append(":").append(String.valueOf(serverPort));
      }
      
      buffer.append(requestUri);
      
      if (queryString != null) {
          buffer.append("?");
          buffer.append(queryString);
      }
      
      return buffer.toString();
  }

}
