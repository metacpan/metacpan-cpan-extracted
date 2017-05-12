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

static gboolean
xfce4perl_match_func(const gchar *basedir,
                     const gchar *relpath,
                     gpointer user_data)
{
    GPerlCallback *callback = user_data;
    GValue retval = {0,};
    gboolean ret;
    
    g_value_init(&retval, G_TYPE_BOOLEAN);
    gperl_callback_invoke(callback, &retval, basedir, relpath);
    ret = g_value_get_boolean(&retval);
    g_value_unset(&retval);
    
    return ret;
}

static gchar **
xfce4perl_xfce_resource_match_custom(XfceResourceType type,
                                     gboolean unique,
                                     SV *func,
                                     SV *user_data)
{
   gchar **files = NULL;
   GPerlCallback *callback;
   GType param_types[2];
   
   param_types[0] = G_TYPE_STRING;
   param_types[1] = G_TYPE_STRING;
   
   callback = gperl_callback_new(func, user_data,
                                 2, param_types,
                                 G_TYPE_BOOLEAN);
   files = xfce_resource_match_custom(type, unique,
                                      xfce4perl_match_func, callback);
   gperl_callback_destroy(callback);
   
   return files;
}

MODULE = Xfce4::Resource    PACKAGE = Xfce4::Resource    PREFIX = xfce_resource_

=for apidoc
=for signature list = Xfce4::Resource->dirs ($type)
=for arg type (Xfce4::ResourceType)
Returns a list of directories searched for the selected resource type.
=cut
## gchar **xfce_resource_dirs(XfceResourceType type)
void
xfce_resource_dirs(class, type)
        XfceResourceType type
    PREINIT:
        gchar **dirs = NULL;
        gint i;
    PPCODE:
        dirs = xfce_resource_dirs(type);
        for(i = 0; dirs[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; dirs[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(dirs[i])));
        g_strfreev(dirs);


=for apidoc
=for signature string = Xfce4::Resource->lookup ($type, $filename)
=cut
gchar *
xfce_resource_lookup(class, type, filename)
        XfceResourceType type
        const gchar *filename
    C_ARGS:
        type,
        filename

=for apidoc
=for signature list = Xfce4::Resource->lookup_all ($type, $filename)
=cut    
## gchar **xfce_resource_lookup_all(XfceResourceType type,
##                                  const gchar *filename)
void
xfce_resource_lookup_all(class, type, filename)
        XfceResourceType type
        const gchar *filename
    PREINIT:
        gchar **files = NULL;
        gint i;
    PPCODE:
        files = xfce_resource_lookup_all(type, filename);
        for(i = 0; files[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; files[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(files[i])));
        g_strfreev(files);

=for apidoc
=for signature list = Xfce4::Resource->match ($type, $pattern, $unique)
=cut
## gchar **xfce_resource_match(XfceResourceType type,
##                             const gchar     *pattern,
##                             gboolean         unique)
void
xfce_resource_match(class, type, pattern, unique)
        XfceResourceType type
        const gchar *pattern
        gboolean unique
    PREINIT:
        gchar **files = NULL;
        gint i;
    PPCODE:
        files = xfce_resource_match(type, pattern, unique);
        for(i = 0; files[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; files[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(files[i])));
        g_strfreev(files);

=for apidoc
=for signature list = Xfce4::Resource->match_custom ($type, $unique, $match_func, $user_data)
=for arg func (__hide__)
=for arg user_data (scalar)
=for arg match_func (function)
=for arg unique (boolean)
=for arg type (Xfce4::ResourceType)
=cut
## gchar **xfce_resource_match_custom(XfceResourceType type,
##                                    gboolean unique,
##                                    XfceMatchFunc func,
##                                    gpointer user_data)
void
xfce_resource_match_custom(class, type, unique, func, user_data)
        XfceResourceType type
        gboolean unique
        SV * func
        SV * user_data
    PREINIT:
        gchar **files = NULL;
        gint i;
    PPCODE:
        files = xfce4perl_xfce_resource_match_custom(type,
                                                     unique,
                                                     func,
                                                     user_data=NULL);
        for(i = 0; files[i]; i++)
            ;
        EXTEND(SP, i);
        for(i = 0; files[i]; i++)
            PUSHs(sv_2mortal(newSVGChar(files[i])));
        g_strfreev(files);

=for apidoc
=for signature Xfce4::Resource->push_path ($type, $path)
=cut
void
xfce_resource_push_path(class, type, path)
        XfceResourceType type
        const gchar *path
    C_ARGS:
        type,
        path

=for apidoc
=for signature Xfce4::Resource->pop_path ($type)
=cut
void
xfce_resource_pop_path(class, type)
        XfceResourceType type
    C_ARGS:
        type

=for apidoc
=for signature string = Xfce4::Resource->save_location ($type, $relpath, $create)
=cut
gchar *
xfce_resource_save_location(class, type, relpath, create)
        XfceResourceType type
        const gchar *relpath
        gboolean create
    C_ARGS:
        type,
        relpath,
        create
