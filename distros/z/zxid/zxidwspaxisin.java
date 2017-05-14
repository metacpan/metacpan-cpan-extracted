/* zxidwspaxisin.java  -  Handler for Axis2 module for TAS3 WSP
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidappdemo.java,v 1.4 2009-11-29 12:23:06 sampo Exp $
 * 15.12.2009, created --Sampo
 *
 * See also: zxid-java.pd, zxidwspdemo.java for server side
 * http://ws.apache.org/axis2/1_1/modules.html
 */

package zxidjava;

import zxidjava.*;   // Pull in the zxidjni.az() API
import java.io.*;
import java.util.Iterator;
import javax.xml.namespace.QName;

import org.apache.axiom.om.OMElement;
import org.apache.axiom.soap.SOAPHeader;
import org.apache.axiom.soap.SOAPHeaderBlock;
import org.apache.axis2.AxisFault;
import org.apache.axis2.context.MessageContext;
import org.apache.axis2.handlers.AbstractHandler;
import org.apache.axis2.util.XMLUtils;
import org.apache.ws.security.processor.SAMLTokenProcessor;
import org.w3c.dom.Element;

public class zxidwspaxisin extends AbstractHandler {

    static final String conf = "URL=http://sp1.zxidsp.org:8080/sso&PATH=/var/zxid/";
    static zxidjava.zxid_conf cf;
    static {
	// CONFIG: You must have created /var/zxid directory hierarchy. See `make dir'
	// CONFIG: You must create edit the URL to match your domain name and port
	System.loadLibrary("zxidjni");
	cf = zxidjni.new_conf_to_cf(conf);
	zxidjni.set_opt(cf, 1, 1);
    }
    
    public zxidwspaxisin() {
	// Constructor
    }
    
    public InvocationResponse invoke(MessageContext mctx) throws AxisFault {
        if (!context.isEngaged(zxidwspaxismod.MODULE_NAME)) {
            return InvocationResponse.CONTINUE;        
        }
	
	zxid_ses ses = mctx.getProperty("zxidses");

	String env = mctx.getEnvelope().toString();
	System.err.print("wsp in processing env("+env+").\n");
	String nid = zxidjni.wsp_validate(cf, ses, null, env);
	// *** validation error not handled
	System.err.print("Doing work for user nid("+nid+").\n");
        return InvocationResponse.CONTINUE;
    }
    
    /* ------------ ASC (1) ----------------- */

    public InvocationResponse invoke(MessageContext mctx) throws AxisFault {
        if (!context.isEngaged(zxidwspaxismod.MODULE_NAME)) {
            return InvocationResponse.CONTINUE;        
        }
	
	zxid_ses ses = zxidjni.as_call(cf, idp_meta, user, pw);
	mctx.putProperty("zxidses", ses);

	String env = mctx.getEnvelope().toString();
	System.err.print("wsp in processing env("+env+").\n");
	String nid = zxidjni.wsp_validate(cf, ses, null, env);
	System.err.print("Doing work for user nid("+nid+").\n");
        return InvocationResponse.CONTINUE;
    }
    
    

}

/* EOF */
