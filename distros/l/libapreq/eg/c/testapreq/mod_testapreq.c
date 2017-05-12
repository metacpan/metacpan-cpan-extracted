/*  Copyright 2000-2004  The Apache Software Foundation
**
**  Licensed under the Apache License, Version 2.0 (the "License");
**  you may not use this file except in compliance with the License.
**  You may obtain a copy of the License at
**
**      http://www.apache.org/licenses/LICENSE-2.0
**
**  Unless required by applicable law or agreed to in writing, software
**  distributed under the License is distributed on an "AS IS" BASIS,
**  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
**  See the License for the specific language governing permissions and
**  limitations under the License.
*/

#include "apache_request.h"
#include "apache_cookie.h"

module MODULE_VAR_EXPORT testapreq_module;

static void util_start_html(request_rec *r, char *title)
{
   ap_rputs("<HTML>\n", r);
   ap_rputs("<HEADER>\n", r);
   ap_rprintf(r, "<TITLE>%s</TITLE>\n", title);
   ap_rputs("</HEADER>\n", r);
   ap_rputs("<BODY>\n", r);
}

static void util_end_html(request_rec *r)
{
    ap_rputs("</BODY></HTML>\n", r);
}

static void util_start_form(request_rec *r, char *type)
{
    ap_rprintf(r, "<FORM METHOD=\"POST\"  ENCTYPE=\"%s\">\n",
	       type ? type : DEFAULT_ENCTYPE);
}

static void util_end_form(request_rec *r)
{
    ap_rputs("</FORM>\n", r);
}

static void util_submit(request_rec *r, char *name)
{
    ap_rprintf(r, "<INPUT TYPE=\"submit\" NAME=\"%s\">\n", 
	       name ? name : ".submit");
}

static void util_textfield(request_rec *r, char *key, char *val)
{
    ap_rprintf(r, "<INPUT TYPE=\"text\" NAME=\"%s\" VALUE=\"%s\">\n", key, val);
}

static void util_filefield(request_rec *r, char *key, char *val)
{
    ap_rprintf(r, "<INPUT TYPE=\"file\" NAME=\"%s\" VALUE=\"%s\">\n", key, val);
}

static int util_isa_default(char *wanted, char **list)
{
    int i;
    for(i=0; list[i]; i++) {
	if(strEQ(wanted, list[i]))
	    return 1;
    }
    return 0;
}

static void util_checkbox_group(request_rec *r, char *name, char **values, char **defaults)
{
    int i;
    for (i=0; values[i]; i++) {
	ap_rprintf(r, 
		   "<INPUT TYPE=\"checkbox\" NAME=\"%s\" VALUE=\"%s\" %s>%s\n",
		   name, values[i], 
		   util_isa_default(values[i], defaults) ?
		   "CHECKED" : "", values[i]);
    }
}

static void util_popup_menu(request_rec *r, char *name, char **values)
{
    int i;
    ap_rprintf(r, "<SELECT NAME=\"%s\">\n", name); 
    for (i=0; values[i]; i++) 
	ap_rprintf(r, "<OPTION  VALUE=\"%s\">%s\n", values[i], values[i]); 
    ap_rputs("</SELECT>\n", r);
}

#define P_SEP ap_rputs("<P>", r)

static char *checkbox_combo[] = {
    "eenie","meenie","minie","moe",NULL
};

static char *checkbox_combo_defaults[] = {
    "eenie","minie",NULL 
};

static char *popup_menu_colors[] = {
    "red","green","blue","chartreuse",NULL
};

/*
 * <Location /apreq-form-test> 
 * SetHandler apreq-form
 * </Location> 
 */
