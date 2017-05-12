package org.jolokia.osgish.upload;

import javax.management.MBeanRegistration;
import javax.management.MBeanServer;
import javax.management.ObjectName;
import java.io.File;
import java.util.HashMap;
import java.util.Map;

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
 * Implemententaion of an upload store.
 *
 * @author roland
 * @since Jan 27, 2010
 */
public class UploadStore implements UploadStoreMBean, MBeanRegistration {

    File dataDir;

    // Name to be used for registering as MBean
    private static final String UPLOAD_STORE_NAME = "osgish:type=Upload";

    public UploadStore(File pDataDir) {
        dataDir = pDataDir;
        if (!dataDir.exists()) {
            throw new IllegalArgumentException("No data directory " + dataDir.getAbsolutePath() + " found");
        }
        if (!dataDir.isDirectory()) {
            throw new IllegalArgumentException(dataDir.getAbsolutePath() + " is not a directory");
        }
    }

    public Map listUploadDirectory() {
        File files[] = dataDir.listFiles();
        Map<String,File> ret = new HashMap<String,File>();
        for (File file : files) {
            ret.put(file.getName(),file);
        }
        return ret;
    }

    public String deleteFile(String pFilename) {
        if (pFilename == null) {
            return "No filename given";
        }
        if (pFilename.startsWith("/")) {
            return "Path " + pFilename + " must not be an absolute path";
        }
        File dir = dataDir;

        // Dive into the directory
        String parts[] = pFilename.split("/");
        String last = parts[parts.length-1];
        for (int i = 0;i<parts.length - 1;i++) {
            dir = new File(dir,parts[i]);
            if (!dir.isDirectory()) {
                return dir.getPath() + " is not a directory";
            }
        }
        File file = new File(dir,last);
        if (!file.exists()) {
            return file.getName() + ": No such file";
        }
        if (!file.delete()) {
            return "Could not delete file " + file.getName();
        }
        return null;
    }

    public ObjectName preRegister(MBeanServer server, ObjectName name) throws Exception {
        // We are providing our own name
        return new ObjectName(UPLOAD_STORE_NAME);
    }

    public void postRegister(Boolean registrationDone) {
    }

    public void preDeregister() throws Exception {
    }

    public void postDeregister() {
    }
}
