package org.jolokia.osgish;

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
 * MBean for osgish communication between 'osgish' and the osgi-agent bundle.
 *
 * @author roland
 */
public interface OsgishServiceMBean {


    /**
     * Check for state changs on the server side. A client can use this method in order
     * to determine, whether it should update an internal cache.
     *
     * @param pWhat what should be checked for changes
     *        ("bundles","services","all")
     * @param pTimestamp date since what state changes are
     *        taken into account (in epoch seconds)
     * @return true if the state changed, false otherwise
     */
    boolean hasStateChanged(String pWhat,long pTimestamp);
}
