/**********************************************************************
*              iodbc.xs  The perl iODBC extension 0.1                 *
***********************************************************************
*              Copyright (C) 1996 J. Michael Mahan and                *
*                  Rose-Hulman Institute of Technology                *
***********************************************************************
*    This package is free software; you can redistribute it and/or    *
* modify it under the terms of the GNU General Public License or      *
* Larry Wall's "Artistic License".                                    *
***********************************************************************
*    This package is distributed in the hope that it will be useful,  *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of     *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU  *
*  General Public License for more details.                           *
**********************************************************************/

#include <iodbc.h>
#include <isql.h>
#include <isqlext.h>
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif
static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'F':
	if (strEQ(name, "FALSE"))
#ifdef FALSE
	    return FALSE;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SQL_ALL_EXCEPT_LIKE"))
#ifdef SQL_ALL_EXCEPT_LIKE
	    return SQL_ALL_EXCEPT_LIKE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CLOSE"))
#ifdef SQL_CLOSE
	    return SQL_CLOSE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CHAR"))
#ifdef SQL_CHAR
	    return SQL_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_READONLY"))
#ifdef SQL_ATTR_READONLY
	    return SQL_ATTR_READONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_READWRITE_UNKNOWN"))
#ifdef SQL_ATTR_READWRITE_UNKNOWN
	    return SQL_ATTR_READWRITE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ATTR_WRITE"))
#ifdef SQL_ATTR_WRITE
	    return SQL_ATTR_WRITE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_AUTO_INCREMENT"))
#ifdef SQL_COLUMN_AUTO_INCREMENT
	    return SQL_COLUMN_AUTO_INCREMENT;
#else
	    goto not_there;
#endif

	if (strEQ(name, "SQL_COLUMN_CASE_SENSITIVE"))
#ifdef SQL_COLUMN_CASE_SENSITIVE
	    return SQL_COLUMN_CASE_SENSITIVE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_COUNT"))
#ifdef SQL_COLUMN_COUNT
	    return SQL_COLUMN_COUNT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_DISPLAY_SIZE"))
#ifdef SQL_COLUMN_DISPLAY_SIZE
	    return SQL_COLUMN_DISPLAY_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_DRIVER_START"))
#ifdef SQL_COLUMN_DRIVER_START
	    return SQL_COLUMN_DRIVER_START;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_LABEL"))
#ifdef SQL_COLUMN_LABEL
	    return SQL_COLUMN_LABEL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_LENGTH"))
#ifdef SQL_COLUMN_LENGTH
	    return SQL_COLUMN_LENGTH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_MONEY"))
#ifdef SQL_COLUMN_MONEY
	    return SQL_COLUMN_MONEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_NAME"))
#ifdef SQL_COLUMN_NAME
	    return SQL_COLUMN_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_NULLABLE"))
#ifdef SQL_COLUMN_NULLABLE
	    return SQL_COLUMN_NULLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_OWNER_NAME"))
#ifdef SQL_COLUMN_OWNER_NAME
	    return SQL_COLUMN_OWNER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_PRECISION"))
#ifdef SQL_COLUMN_PRECISION
	    return SQL_COLUMN_PRECISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_QUALIFIER_NAME"))
#ifdef SQL_COLUMN_QUALIFIER_NAME
	    return SQL_COLUMN_QUALIFIER_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_SCALE"))
#ifdef SQL_COLUMN_SCALE
	    return SQL_COLUMN_SCALE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_SEARCHABLE"))
#ifdef SQL_COLUMN_SEARCHABLE
	    return SQL_COLUMN_SEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_TABLE_NAME"))
#ifdef SQL_COLUMN_TABLE_NAME
	    return SQL_COLUMN_TABLE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_TYPE"))
#ifdef SQL_COLUMN_TYPE
	    return SQL_COLUMN_TYPE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_TYPE_NAME"))
#ifdef SQL_COLUMN_TYPE_NAME
	    return SQL_COLUMN_TYPE_NAME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_UNSIGNED"))
