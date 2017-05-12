/* -*- Mode: C; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 4 -*-
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 * 
 * The Original Code is the XML::Sablotron module.
 * 
 * The Initial Developer of the Original Code is Ginfer Alliance Ltd.
 * Portions created by Ginger Alliance are 
 * Copyright (C) 1999-2000 Ginger Alliance Ltd..  
 * All Rights Reserved.
 * 
 * Contributor(s): Nicolas Trebst, science+computing ag
 *                 n.trebst@science-computing.de
 * 
 * Alternatively, the contents of this file may be used under the
 * terms of the GNU General Public License Version 2 or later (the
 * "GPL"), in which case the provisions of the GPL are applicable 
 * instead of those above.  If you wish to allow use of your 
 * version of this file only under the terms of the GPL and not to
 * allow others to use your version of this file under the MPL,
 * indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by
 * the GPL.  If you do not delete the provisions above, a recipient
 * may use your version of this file under either the MPL or the
 * GPL.
 */

/*
 *
 *  ../Sablotron.xs includes this file
 *
 */ 



#include "Handler_stubs.h"

/**************************************************************
  message handler
**************************************************************/
MessageHandler mh_handler_vector = {
  MessageHandlerMakeCodeStub,
  MessageHandlerLogStub,
  MessageHandlerErrorStub
};

/*********************
 scheme handler
*********************/
SchemeHandler sh_handler_vector = {
  SchemeHandlerGetAllStub,
  SchemeHandlerFreeMemoryStub,
  SchemeHandlerOpenStub,
  SchemeHandlerGetStub,
  SchemeHandlerPutStub,
  SchemeHandlerCloseStub
};

/*********************
 SAX-like handler
*********************/
SAXHandler sax_handler_vector = {
    SAXHandlerStartDocumentStub,
    SAXHandlerStartElementStub,
    SAXHandlerEndElementStub,
    SAXHandlerStartNamespaceStub,
    SAXHandlerEndNamespaceStub,
    SAXHandlerCommentStub,
    SAXHandlerPIStub,
    SAXHandlerCharactersStub,
    SAXHandlerEndDocumentStub
};

/*********************
 miscellaneous handler
*********************/
MiscHandler xh_handler_vector = {
  MiscHandlerDocumentInfoStub
};



/**************************************************************
  message handler
**************************************************************/
MH_ERROR 
MessageHandlerMakeCodeStub(void *userData, void *processor, int severity, 
	unsigned short facility, 
	unsigned short code) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "MHMakeCode", 10, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSViv(severity)));
    XPUSHs(sv_2mortal(newSViv(facility)));
    XPUSHs(sv_2mortal(newSViv(code)));
    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    croak("MHMakeCode method missing");
  }
  return ret;
}


MH_ERROR 
MessageHandlerLogStub(void *userData, void *processor, MH_ERROR code, 
	MH_LEVEL level, char **fields) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  char **foo;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);;
  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "MHLog", 5, 0);

  if (gv) {
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSViv(code)));
    XPUSHs(sv_2mortal(newSViv(level)));
    foo = fields;
    while (*foo) {
      XPUSHs(sv_2mortal(newSVpv(*foo, strlen(*foo))));
      foo++;
    }

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_VOID);

    FREETMPS;
    LEAVE;
  } else {
    croak("MHLog method missing");
  }
  return code;
}


MH_ERROR 
MessageHandlerErrorStub(void *userData, void *processor, MH_ERROR code, 
	MH_LEVEL level, char **fields) 
{
  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  char **foo;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);
  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "MHError", 7, 0);

  if (gv) {
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSViv(code)));
    XPUSHs(sv_2mortal(newSViv(level)));
    foo = fields;
    while (*foo) {
      XPUSHs(sv_2mortal(newSVpv(*foo, strlen(*foo))));
      foo++;
    }

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    FREETMPS;
    LEAVE;
  } else {
    croak("MHError method missing");
  }
  return code;
}


/*********************
 scheme handler
*********************/
int SchemeHandlerGetAllStub(void *userData, void *processor,
    const char *scheme, const char *rest, 
    char **buffer, int *byteCount) {

  SV *wrapper;
  SV *processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;
  unsigned int len;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHGetAll", 8, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSVpv((char*) scheme, strlen(scheme))));
    XPUSHs(sv_2mortal(newSVpv((char*) rest, strlen(rest))));

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    ret = 0; /* oops */
    value = POPs;
    if ( SvOK(value) ) {
      SvPV(value, len);
      *buffer = (char*) malloc(len + 1);
      strcpy(*buffer, SvPV(value, PL_na));
      *byteCount = len + 1;
    } else {
      *byteCount = -1;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    *byteCount = -1;
  }
  return ret;
}

int SchemeHandlerFreeMemoryStub(void *userData, void *processor,
    char *buffer) {
  unsigned long ret = 0;
  if (buffer) {
    free(buffer);
  }
  return ret;
}

int SchemeHandlerOpenStub(void *userData, void *processor,
    const char *scheme, const char *rest, int *handle) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHOpen", 6, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSVpv((char*) scheme, strlen(scheme))));
    XPUSHs(sv_2mortal(newSVpv((char*) rest, strlen(rest))));

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    value = POPs;
    if ( SvOK(value) ) {
      ret = 0;
      SvREFCNT_inc(value);
      *handle = (int) value;
    } else {
      ret = 100;
      *handle = 0;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    croak("SHOpen method missing");
  }
  return ret;
}

