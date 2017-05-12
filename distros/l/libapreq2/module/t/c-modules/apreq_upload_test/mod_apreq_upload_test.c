/*
**  Licensed to the Apache Software Foundation (ASF) under one or more
** contributor license agreements.  See the NOTICE file distributed with
** this work for additional information regarding copyright ownership.
** The ASF licenses this file to You under the Apache License, Version 2.0
** (the "License"); you may not use this file except in compliance with
** the License.  You may obtain a copy of the License at
**
**      http://www.apache.org/licenses/LICENSE-2.0
**
**  Unless required by applicable law or agreed to in writing, software
**  distributed under the License is distributed on an "AS IS" BASIS,
**  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
**  See the License for the specific language governing permissions and
**  limitations under the License.
*/

#ifdef CONFIG_FOR_HTTPD_TEST
#if CONFIG_FOR_HTTPD_TEST

<Location /apreq_upload_test>
   SetHandler apreq_upload_test
</Location>

#endif
#endif

#define APACHE_HTTPD_TEST_HANDLER apreq_upload_test_handler

#include "apache_httpd_test.h"

#include "apreq_module.h"
#include "apreq_param.h"
#include "apreq_module_apache2.h"
#include "apreq_util.h"

#include "httpd.h"


static int apreq_upload_test_handler(request_rec *r)
{
    apreq_handle_t *req;
    const apreq_param_t *param;

    if (strcmp(r->handler, "apreq_upload_test") != 0) {
      return DECLINED;
    }

    req = apreq_handle_apache2(r) ;
 
    ap_log_rerror(APLOG_MARK, APLOG_DEBUG, APR_SUCCESS,
                  r, "starting apreq_upload_test");

    ap_set_content_type(r, "text/plain");

    param = apreq_body_get(req, "filename");

    if (param == NULL) {
      ap_rputs("missing upload field", r);
    }
    else if (param->upload == NULL) {
      ap_rputs("not an upload field", r);
    }
    else {
      apr_table_t *info;      /* upload headers */
      apr_bucket_brigade *bb; /* upload contents */
      apr_bucket *e;
      apr_size_t total = 0;

      info = param->info;
      bb = apr_brigade_create(r->pool, r->connection->bucket_alloc);
      apreq_brigade_copy(bb, param->upload);

      while ((e = APR_BRIGADE_FIRST(bb)) != APR_BRIGADE_SENTINEL(bb)) {
        apr_size_t dlen;
        const char *data;
         
        /* apr_bucket_read() has side effects on spool buckets, which
         * is why we read from a copy of the brigade - to conserve memory
         */
        if (apr_bucket_read(e, &data, &dlen, APR_BLOCK_READ)) {
          ap_rprintf(r, "bad bucket read");
          break;
        }
        else {
          total += dlen;
        }

        apr_bucket_delete(e);
      }

      ap_rprintf(r, "%d", total);
    }

    ap_log_rerror(APLOG_MARK, APLOG_DEBUG, APR_SUCCESS,
                  r, "finished apreq_upload_test");

    return OK;
}

APACHE_HTTPD_TEST_MODULE(apreq_upload_test);
