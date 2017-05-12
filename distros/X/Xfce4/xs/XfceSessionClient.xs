/* NOTE: THIS FILE WAS POSSIBLY AUTO-GENERATED! */

/*
 * Copyright (c) 2005 Brian Tarricone <bjt23@cornell.edu>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "xfce4perl.h"

MODULE = Xfce4::SessionClient    PACKAGE = Xfce4::SessionClient    PREFIX = client_session_

SessionClient *
client_session_new_full(class, data, restart_style, priority, client_id, program, current_directory, restart_command, clone_command, discard_command, resign_command, shutdown_command)
        gpointer data
        SessionRestartStyle restart_style
        gchar priority
        gchar * client_id
        gchar * program
        gchar * current_directory
        gchar ** restart_command
        gchar ** clone_command
        gchar ** discard_command
        gchar ** resign_command
        gchar ** shutdown_command

SessionClient *
client_session_new(class, argc, argv, data, restart_style, priority)
        gint argc
        gchar **argv
        gpointer data
        SessionRestartStyle restart_style
        gchar priority

gboolean
client_session_init(session_client)
        SessionClient * session_client
    CODE:
        RETVAL = session_init(session_client);
    OUTPUT:
        RETVAL

void
client_session_shutdown(session_client)
        SessionClient * session_client
    CODE:
        session_shutdown(session_client);

void
client_session_logout(session_client)
        SessionClient * session_client
    CODE:
        logout_session(session_client);
