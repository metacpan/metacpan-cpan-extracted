/*
 * This code is a part of tux_perl, and is released under the GPL.
 * Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
 * See README and COPYING for more information, or see
 *   http://tux-perl.sourceforge.net/.
 *
 * $Id: tux_perl.c,v 1.2 2002/11/11 11:17:02 yaleh Exp $
 */

/*
 * The only purpose of this lib is loading the implementation lib with
 * RTLD_GLOBAL. Or it can be implemented by fixing the source of tux.
 * This flag is required or undefined symbols will be reported when parsing
 * a perl script which uses modules requiring XS.
 */

#include <unistd.h>
#include <tuxmodule.h>
#include <dlfcn.h>
#include "tux_perl.h"
#include "config_hash.h"

#define CLOSE_IFOPEN(h) if((h)!=-1)close(h)

#define CONFIG_FILE "tux_perl.conf"
#define CONFIG_FILE_PATH SYSCONFDIR"/"CONFIG_FILE

#define CONFIG_INIT_LOG_FILE "init_log_file"
#define CONFIG_RUNTIME_LOG_FILE "runtime_log_file"
#define CONFIG_IMP_LIB "imp_lib"

void (*init_fcn)(void);
int (*handle_fcn)(user_req_t *req);

hash_folder * config;

void TUXAPI_init (void)
{
  void * handle;
  const char * msg;
  int fh=-1;
  char *tmp;

  init_fcn=NULL;
  handle_fcn=NULL;

  if((config=read_hash(CONFIG_FILE_PATH))==NULL)
    return;

  // Open a file for stderr
  // Original stderr has already been closed by TUX
  if(((tmp=get_value(config,CONFIG_INIT_LOG_FILE))!=NULL) &&
     (fh=open(tmp,O_WRONLY|O_CREAT|O_APPEND))){
    dup2(fh,2);
    TP_LOG("Init tp_adapter...\n");
  }

  if(((tmp=get_value(config,CONFIG_IMP_LIB))==NULL) ||
     (handle=dlopen(tmp,RTLD_NOW|RTLD_GLOBAL))==NULL){
    TP_LOG("Failed to load %s: %s\n",tmp,dlerror());
    CLOSE_IFOPEN(fh);
    return;
  }

  fprintf(stderr,"Lib is open...\n");
  dlerror();

  init_fcn=dlsym(handle,"init");
  if((msg=dlerror())!=NULL){
    TP_LOG("Didn't find TUXAPI_init(): %s\n",msg);
    CLOSE_IFOPEN(fh);
    return;
  }

  handle_fcn=dlsym(handle,"handle_events");
  if((msg=dlerror())!=NULL){
    TP_LOG("Didn't find TUXAPI_handle_events(): %s\n",msg);
    CLOSE_IFOPEN(fh);
    return;
  }

  init_fcn();

  TP_LOG("Adapter init finished.\n");

  CLOSE_IFOPEN(fh);
}

int TUXAPI_handle_events (user_req_t *req)
{
  int ret=TUX_RETURN_USERSPACE_REQUEST;
  int fh=-1;
  char * tmp;

  // Open a file for stderr
  // Original stderr has already been closed by TUX
  if((tmp=get_value(config,CONFIG_RUNTIME_LOG_FILE))!=NULL &&
     (fh=open(tmp,O_WRONLY|O_CREAT|O_APPEND))!=-1){
    dup2(fh,2);
  }

  if(handle_fcn!=NULL)
    ret=handle_fcn(req);
  else{
    ret = tux(TUX_ACTION_FINISH_REQ, req);
  }

  CLOSE_IFOPEN(fh);

  return ret;
}
