package org.jolokia.osgish.upload;

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
 * MBean for managing the upload store
 *
 * @author roland
 * @since Jan 27, 2010
 */
public interface UploadStoreMBean {

    /**
     * List the content of the upload director
     *
     * @return a map with the filename as key (string) and another map describing the files
     *         properties.
     */
    Map listUploadDirectory();

    /**
     * Delete a certain file in the directory
     *
     * @param pFilename name to delete
     * @return error message if any or null if everything was fine
     */
    String deleteFile(String pFilename);
}
