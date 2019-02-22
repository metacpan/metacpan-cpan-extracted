/* -*- Mode: C -*- */

/*--------------------------------------------------------------------------
 * File: dtaTwConfig.h
 * Author: Bryan Jurish <configure.ac>
 * Description:
 *   + DTA tokenizer wrapper : configuration (hack)
 *--------------------------------------------------------------------------*/

/* 
 * Define a sentinel preprocessor symbol _DTATW_CONFIG_H, just
 * in case someone wants to check whether we've already
 * (#include)d this file ....
 */
#ifndef _DTATW_CONFIG_H
#define _DTATW_CONFIG_H
#endif /* _DTATW_CONFIG_H */

/* 
 * Putting autoheader files within the above #ifndef/#endif idiom
 * is potentially a BAD IDEA, since we might need to (re-)define
 * the package's autoheader-generated preprocessor symbols (e.g. after
 * (#include)ing in some config.h from another autoheader package
 */
#include <dtatwConfigNoAuto.h>
#include <dtatwConfigAuto.h>
