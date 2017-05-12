/**
 * @file darray.h (double array)
 * @author Hightman Mar
 * @editor set number ; syntax on ; set autoindent ; set tabstop=4 (vim)
 * $Id: darray.h,v 1.1.1.1 2007/06/05 04:19:45 hightman Exp $
 */

#ifndef	_SCWS_DARRAY_20070525_H_
#define	_SCWS_DARRAY_20070525_H_

#ifdef HAVE_CONFIG_H
#	include "config.h"
#endif


void **darray_new(int row, int col, int size);
void darray_free(void **arr);

#endif
