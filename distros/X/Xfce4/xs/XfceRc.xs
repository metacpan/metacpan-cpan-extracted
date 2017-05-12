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

typedef XfceRc * Xfce4__Rc;

MODULE = Xfce4::Rc    PACKAGE = Xfce4::Rc    PREFIX = xfce_rc_

##Xfce4::Rc
##xfce_rc_simple_open(class, filename, readonly)
##        const gchar     * filename
##        gboolean readonly
##    C_ARGS:
##        filename,
##        readonly

##Xfce4::Rc
##xfce_rc_config_open(class, type, resource, readonly)
##        XfceResourceType type
##        const gchar     * resource
##        gboolean readonly
##    C_ARGS:
##        type,
##        resource,
##        readonly


=for apidoc Xfce4::Rc::open
=for signature rc = Xfce4::Rc->open ($filename, $readonly)
=for signature rc = Xfce4::Rc->open ($type, $resource, $readonly)
=for arg arg1 (__hide__)
=for arg arg2 (__hide__)
=for arg arg3 (__hide__)
=for arg readonly (boolean)
=for arg filename (string)
=for arg resource (string)
=for arg type (Xfce4::ResourceType)
The two-argument version opens an RC file using an absoulte pathname.
The three-argument version opens an RC file using a resource type and the
XDG base directory spec to locate the file.
=cut

=for apidoc Xfce4::Rc::simple_open
=for signature rc = Xfce4::Rc->simple_open ($filename, $readonly)
=for arg arg1 (__hide__)
=for arg arg2 (__hide__)
=for arg arg3 (__hide__)
=for arg readonly (boolean)
=for arg filename (string)
=cut

=for apidoc Xfce4::Rc::config_open
=for signature rc = Xfce4::Rc->config_open ($type, $resource, $readonly)
=for arg arg1 (__hide__)
=for arg arg2 (__hide__)
=for arg arg3 (__hide__)
=for arg readonly (boolean)
=for arg resource (string)
=for arg type (Xfce4::ResourceType)
=cut

## this is a little icky.  depending on which is the correct function to call,
## the datatypes of the arguments are different.
Xfce4::Rc
xfce_rc_open(class, arg1, arg2, arg3=NULL)
    ALIAS:
        Xfce4::Rc::simple_open = 1
        Xfce4::Rc::config_open = 2
    PREINIT:
        XfceResourceType type;
        const gchar *resource;
        gboolean readonly;
    CODE:
        if(ix == 0 && (items != 3 && items != 4))
            croak("Usage: Xfce4::Rc->open(type=NULL, resource, readonly)");
        else if(ix == 1 && items != 3)
            croak("Usage: Xfce4::Rc->simple_open(filename, readonly)");
        else if(ix == 2 && items != 4)
            croak("Usage: Xfce4::Rc->config_open(type, resource, readonly)");
        
        if((ix == 0 && items == 3) || (ix == 1)) {
            resource = SvGChar(ST(1));
            readonly = (bool)SvTRUE(ST(2));
            RETVAL = xfce_rc_simple_open(resource, readonly);
        } else if((ix == 0 && items == 4) || (ix == 2)) {
            type = SvXfceResourceType(ST(1));
            resource = SvGChar(ST(2));
            readonly = (bool)SvTRUE(ST(3));
            RETVAL = xfce_rc_config_open(type, resource, readonly);
        } else {
            croak("Xfce4::Rc->open(): Something weird (and bad) happened.");
            RETVAL = NULL;
        }
    OUTPUT:
        RETVAL

void
xfce_rc_DESTROY(rc)
        Xfce4::Rc rc
    CODE:
        xfce_rc_close(rc);

## do not bind this function, as perl's automatic MM will take care of it.
## void
## xfce_rc_close(rc)
##        XfceRc * rc

void
xfce_rc_flush(rc)
        Xfce4::Rc rc

void
xfce_rc_rollback(rc)
        Xfce4::Rc rc

gboolean
xfce_rc_is_dirty(rc)
        Xfce4::Rc rc