int SchemeHandlerGetStub(void *userData, void *processor,
    int handle, char *buffer, int *byteCount) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;
  unsigned int len;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHGet", 5, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs((SV*)handle);
    XPUSHs(sv_2mortal(newSViv(*byteCount)));
    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;
	
    value = POPs;
    if SvOK(value) {
      char *aux;
      aux = SvPV(value, len);
      *byteCount = len < *byteCount ? len : *byteCount;
      strncpy(buffer, aux, *byteCount);
    } else {
      *byteCount = 0;
    }

    ret = 0; /* oops */

    PUTBACK;
    FREETMPS;
    LEAVE;
  } else {
    croak("SHGet method missing");
  }
  return ret;
}

int SchemeHandlerPutStub(void *userData, void *processor,
    int handle, const char *buffer, int *byteCount) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;
  SV *value;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHPut", 5, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs((SV*) handle);
    XPUSHs(sv_2mortal(newSVpv((char*) buffer, *byteCount)));
    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), G_SCALAR);

    SPAGAIN;

    value = POPs;
    if (SvOK(value)) {
      ret = 0;
    } else {
      ret = 100;
    }

    PUTBACK;

    FREETMPS;
    LEAVE;
  } else {
    croak("SHPut method missing");
  }
  return ret;
}

int SchemeHandlerCloseStub(void *userData, void *processor,
    int handle) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;
  unsigned long ret = 0;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "SHClose", 7, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs((SV*) handle);

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), 0);

    SvREFCNT_dec((SV*) handle);
    ret = 0;

    FREETMPS;
    LEAVE;
  } else {
    croak("SHClose method missing");
  }
  return ret;
}


/*********************
 SAX-like handler
*********************/
void SAXHandlerStartDocumentStub(void* userData, void *processor)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerStartDocument"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXStartDocument", 16, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXStartDocument method missing");
    }
}

void SAXHandlerStartElementStub(void* userData, void *processor,
                                const char* name, const char** atts)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;
    char **att;

    /* printf("===> %s\n", "SAXHandlerStartElement"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXStartElement", 15, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) name, strlen(name))));
        att = (char**)atts;
        while (*att) {
            XPUSHs(sv_2mortal(newSVpv(*att, strlen(*att))));
            att++;
        }

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXStartElement method missing");
    }
}

void SAXHandlerEndElementStub(void* userData, void *processor,
                              const char* name)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerEndElement"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXEndElement", 13, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) name, strlen(name))));

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXEndElement method missing");
    }
}

void SAXHandlerStartNamespaceStub(void* userData, void *processor,
                                  const char* prefix, const char* uri)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerStartNamespace"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXStartNamespace", 17, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) prefix, strlen(prefix))));
        XPUSHs(sv_2mortal(newSVpv((char*) uri, strlen(uri))));

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXStartNamespace method missing");
    }
}

void SAXHandlerEndNamespaceStub(void* userData, void *processor,
                                const char* prefix)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerEndNamespaceStub"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXEndNamespace", 15, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) prefix, strlen(prefix))));

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXEndNamespace method missing");
    }
}

void SAXHandlerCommentStub(void* userData, void *processor,
                           const char* contents)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerComment"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXComment", 10, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) contents, strlen(contents))));

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXComment method missing");
    }
}

void SAXHandlerPIStub(void* userData, void *processor,
                      const char* target, const char* contents)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerPI"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXPI", 5, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) target, strlen(target))));
        XPUSHs(sv_2mortal(newSVpv((char*) contents, strlen(contents))));

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXPI method missing");
    }
}

void SAXHandlerCharactersStub(void* userData, void *processor,
                              const char* contents, int length)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerCharacters"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXCharacters", 13, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        XPUSHs(sv_2mortal(newSVpv((char*) contents, length)));

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXCharacters method missing");
    }
}

void SAXHandlerEndDocumentStub(void* userData, void *processor)
{
    SV *wrapper;
    SV * processor_obj;
    HV *stash;
    GV *gv;

    /* printf("===> %s\n", "SAXHandlerEndDocument"); */

    wrapper = (SV*)userData;
    
    processor_obj = (SV*) SablotGetInstanceData(processor);
    stash = SvSTASH(SvRV(wrapper));
    gv = gv_fetchmeth(stash, "SAXEndDocument", 14, 0);
    
    if (gv) {
        dSP;
        ENTER;
        SAVETMPS;
        
        PUSHMARK(SP);  
        XPUSHs(wrapper);
        if (processor_obj) 
            XPUSHs(processor_obj);
        else
            XPUSHs(&sv_undef);

        PUTBACK;
        
        perl_call_sv((SV*)GvCV(gv), G_SCALAR);
        
        FREETMPS;
        LEAVE;
    } else {
        croak("SAXEndDocument method missing");
    }
}


/*********************
 miscellaneous handler
*********************/
void
MiscHandlerDocumentInfoStub(void* userData, void *processor,
                        const char *contentType, 
                        const char *encoding) {

  SV *wrapper;
  SV * processor_obj;
  HV *stash;
  GV *gv;

  wrapper = (SV*)userData;

  processor_obj = (SV*) SablotGetInstanceData(processor);

  stash = SvSTASH(SvRV(wrapper));
  gv = gv_fetchmeth(stash, "XHDocumentInfo", 14, 0);

  if (gv) { 
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);  
    XPUSHs(wrapper);
    if (processor_obj) 
      XPUSHs(processor_obj);
    else
      XPUSHs(&sv_undef);
    XPUSHs(sv_2mortal(newSVpv((char*) contentType, strlen(contentType))));
    XPUSHs(sv_2mortal(newSVpv((char*) encoding, strlen(encoding))));

    PUTBACK;

    perl_call_sv((SV*)GvCV(gv), 0);

    FREETMPS;
    LEAVE;
  } else {
    croak("XHDocumentInfo method missing");
  }
}
