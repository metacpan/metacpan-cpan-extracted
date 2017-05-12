package org.jolokia.osgish.bundle;

import org.apache.aries.jmx.Activator;
import org.apache.felix.http.jetty.internal.JettyActivator;
import org.jolokia.osgi.JolokiaActivator;
import org.jolokia.osgish.OsgishActivator;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

/*
 * osgish - An OSGi Shell
 *
 * Copyright (C) 2009 Roland Huß, roland@cpan.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * A commercial license is available as well. Please contact roland@cpan.org for
 * further details.
 */


/**
 * Activator for activation the embedded j4p agent as well
 * as the Aries JMX bundle. So it's an aggregated activator.
 *
 * It also registers an (arbitrary) MBeanServer if not already
 * an MBeanServer is registered. This service is required by Aries JMX.

 * @author roland
 * @since Jan 9, 2010
 */
public class OsgishBundleActivator implements BundleActivator {

    // Activators to delegate to
    private JolokiaActivator j4pActivator;
    private OsgishActivator osgishActivator;
    private Activator ariesActivator;
    private JettyActivator felixHttpWebActivator;

    // Name of our MBeans
    public OsgishBundleActivator() {
        felixHttpWebActivator = new JettyActivator();
        j4pActivator = new JolokiaActivator();
        ariesActivator = new Activator();
        osgishActivator = new OsgishActivator();
    }

    public void start(BundleContext pContext) throws Exception {
        felixHttpWebActivator.start(pContext);
        ariesActivator.start(pContext);
        j4pActivator.start(pContext);
        osgishActivator.start(pContext);
    }

    public void stop(BundleContext pContext) throws Exception {
        osgishActivator.stop(pContext);
        j4pActivator.stop(pContext);
        ariesActivator.stop(pContext);
        felixHttpWebActivator.stop(pContext);
    }
}
