/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: tux_perl_imp.c,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <EXTERN.h>
#include <perl.h>
#include <tuxmodule.h>
#include "tux_perl.h"
#include "config_hash.h"
#include "perlxsi.h"

#define CONFIG_FILE "tux_perl.conf"
#define CONFIG_FILE_PATH SYSCONFDIR"/"CONFIG_FILE

#define PERL_MODULE "perl_module"
#define PERL_LIB_PATH "perl_lib_path"
#define PERL_MODULE_LIB "lib"
#define PERL_HANDLER_NAME "name"
#define PERL_HANDLER "handler"

#define STATIC_REPLY "HTTP/1.0 404 Not Found\r\nContent-Type: text/plain\r\n\r\nFailed to initial tux_perl!"
#define UNKNOWN_MODULE_REPLY "HTTP/1.0 404 Not Found\r\nContent-Type: text/plain\r\n\r\nTux_perl: Requested module not found!"

#define MAX_LINE_LENGTH 1024
#define MODULE_NAME_TERMINATOR '&'
#define FINISH_EVENT -1
#define FINISH_CLOSE_EVENT -2

int exitstatus;
static PerlInterpreter *my_perl;
hash_folder * config;

typedef struct handler_node_t handler_node;
struct handler_node_t{
  handler_node * next;
  char *name,*handler;
  int name_len;
};

handler_node * handler_list;

handler_node * new_handler(char * name, char * handler)
{
  handler_node * p;

  p=malloc(sizeof(handler_node));
  p->name=(name==NULL)?NULL:strdup(name);
  p->name_len=(name==NULL)?0:strlen(name);
  p->handler=(handler==NULL)?NULL:strdup(handler);
  p->next=NULL;

  return p;
}

handler_node * append_handler(handler_node * head, handler_node * node)
{
  handler_node * p;

  if(head==NULL || node==NULL)
    return NULL;

  for(p=head;p->next!=NULL;p=p->next)
    ;

  p->next=node;

  return node;
}

char * find_handler(handler_node * handler_list, char * name,char terminator)
{
  handler_node * p;

  if(handler_list==NULL || name==NULL)
    return NULL;

  for(p=handler_list;p!=NULL;p=p->next)
    if(p->name!=NULL &&
       strncmp(p->name,name,p->name_len)==0 &&
       (name[p->name_len]=='\0' || name[p->name_len]==terminator)
       )
      return p->handler;

  return NULL;
}

void init (void)
{
  char * embedding[] = {"","-e","0"};
  hash_node *node;
  char tmp[MAX_LINE_LENGTH+1],*p;

  handler_list=NULL;

  TP_LOG("Entered tux_perl_imp init...\n");

  if((config=read_hash(CONFIG_FILE_PATH))==NULL)
    return;

  if((my_perl = perl_alloc()) == NULL) {
    TP_LOG( "no memory!");
    return;
  }
  perl_construct(my_perl);

  exitstatus = perl_parse(my_perl, xs_init, 3, embedding, NULL);
  if(exitstatus!=0){
    TP_LOG("Failed to call perl_parse : 0x%x\n",exitstatus);
    return;
  }

  exitstatus = perl_run(my_perl);
  if(exitstatus!=0){
    TP_LOG("Failed to call perl_run : 0x%x\n",exitstatus);
    return;
  }

  for(node=config->first_child,node=find_node(node,PERL_LIB_PATH);
      node!=NULL;
      node=find_node(node->next,PERL_LIB_PATH))
    if(IS_VARIABLE(node)){
      sprintf(tmp,
	      "eval { push @INC,'%s'; }; warn 'Failed to append PERL PATH: '.$@ if $@",
	      HASH_VARIABLE(node)->value);
      eval_pv(tmp,TRUE);
    }

  handler_list=new_handler(NULL,NULL);

  for(node=config->first_child,node=find_node(node,PERL_MODULE);
      node!=NULL;
      node=find_node(node->next,PERL_MODULE))
    if(IS_FOLDER(node))
      if((p=get_value(HASH_FOLDER(node),PERL_MODULE_LIB))!=NULL){
	sprintf(tmp,
		"eval { require %s; }; warn 'Failed to load module: '.$@ if $@",
		p);
	eval_pv(tmp,TRUE);
	append_handler(handler_list,
		       new_handler(get_value(HASH_FOLDER(node),PERL_HANDLER_NAME),
				   get_value(HASH_FOLDER(node),PERL_HANDLER))
		       );	
      }

}


SV * bless_request(user_req_t *r)
{
  SV *sv = sv_newmortal();
  sv_setref_pv(sv, "Tux", (void*)r);
  fprintf(stderr, "blessing user_req_t=(0x%lx)\n",(unsigned long)r);
  return sv;  
}

int perl_handler(user_req_t *req,char * handler)
{
  int result;

  dSP;                            /* initialize stack pointer      */
  ENTER;                          /* everything created after here */
  SAVETMPS;                       /* ...is a temporary variable.   */
  PUSHMARK(SP);
  XPUSHs(bless_request(req));
  PUTBACK;
  call_pv(handler,G_SCALAR);
  SPAGAIN;
  result=POPi;
  PUTBACK;
  FREETMPS;                       /* free that return value        */
  LEAVE;
  return result;
}

int handle_events (user_req_t *req)
{
  int ret = TUX_RETURN_USERSPACE_REQUEST;
  char * handler;

  switch(req->event){
  case FINISH_EVENT:
    ret = tux(TUX_ACTION_FINISH_REQ, req);
    break;
  case FINISH_CLOSE_EVENT:
    ret = tux(TUX_ACTION_FINISH_CLOSE_REQ, req);
    break;
  default:
    if(exitstatus){
      req->object_addr = STATIC_REPLY;
      req->objectlen = strlen(STATIC_REPLY);
      
      req->http_status = 200;
      req->event = FINISH_CLOSE_EVENT;
      ret = tux(TUX_ACTION_SEND_BUFFER, req);
    }else{
      if((handler=find_handler(handler_list,req->query,MODULE_NAME_TERMINATOR))==NULL){
	req->object_addr = UNKNOWN_MODULE_REPLY;
	req->objectlen = strlen(UNKNOWN_MODULE_REPLY);
      
	req->http_status = 200;
	req->event = FINISH_CLOSE_EVENT;
	ret = tux(TUX_ACTION_SEND_BUFFER, req);
      }else{
	fprintf(stderr,"Get dynamic content for object: %s\n",req->query);
	ret = perl_handler(req,handler);
      }
    }
    break;
  }

  return ret;
}

