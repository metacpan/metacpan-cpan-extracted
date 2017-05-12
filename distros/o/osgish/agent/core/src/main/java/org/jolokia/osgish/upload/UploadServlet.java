package org.jolokia.osgish.upload;

import org.apache.commons.fileupload.FileItemIterator;
import org.apache.commons.fileupload.FileItemStream;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.osgi.service.log.LogService;
import org.osgi.util.tracker.ServiceTracker;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;

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
 * Servlet used for uploading bundles
 *
 * @author roland
 * @since Jan 26, 2010
 */
public class UploadServlet extends HttpServlet {

    // for logging. It is supposed to be open and managed outside
    private ServiceTracker logTracker;

    // Directory where to upload
    private File uploadDirectory;

    public UploadServlet(ServiceTracker pLogTracker,File pDataDir) {
        logTracker = pLogTracker;

        uploadDirectory = pDataDir;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        throw new ServletException("GET is not supported for file upload");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!ServletFileUpload.isMultipartContent(request)) {
            throw new ServletException("Request has no multipart content");
        }
        // Create a new file upload handler
        ServletFileUpload upload = new ServletFileUpload();

        // Parse the request
        FileItemIterator iter;
        try {
            iter = upload.getItemIterator(request);
            while (iter.hasNext()) {
                FileItemStream item = iter.next();
                InputStream in = item.openStream();
                if (item.isFormField()) {
                    throw new ServletException("A Form field is not expected here");
                } else {
                    File dest = new File(uploadDirectory, item.getName());
                    try {
                        OutputStream out = new FileOutputStream(dest);
                        copy(in,out);
                        LogService log = (LogService) logTracker.getService();
                        if (log != null) {
                            log.log(LogService.LOG_INFO,"Uploaded " + dest.getName() +
                                    " (size: " + dest.length() + ")");
                        }
                        // TODO: Return internal location/url of this bundle
                    } catch (IOException exp) {
                        throw new ServletException("Cannot copy uploaded file to " +
                                dest.getAbsolutePath() + ": " + exp,exp);
                    }
                }
            }
        } catch (FileUploadException e) {
            throw new ServletException("Upload failed: " + e,e);
        }
        response.setStatus(HttpServletResponse.SC_OK);
    }

    // Copy input stream in output directory
    private void copy(InputStream in,OutputStream out) throws IOException {
		try {
			byte[] buffer = new byte[4096];
			int bytesRead;
			while ((bytesRead = in.read(buffer)) != -1) {
				out.write(buffer, 0, bytesRead);
			}
			out.flush();
		}
		finally {
			try { in.close();} catch (IOException ex) { }
			try { out.close(); }catch (IOException ex) {}
		}
	}

    /**
     * Get the upload alias based on the already install j4p alias
     *
     * @param pServletAlias j4p servlet alias
     * @return alias with suffix for how his servlet needs to be registered.
     */
    public String getServletAlias(String pServletAlias) {
        return pServletAlias + "-upload";
    }
}