#ifdef SQL_COLUMN_UNSIGNED
	    return SQL_COLUMN_UNSIGNED;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_COLUMN_UPDATABLE"))
#ifdef SQL_COLUMN_UPDATABLE
	    return SQL_COLUMN_UPDATABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_BINARY"))
#ifdef SQL_C_BINARY
	    return SQL_C_BINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_BIT"))
#ifdef SQL_C_BIT
	    return SQL_C_BIT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_BOOKMARK"))
#ifdef SQL_C_BOOKMARK
	    return SQL_C_BOOKMARK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_CHAR"))
#ifdef SQL_C_CHAR
	    return SQL_C_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DATE"))
#ifdef SQL_C_DATE
	    return SQL_C_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DEFAULT"))
#ifdef SQL_C_DEFAULT
	    return SQL_C_DEFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_DOUBLE"))
#ifdef SQL_C_DOUBLE
	    return SQL_C_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_FLOAT"))
#ifdef SQL_C_FLOAT
	    return SQL_C_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_LONG"))
#ifdef SQL_C_LONG
	    return SQL_C_LONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SHORT"))
#ifdef SQL_C_SHORT
	    return SQL_C_SHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SLONG"))
#ifdef SQL_C_SLONG
	    return SQL_C_SLONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_SSHORT"))
#ifdef SQL_C_SSHORT
	    return SQL_C_SSHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_STINYINT"))
#ifdef SQL_C_STINYINT
	    return SQL_C_STINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TIME"))
#ifdef SQL_C_TIME
	    return SQL_C_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TIMESTAMP"))
#ifdef SQL_C_TIMESTAMP
	    return SQL_C_TIMESTAMP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_TINYINT"))
#ifdef SQL_C_TINYINT
	    return SQL_C_TINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_ULONG"))
#ifdef SQL_C_ULONG
	    return SQL_C_ULONG;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_USHORT"))
#ifdef SQL_C_USHORT
	    return SQL_C_USHORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_C_UTINYINT"))
#ifdef SQL_C_UTINYINT
	    return SQL_C_UTINYINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DECIMAL"))
#ifdef SQL_DECIMAL
	    return SQL_DECIMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DOUBLE"))
#ifdef SQL_DOUBLE
	    return SQL_DOUBLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DROP"))
#ifdef SQL_DROP
	    return SQL_DROP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ERROR"))
#ifdef SQL_ERROR
	    return SQL_ERROR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_FLOAT"))
#ifdef SQL_FLOAT
	    return SQL_FLOAT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INTEGER"))
#ifdef SQL_INTEGER
	    return SQL_INTEGER;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_INVALID_HANDLE"))
#ifdef SQL_INVALID_HANDLE
	    return SQL_INVALID_HANDLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LIKE_ONLY"))
#ifdef SQL_LIKE_ONLY
	    return SQL_LIKE_ONLY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_LONGVARCHAR"))
#ifdef SQL_LONGVARCHAR
	    return SQL_LONGVARCHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NEED_DATA"))
#ifdef SQL_NEED_DATA
	    return SQL_NEED_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_DATA_FOUND"))
#ifdef SQL_NO_DATA_FOUND
	    return SQL_NO_DATA_FOUND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_NULLS"))
#ifdef SQL_NO_NULLS
	    return SQL_NO_NULLS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NUMERIC"))
#ifdef SQL_NUMERIC
	    return SQL_NUMERIC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NO_TOTAL"))
#ifdef SQL_NO_TOTAL
	    return SQL_NO_TOTAL
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NTS"))
#ifdef SQL_NTS
	    return SQL_NTS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULLABLE"))
#ifdef SQL_NULLABLE
	    return SQL_NULLABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULLABLE_UNKNOWN"))
#ifdef SQL_NULLABLE_UNKNOWN
	    return SQL_NULLABLE_UNKNOWN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_DATA"))
