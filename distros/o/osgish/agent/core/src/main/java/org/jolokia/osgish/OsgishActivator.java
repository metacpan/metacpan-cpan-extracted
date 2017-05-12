package org.jolokia.osgish;

import org.jolokia.osgi.servlet.JolokiaContext;
import org.jolokia.osgish.upload.UploadServlet;
import org.jolokia.osgish.upload.UploadStore;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.osgi.framework.ServiceRegistration;
import org.osgi.service.http.*;
import org.osgi.service.log.LogService;
import org.osgi.util.tracker.ServiceTracker;
import org.osgi.util.tracker.ServiceTrackerCustomizer;

import javax.management.*;
import javax.servlet.ServletException;
import java.io.File;
import java.io.IOException;
import java.lang.management.ManagementFactory;

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
 * as the Aries JMX bundle. So it's an aggregat activator.
 *
 * It also registers an (arbitrary) MBeanServer if not already
 * an MBeanServer is registered. This service is required by Aries JMX.

 * @author roland
 * @since Jan 9, 2010
 */
public class OsgishActivator implements BundleActivator {

    // Name of our MBeans
    private ObjectName serviceMBeanName;
    private ObjectName uploadStoreMBeanName;

    // MBeanServer where we registered our MBeans
    private MBeanServer mBeanServer;

    // Service Tracker for HttpService
    private ServiceTracker httpServiceTracker;

    // Service Tracker for the JolokiaContext
    private ServiceTracker jolokiaTracker;

    // Tracker to be used for the LogService
    private ServiceTracker logTracker;

    // Registration of our MBeanServer Service. Might be null
    private ServiceRegistration mBeanServerRegistration;

    // Directory used for upload
    private File uploadDir;

    // Alias of the upload servlet
    private String uploadServiceAlias;

    public void start(BundleContext pContext) throws Exception {
        uploadDir = getUploadDirectory(pContext);

        openLogTracker(pContext);
        registerMBeanServer(pContext);
        registerMBeans(pContext);
        startJolokiaContextTracker(pContext);
    }

    public void stop(BundleContext pContext) throws Exception {
        unregisterMBeans();
        unregisterMBeanServer();
        closeLogTracker();
    }


    private void registerMBeanServer(BundleContext pContext) {
        ServiceReference mBeanServerRef = pContext.getServiceReference(MBeanServer.class.getCanonicalName());
        if (mBeanServerRef == null) {
            // Register a MBeanServer as service
            mBeanServer = getMBeanServer();
            mBeanServerRegistration =
                    pContext.registerService(MBeanServer.class.getCanonicalName(), mBeanServer, null);
        } else {
            boolean serviceFound = true;
            try {
                mBeanServer = (MBeanServer) pContext.getService(mBeanServerRef);
                if (mBeanServer == null) {
                    mBeanServer = getMBeanServer();
                    pContext.registerService(MBeanServer.class.getCanonicalName(), mBeanServer, null);
                    serviceFound = false;
                }
            } finally {
                if (mBeanServerRef != null && serviceFound) {
                    pContext.ungetService(mBeanServerRef);
                }
                mBeanServerRegistration = null;
            }
        }
    }

    // Unregister MBeanServer Service if we did the registration.
    // Might not be necessary, since the framework will stop the service anyway
    // But we are nice ;-)
    private void unregisterMBeanServer() {
        if (mBeanServerRegistration != null) {
            mBeanServerRegistration.unregister();
            mBeanServerRegistration = null;
        }
        mBeanServer = null;
    }

    // Register our own service for MBeanServer at use.
    private void registerMBeans(BundleContext pBundleContext)
            throws MBeanRegistrationException, InstanceAlreadyExistsException, NotCompliantMBeanException {
        OsgishService service = new OsgishService(pBundleContext);
        serviceMBeanName = mBeanServer.registerMBean(service,null).getObjectName();

        UploadStore uploadStore = new UploadStore(uploadDir);
        uploadStoreMBeanName = mBeanServer.registerMBean(uploadStore,null).getObjectName();
    }

    // Un-Register MBean. Since we want to use the same MBeanSever as during registration
    // We kept a reference to the mbean server
    private void unregisterMBeans() throws InstanceNotFoundException, MBeanRegistrationException {
        if (mBeanServer != null) {
            mBeanServer.unregisterMBean(serviceMBeanName);
            mBeanServer.unregisterMBean(uploadStoreMBeanName);
        }
    }

