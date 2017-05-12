package org.jolokia.osgish;

import org.osgi.framework.*;
import org.osgi.service.log.LogService;
import org.osgi.util.tracker.ServiceTracker;

import javax.management.MBeanRegistration;
import javax.management.MBeanServer;
import javax.management.MalformedObjectNameException;
import javax.management.ObjectName;

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
 * Implementation of a service layer for communication between 'osgish' and the
 * osgi agent bundle.
 *
 * @author roland
 */
public class OsgishService implements OsgishServiceMBean, MBeanRegistration, ServiceListener, BundleListener {

    // remember context for housekeeping
    BundleContext bundleContext;

    // Timestamps for state checks
    private long bundlesLastChanged;
    private long servicesLastChanged;
    private long packagesLastChanged;

    // Tracker to be used for the LogService
    private ServiceTracker logTracker;

    // Name under which this MBean is registered
    private static final String OSGISH_SERVICE_NAME = "osgish:type=Service";

    public OsgishService(BundleContext pBundleContext) {

        logTracker = new ServiceTracker(pBundleContext, LogService.class.getName(), null);
        long time = getCurrentTime();
        bundlesLastChanged = time;
        servicesLastChanged = time;
        packagesLastChanged = time;
        bundleContext = pBundleContext;
    }

    public boolean hasStateChanged(String pWhat, long pTimestamp) {
        if ("bundles".equals(pWhat)) {
            return isYoungerThan(bundlesLastChanged,pTimestamp);
        } else if ("services".equals(pWhat)) {
            return isYoungerThan(servicesLastChanged,pTimestamp);
        } else if ("packages".equals(pWhat)) {
            return isYoungerThan(packagesLastChanged,pTimestamp);
        }
        return false;
    }

    private boolean isYoungerThan(long pLastChanged, long pTimestamp) {
        return pLastChanged >= pTimestamp;
    }

    void log(int level,String message) {
        LogService logService = (LogService) logTracker.getService();
        if (logService != null) {
            logService.log(level,message);
        }
    }


    // =================================================================================
    // Listener interfaces
    public void serviceChanged(ServiceEvent event) {
        servicesLastChanged = getCurrentTime();
    }

    public void bundleChanged(BundleEvent event) {
        long time = getCurrentTime();
        bundlesLastChanged = time;
        packagesLastChanged = time;
    }

    private long getCurrentTime() {
        return System.currentTimeMillis() / 1000;
    }


    // =================================================================================
    // MBeanRegistration

    public ObjectName preRegister(MBeanServer pMBeanServer, ObjectName pObjectName)
            throws MalformedObjectNameException {
        // We are providing our own name
        return new ObjectName(OSGISH_SERVICE_NAME);
    }

    public void postRegister(Boolean pBoolean) {
        bundleContext.addBundleListener(this);
        bundleContext.addServiceListener(this);
        logTracker.open();
        log(LogService.LOG_DEBUG,"Registered " + OSGISH_SERVICE_NAME);
    }

    public void preDeregister()  {
        bundleContext.removeBundleListener(this);
        bundleContext.removeServiceListener(this);
        log(LogService.LOG_DEBUG,"Unregistered " + OSGISH_SERVICE_NAME);
        logTracker.close();
    }

    public void postDeregister() {
    }


}