#ifdef SQL_NULL_DATA
	    return SQL_NULL_DATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HDBC"))
#ifdef SQL_NULL_HDBC
	    return SQL_NULL_HDBC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HENV"))
#ifdef SQL_NULL_HENV
	    return SQL_NULL_HENV;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_NULL_HSTMT"))
#ifdef SQL_NULL_HSTMT
	    return SQL_NULL_HSTMT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_REAL"))
#ifdef SQL_REAL
	    return SQL_REAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_RESET_PARAMS"))
#ifdef SQL_RESET_PARAMS
	    return SQL_RESET_PARAMS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SMALLINT"))
#ifdef SQL_SMALLINT
	    return SQL_SMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_STILL_EXECUTING"))
#ifdef SQL_STILL_EXECUTING
	    return SQL_STILL_EXECUTING;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SUCCESS"))
#ifdef SQL_SUCCESS
	    return SQL_SUCCESS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SUCCESS_WITH_INFO"))
#ifdef SQL_SUCCESS_WITH_INFO
	    return SQL_SUCCESS_WITH_INFO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNBIND"))
#ifdef SQL_UNBIND
	    return SQL_UNBIND;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_UNSEARCHABLE"))
#ifdef SQL_UNSEARCHABLE
	    return SQL_UNSEARCHABLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_VARBINARY"))
#ifdef SQL_VARBINARY
	    return SQL_VARBINARY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_VARCHAR"))
#ifdef SQL_VARCHAR
	    return SQL_VARCHAR;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	if (strEQ(name, "TRUE"))
#ifdef TRUE
	    return TRUE;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = iodbc		PACKAGE = iodbc


double
constant(name,arg)
	char *		name
	int		arg

RETCODE
SQLAllocEnv(phenv)
	HENV		&phenv  = NO_INIT
	OUTPUT:
		phenv
		RETVAL

RETCODE
SQLAllocConnect(henv,phdbc)
	HENV		henv
	HDBC		&phdbc = NO_INIT
	OUTPUT:
		phdbc
		RETVAL

RETCODE
SQLConnect(hdbc,szDSN,cbDSN,szUID,cbUID,szAuthStr,cbAuthStr)
	HDBC		hdbc
	char *		szDSN
	SWORD		cbDSN
	char *		szUID
	SWORD		cbUID
	char *		szAuthStr
	SWORD		cbAuthStr

RETCODE
SQLAllocStmt(hdbc,phstmt)
	HDBC		hdbc
	HSTMT		&phstmt = NO_INIT
	OUTPUT:
		phstmt
		RETVAL

RETCODE
SQLSetCursorName(hstmt,szCursor,cbCursor)
	HSTMT		hstmt
	char *		szCursor
	SWORD		cbCursor

RETCODE
SQLGetCursorName(hstmt,szCursor,cbCursorMax,pcbCursor)
        HSTMT           hstmt
        char *          szCursor = NO_INIT
	SWORD		cbCursorMax
	SWORD		pcbCursor
        CODE:
		szCursor = (char *) malloc (sizeof(char)*cbCursorMax);
                RETVAL = SQLGetCursorName(hstmt,szCursor,cbCursorMax,&pcbCursor);
        OUTPUT:
		szCursor
		pcbCursor
                RETVAL
	CLEANUP:
		free(szCursor);

RETCODE
SQLPrepare(hstmt,szSqlStr,cbSqlStr)
	HSTMT		hstmt
	char *		szSqlStr
	SWORD		cbSqlStr

RETCODE
SQLExecute(hstmt)
	HSTMT		hstmt
	OUTPUT:
		RETVAL

RETCODE
SQLExecDirect(hstmt,szSqlStr,cbSqlStr)
	HSTMT		hstmt
	char *		szSqlStr
	SWORD		cbSqlStr

RETCODE
SQLRowCount(hstmt,pcrow)
	HSTMT		hstmt
	SDWORD 		&pcrow = NO_INIT
	OUTPUT:
		pcrow
		RETVAL

