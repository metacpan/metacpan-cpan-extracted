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
#include <EXTERN.h>
#include "perl.h"

#define NO_XSLOCKS
#include "XSub.h"
#if defined(__cplusplus)
}
#endif

#include "ODBCbuild.h"
#include "ODBC.h"
#include "CResults.hpp"

CResults::CResults(ODBC_TYPE *h){
	char szBuff[100];
	int	iTemp;
	BOOL	bResult = FALSE;

	dRowSetSize	= 0;
	sNumOfCols	= 0;
	dSize		= 0;
	dReturnSize = 0;
	szColumn	= 0;
	iODBC		= h->conn;

	SQLGetStmtOption(h->hstmt, SQL_ROWSET_SIZE, &dRowSetSize);

	if (SQLNumResultCols(h->hstmt, (SWORD *)&sNumOfCols) == SQL_SUCCESS){
		
		if (szColumn = new char* [sNumOfCols + 1]){		//	Alloc array of strings
			memset(szColumn, 0x00, sizeof(char*) * (sNumOfCols + 1));
		}
	
//	TESTING: multiply alloced data by dRowSetSize
		if (dSize = new SQLLEN [(sNumOfCols + 1) * dRowSetSize]){		//	Alloc array of sizes
		    memset(dSize, 0x00, (sizeof(SQLLEN) * (sNumOfCols + 1) * dRowSetSize));
		}
	
//	TESTING: multiply alloced data by dRowSetSize
		if (dReturnSize = new SQLLEN [(sNumOfCols + 1) * dRowSetSize]){	//	Alloc array of return sizes
		    memset(dReturnSize, 0x00, (sizeof(SQLLEN) * (sNumOfCols + 1) * dRowSetSize));
		}

		if(szColumn && dSize && dReturnSize){
			SWORD	dColType;

			for(iTemp = 1; iTemp <= sNumOfCols; iTemp++){
				if (SQLColAttributes(h->hstmt, iTemp, SQL_COLUMN_DISPLAY_SIZE, NULL, 0, NULL, &dSize[iTemp]) == SQL_SUCCESS){
						//	If we cant resolve the size define it as the MAX Buffer
						//	size. Later we can change this if needed.

						//	This is just a patch. We need a mechanism to monitor 
						//	if this needs more memory or not. Now a user can configure
						//	the memory size by hand. But this will be the size for ALL of this type.
						//	Sad. Very sad. We need to fix this hack!!!!!
					if(dSize[iTemp] > MAX_DATA_ASSUME_SIZE){
						dSize[iTemp] = h->iMaxBufSize;
					}

//	 Here is dRowSetSize again.
					if (!(szColumn[iTemp] = (char *) new UCHAR [(++dSize[iTemp]) * dRowSetSize])){
						sprintf((char *)szBuff, "Could not allocate enough memory (%d bytes) for column %d.\n", (dSize[iTemp] * dRowSetSize), iTemp);
						::ODBCError((char *)szBuff, h, "CResults()", "1");
						break;
					}
					memset(szColumn[iTemp], 0x00, dSize[iTemp] * dRowSetSize);
				}
			}
				//	So far so good, now lets bind to the columns
			if(! h->Error->ErrNum){
				for(iTemp = 1; iTemp <= sNumOfCols; iTemp++){
					SWORD	sTemp;
					SWORD	sSQLType;

					if (iTemp){
						dColType = SQL_C_CHAR;
						SQLDescribeCol(h->hstmt, iTemp, 0, 0, &sTemp, &sSQLType,(SQLULEN *) &szBuff, &sTemp, &sTemp);
						if ((sSQLType == SQL_LONGVARBINARY) || (sSQLType == SQL_BINARY) || (sSQLType == SQL_VARBINARY)){
							dColType = SQL_C_BINARY;
						}
					}else{
						dColType = SQL_C_BOOKMARK;
					}
			
					if(SQLBindCol(h->hstmt, iTemp, dColType, szColumn[iTemp], dSize[iTemp], &dReturnSize[iTemp]) != SQL_SUCCESS){
						sprintf((char *)szBuff, "Could not bind column %d.\n", iTemp);
						::ODBCError((char *)szBuff, h, "CResults()", "2");
						bResult = FALSE;
					}
				}		 
				bResult = TRUE;
			}
		}
	}
	if(bResult == FALSE){
		RemoveBuffers();
		if(dSize){
			delete [] dSize;
		}
		if(dReturnSize){
			delete [] dReturnSize;
		}
		sNumOfCols = 0;
	}					
}
			
CResults::~CResults(){
	
	RemoveBuffers();
	if(dSize){
		delete [] dSize;
	}
	if(dReturnSize){
		delete [] dReturnSize;
	}
	sNumOfCols = 0;
}								

SDWORD CResults::Size(int iElement){
	SDWORD	dReturn  = 0;

	if (iElement >= 0 && iElement <= sNumOfCols){
		dReturn = dSize[iElement];
	}
	return dReturn;
}

SDWORD CResults::ReturnSize(int iElement){
	SDWORD	dReturn  = 0;

	if (iElement >= 0 && iElement <= sNumOfCols){
			//	We should be reporting the correct size regardless of SQL_NULL_DATA so 
			//	remark out the if (dReturnSize... for now...until we know we don't need it.
		//	if (dReturnSize[iElement] == SQL_NULL_DATA){
		switch(dReturnSize[iElement]){
			case SQL_NULL_DATA:
				dReturn = 0;
				break;
			case SQL_NO_TOTAL:
					//	This is bad. If we don't know how long the data is this assumes
					//	that the data is a null terminated string. BAD!
				dReturn = strlen(szColumn[iElement]);
				break;
			default:
				dReturn = dReturnSize[iElement];
				break;
		}
		//	}
	}
	return dReturn;
}

SWORD CResults::NumOfCols(){
	return sNumOfCols;
}

char *CResults::operator[](int iElement){;
	char	*szReturn = 0;
	
	if (iElement >= 0 && iElement <= sNumOfCols){
		switch(dReturnSize[iElement]){
			case SQL_NULL_DATA:
				szReturn = NULL_VALUE;
				break;

			case SQL_NO_TOTAL:
			default:
				szReturn = szColumn[iElement];	
				break;
		}
	}
	return szReturn;
}
			
void CResults::RemoveBuffers(){
	int	iTemp;
	ODBC_Conn	*h;

	if (h = ::_NT_ODBC_Verify(iODBC)){
		if (h->hstmt){
			SQLFreeStmt(h->hstmt, SQL_UNBIND);
		}
	}
	if(szColumn){
		for(iTemp = 0; iTemp <= sNumOfCols; iTemp++){
			if (szColumn[iTemp]) delete [] szColumn[iTemp];
		}
		delete [] szColumn;
	}			
}	

void CResults::Clean(){
	int	iTemp;
	for(iTemp = 1; iTemp <= sNumOfCols; iTemp++){
		memset(szColumn[iTemp], 0x00, (dSize[iTemp] * dRowSetSize));
	}
}

DWORD CResults::RowSetSize(){
	return dRowSetSize;
}
