/* HRR.h  -  Glue functions to adapt apr to both Apache httpd 2.2 and 2.4
 * Copyright (c) 2015 Synergetics NV (sampo@synergetics.be), All Rights Reserved.
 * Author: Sampo Kellomaki (sampo@iki.fi)
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing or as licensed below.
 * Licensed under Apache License 2.0, see file COPYING.
 * $Id: HRR.h,v 1.17 2010-01-08 02:10:09 sampo Exp $
 *
 * 12.4.2015,  created --Sampo
 *
 * http://httpd.apache.org/docs/2.2/developer/
 * http://modules.apache.org/doc/API.html
 */

#ifndef _HRR_H
#define _HRR_H 1

#ifdef USE_HRR

#define HRRC_headers_in      0
#define HRRC_headers_out     1
#define HRRC_err_headers_out 2
#define HRRC_pool            4
#define HRRC_args            5
#define HRRC_uri             6
#define HRRC_user            7
#define HRRC_filename        8
#define HRRC_path_info       9
#define HRRC_header_only    10
#define HRRC_remaining      11
#define HRRC_main           12
#define HRRC_method_number  13
#define HRRC_subprocess_env 14
#define HRRC_per_dir_config 15

#define HRR_headers_in(r)      HRR_field((r), HRRC_headers_in)
#define HRR_headers_out(r)     HRR_field((r), HRRC_headers_out)
#define HRR_err_headers_out(r) HRR_field((r), HRRC_err_headers_out)
#define HRR_pool(r)            HRR_field((r), HRRC_pool)
#define HRR_subprocess_env(r)  HRR_field((r), HRRC_subprocess_env)
#define HRR_args(r)            HRR_field((r), HRRC_args)
#define HRR_uri(r)             HRR_field((r), HRRC_uri)
#define HRR_user(r)            HRR_field((r), HRRC_user)
#define HRR_filename(r)        HRR_field((r), HRRC_filename)
#define HRR_path_info(r)       HRR_field((r), HRRC_path_info)
#define HRR_header_only(r)     HRR_field_int((r), HRRC_header_only)
#define HRR_remaining(r)       HRR_field_int((r), HRRC_remaining)
#define HRR_main(r)            HRR_field((r), HRRC_main)
#define HRR_method_number(r)   HRR_field_int((r), HRRC_method_number)
#define HRR_per_dir_config(r)  HRR_field((r), HRRC_per_dir_config)

#define HRR_set_args(r,v)      HRR_set_field((r), HRRC_args, (v))
#define HRR_set_uri(r,v)       HRR_set_field((r), HRRC_uri,  (v))
#define HRR_set_user(r,v)      HRR_set_field((r), HRRC_user, (v))

void* HRR_field(request_rec* r, int field);
int   HRR_field_int(request_rec* r, int field);
void  HRR_set_field(request_rec* r, int field, void* v);

#else

#define HRR_headers_in(r)      ((r)->headers_in)
#define HRR_headers_out(r)     ((r)->headers_out)
#define HRR_err_headers_out(r) ((r)->err_headers_out)
#define HRR_pool(r)            ((r)->pool)
#define HRR_subprocess_env(r)  ((r)->subprocess_env)
#define HRR_args(r)            ((r)->args)
#define HRR_uri(r)             ((r)->uri)
#define HRR_user(r)            ((r)->user)
#define HRR_filename(r)        ((r)->filename)
#define HRR_path_info(r)       ((r)->path_info)
#define HRR_header_only(r)     ((r)->header_only)
#define HRR_remaining(r)       ((r)->remaining)
#define HRR_main(r)            ((r)->main)
#define HRR_method_number(r)   ((r)->method_number)
#define HRR_per_dir_config(r)  ((r)->per_dir_config)

#define HRR_set_args(r,v)      ((r)->args = (v))
#define HRR_set_uri(r,v)       ((r)->uri  = (v))
#define HRR_set_user(r,v)      ((r)->user = (v))

#endif

#endif /* _HRR_H */