RETCODE
SQLNumResultCols(hstmt,pccol)
	HSTMT		hstmt
	SWORD 		&pccol = NO_INIT
	OUTPUT:
		pccol
		RETVAL

RETCODE
SQLDescribeCol(hstmt,icol,szColName,cbColNameMax,pcbColName,pfSqlType,pcbColDef,pibScale,pfNullable)
	HSTMT		hstmt
	UWORD		icol
	char *		szColName
	SWORD		cbColNameMax
	SWORD 		pcbColName = NO_INIT
	SWORD 		pfSqlType = NO_INIT
	UDWORD 		pcbColDef = NO_INIT
	SWORD 		pibScale = NO_INIT
	SWORD		pfNullable = NO_INIT
	CODE:	
		szColName = (char *) malloc(sizeof(char)*cbColNameMax);
		RETVAL = SQLDescribeCol(hstmt,icol,szColName,cbColNameMax,&pcbColName,&pfSqlType,&pcbColDef,&pibScale,&pfNullable);
	OUTPUT:
		szColName
		pcbColName
		pfSqlType
		pcbColDef
		pibScale
		pfNullable
		RETVAL
	CLEANUP:
		free(szColName);

RETCODE
SQLColAttributes(hstmt,icol,fDescType,rgbDesc,cbDescMax,pcbDesc,pfDesc)
	HSTMT		hstmt
	UWORD		icol
	UWORD		fDescType
	char *		rgbDesc = NO_INIT
	SWORD		cbDescMax
	SWORD 		pcbDesc = NO_INIT
	SDWORD 		pfDesc = NO_INIT
	CODE:
		rgbDesc = (char *) malloc (sizeof(char)*cbDescMax);
		RETVAL = SQLColAttributes(hstmt,icol,fDescType,(PTR)rgbDesc,cbDescMax,&pcbDesc,&pfDesc);
	OUTPUT:
		pcbDesc
		pfDesc
		rgbDesc
		RETVAL

RETCODE 
SQLBindColint(hstmt,icol,fCType,rgbValue,cbValueMax,pcbValue)
	HSTMT		hstmt
	UWORD		icol
	SWORD		fCType
	void *		rgbValue = NO_INIT 
	SDWORD		cbValueMax
	SDWORD 		pcbValue 
	CODE:
	  switch(fCType) {   
	    case SQL_C_CHAR: {
	      rgbValue = (void *) malloc(sizeof(char)*cbValueMax);
              RETVAL=SQLBindCol(hstmt,icol,fCType,(UCHAR *)rgbValue,cbValueMax,&pcbValue);
	      break;
	    } case SQL_C_SSHORT: {
	      rgbValue = (void *) malloc(sizeof(SWORD));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(SWORD *) rgbValue,cbValueMax,&pcbValue);

	      break;	
	    } case SQL_C_USHORT: {
	      rgbValue = (void *) malloc(sizeof(UWORD));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(UWORD *)rgbValue,cbValueMax,&pcbValue);

	      break;	
	    } case SQL_C_SHORT: {
	      rgbValue = (void *) malloc(sizeof(short));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(short *)rgbValue,cbValueMax,&pcbValue);

	      break;
	    } case SQL_C_SLONG:{
	      rgbValue = (void *) malloc(sizeof(SDWORD));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(SDWORD *)rgbValue,cbValueMax,&pcbValue);

	      break;
	    } case SQL_C_ULONG: {
	      rgbValue = (void *) malloc(sizeof(UDWORD));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(UDWORD *)rgbValue,cbValueMax,&pcbValue);

	      break;
	    } case SQL_C_LONG: {
	      rgbValue = (void *) malloc(sizeof(DWORD));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(DWORD *)rgbValue,cbValueMax,&pcbValue);

	      break;
	    } case SQL_C_FLOAT:{  
	    } case SQL_C_DOUBLE: {
	      rgbValue = (void *) malloc(sizeof(double));
          RETVAL=SQLBindCol(hstmt,icol,fCType,(double *)rgbValue,cbValueMax,&pcbValue);

	      break;
	    } default: {
	      rgbValue = (void *) malloc(sizeof(char)*cbValueMax);
          RETVAL=SQLBindCol(hstmt,icol,fCType,(char *)rgbValue,cbValueMax,&pcbValue);

	    }
	  }; 
	OUTPUT:
	rgbValue 
	RETVAL