static int form_handler(request_rec *r) {
    ApacheRequest *req = ApacheRequest_new(r);
    int status = ApacheRequest_parse(req);

    if (status != OK) {
	return status;
    }

    r->content_type = "text/html";
    ap_send_http_header(r);

    util_start_html(r, "Hello");
    util_start_form(r, NULL);
    ap_rputs("What's your name? ", r);
    util_textfield(r, "name", "");
    P_SEP;
    ap_rputs("What's the combination?", r);
    P_SEP;
    util_checkbox_group(r, "words", 
			checkbox_combo, checkbox_combo_defaults);
    P_SEP;
    ap_rputs("What's your favorite color? ", r);
    util_popup_menu(r, "color", popup_menu_colors);
    P_SEP;
    util_submit(r, NULL);
    util_end_form(r);
    P_SEP;

    if(r->method_number == M_POST) {
        ap_rprintf(r, "Your name is: %s", 
		   ApacheRequest_param(req, "name")); 
        P_SEP;
        ap_rprintf(r, "The keywords are: %s", 
		   ApacheRequest_params_as_string(req, "words")); 
	P_SEP;
        ap_rprintf(r, "Your favorite color is: %s", 
		   ApacheRequest_param(req, "color")); 
   }

   util_end_html(r);
   return OK;
}

static int upload_handler(request_rec *r) {
    ApacheRequest *req = ApacheRequest_new(r);
    int status = ApacheRequest_parse(req);

    if (status != OK) {
	return status;
    }

    r->content_type = "text/html";
    ap_send_http_header(r);

    util_start_html(r, "Upload test");
    util_start_form(r, "multipart/form-data");
    ap_rputs("Select File: ", r);
    util_filefield(r, "filename", "");
    P_SEP;
    util_submit(r, NULL);
    util_end_form(r);

    if(r->method_number == M_POST) {
	char buf[IOBUFSIZE];
	ap_rprintf(r, "Filename: %s (%d)", 
		   ApacheRequest_param(req, "filename"),
		   (int)req->upload->size);
	P_SEP;
	while(fgets(buf, sizeof(buf), req->upload->fp)) {
	    ap_rputs(buf, r);
	}
    }

    util_end_html(r);
    return OK;
}

static int cookie_handler(request_rec *r) {
    ApacheCookieJar *cookies = ApacheCookie_parse(r, NULL);

    r->content_type = "text/html";

    if (ApacheCookieJarItems(cookies)) {
	int i;

	ap_send_http_header(r);
	util_start_html(r, "Cookie test");
	for (i=0; i<ApacheCookieJarItems(cookies); i++) {
	    ApacheCookie *c = ApacheCookieJarFetch(cookies, i);
	    ap_rprintf(r, "%s => %s\n",
		       c->name, ApacheCookie_as_string(c));
	    P_SEP;
	}
    }
    else {
	ApacheCookie *apc = ApacheCookie_new(r, 
					     "-name", "test", 
					     "-value", "foo",
					     NULL);
	ApacheCookie_expires(apc, "+1m");
	ApacheCookie_bake(apc);
	ap_send_http_header(r);
	util_start_html(r, "Cookie test");
	ap_rputs("No cookies in the jar", r);
    }
    util_end_html(r);
    return OK;
}

static handler_rec testapreq_handlers[] =
{
    {"apreq-form", form_handler},
    {"apreq-upload", upload_handler},
    {"apreq-cookie", cookie_handler},
    {NULL}
};

module MODULE_VAR_EXPORT testapreq_module =
{
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer                 */
    NULL,               /* per-directory config creator       */
    NULL,               /* dir config merger                  */
    NULL,               /* server config creator              */
    NULL,               /* server config merger               */
    NULL,               /* command table                      */
    testapreq_handlers, /* [7]  content handlers              */
    NULL,               /* [2]  URI-to-filename translation   */
    NULL,               /* [5]  check/validate user_id        */
    NULL,               /* [6]  check user_id is valid *here* */
    NULL,               /* [4]  check access by host address  */
    NULL,               /* [7]  MIME type checker/setter      */
    NULL,               /* [8]  fixups                        */
    NULL,               /* [9]  logger                        */
    NULL,               /* [3]  header parser                 */
    NULL,               /* process initialization             */
    NULL,               /* process exit/cleanup               */
    NULL                /* [1]  post read_request handling    */
};