    private MBeanServer getMBeanServer() {
        // Using this one, which is always there. No security in mind, though.
        // Alternative: Use a new MBeanServer() ?
        return ManagementFactory.getPlatformMBeanServer();
    }

    // Register servlet at HttpService if it becomes available. This is a two step process:
    // First, it is waited that the JolokiaContext comes online as a service. It will contain
    // the servlet alias to register under as well as the security config. Next, the HttpService
    // is waited for to register the servlet itself.
    private void startJolokiaContextTracker(BundleContext pContext) {
        UploadServlet uploadServlet = new UploadServlet(logTracker,uploadDir);
        jolokiaTracker = new ServiceTracker(pContext, JolokiaContext.class.getName(),
                                                getJolokiaContextRegistrationCustomizer(pContext, uploadServlet));
        jolokiaTracker.open();
    }

    private ServiceTrackerCustomizer getJolokiaContextRegistrationCustomizer(final BundleContext pContext,
                                                                             final UploadServlet pUploadServlet) {
        return new ServiceTrackerCustomizer() {
            public Object addingService(ServiceReference reference) {
                JolokiaContext jolokiaContext = (JolokiaContext) pContext.getService(reference);
                uploadServiceAlias = pUploadServlet.getServletAlias(jolokiaContext.getServletAlias());
                registerUploadServlet(jolokiaContext, pContext, pUploadServlet);
                return jolokiaContext;
            }

            public void modifiedService(ServiceReference reference, Object service) {
            }

            public void removedService(ServiceReference reference, Object service) {
            }
        };
    }

    // Register the upload servlet indirectrly via an HttpService (we are using a tracker to play nicely the dynamics)
    private void registerUploadServlet(JolokiaContext pJolokiaContext, BundleContext pContext, UploadServlet pUploadServlet) {
        httpServiceTracker = new ServiceTracker(pContext, HttpService.class.getName(),
                                                getHttpServiceRegistrationCustomizer(pContext, pUploadServlet, pJolokiaContext));
        httpServiceTracker.open();
    }


    // The customizer listens for when the HttpService gets online and registers the servlet accordingly
    private ServiceTrackerCustomizer getHttpServiceRegistrationCustomizer(final BundleContext pContext,
                                                                          final UploadServlet pUploadServlet, final JolokiaContext pJolokiaContext) {

        final String alias = pUploadServlet.getServletAlias(pJolokiaContext.getServletAlias());
        return new ServiceTrackerCustomizer() {
            public Object addingService(ServiceReference reference) {
                HttpService httpService = (HttpService) pContext.getService(reference);
                try {
                    httpService.registerServlet(alias,
                                                pUploadServlet,
                                                null,pJolokiaContext.getHttpContext()
                                                );
                } catch (ServletException e) {
                    log(LogService.LOG_ERROR,"ServletException during registration of " + alias,e);
                } catch (NamespaceException e) {
                    log(LogService.LOG_ERROR,"NamespaceException during registration of " + alias,e);
                }
                return httpService;
            }

            public void modifiedService(ServiceReference reference, Object service) {
            }

            public void removedService(ServiceReference reference, Object service) {
                HttpService httpService = (HttpService) service;
                httpService.unregister(alias);
            }
        };
    }

    // Logging
    private void openLogTracker(BundleContext pContext) {
        // Track logging service
        logTracker = new ServiceTracker(pContext, LogService.class.getName(), null);
        logTracker.open();
    }



    private void closeLogTracker() {
        logTracker.close();
        logTracker = null;
    }

    private void log(int level,String message, Exception ... exp) {
        LogService logService = (LogService) logTracker.getService();
        if (logService != null) {
            if (exp != null && exp.length > 0) {
                logService.log(level,message,exp[0]);
            } else {
                logService.log(level,message);
            }
        } else {
            System.err.println((level == LogService.LOG_ERROR ? "ERROR: " : "") + message);
            if (exp != null && exp.length > 0) {
                exp[0].printStackTrace(System.err);
            }
        }
    }

    // Check for a upload directory
    private File getUploadDirectory(BundleContext pContext) {
        File dir = pContext.getDataFile("");
        if (dir == null) {
            // In case the OSGi container doesnt support a bundle specific data directory
            try {
                dir = File.createTempFile("osgish-upload",".dir");
                if(!dir.delete() || !dir.mkdir()) {
                    throw new IllegalStateException("Cannot create temporary directory " + dir.getAbsolutePath());
                }
            } catch (IOException e) {
                throw new IllegalStateException("Cannot get a upload directory: " + e,e);
            }
        }
        return dir;
    }
}