RETCODE
SQLFetchint(hstmt)
	HSTMT		hstmt
	CODE:
		RETVAL=SQLFetch(hstmt);
	OUTPUT:
		RETVAL

RETCODE
SQLError(henv,hdbc,hstmt,szSqlState,pfNativeError,szErrorMsg,cbErrorMsgMax,pcbErrorMsg)
	HENV		henv
	HDBC		hdbc
	HSTMT		hstmt
	char * 		szSqlState 
	SDWORD 		pfNativeError
	char * 		szErrorMsg
	SWORD		cbErrorMsgMax
	SWORD 		pcbErrorMsg
	CODE:
		szSqlState = (char *) malloc (sizeof("00000"));
		szErrorMsg = (char *) malloc (sizeof(char)*cbErrorMsgMax);
		RETVAL = SQLError(henv,hdbc,hstmt,szSqlState,&pfNativeError,szErrorMsg,cbErrorMsgMax,&pcbErrorMsg);
	OUTPUT:
		szSqlState
		pfNativeError
		szErrorMsg
		pcbErrorMsg
		RETVAL
	CLEANUP:
		free(szSqlState);
		free(szErrorMsg);

RETCODE
SQLFreeStmtint(hstmt,fOption)
	HSTMT		hstmt
	UWORD		fOption
	CODE:
	RETVAL=SQLFreeStmt(hstmt,fOption);
	OUTPUT:
		RETVAL

RETCODE
SQLCancel(hstmt)
	HSTMT		hstmt
	OUTPUT:
		RETVAL

RETCODE
SQLTransact(henv,hdbc,fType)
	HENV		henv
	HDBC		hdbc
	UWORD		fType
	OUTPUT:
		RETVAL

RETCODE
SQLDisconnect(hdbc)
	HDBC		hdbc
	OUTPUT:
		RETVAL

RETCODE
SQLFreeConnect(hdbc)
	HDBC		hdbc
	OUTPUT:
		RETVAL

RETCODE
SQLFreeEnv(henv)
	HENV		henv
	OUTPUT:
		RETVAL

void
SQLFreeCol(rgbValue)
	void * rgbValue
	CODE:
		free(rgbValue);

void
SQLRefreshCol(rgbValue,fCType)
	void *	rgbValue
	SWORD	fCType
	CODE:
		ST(0) = sv_newmortal();
		switch(fCType){
			case SQL_C_CHAR: {
 				sv_setpv(ST(0),(char *) (UCHAR *) rgbValue);
				break;
			} case SQL_C_SSHORT: {
				sv_setiv(ST(0),(IV) *(SWORD *) rgbValue);
                                break;	
 			} case SQL_C_USHORT: {
				sv_setiv(ST(0),(IV) *(UWORD *) rgbValue);
                                break;	
                        } case SQL_C_SHORT: {
                                sv_setiv(ST(0),(IV) *(short *) rgbValue);
                                break;
 			} case SQL_C_SLONG:{
				sv_setiv(ST(0),(IV) *(SDWORD *) rgbValue);
                                break;
 			} case SQL_C_ULONG: {
                        	sv_setiv(ST(0),(IV) *(UDWORD *) rgbValue);
                                break;
                        } case SQL_C_LONG: {
                                sv_setiv(ST(0),(IV) *(DWORD *) rgbValue);
                                break;
			} case SQL_C_FLOAT: 
 			case SQL_C_DOUBLE: {
				sv_setnv(ST(0),*(double *) rgbValue);
                                break;
			} default: {
				sv_setpv(ST(0),"--");
			}
		}

