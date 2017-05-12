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

#ifndef HanderStubsHIncl
#define HanderStubsHIncl

#include <sxpath.h>

/* Message Handler */
Declare
(
 MH_ERROR MessageHandlerMakeCodeStub(void *userData, void *processor, int severity, unsigned short facility, unsigned short code);
)

Declare
(
 MH_ERROR MessageHandlerLogStub(void *userData, void *processor, MH_ERROR code, MH_LEVEL level, char **fields) ;
)

Declare
(
 MH_ERROR MessageHandlerErrorStub(void *userData, void *processor, MH_ERROR code, MH_LEVEL level, char **fields) ;
)


/* Scheme Handler */
Declare
(
int SchemeHandlerGetAllStub(void *userData, void *processor, const char *scheme, const char *rest, char **buffer, int *byteCount);
)

Declare
(
 int SchemeHandlerFreeMemoryStub(void *userData, void *processor, char *buffer);
)

Declare
(
 int SchemeHandlerOpenStub(void *userData, void *processor, const char *scheme, const char *rest, int *handle);
)

Declare
(
 int SchemeHandlerGetStub(void *userData, void *processor, int handle, char *buffer, int *byteCount); 
)

Declare
(
 int SchemeHandlerPutStub(void *userData, void *processor, int handle, const char *buffer, int *byteCount);
)

Declare
(
 int SchemeHandlerCloseStub(void *userData, void *processor, int handle);
)

/* SAX-like handler */
Declare
(
 void SAXHandlerStartDocumentStub(void* userData, void *processor);)


Declare
(
 void SAXHandlerStartElementStub(void* userData, void *processor, const char* name, const char** atts);
)

Declare
(
 void SAXHandlerEndElementStub(void* userData, void *processor, const char* name);
)

Declare
(
 void SAXHandlerStartNamespaceStub(void* userData, void *processor, const char* prefix, const char* uri);
)

Declare
(
 void SAXHandlerEndNamespaceStub(void* userData, void *processor, const char* prefix);
)

Declare
(
 void SAXHandlerCommentStub(void* userData, void *processor, const char* contents);
)

Declare
(
 void SAXHandlerPIStub(void* userData, void *processor, const char* target, const char* contents);
)

Declare
(
 void SAXHandlerCharactersStub(void* userData, void *processor, const char* contents, int length);
)

Declare
(
 void SAXHandlerEndDocumentStub(void* userData, void *processor);
)

/* miscellaneous handler */
Declare
(
 void MiscHandlerDocumentInfoStub(void* userData, void *processor, const char *contentType, const char *encoding);
)


#endif /* defined HanderStubsHIncl */
