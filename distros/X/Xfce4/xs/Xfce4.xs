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

MODULE = Xfce4    PACKAGE = Xfce4    PREFIX = xfce_

BOOT:
    {
#include "register.xsh"
#include "boot.xsh"
        
        gperl_handle_logs_for("Xfce");
    }


#####################  libxfce4util/xfce-miscutils.h #####################

=for object Xfce4::licenses Builtin License Information
=cut

=head1 DESCRIPTION

  The Xfce library contains copies of the three licenses used by Xfce:
  BSD, LGPL, and GPL.  These are mostly useful with L<Xfce4::AboutDialog>.

=cut

=for apidoc
Returns a string containing the entire text of the BSD license (without
advertising clause).
=cut
const gchar *
LICENSE_BSD()
    PREINIT:
        extern const char xfce_builtin_license_BSD[];
    CODE:
        RETVAL = xfce_builtin_license_BSD;
    OUTPUT:
        RETVAL

=for apidoc
Returns a string containing the entire text of the GNU General Public
License.
=cut
const gchar *
LICENSE_GPL()
    PREINIT:
        extern const char xfce_builtin_license_GPL[];
    CODE:
        RETVAL = xfce_builtin_license_GPL;
    OUTPUT:
        RETVAL

=for apidoc
Returns a string containing the entire text of the GNU Lesser General
Public License.
=cut
const gchar *
LICENSE_LGPL()
    PREINIT:
        extern const char xfce_builtin_license_LGPL[];
    CODE:
        RETVAL = xfce_builtin_license_LGPL;
    OUTPUT:
        RETVAL

=for object Xfce4::misc Miscellaneous Functions
=cut

=head1 SYNOPSIS

  Miscellaneous utility functions useful for Xfce application
  programmers.

=cut

=for apidoc
=for signature string = Xfce4->get_homedir
Returns a value for the user's homedir.  Tries harder than
g_get_homedir().
=cut
const gchar *
xfce_get_homedir(class)
    C_ARGS:
        /* void */

## rest of stuff in libxfce4util/xfce-miscutils.h aren't too useful in a
## perl environment.


##################### libxfcegui4/xfce-exec.h #####################


## gboolean xfce_exec(const char *exec,
##                    gboolean in_terminal,
##                    gboolean use_sn,
##                    GError **error)
=for apidoc
=for signature boolean = Xfce4->exec ($cmd, $in_terminal, $use_sn)
Runs 'cmd' and forks the process off into the background.  If 'in_termnial'
is true, will spawn a terminal first.  If 'use_sn' is true, will activate
startup notification.
=cut
gboolean
xfce_exec(class, cmd, in_terminal, use_sn)
        const char *cmd
        gboolean in_terminal
        gboolean use_sn
    PREINIT:
        GError *error = NULL;
    CODE:
        RETVAL = xfce_exec(cmd, in_terminal, use_sn, &error);
        if(!RETVAL)
            gperl_croak_gerror(cmd, error);
    OUTPUT:
        RETVAL

## TODO: implement me, use hash value for envp instead of "key=value" array
## gboolean xfce_exec_with_envp(const char *cmd,
##                              gboolean in_terminal,
##                              gboolean use_sn,
##                              GError **error,
##                              char **envp)


## gboolean xfce_exec_sync(const char *exec,
##                         gboolean in_terminal,
##                         gboolean use_sn,
##                         GError **error)
=for apidoc
=for signature boolean = Xfce4->exec_sync ($cmd, $in_terminal, $use_sn)
Runs 'cmd' and waits for it to return before proceeding.  If 'in_termnial'
is true, will spawn a terminal first.  If 'use_sn' is true, will activate
startup notification.
=cut
gboolean
xfce_exec_sync(class, cmd, in_terminal, use_sn)
        const char *cmd
        gboolean in_terminal
        gboolean use_sn
    PREINIT:
        GError *error = NULL;
    CODE:
        RETVAL = xfce_exec_sync(cmd, in_terminal, use_sn, &error);
        if(!RETVAL)
            gperl_croak_gerror(cmd, error);
    OUTPUT:
        RETVAL

## TODO: implement me, use hash value for envp instead of "key=value" array
## gboolean xfce_exec_sync_with_envp(const char *cmd,
##                                   gboolean in_terminal,
##                                   gboolean use_sn,
##                                   GError **error,
##                                   char **envp)


## versioning stuff ##

=for object Xfce4::version Library Version Information
=cut

=head1 DESCRIPTION

  Various version-related constants and functions.  Note that these all
  refer to the Xfce C library versions (e.g., libxfce4util), and not the
  version of this perl module.

=cut

=for apidoc
Returns a string containing the runtime Xfce version.
=cut
const gchar *
xfce_version_string()

=for apidoc
Provides a mechanism for checking the version that Xfce4 was compiled against.
Equivalent to the LIBXFCE4UTIL_CHECK_VERSION() macro.  You usually want to
use this to check for widget/function availability at perl runtime.
=cut
gboolean
XFCE_CHECK_VERSION(class, major, minor, micro)
        guint major
        guint minor
        guint micro
    CODE:
        RETVAL = LIBXFCE4UTIL_CHECK_VERSION(major, minor, micro);
    OUTPUT:
        RETVAL

=for apidoc Xfce4::MAJOR_VERSION __function__
The major version of the Xfce library against which Xfce4 was compiled.
=cut

=for apidoc Xfce4::MINOR_VERSION __function__
The minor version of the Xfce library against which Xfce4 was compiled.
=cut

=for apidoc Xfce4::MICRO_VERSION __function__
The micro version of the Xfce library against which Xfce4 was compiled.
=cut

guint
MAJOR_VERSION()
    ALIAS:
        Xfce4::MINOR_VERSION = 1
        Xfce4::MICRO_VERSION = 2
    CODE:
        switch(ix) {
            case 0: RETVAL = LIBXFCE4UTIL_MAJOR_VERSION; break;
            case 1: RETVAL = LIBXFCE4UTIL_MINOR_VERSION; break;
            case 2: RETVAL = LIBXFCE4UTIL_MICRO_VERSION; break;
            default:
                RETVAL = -1;
                g_assert_not_reached();
        }
    OUTPUT:
        RETVAL

=for apidoc Xfce4::major_version __function__
The major version of the Xfce library currently in use at runtime.
=cut

=for apidoc Xfce4::minor_version __function__
The minor version of the Xfce library currently in use at runtime.
=cut

=for apidoc Xfce4::micro_version __function__
The micron version of the Xfce library currently in use at runtime.
=cut

guint
xfce_major_version()
    ALIAS:
        Xfce4::minor_version = 1
        Xfce4::micro_version = 2
    CODE:
        guint major = 0, minor = 0, micro = 0;
        if(sscanf(xfce_version_string(), "%u.%u.%u", &major, &minor, &micro) == 3) {
            switch(ix) {
                case 0: RETVAL = major; break;
                case 1: RETVAL = minor; break;
                case 2: RETVAL = micro; break;
                default:
                    RETVAL = -1;
                    g_assert_not_reached();
            }
        } else
            RETVAL = 0;
    OUTPUT:
        RETVAL

