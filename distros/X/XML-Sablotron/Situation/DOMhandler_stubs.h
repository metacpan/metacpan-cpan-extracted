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

#ifndef DOMHanderStubsHIncl
#define DOMHanderStubsHIncl

#include <sxpath.h>

Declare
(
 SXP_NodeType DOMHandlerGetNodeTypeStub( SXP_Node node, void *userData );
) 

Declare
(
 const SXP_char *DOMHandlerGetNodeNameStub( SXP_Node node, void *userData );
)

Declare
(
 const SXP_char *DOMHandlerGetNodeNameURIStub( SXP_Node node, void *userData );
)

Declare
(
 const SXP_char *DOMHandlerGetNodeNameLocalStub( SXP_Node node, void *userData );
)

Declare
(
 const SXP_char *DOMHandlerGetNodeValueStub( SXP_Node node, void *userData );
)

Declare
(
 SXP_Node DOMHandlerGetNextSiblingStub( SXP_Node node, void *userData );
)

Declare
(
 SXP_Node DOMHandlerGetPreviousSiblingStub( SXP_Node node, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetNextAttrNSStub( SXP_Node node, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetPreviousAttrNSStub( SXP_Node node, void *userData );
)

Declare
(
  int DOMHandlerGetChildCountStub( SXP_Node node, void *userData );
)

Declare
(
  int DOMHandlerGetAttributeCountStub( SXP_Node node, void *userData );
)

Declare
(
  int DOMHandlerGetNamespaceCountStub( SXP_Node node, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetChildNoStub( SXP_Node node, int index, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetAttributeNoStub( SXP_Node node, int index, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetNamespaceNoStub( SXP_Node node, int index, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetParentStub( SXP_Node node, void *userData );
)

Declare
(
  SXP_Document DOMHandlerGetOwnerDocumentStub( SXP_Node node, void *userData );
)

Declare
(
  int DOMHandlerCompareNodesStub( SXP_Node node1, SXP_Node node2, void *userData );
)

Declare
(
  SXP_Document DOMHandlerRetrieveDocumentStub( const SXP_char *uri, const SXP_char *baseUri, void *userData );
)

Declare
(
  SXP_Node DOMHandlerGetNodeWithIDStub( SXP_Document doc, const SXP_char* id, void *userData );
)

Declare
(
  void DOMHandlerFreeBufferStub( SXP_Node node, SXP_char *buff, void *userData );
)


#endif /* defined DOMHanderStubsHIncl */
