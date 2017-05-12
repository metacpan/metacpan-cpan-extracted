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

static GHashTable *free_data_funcs = NULL;

static gboolean
xfce4perl_free_old_callbacks(NetkTasklist *tasklist)
{
    GPerlCallback *old_load_callback, *old_free_callback;
    
    old_load_callback = g_object_get_data(G_OBJECT(tasklist),
                                          "xfce4perl-callback");
    if(old_load_callback) {
        old_free_callback = g_hash_table_lookup(free_data_funcs,
                                                old_load_callback);
        if(old_free_callback) {
            g_hash_table_remove(free_data_funcs, old_free_callback);
            gperl_callback_destroy(old_free_callback);
        }
        gperl_callback_destroy(old_load_callback);
        g_object_set_data(G_OBJECT(tasklist), "xfce4perl-callback", NULL);
        
        return TRUE;
    }
    
    return FALSE;
}


static GdkPixbuf *
xfce4perl_load_icon_func(const char *icon_name,
                         int size,
                         unsigned int flags,
                         void *data)
{
    GdkPixbuf *ret = NULL;
    GValue retval = {0,};
    
    g_value_init(&retval, GDK_TYPE_PIXBUF);
    gperl_callback_invoke((GPerlCallback *)data, &retval,
                          icon_name, size, flags);
    ret = g_value_get_pointer(&retval);
    g_value_unset(&retval);
    
    return ret;
}

static void
xfce4perl_free_data_func(gpointer user_data)
{
    GPerlCallback *free_callback;
    
    free_callback = g_hash_table_lookup(free_data_funcs, user_data);
    if(free_callback)
        gperl_callback_invoke(free_callback, NULL);
    
    /* FIXME: do we need to free stuff at this point? */
}

static void
xfce4perl_netk_tasklist_set_icon_loader(NetkTasklist *tasklist,
                                        SV *load_icon_func,
                                        SV *data,
                                        SV *free_data_func)
{
    GPerlCallback *load_callback, *free_callback;
    GPerlCallback *old_load_callback, *old_free_callback;
    GType param_types[3];

    param_types[0] = G_TYPE_STRING;
    param_types[1] = G_TYPE_INT;
    param_types[2] = G_TYPE_UINT;
    
    /* this is kinda icky */
    if(!free_data_funcs) {
        free_data_funcs = g_hash_table_new_full(g_direct_hash,
                                                g_direct_equal,
                                                NULL,
                                                (GDestroyNotify)gperl_callback_destroy);
    }
    
    load_callback = gperl_callback_new(load_icon_func,
                                       data,
                                       3, param_types,
                                       GDK_TYPE_PIXBUF);
    free_callback = gperl_callback_new(free_data_func,
                                       data,
                                       0, NULL,
                                       G_TYPE_NONE);
    
    g_hash_table_insert(free_data_funcs, load_callback, free_callback);
    
    netk_tasklist_set_icon_loader(tasklist,
                                  xfce4perl_load_icon_func,
                                  load_callback,
                                  xfce4perl_free_data_func);
    
    if(!xfce4perl_free_old_callbacks(tasklist)) {
        g_signal_connect(G_OBJECT(tasklist), "destroy",
                         G_CALLBACK(xfce4perl_free_old_callbacks), NULL);
    }
}

MODULE = Xfce4::Netk::Tasklist    PACKAGE = Xfce4::Netk::Tasklist    PREFIX = netk_tasklist_

GtkWidget *
netk_tasklist_new(class, screen)
        NetkScreen * screen
    C_ARGS:
        screen

void
netk_tasklist_set_screen(tasklist, screen)
        NetkTasklist * tasklist
        NetkScreen * screen

## const int *netk_tasklist_get_size_hint_list(NetkTasklist *tasklist,
##                                             int *n_elements)
void
netk_tasklist_get_size_hint_list(tasklist)
        NetkTasklist * tasklist
    PREINIT:
        int n_elements = 0;
        const int *size_hints = NULL;
        gint i;
    INIT:
        dXSTARG;
    PPCODE:
        size_hints = netk_tasklist_get_size_hint_list(tasklist, &n_elements);
        EXTEND(SP, n_elements);
        for(i = n_elements - 1; i >= 0; i--)
            PUSHi(sv_2mortal(newSViv(size_hints[i])));

void
netk_tasklist_set_grouping(tasklist, grouping)
        NetkTasklist * tasklist
        NetkTasklistGroupingType grouping

void
netk_tasklist_set_grouping_limit(tasklist, limit)
        NetkTasklist * tasklist
        gint limit

void
netk_tasklist_set_include_all_workspaces(tasklist, include_all_workspaces)
        NetkTasklist * tasklist
        gboolean include_all_workspaces

void
netk_tasklist_set_show_label(tasklist, show_label)
        NetkTasklist * tasklist
        gboolean show_label

void
netk_tasklist_set_minimum_width(tasklist, size)
        NetkTasklist * tasklist
        gint size

gint
netk_tasklist_get_minimum_width(tasklist)
        NetkTasklist * tasklist

void
netk_tasklist_set_minimum_height(tasklist, size)
        NetkTasklist * tasklist
        gint size

gint
netk_tasklist_get_minimum_height(tasklist)
        NetkTasklist * tasklist

## void netk_tasklist_set_icon_loader(NetkTasklist *tasklist,
##                                    NetkLoadIconFunction load_icon_func,
##                                    void *data,
##                                    GDestroyNotify free_data_func)
void
netk_tasklist_set_icon_loader(tasklist, load_icon_func, data, free_data_func)
        NetkTasklist * tasklist
        SV * load_icon_func
        SV * data
        SV * free_data_func
    CODE:
        xfce4perl_netk_tasklist_set_icon_loader(tasklist, 
                                                load_icon_func,
                                                data=NULL,
                                                free_data_func=NULL);