gboolean
xfce_rc_is_readonly(rc)
        Xfce4::Rc rc

const gchar *
xfce_rc_get_locale(rc)
        Xfce4::Rc rc

## gchar **xfce_rc_get_groups(const XfceRc *rc)
void
xfce_rc_get_groups(rc)
        Xfce4::Rc rc
    PREINIT:
        gchar **groups = NULL;
        gint i;
    PPCODE:
        groups = xfce_rc_get_groups(rc);
        for(i = 0; groups[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; groups[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(groups[i])));
        g_strfreev(groups);

## gchar **xfce_rc_get_entries(const XfceRc *rc, const gchar *group)
void
xfce_rc_get_entries(rc, group)
        Xfce4::Rc rc
        const gchar  * group
    PREINIT:
        gchar **entries = NULL;
        gint i;
    PPCODE:
        entries = xfce_rc_get_entries(rc, group);
        for(i = 0; entries[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; entries[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(entries[i])));
        g_strfreev(entries);

void
xfce_rc_delete_group(rc, group, global)
        Xfce4::Rc      rc
        const gchar  * group
        gboolean       global

const gchar *
xfce_rc_get_group(rc)
        Xfce4::Rc rc

gboolean
xfce_rc_has_group(rc, group)
        Xfce4::Rc rc
        const gchar  * group

void
xfce_rc_set_group(rc, group)
        Xfce4::Rc      rc
        const gchar  * group

void
xfce_rc_delete_entry(rc, key, global)
        Xfce4::Rc      rc
        const gchar  * key
        gboolean       global

gboolean
xfce_rc_has_entry(rc, key)
        Xfce4::Rc      rc
        const gchar  * key

const gchar*
xfce_rc_read_entry(rc, key, fallback)
        Xfce4::Rc      rc
        const gchar  * key
        const gchar  * fallback

const gchar*
xfce_rc_read_entry_untranslated(rc, key, fallback)
        Xfce4::Rc      rc
        const gchar  * key
        const gchar  * fallback

gboolean
xfce_rc_read_bool_entry(rc, key, fallback)
        Xfce4::Rc      rc
        const gchar  * key
        gboolean       fallback

gint
xfce_rc_read_int_entry(rc, key, fallback)
        Xfce4::Rc      rc
        const gchar  * key
        gint           fallback

## gchar** xfce_rc_read_list_entry(const XfceRc *rc,
##                                 const gchar *key,
##                                 const gchar *delimiter)
void
xfce_rc_read_list_entry(rc, key, delimiter)
        Xfce4::Rc      rc
        const gchar  * key
        const gchar  * delimiter
    PREINIT:
        gchar **entries = NULL;
        gint i;
    PPCODE:
        entries = xfce_rc_read_list_entry(rc, key, delimiter);
        for(i = 0; entries[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; entries[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(entries[i])));
        g_strfreev(entries);

void
xfce_rc_write_entry(rc, key, value)
        Xfce4::Rc      rc
        const gchar  * key
        const gchar  * value

void
xfce_rc_write_bool_entry(rc, key, value)
        Xfce4::Rc      rc
        const gchar  * key
        gboolean       value

void
xfce_rc_write_int_entry(rc, key, value)
        Xfce4::Rc      rc
        const gchar  * key
        gint           value

## void xfce_rc_write_list_entry(XfceRc *rc,
##                               const gchar *key,
##                               const gchar *value,
##                               const gchar *separator)
void
xfce_rc_write_list_entry(rc, key, ...)
        Xfce4::Rc      rc
        const gchar  * key
    PREINIT:
        gchar **value = NULL;
        gint nvalues, i;
        gchar *separator = NULL;
    CODE:
        nvalues = items - 3;
        value = g_new(gchar *, nvalues+1);
        for(i = 0; i < nvalues; i++)
          value[i] = SvGChar(ST(i+2));
        value[nvalues] = NULL;
        separator = SvGChar(ST(i));
        
        xfce_rc_write_list_entry(rc, key, value, separator);
        
        g_free(value);  /* gstrfreev()? */
