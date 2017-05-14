// zxidjavatest.java  -  Command line for testing calls to libzxid using JNI
// Copyright (c) 2013 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
// Author: Sampo Kellomaki (sampo@iki.fi)
// This is confidential unpublished proprietary source code of the author.
// NO WARRANTY, not even implied warranties. Contains trade secrets.
// Distribution prohibited unless authorized in writing.
// Licensed under Apache License 2.0, see file COPYING.
// $Id: zxid.java,v 1.13 2009-11-29 12:23:06 sampo Exp $
// 16.11.2013, created --Sampo
//
// javac -J-Xmx128m -g zxidjavatest.java
// ./zxidjavatest.sh

import zxidjava.*;

public class zxidjavatest {
    static zxidjava.zxid_conf cf;
    static { System.loadLibrary("zxidjni"); }

  public static void main(String argv[]) throws java.io.IOException
  {
      System.err.print("Start...\n");
      System.err.print(zxidjni.version_str());
      System.err.print("\nTrying to conf...\n");
      cf = zxidjni.new_conf_to_cf("CPATH=/var/zxid/");
      zxidjni.set_opt(cf, 1, 1);
      System.err.print(zxidjni.show_conf(cf));
      System.err.print("\nDone.\n");
  }
}

/* EOF */
