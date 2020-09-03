/*
        +==========================================================+
        |                                                          |
        |              ODBC extension for Win32 Perl               |
        |              -----------------------------               |
        |                                                          |
        |            by Dave Roth <rothd@roth.net>                 |
        |                                                          |
        |                  version v970208                         |
        |                                                          |
        | Copyright (c) 1996-1997 Dave Roth. All rights reserved.  |
        |   This program is free software; you can redistribute    |
        | it and/or modify it under the same terms as Perl itself. |
        |                                                          |
        +==========================================================+


          based on original code by Dan DeMaggio (dmag@umich.edu)

   Use under GNU General Public License or Larry Wall's "Artistic License"
*/


#define WIN32_LEAN_AND_MEAN
#include <stdlib.h>
#include <math.h>
#include <windows.h>

#include <stdio.h>

#include <sql.h>
#include <sqlext.h>
#include <odbcinst.h>

#if defined(__cplusplus)
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"

#define NO_XSLOCKS
#include "XSub.h"
#if defined(__cplusplus)
}
#endif

#define	_CMOM_
#include "ODBC.h"
#include "CMom.hpp"


int	CMom::iTotalHistory = 0;

CMom::CMom(){
		//	There should ONLY be one of these
	iType 	= MASTER;
	iNumOfEntries = START_NUM_OF_DAUGHTERS;
	InitMom();
	InitializeCriticalSection(&gCSMom);
}

CMom::CMom(DWORD dThread){
		//	There should be one of these per thread.
	iType	= DAUGHTER;
	iNumOfEntries = START_NUM_OF_ODBCS;
	
	if(InitMom()){
		::cMom->Add(dThread, this);
	}
}

int CMom::InitMom(){
	BOOL	bResult = TRUE;

	pList	= 0;
	iInUse	= 0;
	iNextID	= 0;
	iHistory = 0;

#ifdef _DEBUG	
	if (ghDebug){
		DebugConnection("CMom structure initializing.\n", 0);
	}
#endif

		//	This is the first time that this should be running so
		//	there should be no thread competition.
	pItems = (DWORD *) new DWORD [iNumOfEntries];
	pList  = (void **) new CMom* [iNumOfEntries];
	
	if(pList && pItems){
			//	Fill out the items with FREE_ITEM not 0x00 so that we can have
			//	IDs that are 0.
		memset(pList,  0x00,      sizeof(void*) * (iNumOfEntries));
		memset(pItems, FREE_ITEM, sizeof(DWORD) * (iNumOfEntries));
	}else{
		if (pList) delete [] pList;
		if (pItems) delete [] pItems;	
		iNumOfEntries = 0;
		bResult = FALSE;
	}
	return bResult;
}

CMom::~CMom(){
	int	iTemp = 0;

	if (pList){
		if (iType == MASTER){
			char *szTemp;
			DWORD	dCount;
			DEBUG_DUMP("CMom::~CMom: Entering Critical Section gCS")
szTemp = "\n\n====================================\nCMom::~CMom: WE ARE DELETING CMom! OH MY GOD! NO!!! DON'T DO IT!!!\n\n\n";
WriteConsole(ghDebug, szTemp, strlen(szTemp), &dCount, 0);


			EnterCriticalSection(&gCS);
		#ifdef _DEBUG
			DebugConnection("CMom Mother structure destroying.\n", 0);
		#endif
		}else{
/*
	DELETE THIS BLOCK:
				If this is not a MASTER then it is a DAUGHTER and a Daughter
				is only controlled by one thread so we should not need a CS
				since a thread can not preempt itself.		
			EnterCriticalSection(&gCSMom);
*/
		#ifdef _DEBUG
			DebugConnection("CMom Daughter structure destroying.\n", 0);
		#endif
		}

		while(iTemp < iNumOfEntries){	
			if(pList[iTemp]){
				switch(iType){
					case MASTER:
						delete (CMom *) pList[iTemp];
						pItems[iTemp] = FREE_ITEM;
						pList[iTemp] = 0;
						break;
					case DAUGHTER:
							//	Next line will be used once ODBC_TYPE is an
							//	object class
						//	delete (ODBC_TYPE *) pList[iTemp];
							//	In the meantime...
					#ifdef _DEBUG
						DebugConnection("CMom daughter deleting connetion...", 0);
					#endif
						DeleteConn(((ODBC_TYPE *)pList[iTemp])->conn);
						break;
				}
			}
			iTemp++;
		}
		delete [] pList;

		if (iType == MASTER){
			DeleteCriticalSection(&gCSMom);
			LeaveCriticalSection(&gCS);
			DEBUG_DUMP("CMom::~CMom: Left Critical Section gCS    ")
		}else{
/*	DELETE THIS BLOCK:
	see above for reason.
			LeaveCriticalSection(&gCSMom);
*/			
				//	This Remove MUST not be within a gCSMom CS!!!!!!
			::cMom->Remove(GetCurrentThreadId());
		}
	}
	if (pItems) delete [] pItems;

		//	This should have only been called by a Mom so 
		//	the calling Mom will know how to clean up the upper
		//	level stuff.
}

