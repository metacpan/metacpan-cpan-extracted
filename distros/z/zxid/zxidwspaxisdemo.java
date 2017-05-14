/* zxidwspaxisdemo.java  -  Demonstration web service, TAS3 enabled using the zxidwspaxismod
 * Copyright (c) 2009 Symlabs (symlabs@symlabs.com), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: zxidappdemo.java,v 1.3 2009-11-20 20:27:13 sampo Exp $
 * 16.10.2009, created --Sampo
 *
 * See also: zxid-java.pd, zxidappdemo.java for client side
 *
 * Discovery registration:
 *   ./zxcot -e http://sp.tas3.pt:8080/zxidservlet/wspdemo 'TAS3 WSP Demo' http://sp.tas3.pt:8080/zxidservlet/wspdemo?o=B urn:x-foobar | ./zxcot -d -b /var/zxid/idpdimd
 *   touch /var/zxid/idpuid/.all/.bs/urn_x-foobar,l9O3xlWWi9kLZm-yQYRytpf0lqw
 */

import zxidjava.*;   // Pull in the zxidjni.az() API
import java.io.*;

public class zxidwspaxisdemo extends HttpServlet {
    public String demodemo(String in) {
	System.err.print("demodemo wsp in("+in+").\n");
	return "DEMO-"+in+"-DEMO";
    }
}

/* EOF */