BOOL CMom::Add(DWORD dID, void *pObject){
	BOOL	bReturn = 0;

	bReturn = AddToList(dID, pObject);
	return bReturn;
}

BOOL CMom::Add(void *pObject){
	BOOL	bReturn = 0;
	
	if (!(bReturn = AddToList(iNextID++, pObject))){
		iNextID--;
	}else{
		iTotalHistory++;
	}
	return bReturn;
}

	//	Add an object to the list								 	
BOOL CMom::AddToList(DWORD dID, void *pObject){
	void 	**pTempList;
	DWORD	*pTempItems;
	BOOL	bResult = FALSE;

	if (pObject && pList && pItems && (!(this->operator[](dID)))){
		if(iType == MASTER){
			DEBUG_DUMP("CMom::AddToList: Entering Critical Section gCSMom")
			EnterCriticalSection(&gCSMom);
		}
		if (iInUse >= iNumOfEntries){
			iNumOfEntries = iInUse + 1;
				//	ALWAYS refer to iNumOfEntries as the total number of elements. The biggest
				//	index should be iNumOfEntries + 1 (unless iNum... == 0, of course)
			pTempList  = new void* [iNumOfEntries];
			pTempItems = new DWORD [iNumOfEntries];
			
			if (pTempList && pTempItems){
				memcpy(pTempList, pList,   sizeof(void*) * (iNumOfEntries - 1));
				memcpy(pTempItems, pItems, sizeof(DWORD) * (iNumOfEntries - 1));
			
					//	Don't worry about iNumOfEntries == 0; when we new xxx [iNumOfEntries] that
					//	will fail if 0 and we won't get here!
				pTempList[iNumOfEntries  - 1]  = pObject;
				pTempItems[iNumOfEntries - 1] = dID;

				if (pList)  delete [] (void **)pList;
				if (pItems) delete [] (DWORD *)pItems;

				pList = pTempList;
				pItems = pTempItems;
				iInUse++;
				iHistory++;
				bResult = TRUE;
			}else{
				if (pTempList)  delete [] (void **)pTempList;
				if (pTempItems) delete [] (DWORD *)pTempItems;
				iNumOfEntries--;
			}
		}else{
			int	iTemp = 0;
			while(iTemp < iNumOfEntries){
				if (pItems[iTemp] == FREE_ITEM){
					pItems[iTemp] = dID;
					pList[iTemp]  = pObject;
					bResult = TRUE;
					iInUse++;
					iHistory++;
					break;
				}
				iTemp++;
			}
		}
		if(iType == MASTER){
			LeaveCriticalSection(&gCSMom);
			DEBUG_DUMP("CMom::AddToList: Left Critical Section gCSMom    ")
		}
	}
	return bResult;
}

int CMom::Remove(DWORD dID){		
	int	iTemp = 0;
	int	iResult = 0;

 	if (iType == MASTER){
		DEBUG_DUMP("CMom::Remove: Entering Critical Section gCSMom")
 		EnterCriticalSection(&gCSMom);
	}
	while(iTemp < iNumOfEntries){
		if (pItems[iTemp] == dID){
			pItems[iTemp] = FREE_ITEM;
			pList[iTemp]  = 0;
			if (iInUse) iInUse--;
			iResult = 1;
			break;
		}
		iTemp++;
	}
	if (iType == MASTER){
		LeaveCriticalSection(&gCSMom);
		DEBUG_DUMP("CMom::Remove: Left Critical Section gCSMom")
	}
	return iResult;
}

void *CMom::operator[](DWORD dID){
	int	iTemp = 0;
	void	*pResult = 0;

			//	We can not use DEBUG_DUMP() because of recursion from DEBUG_DUMP()

	DEBUG_DUMP("CMom::operator[](DWORD): Entering Critical Section gCSMom");

	EnterCriticalSection(&gCSMom);
	while(iTemp < iNumOfEntries){
		if (pItems[iTemp] == dID){
			pResult = pList[iTemp];
			break;
		}
		iTemp++;
	}
	LeaveCriticalSection(&gCSMom);

	DEBUG_DUMP("CMom::operator[](DWORD): Left Critical Section gCSMom    ");

	return pResult;
}

DWORD CMom::operator[](void *pObject){
	int	iTemp = 0;
	DWORD dResult = 0;
	

	DEBUG_DUMP("CMom::operator[](void*): Entering Critical Section gCSMom");

	EnterCriticalSection(&gCSMom);
	while(iTemp < iNumOfEntries){
		if (pList[iTemp] == pObject){
			dResult = pItems[iTemp];
			break;
		}
		iTemp++;
	}
	LeaveCriticalSection(&gCSMom);

	DEBUG_DUMP("CMom::operator[](void*): Left Critical Section gCSMom    ");

	return dResult;
}

int	CMom::TotalElements(){
	return iNumOfEntries;
}

int CMom::Total(){
	return iInUse;
}



	
	
