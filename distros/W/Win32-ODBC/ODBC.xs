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

#define PERL_POLLUTE
#define __WIN32_ODBC__

#define WIN32_LEAN_AND_MEAN
#include <stdlib.h>
#include <math.h>   // VC-5.0 brainmelt
#include <windows.h>
#include <stdio.h>
    
    //  ODBC Stuff
#ifdef __CYGWIN__
#   include <iodbcinst.h>
#else
#   include <sql.h>
#   include <sqlext.h>
#   include <odbcinst.h>
#endif
    //  Win32 Perl Stuff
#if defined(__cplusplus)
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSub.h"

#include "ppport.h"

#if defined(__cplusplus)
}   
#endif


    //  Win32::ODBC Stuff                       
#include "ODBCbuild.h"
#include "CResults.hpp" 
#include "CMom.hpp"
#include "ODBC.h"
#include "Constant.h"

#undef  __WIN32_ODBC__

extern  CMOM *cMom;

RETCODE TableColList(pTHX_ int iType);

/*----------------------- P E R L   F U N C T I O N S -------------------*/


XS(XS_WIN32__ODBC_Constant)
{
    dXSARGS;
    if (items < 1)
    {
        croak("Usage: Win32::ODBC::Constant(name)\n");
    }
    {
            STRLEN n_a;
        char* name = (char*)SvPV(ST(0),n_a);
        ST(0) = sv_newmortal();
        sv_setiv(ST(0), constant(name));
    }
    XSRETURN(1);
}


/*----------------------- M I S C   F U N C T I O N S -------------------*/
    /*
        Allocate memory for a new connection and set up the structure
    */

ODBC_TYPE *NewODBC(){
    ODBC_TYPE *h = 0;
    int iResult = 0;
    CMom    *cmDaughter;


#ifdef _DEBUG
    if (ghDebug){
        DebugConnection("Creating a new ODBC object.", 0);
    }
#endif
    if (!(cmDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId()))){
        cmDaughter = new CMom(GetCurrentThreadId());
    }
    if (cmDaughter){ 

#ifdef _DEBUG
        DEBUG_DUMP("NewODBC: Entering Critical Section gCS")
#endif
        EnterCriticalSection(&gCS);
        if (! ghEnv){
            SQLAllocEnv(&ghEnv);
        }
        LeaveCriticalSection(&gCS);

#ifdef _DEBUG
        DEBUG_DUMP("NewODBC: Left Critical Section gCS    ")
#endif

        if (ghEnv){                            
            if (h= new ODBC_TYPE){
                if (h->Error = new ODBC_ERROR){
                    if (cmDaughter->Add((void *)h)){
                        iResult = 1;                        
                        h->szDSN = 0;
                        h->szCommand = 0;
                        CleanODBC(h);
                            //  Add these values AFTER cleaning the ODBC Object
                        h->conn = cmDaughter->operator[]((void *)h);
#ifdef _DEBUG
                        DebugConnection("...created ODBC object.", h);
#endif
                        h->henv = ghEnv;
                             
                    }
                }
                if (!iResult){
                    FreeODBC(h);
                    delete h;
                    h = 0;
                }
            }
        }
    }
#ifdef _DEBUG
    else{
        DebugConnection("...failed with new ODBC object: Could not find or create daughter.", h);
    }
if (!h){
    DebugConnection("...creation of ODBC object failed.", h);
}
#endif
    return h;
}

    /*
        Clean up an ODBC structure.
    */

ODBC_TYPE *CleanODBC(ODBC_TYPE *h){
    h->hstmt    = SQL_NULL_HSTMT;
    h->henv     = SQL_NULL_HENV;
    h->hdbc     = 0;
    h->Results  = 0;
    h->iMaxBufSize  = DEFAULT_DATA_BUF_SIZE;
    h->numcols      = 0;

    h->uStmtCloseType = DEFAULT_STMT_CLOSE_TYPE;
    h->iDebug = 0;
    h->dNumOfRows = 0;
    strcpy(h->szUserDSN, "");
    if (h->szDSN){
        delete [] h->szDSN;
        h->szDSN = 0;
    }
    if (h->szCommand){
        delete [] h->szCommand;
        h->szCommand = 0;
    }
    CleanError(h->Error);
    return h;
}

    /*
        Deallocates memory used for an ODBC structure.
        If the master list (ODBCLIST) is passed to this it will do nothing unless
        there are no other ODBC structures remaining.
    */

int FreeODBC(ODBC_TYPE *h){
    int iResult = 1;

#ifdef _DEBUG
    if (ghDebug){
        char szBuff[1000];
        DebugConnection("FreeODBC has been called.\n", h);
    }
#endif
        //  There is a call in this function to itself if we delete the
        //  last connection. BECAUASE OF THIS do NOT put a critical section
        //  in this function lest we reach a deadlock condition.
    if (h->Results){
        delete h->Results;
        h->Results = 0;
    }
    if (h->hstmt){
            //  If ghDLL is NULL (process has already detached) then
            //  forget this (Win32 will purge the memory anyway).
        if (ghDLL) SQLFreeStmt(h->hstmt, SQL_DROP);
        h->hstmt = SQL_NULL_HSTMT;
    }
    if (h->hdbc){
        h->hdbc->iCount--;
        if (! h->hdbc->iCount){
                    //  Disconnect ONLY if you have no parents
                    //  If ghDLL is NULL (process has already detached) then
                    //  forget this (Win32 will purge the memory anyway).
            if (ghDLL){
                if (h->hdbc->iConnected){
                    SQLDisconnect(h->hdbc->hdbc);
                    h->hdbc->hdbc = SQL_NULL_HDBC;
                    h->hdbc->iConnected = 0;
                }
                SQLFreeConnect(h->hdbc->hdbc);
            }
            delete h->hdbc;
        }
        h->hdbc = 0;
    }
    if (h->Error){
        delete h->Error;
        h->Error = 0;
    }
    h->henv = SQL_NULL_HENV;

    
    if (h->iDebug){

#ifdef _DEBUG
        DebugConnection("Setting Debug Mode off for connection\n\t\t(due to object destuction).", h);
#endif

        RemoveDebug(h);
    }

#ifdef _DEBUG
    if (ghDebug){
        char szBuff[30];
        sprintf(szBuff, "FreeODBC was %s.\n", (iResult)? "successful":"unsuccessful");
        DebugConnection(szBuff, h);
    }
#endif

    if (iResult){
        CleanODBC(h);
    }
    return iResult;
}

void AddDebug(ODBC_TYPE *h){
    if (! h->iDebug){
        if (h->conn){
                //  Increase the debug flag ONLY if
            giDebug++;
        }else{
            giDebugGlobal = 1;
        }
        if (! ghDebug){
#if _DEBUG
            AllocConsole();
            SetConsoleTitle("DEBUG: ODBC.PLL");
            ghDebug = GetStdHandle(STD_ERROR_HANDLE);
#endif
        }
        h->iDebug = 1;
    }
}

void RemoveDebug(ODBC_TYPE *h){
    if(h->iDebug){
        if (h->conn){
            giDebug--;
            if (giDebug < 1){
                giDebug = 0;
            }
        }else{
//          giDebugGlobal = 0;
        }
        if (!(giDebug + giDebugGlobal)){
#ifdef _DEBUG
            DebugConnection("Closing Debug Output File.", h);
#endif
            DEBUG_DUMP("RemoveDebug: Entering Critical Section gDCS")
            EnterCriticalSection(&gDCS);
            ghDebug = 0;
#if _DEBUG
            FreeConsole();
#endif
            CloseHandle(ghFile);
            ghFile = 0; 
            if(gszFile){
                delete [] gszFile;
                gszFile = 0;
            }
            LeaveCriticalSection(&gDCS);
            DEBUG_DUMP("RemoveDebug: Left Critical Section gDCS    ")
        }
        h->iDebug = 0;
    }
}

    /*
        Reset (clean) an ODBC structures error state information
    */
void CleanError(ODBC_ERROR *h){
    if (h){
        strcpy(h->szError, "");
        strcpy((char *)h->szSqlState, "");
        strcpy(h->szFunction, "");
        strcpy(h->szFunctionLevel, "");
        h->ErrNum = 0;
        h->EOR = 0;
    }
    return;
}

    /*
        Reset an ODBC Stmt. (alloc memory if needed, free it up if needed)
    */    

RETCODE ResetStmt(ODBC_TYPE *h){
    RETCODE iReturnCode = SQL_SUCCESS;

    if (h->uStmtCloseType != SQL_DONT_CLOSE){
                //  If the SQLFreeStmt() failed, should we reallocate the stmt? 
                //  For now let's just return the error code and skip the reallocation.
        if (h->hstmt != SQL_NULL_HSTMT){
            iReturnCode = SQLFreeStmt(h->hstmt, h->uStmtCloseType);
            if (iReturnCode == SQL_SUCCESS){
                    //  We will need to realloc the hstmt ONLY if we DROPPED it!
                if(h->uStmtCloseType == SQL_DROP){
                    h->hstmt = SQL_NULL_HSTMT;
                }
            }else{
                _NT_ODBC_Error(h, "ResetStmt", "1");
            }
        }
        if (h->hstmt == SQL_NULL_HSTMT){
            if ((iReturnCode = SQLAllocStmt(h->hdbc->hdbc, &h->hstmt)) != SQL_SUCCESS){
                _NT_ODBC_Error(h, "ResetStmt", "2");
            }
        }
    }   
    return iReturnCode;
}
    
    /*
        Process an ODBC structures error state from the ODBC API.
        This is called when an error is encountered via the ODBC API.
    */

void _NT_ODBC_Error(ODBC_TYPE * h, char *szFunction, char *szFunctionLevel){
    SDWORD cbErrorMsg;

    if(!h){
        h = ODBCLIST;
    }
    strcpy((char *)h->Error->szSqlState, "");
    strcpy(h->Error->szError, "");
    SQLError(h->henv, h->hdbc->hdbc, h->hstmt, (SQLCHAR *)h->Error->szSqlState, (SQLINTEGER *)&(h->Error->ErrNum), (SQLCHAR *)h->Error->szError, ODBC_BUFF_SIZE, (SQLSMALLINT *)&cbErrorMsg);

        //  Next couple of lines should be NOT needed. If there is no error, then
        //  we should not have come here in the first place. If, however, there
        //  is state information that may be relevant (SQL_SUCCESS_WITH_INFO)
    if (!h->Error->ErrNum){
        h->Error->ErrNum = 911;
    }
    strcpy(h->Error->szFunction, szFunction);
    strcpy(h->Error->szFunctionLevel, szFunctionLevel);

#ifdef _DEBUG
    if (giDebug){
        DebugDumpError(h);
    }
#endif

}

    /*
        Process an ODBC structures error state from Win32::ODBC.
        This is called when an error is encountered NOT from the ODBC API
        but from this body of code.
    */

ODBC_TYPE *ODBCError(char *szString, ODBC_TYPE *h, char *szFunction, char * szFunctionLevel){
    if (!h){
        h = ODBCLIST;
    }
    if (h){
        h->Error->ErrNum = 911;
        strcpy(h->Error->szError, szString);
        strcpy(h->Error->szFunction, szFunction);
        strcpy(h->Error->szFunctionLevel, szFunctionLevel);
    }

#ifdef _DEBUG
    if (giDebug){
        DebugDumpError(h);
    }
#endif
    return h;
}

#ifdef _DEBUG
    void DebugDumpError(ODBC_TYPE *h){
        char *szBuff;
        int iLength;

        if (h && h->iDebug && ghDebug){
            iLength = ((h->Error->szError)? strlen(h->Error->szError):0) + ((h->Error->szSqlState)? strlen((const char *)h->Error->szSqlState):0)
                  + ((h->Error->szFunction)? strlen(h->Error->szFunction):0) + ((h->Error->szFunctionLevel)? strlen(h->Error->szFunctionLevel):0)
                  + 100;
            if(szBuff = new char [iLength]){
                sprintf(szBuff, "ODBCError from connection %i:\n\tErrno: %i\n\tError:\"%s\"\n\tSQLState: %s\n\tFunction: %s\n\tLevel: %s\n",
                             h->conn, h->Error->ErrNum, h->Error->szError, h->Error->szSqlState, h->Error->szFunction, h->Error->szFunctionLevel);
                DebugConnection(szBuff, h);
            }
            delete [] szBuff;
        }
    }

    void DebugConnection(char *szString, ODBC_TYPE *h){
        DWORD   dCount;
        CMom    *cDaughter = 0;
        char    *szBuff;
        int     iLength;
    
        if (ghDebug){
            if (::cMom){
                cDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId());
            }
            iLength = 100;
            if (szBuff = new char [iLength]){
                sprintf(szBuff, "Thread %05i, Total Threads %03i, Connection %03i, Thread Connections %03i:\n\t", GetCurrentThreadId(), giThread, (h)? h->conn:-1, (cDaughter)? cDaughter->Total():0);

        DEBUG_DUMP("DebugConnection: Entering Critical Section gDCS");

                EnterCriticalSection(&gDCS);
                DebugPrint(szBuff);
                DebugPrint(szString);
                DebugPrint("\n\n");
                LeaveCriticalSection(&gDCS);

        DEBUG_DUMP("DebugConnection: Left Critical Section gDCS    ");

                delete [] szBuff;
            }
        }
        return;
    }

    void DebugDump(char *szString){
        if (giDebug){

        DEBUG_DUMP("DebugDump: Entering Critical Section gDCS");

            EnterCriticalSection(&gDCS);
            DebugPrint(szString);
            LeaveCriticalSection(&gDCS);

        DEBUG_DUMP("DebugDump: Left Critical Section gDCS    ");

        }
        return;
    }           

    void DebugPrint(char *szString){
        DWORD   dCount;
        if (ghDebug){
            WriteConsole(ghDebug, szString, strlen(szString), &dCount, 0);
        }
        if (!ghFile && gszFile){
            ghFile = CreateFile(gszFile, GENERIC_WRITE, FILE_SHARE_READ, 0, CREATE_ALWAYS,  0, 0);
            DebugPrint("\n\t*******\n\tDumping debug text to: \"");
            DebugPrint(gszFile);
            DebugPrint("\"\n\t*******\n");
        }
        if(ghFile){
            WriteFile(ghFile, szString, strlen(szString), &dCount, 0);
            FlushFileBuffers(ghFile);
        }
        return;
    }
#endif  
    /*
        Map a column name (field name) to a column number that exists in a
        resulting dataset.
    */

int ColNameToNum(ODBC_TYPE *h, char *szName){
    int iResult = 0;
    int x;
    char    szBuff[ODBC_BUFF_SIZE];
    DWORD   dBuffLen = 0;

    for(x=1; x<=h->numcols; x++){
        SQLColAttributes(h->hstmt, x, SQL_COLUMN_NAME, szBuff, ODBC_BUFF_SIZE, (short *)&dBuffLen, NULL);
        if(!stricmp(szName, szBuff)){
            iResult = x;
            break;
        }
    }
    return iResult;
}


    /*
        Check if the specified connection is valid and return the pointer
        to the ODBC structure.
        Return a pointer to the master list (ODBCLIST) and genereate an error if
        there is no valid connection.
    */
ODBC_TYPE * _NT_ODBC_Verify(int iODBC){
    CMom    *cmDaughter = 0;
    ODBC_TYPE *h = 0;
    
    if(::cMom){
//      EnterCriticalSection(&gCS);
        if (cmDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId())){
            if (!(h = (ODBC_TYPE *) cmDaughter->operator[]((DWORD)iODBC))){
                h = (ODBC_TYPE *) cmDaughter->operator[]((DWORD)0);
            }
        }
//      LeaveCriticalSection(&gCS);
    }
    return (h);
}

    /*
        Delete an ODBC structure. This will call other routines to release
        allocated memory and reset ODBC state information.
    */
int DeleteConn(int iODBC){
    ODBC_TYPE   *h = 0;
    int iResult = 0;

    if(::cMom){
        CMom    *cmDaughter = 0;
        if (cmDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId())){
            if (h = (ODBC_TYPE *) cmDaughter->operator[]((DWORD)iODBC)){
                if (FreeODBC(h)){
                    cmDaughter->Remove((DWORD)iODBC);
                    delete h;
                    iResult++;
                }
            }
        }
    }
    return iResult;         
}




    /*
        Map an Stmt close type string to the actual Stmt close type value.
    */

char *MapCloseType(UWORD uCloseType){
    char *szType;

    switch(uCloseType){
        case SQL_DONT_CLOSE:
            szType = "SQL_DONT_CLOSE";
            break;

        case SQL_DROP:
            szType = "SQL_DROP";
            break;

        case SQL_CLOSE:
            szType = "SQL_CLOSE";
            break;

        case SQL_UNBIND:
            szType = "SQL_UNBIND";
            break;

        case SQL_RESET_PARAMS:
            szType = "SQL_RESET_PARAMS";

        default:
            szType = 0;
    }
    return szType;
}



/*------------------- P E R L   O D B C   F U N C T I O N S ---------------*/

        /*
            ODBC_Connect
            Connects to and ODBC Data Source Name (DSN).
        */
XS(XS_WIN32__ODBC_Connect) // ODBC_Connect(Connection string: input) returns connection #
{
    dXSARGS;

    char      szDSN[DSN_LENGTH]; // string to hold datasource name
    ODBC_TYPE * h;
    char        *szIn = 0;
    int         iTemp = 0;

    RETCODE retcode;           // Misc ODBC sh!t
    UCHAR   buff[ODBC_BUFF_SIZE];
    SDWORD  bufflenout;
    int     lenn = 0;
    STRLEN  n_a;

    if(items < 1 || !(items & 1)){
            //  We need at least 1 (DSN) entry. If more then we need them in pairs of
            //  two, hence (items & 1) make sure we have an odd number of entries...
            //  (dsn) + (ConnetOption, Value) [ + (ConnectOption, Value)] ...
        CROAK("usage: ($Connection, $Err, $ErrText) = ODBC_Connect($DSN [, $ConnectOption , $Value] ...)\n");
    }
    szIn = SvPV(ST(0), n_a); 

    if(strcspn(szIn, "[]{}(),;?*=!@") < strlen(szIn)){
        strncpy(szDSN, szIn, DSN_LENGTH - 1);
        szDSN[DSN_LENGTH - 1] = '\0';
    }else{
            //  Let's assume that the DSN will not exceed DSN_LENGTH
        strcpy(szDSN, "DSN=");  
        strcat(szDSN, szIn); // Data Source string
        strcat(szDSN, ";");
    }

    PUSHMARK(sp);

            //  Allocate new ODBC connection
    if (!(h = NewODBC())){
        h = ODBCError("Could not allocate memory of an ODBC connection\n", (ODBC_TYPE*)0, "ODBC_Connect", "1");
    }else{
        strcpy(h->szUserDSN, szIn);
        if (h->hdbc = new ODBC_HDBC){
            h->hdbc->hdbc = SQL_NULL_HDBC;
            h->hdbc->iConnected = 0;
            h->hdbc->iCount = 1;    //  Set the count to include this particular instance
        }else{
            _NT_ODBC_Error(h, "ODBC_Connect could not allocate memory for an HDBC connection", "1a");
            DeleteConn(h->conn);
        }
    
        if (!h->Error->ErrNum){
            retcode = SQLAllocConnect(h->henv, &h->hdbc->hdbc);
            if (retcode != SQL_SUCCESS)
            {
                _NT_ODBC_Error((ODBC_TYPE*)0, "ODBC_Connect", "2");
                DeleteConn(h->conn);
            }
        }
        if (!h->Error->ErrNum){
                //  If any pre-connect SQLConnectOptions are specified, do them now...
            if (items > 1){
                int iTemp = items -1;
                UWORD   uType;
                UDWORD  udValue;
                char    szError[100];

                while (iTemp > 1){
                    uType = (UWORD)SvIV(ST(iTemp - 1));
                    if (SvIOKp(ST(iTemp)) || SvNOKp(ST(iTemp))){
                        udValue = SvIV(ST(iTemp));
                    }else{
                        udValue = (UDWORD) SvPV(ST(iTemp), n_a);
                    }
                    retcode = SQLSetConnectOption(h->hdbc->hdbc, uType, udValue);
                    if (retcode != SQL_SUCCESS){
                        sprintf(szError, "2a: Connect Item number %i", (iTemp/2));
                        _NT_ODBC_Error(h, "ODBC_Connect", szError);
                        break;
                    }
                    iTemp -= 2;
                }
            }
        }
        if (!h->Error->ErrNum){
            retcode = SQLDriverConnect(h->hdbc->hdbc, (HWND) NULL, (unsigned char *)szDSN, strlen(szDSN), buff, ODBC_BUFF_SIZE, (short *)&bufflenout, SQL_DRIVER_NOPROMPT);
            if (retcode != SQL_SUCCESS && retcode != SQL_SUCCESS_WITH_INFO){
                _NT_ODBC_Error(h, "ODBC_Connect", "4");
                strcpy(ODBCLIST->Error->szError, h->Error->szError);
                strcpy((char *)ODBCLIST->Error->szSqlState, (char *)h->Error->szSqlState);
                strcpy(ODBCLIST->Error->szFunction, h->Error->szFunction);
                strcpy(ODBCLIST->Error->szFunctionLevel, h->Error->szFunctionLevel);
                    //  If connection fails it does not genereate an error num. Hmmm...
                if(! h->Error->ErrNum){
                    h->Error->ErrNum = 911;
                }
                ODBCLIST->Error->ErrNum = h->Error->ErrNum;
                DeleteConn(h->conn);
                h = ODBCLIST;
            }else{
                h->hdbc->iConnected = 1;
                if (h->szDSN = new char [strlen((const char *)buff) + 1]){
                    strcpy(h->szDSN, (char *) buff);
                }

                if (retcode == SQL_SUCCESS_WITH_INFO){
                    _NT_ODBC_Error(h, "ODBC_Connect", "5");
                    h->Error->ErrNum = 0;
                }
            }
        }
        if (!h->Error->ErrNum){
            retcode = ResetStmt(h);
            if (retcode != SQL_SUCCESS){
                DeleteConn(h->conn);
            }
        }
    }
    if (!h->Error->ErrNum){ // everything is happy
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)h->conn)));
            //  Report the szError ONLY because it may contain state info.
        XPUSHs(sv_2mortal(newSVpv(h->Error->szError, strlen(h->Error->szError))));
    }else{
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
} 


XS(XS_WIN32__ODBC_Execute) // ODBC_Execute($connection, $sql_text) returns (0,@fieldnames) or (err, errtext)
{
    dXSARGS;
    ODBC_TYPE * h;
    RETCODE retcode;          //ODBC gunk
    UCHAR  buff2[ODBC_BUFF_SIZE];
    SDWORD bufflenout;
    UWORD  x;
    char * szSQL; 
    STRLEN n_a;

    if(items < 2){
        CROAK("usage: ($err,@fields) = ODBC_Execute($connection, $sql_text)\nprint \"Oops: $field[0]\" if ($err);\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    
    PUSHMARK(sp);

    if (h != ODBCLIST){
        szSQL = SvPV(ST(1), n_a);            // get SQL string
            //  Do we really want to resetsmtm now? 
        if (ResetStmt(h) == SQL_SUCCESS){
            if (h->szCommand){
                delete [] h->szCommand;
                h->szCommand = 0;
            }
            if (h->szCommand = new char [strlen(szSQL) + 1]){
                strcpy(h->szCommand, szSQL);
            } 
        }
    
    
        if (!h->Error->ErrNum){
            retcode = SQLExecDirect(h->hstmt, (unsigned char*)szSQL, strlen(szSQL));
            if (retcode != SQL_SUCCESS && retcode != SQL_SUCCESS_WITH_INFO){
                _NT_ODBC_Error(h, "ODBC_Execute", "1");
            }else{
                if(h->Results){
                    delete h->Results;
                }
                h->Results = new CResults(h);
            }
        }
    }
    if (!h->Error->ErrNum){ // everything is happy
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        retcode = SQLNumResultCols(h->hstmt, (short *)&h->numcols);
        for(x=1; x<=h->numcols; x++){
            SQLColAttributes(h->hstmt, x, SQL_COLUMN_NAME, buff2, ODBC_BUFF_SIZE, (short *)&bufflenout, NULL);
            XPUSHs(sv_2mortal(newSVpv((char *)buff2, strlen((const char*)buff2))));
        }
    }else{                                      
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}

    /*
        ODBC_Fetch
        Fetch a row from the current dataset.
    */
XS(XS_WIN32__ODBC_Fetch) // ODBC_Fetch($connection) returns (0,@dataelements) or ($err,$errtext)
{
    dXSARGS;
    ODBC_TYPE * h;

    RETCODE retcode;         // yet more ODBC garbage
    UWORD   uType = SQL_FETCH_NEXT;
    SDWORD  sdRow = 1;
    DWORD   dRowSetSize = 1;

    UWORD   *rgfRowStatus = 0;
    SQLULEN  udCRow = 0;
    int     iTemp;  

    if(items < 1 || items > 3){
        CROAK("usage: ($err,@col) = ODBC_Fetch($connection [, $Row [, $FetchType]])\n0die \"Oops: $col[0]\" if ($err);\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
        //  NOTICE: We do not perform a CleanODBC(h) here because a dirty
        //  h will tell us if there is an error such as EOR (end of records).
    if (items > 1){
        sdRow = SvIV(ST(1));
//      uType = SQL_FETCH_RELATIVE;
    }
    if (items > 2){
        uType = (UWORD)SvIV(ST(2));
    }
                     
    PUSHMARK(sp);

    if (h != ODBCLIST){
        SQLGetStmtOption(h->hstmt, SQL_ROWSET_SIZE, &dRowSetSize);
//  SQLSetStmtOption(h->hstmt, SQL_ROWSET_SIZE, 1);
        if (!(rgfRowStatus = new UWORD [dRowSetSize])){
            ODBCError("Can not allocate memory for row status results", h, "ODBC_Fetch", "1b");
        }
        if (h->Results){
                //  Clear out the old results
            h->Results->Clean();
        }
        retcode = SQLExtendedFetch(h->hstmt, uType, sdRow, &udCRow, rgfRowStatus);
//  SQLSetStmtOption(h->hstmt, SQL_ROWSET_SIZE, dRowSetSize);

        if((retcode != SQL_SUCCESS) && (retcode != SQL_SUCCESS_WITH_INFO)){
            _NT_ODBC_Error(h, "ODBC_Fetch", "2");
        }
        if (retcode == SQL_NO_DATA_FOUND){
            ODBCError("No data records remain.", h, "ODBC_Fetch", "3");
            h->Error->EOR = 1;
        }
        if(retcode == SQL_SUCCESS_WITH_INFO){
            _NT_ODBC_Error(h, "ODBC_Fetch", "4");           
        }
    }
    if (! h->Error->ErrNum){
             // everything is happy
        XPUSHs(sv_2mortal(newSVnv((double)0))); 
        if(items > 1){
            for(iTemp = 0; iTemp < (int)udCRow; iTemp++){
                XPUSHs(sv_2mortal(newSVnv((double)rgfRowStatus[iTemp])));   
            }
        }else{
            XPUSHs(sv_2mortal(newSVnv((double)1))); 
        }
    }else{
            //  Report the error
        ReturnError(h);
    }

    if (rgfRowStatus){
        delete [] rgfRowStatus;
    }
    PUTBACK;
}

 
XS(XS_WIN32__ODBC_GetError)
{
    dXSARGS;
    ODBC_TYPE *h;

    h = _NT_ODBC_Verify(SvIV(ST(0)));

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVnv((double)h->Error->ErrNum)));
    XPUSHs(sv_2mortal(newSVpv(h->Error->szError, strlen(h->Error->szError))));
    XPUSHs(sv_2mortal(newSVpv((char *)h->Error->szSqlState, strlen(( const char *) h->Error->szSqlState))));
    if (h->iDebug){
        XPUSHs(sv_2mortal(newSVpv((char *)h->Error->szFunction, strlen(( const char *) h->Error->szFunction))));
        XPUSHs(sv_2mortal(newSVpv((char *)h->Error->szFunctionLevel, strlen(( const char *) h->Error->szFunctionLevel))));
    }
        
    PUTBACK;
}
          

XS(XS_WIN32__ODBC_Disconnect) // usage: ODBC_Disconnect($conn) or ODBC_Disconnect() for all
{
    dXSARGS;
    ODBC_TYPE *h;
    int     iResult = 0;
    int     conn;
    
    if(items < 1){
        conn = 0;
    }else{
        conn = SvIV(ST(0));
    }
    PUSHMARK(sp);
    if (!(iResult = DeleteConn(conn))){
        h = ODBCError("No such connection", (ODBC_TYPE*) 0, "ODBC_Disconnect", "1");
    
#ifdef _DEBUG
        if (h){
            if(h->iDebug){
                char szBuff[40];
                sprintf(szBuff, "ODBC_Disconnect: No such connection %i\n", conn);
                DebugConnection(szBuff, h);
            }
        }
#endif

    }
    if (iResult){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)iResult)));
    }else{
                //  Report the error
        ReturnError(h);
    }
        PUTBACK;
}

XS(XS_WIN32__ODBC_TableList) // ODBC_TableList($connection) returns (0,@TableNames) or ($err,$errtext)
{
    dXSARGS;
    RETCODE retcode;

    if(items != 5){
        CROAK("usage: ($Err,@ColumnNames) = ODBC_TableList($connection, $Qualifier, $Owner, $TableName, $TableType)\n");
    }

    retcode = TableColList(aTHX_ 0);
}

XS(XS_WIN32__ODBC_ColumnList)
{
    dXSARGS;    
    RETCODE retcode;

    if(items != 5){
        CROAK("usage: ($Err,@ColumnNames) = ODBC_ColumnList($connection, $Qualifier, $Owner, $TableName, $ColumnName)\n");
    }

    retcode = TableColList(aTHX_ 1);
}

RETCODE TableColList(pTHX_ int iType){
    dXSARGS;
    ODBC_TYPE * h;
    int    iTemp;
    UCHAR  buff2[ODBC_BUFF_SIZE];
    SDWORD bufflenout;
    UWORD  x;
    STRLEN n_a;

    RETCODE retcode;
    UCHAR   *szQualifier, *szOwner, *szName, *szType;
    SWORD   sQLen, sOLen, sNLen, sTLen = 0;
    UWORD   uTemp = 0;

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    
    if (szQualifier = (unsigned char *) SvPV(ST(1), n_a)){
        if (!(sQLen = strlen((char *)szQualifier))){
            szQualifier = 0;
        }
    }

    if (szOwner = (unsigned char *) SvPV(ST(2), n_a)){
        if (!(sOLen = strlen((char *)szOwner))){
            szOwner = 0;
        }
    }

    if (szName = (unsigned char *) SvPV(ST(3), n_a)){
        if (!(sNLen = strlen((char *)szName))){
            szName = 0;
        }
    }

    if (szType = (unsigned char *) SvPV(ST(4), n_a)){
        if (!(sTLen = strlen((char *)szType))){
            szType = 0;
        }
    }
    
    PUSHMARK(sp);

    if (h != ODBCLIST){
        CleanError(h->Error);
        retcode = ResetStmt(h);
        if (h->szCommand){
            delete [] h->szCommand;
            h->szCommand = 0;
        }
                /*  The funny odd thing about this next line is that when we allocate
                    memory of h->szCommand it will be based on a sprintf(). The format
                    string for sprintf() will have references to szQualifier, szOwner, etc.
                    IF any of those strings are 0 then the %s's in the format string may be
                    replaced with "(null)" or some other indicator of a null pointer. Therefore
                    in the event of szQualifier (or whatever) == 0 we will provide an arbitrary
                    number of bytes for allocation (like 10).
                */
                            
        if (h->szCommand = new char [strlen((const char *) TABLE_COMMAND_STRING)
                            + 12    //  for the name of the function
                            + (szQualifier ? strlen((const char *)szQualifier):10)
                            + (szOwner ? strlen((const char *)szOwner):10)
                            + (szName ? strlen((const char *)szName):10)
                            + (szType ? strlen((const char *)szType):10) + 1]){
            sprintf(h->szCommand, TABLE_COMMAND_STRING, (iType)? "SQLColumns":"SQLTables", szQualifier, szOwner, szName, szType);
        }
        
        if(iType){
            retcode = SQLColumns(h->hstmt, szQualifier, sQLen, szOwner, sOLen, szName, sNLen, szType, sTLen);
        }else{
            retcode = SQLTables(h->hstmt, szQualifier, sQLen, szOwner, sOLen, szName, sNLen, szType, sTLen);
        }
        if(retcode != SQL_SUCCESS){
            _NT_ODBC_Error(h, "ODBC_TableColList", "1");
        }
    }
    if (!h->Error->ErrNum){
        if (h->Results){
            delete h->Results;
        }
        h->Results = new CResults (h);
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        retcode = SQLNumResultCols(h->hstmt, (short *)&h->numcols);
        for(x=1; x<=h->numcols; x++){
            *buff2 = '\0';
            SQLColAttributes(h->hstmt, x, SQL_COLUMN_NAME, buff2, ODBC_BUFF_SIZE, (short *)&bufflenout, NULL);
                /*  
                    We need to convert the columns to uppercase since different
                    ODBC drivers impliment this differently (Access uses upperc, MS SQL server uses lowerc)
                    We should probably figure out a more reasonable solution.
                */
            for(iTemp = strlen((char *)buff2) - 1; iTemp >= 0; iTemp--){
                buff2[iTemp] = (char) toupper(buff2[iTemp]);
            }
            XPUSHs(sv_2mortal(newSVpv((char *)buff2, strlen((const char*)buff2))));
        }
    }else{
        //  Report the error
        ReturnError(h);
    }
    PUTBACK;
    return retcode;
}

/*
    This next chunk of code (XS_WIN32__ODBC_MoreResults) was 
    graciously donated by Brian Dunfordshore <Brian_Dunfordshore@bridge.com>.
    Thanks Brian!
    96.07.10
*/
XS(XS_WIN32__ODBC_MoreResults)  // usage: ODBC_MoreResults($conn)
{
    dXSARGS;
    RETCODE retcode;         // yet more ODBC garbage
    ODBC_TYPE *h;
 
    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    PUSHMARK(sp);
    if (h != ODBCLIST){
        retcode = SQLMoreResults(h->hstmt);
        if((retcode != SQL_SUCCESS) && (retcode != SQL_SUCCESS_WITH_INFO)){
            _NT_ODBC_Error(h, "ODBC_MoreResults", "1");
        }
        if (retcode == SQL_NO_DATA_FOUND){
            h->Error->EOR = 1;
            strcpy(h->Error->szError, "No data records remain.");
        }
    }
    if (!h->Error->ErrNum){      // everything is happy
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)1)));   //    Return a TRUE
    }else{
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}

XS(XS_WIN32__ODBC_MaxBufSize) 
{
    dXSARGS;
    ODBC_TYPE * h;
    long    iSize;      

    if(items <1 || items > 2){
        CROAK("usage: ($Err, $Size) = ODBC_MaxBufSize($Connection [, $NewSize])\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    PUSHMARK(sp);

    if (h != ODBCLIST){
        if (items > 1){
            iSize = SvIV(ST(1));
            iSize = ((iSize <= 0)? 0:iSize);
            iSize = ((iSize >= MAX_DATA_BUF_SIZE)? MAX_DATA_BUF_SIZE:iSize);
            h->iMaxBufSize = iSize;
        }
    
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)h->iMaxBufSize)));
    }else{                                      
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;

}

XS(XS_WIN32__ODBC_GetConnections) 
{
    dXSARGS;
    int iTemp;
    ODBC_TYPE   *h;
    CMom    *cmDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId());

    if(items){
        CROAK("usage: (@ConnectionList) = ODBC_GetConnections()\n");
    }
    PUSHMARK(sp);

    for (iTemp = cmDaughter->TotalElements(); iTemp; iTemp--){
        h = (ODBC_TYPE *) cmDaughter->operator[]((DWORD)iTemp - 1);
        if (h){
            XPUSHs(sv_2mortal(newSVnv((double)h->conn)));
        }
    }
    PUTBACK;
}

XS(XS_WIN32__ODBC_GetDSN) 
{
    dXSARGS;
    ODBC_TYPE *h;
    char    *szDSN = 0;
    char    *szTemp = 0;
    DWORD   dSize = 1024;
    char    *szKeys= 0;
    char    *szValues = 0;
    char    *szPointer = 0;
    STRLEN  n_a;

    if(items > 2 || items < 1){
        CROAK("usage: ($Err, $DSN) = ODBC_GetDSN($Connection [, $DSN])\n");
    }
    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);

    if (items > 1){
        szDSN = SvPV(ST(1), n_a);
        if (! strlen(szDSN)){
            szDSN = 0;
        }
    }
    if (! szDSN){
        szDSN = h->szDSN;
        while(szDSN){
            if (szDSN[0] == ';'){
                szDSN++;
            }
            if (! strnicmp("DSN=", szDSN, 4)){
                szDSN += 4 * sizeof(char);
                break;
            }
            szDSN = strchr(szDSN, ';');
        }
    }

    PUSHMARK(sp);

    szTemp = szDSN;
    if (! (szDSN = new char [strlen(szTemp) + 1])){
        szDSN = 0;
        ODBCError("Could not allocate memory for DSN comparison", h, "ODBC_GetDSN", "1");
    }else{

        strcpy(szDSN, szTemp);
        szTemp = strchr(szDSN, ';');
        if (szTemp){
            *szTemp = '\0';
        }
        if (szKeys = new char [dSize + 1]){ 
            SQLGetPrivateProfileString( szDSN, 0, "", szKeys, dSize, "ODBC.INI");
            if (strcmp(szKeys, "")){
                szPointer = szKeys;
                if (szValues = new char [dSize + 1]){   
                    XPUSHs(sv_2mortal(newSVnv((double)0)));
                    while(*szPointer){
                        SQLGetPrivateProfileString( szDSN, szPointer, "", szValues, dSize, "ODBC.INI");
                        XPUSHs(sv_2mortal(newSVpv(szPointer, strlen(szPointer))));
                        XPUSHs(sv_2mortal(newSVpv(szValues, strlen(szValues))));
                        szPointer += strlen(szPointer) + 1;
                    }
                    if(szValues) delete [] szValues;
                }else{
                    ODBCError("Could not allocate enough memory", h, "ODBC_GetDSN", "2");
                }
            }else{
                ODBCError("Not a valid DSN", h, "ODBC_GetDSN", "3");
            }
            if(szKeys) delete [] szKeys;
        }else{
            ODBCError("Could not allocate enough memory", h, "ODBC_GetDSN", "4");
        }
    }

    if (h->Error->ErrNum){
            //  Report the error
        ReturnError(h);
    }
    if (szDSN){
        delete [] szDSN;
    }
    
    PUTBACK;
}

XS(XS_WIN32__ODBC_DataSources) 
{
    dXSARGS;
    ODBC_TYPE *h;
    UCHAR   szDSN[SQL_MAX_DSN_LENGTH + 1];
    SWORD   pcbDSN;
    UCHAR   szDesc[DS_DESCRIPTION_LENGTH];
    SWORD   pcbDesc;    
    char    *szRequestedDSN = 0;
    RETCODE retcode;
    STRLEN  n_a;

    if(items > 1){
        CROAK("usage: ($Err, $DSN) = ODBC_DataSources([$DSN])\n");
    }
    
    h = ODBCLIST;

    if (items){
        szRequestedDSN = SvPV(ST(0), n_a);
        if (!strlen(szRequestedDSN)){
            szRequestedDSN = 0;
        }
    }

    PUSHMARK(sp);

    *szDSN = *szDesc = '\0';
    retcode= SQLDataSources(h->henv, SQL_FETCH_FIRST, szDSN, SQL_MAX_DSN_LENGTH + 1, &pcbDSN, szDesc, DS_DESCRIPTION_LENGTH, &pcbDesc);
    if(retcode == SQL_SUCCESS){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        
        while (retcode == SQL_SUCCESS){
            if ((szRequestedDSN && (!stricmp((const char *)szDSN, szRequestedDSN))) || !szRequestedDSN){
                XPUSHs(sv_2mortal(newSVpv((char *)szDSN, strlen((char*)szDSN))));
                XPUSHs(sv_2mortal(newSVpv((char *)szDesc, strlen((char*)szDesc))));
            }
            *szDSN = *szDesc = '\0';
            retcode= SQLDataSources(h->henv, SQL_FETCH_NEXT, szDSN, SQL_MAX_DSN_LENGTH + 1, &pcbDSN, szDesc, DS_DESCRIPTION_LENGTH, &pcbDesc);
        }

    }else{
        h = ODBCError("No such ODBC connection.", (ODBC_TYPE*) 0, "ODBC_DataSources", "1");
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}

XS(XS_WIN32__ODBC_Drivers) 
{
    dXSARGS;
    ODBC_TYPE *h;
    UCHAR   szAttr[DS_DESCRIPTION_LENGTH + 1];
    SWORD   cbAttr;
    UCHAR   szDesc[DS_DESCRIPTION_LENGTH];
    SWORD   cbDesc; 
    char    *szTemp;
    RETCODE retcode;

    if(items > 0){
        CROAK("usage: ($Err, $DSN) = ODBC_Drivers()\n");
    }
    
    h = ODBCLIST;
    PUSHMARK(sp);
    
    *szDesc = *szAttr = '\0';
    retcode = SQLDrivers(h->henv, SQL_FETCH_FIRST, szDesc, DS_DESCRIPTION_LENGTH, &cbDesc, szAttr, DS_DESCRIPTION_LENGTH, &cbAttr);
    if(retcode == SQL_SUCCESS){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        
        while (retcode == SQL_SUCCESS){
            szTemp = (char *) szAttr;
            while(szTemp[0] != '\0'){
                szTemp = strchr(szTemp, '\0');
                *szTemp++ = ';';
            }
            XPUSHs(sv_2mortal(newSVpv((char *)szDesc, strlen((char*)szDesc))));
            XPUSHs(sv_2mortal(newSVpv((char *)szAttr, strlen((char*)szAttr))));
            *szDesc = *szAttr = '\0';
            retcode = SQLDrivers(h->henv, SQL_FETCH_NEXT, szDesc, DS_DESCRIPTION_LENGTH, &cbDesc, szAttr, DS_DESCRIPTION_LENGTH, &cbAttr);
        }
    }else{
        h = ODBCError("No such ODBC connection.", (ODBC_TYPE*) 0, "ODBC_Drivers", "1");
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}

XS(XS_WIN32__ODBC_RowCount) 
{
    dXSARGS;
    ODBC_TYPE *h;
    SQLLEN  sdRows = 0L;
    RETCODE retcode;

    if(items != 1){
        CROAK("usage: ($Err, $NumOfRows) = ODBC_RowCount($Connection)\n");
    }
    
    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    PUSHMARK(sp);
    
    retcode = SQLRowCount(h->hstmt, &sdRows);
    if(retcode == SQL_SUCCESS){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)sdRows)));
    }else{
        h = ODBCError("No such ODBC connection.", (ODBC_TYPE*) 0, "ODBC_RowCount", "1");
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}


XS(XS_WIN32__ODBC_Info) 
{
    dXSARGS;

    if(items > 0){
        CROAK("usage: ($ExtName, $Version, $Date, $Author, $CompileDate, $Credits, $Comments) = Info()\n");
    }
    
    PUSHMARK(sp);
    
    XPUSHs(sv_2mortal(newSVpv(VERNAME, strlen(VERNAME))));
    XPUSHs(sv_2mortal(newSVpv(VERSION, strlen(VERSION))));
    XPUSHs(sv_2mortal(newSVpv(VERDATE, strlen(VERDATE))));
    XPUSHs(sv_2mortal(newSVpv(VERAUTH, strlen(VERAUTH))));
    XPUSHs(sv_2mortal(newSVpv(VERDATE, strlen(VERDATE))));
    XPUSHs(sv_2mortal(newSVpv(VERTIME, strlen(VERTIME))));
    XPUSHs(sv_2mortal(newSVpv(VERCRED, strlen(VERCRED))));
    XPUSHs(sv_2mortal(newSVpv(VERCOMMENT, strlen(VERCOMMENT))));

    PUTBACK;
}

XS(XS_WIN32__ODBC_GetStmtCloseType) 
{
    dXSARGS;
    ODBC_TYPE * h;
    char    *szType;

    if(items != 1){
        CROAK("usage: ($Err, $Type) = ODBC_GetStmtCloseType($Connection)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    PUSHMARK(sp);
    
    if (!(szType = MapCloseType(h->uStmtCloseType))){
        ODBCError("Invalid Statment Close Type", h, "ODBC_GetStmtCloseType", "1");
    }           
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVpv(szType, strlen(szType))));
    }else{
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}

XS(XS_WIN32__ODBC_SetStmtCloseType) 
{
    dXSARGS;
    ODBC_TYPE * h;
    char    *szType;
    UWORD   uType;      
    
    if(items != 2){
        CROAK("usage: ($Err, $Type) = ODBC_SetStmtCloseType($Connection, $Type)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uType = (UWORD)SvIV(ST(1));
    PUSHMARK(sp);

    switch(uType){
        case SQL_DONT_CLOSE:
        case SQL_DROP:
        case SQL_CLOSE:
        case SQL_UNBIND:
        case SQL_RESET_PARAMS:
            h->uStmtCloseType = uType;
            if (!(szType = MapCloseType(h->uStmtCloseType))){
                ODBCError("Invalid Statment Close Type", h, "ODBC_SetStmtCloseType", "1");
            }
            break;

        default:
            ODBCError("Not a valid Stmt Close Type", h, "ODBC_SetStmtCloseType", "2");
    }                   
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVpv(szType, strlen(szType))));
    }else{
            //  Report the error
        ReturnError(h);
    }


    PUTBACK;
}


XS(XS_WIN32__ODBC_SetConnectOption)
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD   uType;
    UDWORD  udValue;
    RETCODE rResult = 0;
    STRLEN  n_a;

    if(items != 3){
        CROAK("usage: ($Err, $Type) = ODBC_SetConnectOption($Connection, $Type, $Value)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uType = (UWORD)SvIV(ST(1));
    if (SvIOKp(ST(2)) || SvNOKp(ST(2))){
        udValue = SvIV(ST(2));
    }else{
        udValue = (UDWORD) SvPV(ST(2), n_a);
    }
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        rResult = SQLSetConnectOption(h->hdbc->hdbc, uType, udValue);
        if (rResult != SQL_SUCCESS){
            _NT_ODBC_Error(h, "ODBC_SetConnectOption", "1");
        }
    }

    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)1)));
    }else{
            //  Report the error
        ReturnError(h);
    }


    PUTBACK;
}

XS(XS_WIN32__ODBC_GetConnectOption)
{
    dXSARGS;
    ODBC_TYPE * h;
    UCHAR   ucValue[SQL_MAX_OPTION_STRING_LENGTH + 1];
    DWORD   *dValue = (DWORD *)ucValue;
    UWORD   uOption;
    RETCODE rResult = 0;
    
    if(items != 2){
        CROAK("usage: ($Err, $NumValue, $Value) = ODBC_GetConnectOption($Connection, $Type)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uOption = (UWORD)SvIV(ST(1));
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        memset(ucValue, 255, SQL_MAX_OPTION_STRING_LENGTH + 1);
        rResult = SQLGetConnectOption(h->hdbc->hdbc, uOption, ucValue);
        if (rResult != SQL_SUCCESS){
            _NT_ODBC_Error(h, "ODBC_GetConnectOption", "1");
        }
    }

    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        switch(uOption){
            case SQL_ACCESS_MODE:
            case SQL_AUTOCOMMIT:
            case SQL_LOGIN_TIMEOUT:
            case SQL_ODBC_CURSORS:      
            case SQL_OPT_TRACE:         
            case SQL_PACKET_SIZE:           
            case SQL_QUIET_MODE:            
            case SQL_TRANSLATE_OPTION:
            case SQL_TXN_ISOLATION:     
                    //  GetConnectOption returned a DWORD
                XPUSHs(sv_2mortal(newSVnv((double) *dValue)));
                break;

            default:
                    //  GetConnectOption returned a string
                XPUSHs(sv_2mortal(newSVpv((char *)ucValue, strlen((char *) ucValue))));
                break;
        }
    }else{
            //  Report the error
        ReturnError(h);
    }

    
    PUTBACK;
}

XS(XS_WIN32__ODBC_StmtOption)
{
    dXSARGS;
    ODBC_TYPE * h;
    UCHAR   ucValue[SQL_MAX_OPTION_STRING_LENGTH + 1];
    DWORD   *dValue = (DWORD *)ucValue;
    UWORD   uOption;
    UDWORD  udValue;
    RETCODE rResult = 0;
    STRLEN  n_a;

    if(items < 2 || items > 3){
        CROAK("usage: ($Err, $NumValue, $Value) = ODBC_StmtOption($Connection, $Type [,$Value])\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uOption = (UWORD)SvIV(ST(1));
    if (items > 2){
        if (SvIOKp(ST(2)) || SvNOKp(ST(2))){
            udValue = SvIV(ST(2));
        }else{
            udValue = (UDWORD) SvPV(ST(2), n_a);
        }
    }

    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        if(items < 3){
                //  Less than three parameters passed in so we are GETTING the stmt option
            memset(ucValue, 255, SQL_MAX_OPTION_STRING_LENGTH + 1);
            rResult = SQLGetStmtOption(h->hstmt, uOption, &ucValue);
            if (rResult != SQL_SUCCESS){
                _NT_ODBC_Error(h, "ODBC_StmtOption", "1");
            }
        }else{
                //  Three parameters passed in so we are SETTING the stmt option
            rResult = SQLSetStmtOption(h->hstmt, uOption, udValue);
            if (rResult != SQL_SUCCESS){
                _NT_ODBC_Error(h, "ODBC_StmtOption", "2");
            }
        }
    }
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        if(items < 3){
            switch(uOption){
                        /*  Even though this function is basically the same
                            as the ODBC_GetConnectOption the default on the
                            select() is a DWORD since so few (actually as of 
                            now NONE) of the options return strings. So the 
                            list of strings returns (case: xxx) will be small.
                        */
                case 0xf0f0:            //  Something toatly unreasonable since I can't find a real string return.
                        //  GetStmtOption returned a string
                    XPUSHs(sv_2mortal(newSVpv((char *)ucValue, strlen((char *) ucValue))));
                    break;

                default:
                        //  GetStmtOption returned a DWORD
                    XPUSHs(sv_2mortal(newSVnv((double) *dValue)));
                    break;
            }
        }else{
                XPUSHs(sv_2mortal(newSVnv((double)1)));
        }
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}


XS(XS_WIN32__ODBC_GetFunctions)
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD   uOutput[100];
    UWORD   uOption;
    RETCODE rResult = 0;
    int     iTemp, iTotal;
    
    iTemp = iTotal = 0;
    if(items < 1 || items > 101){
        CROAK("usage: ($Err, $NumValue, $Value) = ODBC_GetFunctions($Connection, ($Function1, $Function2 ... $Function100))\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    PUSHMARK(sp);

    items--;

        //  We decremented items, so if it's < 1 assume we want ALL functions!
    if (items < 1){
        uOption = SQL_API_ALL_FUNCTIONS;
        iTotal = 100;
        items = 1;
    }else{
        uOption = (UWORD)SvIV(ST(1));
    }

    while(items--){
        rResult = SQLGetFunctions(h->hdbc->hdbc, uOption, &uOutput[iTemp]);
        if (rResult != SQL_SUCCESS){
            _NT_ODBC_Error(h, "ODBC_GetFunctions", "1");
            if(! strcmp((const char*) h->Error->szSqlState, "00000")){
                    //  The requested function number does not exist.   
                CleanError(h->Error);
                uOutput[iTemp] = ~0;
            }else{
                items = 0;
            }
        }
        iTemp++;
        if (items){     //  If there are no more stack elements we will screw up
                        //  trying to access ST(1 + iTemp)
            uOption = (UWORD)SvIV(ST(1 + iTemp));
        }
    }
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        if (!iTotal){
             iTotal = iTemp;
        }
        for (iTemp = 0; iTemp < iTotal; iTemp++){
            XPUSHs(sv_2mortal(newSVnv((double) uOutput[iTemp])));
        }
    }else{
            //  Report the error
        ReturnError(h);
    }

    
    PUTBACK;
}


XS(XS_WIN32__ODBC_Transact)
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD  uType;
    RETCODE rResult = 0;
    
    if(items != 2){
        CROAK("usage: ($Err, $Type) = ODBC_Transact($Connection, $Type)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uType = (UWORD)SvIV(ST(1));
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        if(uType == SQL_ROLLBACK || uType == SQL_COMMIT){
            rResult = SQLTransact(h->henv, h->hdbc->hdbc, uType);
            if (rResult != SQL_SUCCESS){
                _NT_ODBC_Error(h, "ODBC_Transact", "1");
            }
        }else{
            ODBCError("Invalid Transaction Type", h, "ODBC_Transact", "2");
        }
    }

    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)1)));
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}


XS(XS_WIN32__ODBC_ConfigDSN)
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD  uType;
    int     iStack = 0;
    char    *szDriver = 0;
    char    *szTemp = 0;
    char    *szTemp2 = 0;
    char    *szAttributes = 0;
    int     iResult = 0;
    int     iSize = 0;
    STRLEN  n_a;

    if(items < 3){
        CROAK("usage: ($Err, $Type) = ODBC_ConfigDSN($Connection, $Function, $Driver, @Attributes)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(iStack)));
    CleanError(h->Error);
    iStack++;
    uType = (UWORD)SvIV(ST(iStack));
    iStack++;
    szDriver = SvPV(ST(iStack), n_a);
    if (strlen(szDriver) == 0){
        szDriver = 0;
    }
    iStack++;
    items -= iStack;        //  Reduce the # of items by 3 (compensate for connection, function and driver)

                    //  Remember: when starting szAttributes = 0, not ""
    while (items--){
        szTemp = SvPV(ST(iStack), n_a);
        if(strcspn(szTemp, "[]{}(),?*!@;") < strlen(szTemp)){
            ODBCError("Illegal use of reserved characters []{}(),?*!@;", h, "ODBC_ConfigDSN", "1");
            break;
        }

        
        iStack++;
        iSize += strlen(szTemp) + 2;
        if (! (szTemp2 = new char [iSize])){
            ODBCError("Could not allocate memory for the attribute list", h, "ODBC_ConfigDSN", "2");
            items = 0;
        }else{
            if (szAttributes) {
                strcpy(szTemp2, szAttributes);
            }else{
                strcpy(szTemp2, "");
            }
            strcat(szTemp2, szTemp);
            strcat(szTemp2, ";");
            if (szAttributes){
                delete [] szAttributes;
            }
            szAttributes = szTemp2;
            szTemp2 = 0;
        }
    }

    PUSHMARK(sp);
        /*  
            As of now szAttributes contains the entire DSN
        */

    if (! h->Error->ErrNum){
        if(strcspn(szAttributes, "[]{}(),?*!@") < strlen(szAttributes)){
            ODBCError("Illegal use of reserved characters []{}(),?*!@", h, "ODBC_ConfigDSN", "3");
        }

                //  Format Attribute list for the ConfigDataSource function...
                //  attrib1=value1\0attrib2=value2\0attrib3=value3\0\0
        for (;iSize > -1; iSize--){
            if (szAttributes[iSize] == ';'){
                szAttributes[iSize] = '\0';
            }
        }
        iResult = SQLConfigDataSource(0, (UINT) uType, (LPCSTR) szDriver, (LPCSTR) szAttributes);
    }
    
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)iResult)));
    }else{
            //  Report the error
        ReturnError(h);
    }

    if (szAttributes){
        delete [] szAttributes;
    }

    PUTBACK;
}


XS(XS_WIN32__ODBC_GetInfo)
{
    dXSARGS;
    ODBC_TYPE * h;
    UCHAR   *ucValue = 0;
    int     iSize = sizeof(DWORD) + 1;      //  Arbitrary size to allocate for result
    int     iFlag = 0;
    DWORD   *dValue;
    UWORD   *uValue;
    UWORD   uType;
    SWORD   swBytes = 0;
    RETCODE rResult = 0;
    
    if(items != 2){
        CROAK("usage: ($Err, $NumValue, $Value) = ODBC_GetInfo($Connection, $Type)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uType = (UWORD)SvIV(ST(1));
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        while (!iFlag++){
            if (ucValue = (UCHAR *) new char [iSize]){
                    //  Set the memory set to $FF so we can tell if the return value
                    //  is a string. It will have a \0 at the end of it.
                memset(ucValue, 0xff, iSize);   
                dValue = (DWORD *) ucValue;
                uValue = (UWORD *) ucValue;
                rResult = SQLGetInfo(h->hdbc->hdbc, uType, ucValue, (SWORD) iSize, &swBytes);
                if (rResult != SQL_SUCCESS){
                    _NT_ODBC_Error(h, "ODBC_GetInfo", "1");
                }
            }else{
                ODBCError("Could not allocate memory for result string", h, "ODBC_GetInfo", "2");
                ucValue = 0;
            }
            if (iSize <= (int) swBytes){
                if(ucValue){delete [] ucValue;}
                iSize = (int) swBytes + 1;
                iFlag = 0;
                CleanError(h->Error);
            }
        }
    }

    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        if (ucValue[swBytes] == 0){
                //  GetInfo() returned a string!
            XPUSHs(sv_2mortal(newSVpv((char *) ucValue, (int) swBytes)));
        }else{
            switch (swBytes){   
                case 2:         //  We must have a 16 bit value
                    XPUSHs(sv_2mortal(newSVnv((double) *uValue)));
                    break;

                case 4:         //  We must have a 32 bit value
                    XPUSHs(sv_2mortal(newSVnv((double) *dValue)));
                    break;
            }
        }
    }else{
            //  Report the error
        ReturnError(h);
    }

    if (ucValue){
        delete [] ucValue;
    }
    PUTBACK;
}

XS(XS_WIN32__ODBC_CleanError) 
{
    dXSARGS;
    ODBC_TYPE * h;
    
    if(items != 1){
        CROAK("usage: ($Err) = ODBC_CleanError($Connection)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    
    PUSHMARK(sp);
   
    CleanError(h->Error);
    XPUSHs(sv_2mortal(newSVnv((double)0)));
    XPUSHs(sv_2mortal(newSVnv((double)1)));
    PUTBACK;
}

  
XS(XS_WIN32__ODBC_ColAttributes) 
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD   iCol = 0;
    UWORD   iType = 0;
    UCHAR   *szName = 0;
    UCHAR   szBuff[ODBC_BUFF_SIZE];
    SWORD   dBuffLen = 0;
    SQLLEN  dValue = 0;
    RETCODE rResult;
    STRLEN  n_a;

    if(items != 3){
        CROAK("usage: ($Err) = ODBC_ColAttributes($Connection, $ColName, $Description)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    szName = (unsigned char *) SvPV(ST(1), n_a);
    iType = (UWORD)SvIV(ST(2));
    
    PUSHMARK(sp);
   
    CleanError(h->Error);
    if (!h->Error->ErrNum){
        if (iCol = ColNameToNum(h, (char *)szName)){
            memset(szBuff, '\0', ODBC_BUFF_SIZE);
            rResult = SQLColAttributes(h->hstmt, iCol, iType, szBuff, ODBC_BUFF_SIZE, (short *) &dBuffLen, (SQLLEN *) &dValue);
            if (rResult == SQL_SUCCESS || rResult == SQL_SUCCESS_WITH_INFO){
                if (dBuffLen){
                    XPUSHs(sv_2mortal(newSVnv((double)0)));
                    XPUSHs(sv_2mortal(newSVpv((char *)szBuff, dBuffLen)));
                }else{
                    XPUSHs(sv_2mortal(newSVnv((double)0)));
                    XPUSHs(sv_2mortal(newSVnv((double)dValue)));
                }
            }else{
                ODBCError("Unable to determine Column Attribute", h, "ODBC_ColAttributes", "1");
            }
        }else{
            ODBCError("Field name does not exist", h, "ODBC_ColAttributes", "2");
        }
    }
            //  Process only an error state. If this has been successfull the values have
            //  already been processed.
    if (h->Error->ErrNum){  
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}


 XS(XS_WIN32__ODBC_Debug) 
{
    dXSARGS;
    ODBC_TYPE * h;
    int iDebug = 0;
    char    *szFile = 0;
    STRLEN  n_a;

    if(items < 1 || items > 3){
        CROAK("usage: $Debug = ODBC_Debug($Connection [, $Value])\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);

    if (items > 1 && !h->Error->ErrNum){
        iDebug = SvIV(ST(1));
        if (items > 2){
            szFile = SvPV(ST(2), n_a);
        }
            //  What about the output file?
        if (szFile){
            DEBUG_DUMP("ODBC_Debug: Entering Critical Section gDCS")
            EnterCriticalSection(&gDCS);
            if (ghFile){
            
#ifdef _DEBUG
                char szBuff[1000];
                sprintf(szBuff, "Closing debug file \"%s\"", (gszFile)? gszFile:"none opened");
                DebugConnection(szBuff, h);
#endif
                CloseHandle(ghFile);
                ghFile = 0;
            }
                //  unless a file is specified (not "") then use the default file
            if (strcmp(szFile, "") == 0){
                if (gszFile){
                    delete [] gszFile;
                }
                gszFile = 0;
            }else{
                if (gszFile = new char [strlen(szFile) + 1]){
                    strcpy(gszFile, szFile);
                }
            }
            LeaveCriticalSection(&gDCS);
            DEBUG_DUMP("ODBC_Debug: Left Critical Section gDCS    ")
        }
        if (iDebug){
            AddDebug(h);
            
#ifdef _DEBUG
            if(ghDebug){
                char szBuff[1000];
                sprintf(szBuff, "Debug mode set on by connection %i.\n", h->conn);
                DebugConnection(szBuff, h);
            }
#endif

        }else{
        
#ifdef _DEBUG
            if (ghDebug){
                char szBuff[1000];
                sprintf(szBuff, "Debug mode set off by connection %i.\n", h->conn);
                DebugConnection(szBuff, h);
            }
#endif

            RemoveDebug(h);
        }
        h->iDebug = (iDebug)? 1:0;
    }
    
    PUSHMARK(sp);
   
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)h->iDebug)));
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}

XS(XS_WIN32__ODBC_SetPos)
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD   uRow = 1;
    UWORD   uOption = SQL_POSITION;
    UWORD   uLock = SQL_LOCK_NO_CHANGE;
    RETCODE rResult = 0;
    
    if(items < 2 || items > 4){
        CROAK("usage: ($Err, $Type) = ODBC_SetPos($Connection, $Row [, $Option, $Lock})\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    uRow    = (UWORD)SvIV(ST(1));
    if (items > 2){
        uOption = (UWORD)SvIV(ST(2));
    }
    if (items > 3){
        uLock   = (UWORD)SvIV(ST(3));
    }
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        rResult = SQLSetPos(h->hstmt, uRow, uOption, uLock);
        if (rResult != SQL_SUCCESS){
            _NT_ODBC_Error(h, "ODBC_SetPos", "1");
                //  Set h->Error->EOR so that Fetch() knows the error is not because
                //  of itself.  What a hack!
            //h->Error->EOR = 1;
        }
    }

    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)1)));
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}

XS(XS_WIN32__ODBC_GetData)
{
    dXSARGS;
    ODBC_TYPE * h;
    UCHAR   *szBuf = 0;
    SDWORD  iBuf = DEFAULTCOLSIZE;
    int iTemp;
    
    if(items != 1){
        CROAK("usage: ($Err, $Type) = ODBC_GetData($Connection)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    
    PUSHMARK(sp);
    
/*  HERE WE must figure whether to use SQLGetData() beause we are using
    SQLFetch() or since we are using SQLExtendedFetch() we are to just
    extract the data from h->szFetchBuffer[x].
    The flag to determine this is h->iFetchType (1=fetch;2=extended fetch)
*/


    if (!h->Error->ErrNum && !h->Error->EOR){
        int iTempEnd;
            //  Allocate a default size to be used. This prevents the problem of ODBC 
            //  returning too small of a size for a regular numberical field.
            //  ALSO it saves some allocation time, hopefully the average field
            //  will fit into this size.
            //                                          rothd@roth.net  96.05.03    
                        /*
                            Needed to change SQL_COLUMN_LENGTH to SQL_COLUMN_DISPLAY_SIZE. The
                            former found the # of bytes needed to represent the C data type
                            in memory. The latter is used to find the # of bytes needed to store
                            an ASCII version of the data. 
                            Way big Thanks to Mike Knister <knister@sierra.net> 96.05.13

                            Removed the ++bufflenout to prevent the wrap-around bug
                            (when bufflenout = 2147483647, adding 1 yields -2147483648. Bad, very bad.
                            A whopping big thanks to Jutta M. Klebe <jmk@exc.bybyte.de> 96.04.21

                            Changed (iBuf < bufflenout) to (iBuf <= bufflenout). How silly! if we
                            happen to have returning a field of size iBuf there will be no place 
                            for the \0
                                96.10.07 <rothd@roth.net>
                        */
        XPUSHs(sv_2mortal(newSVnv((double)0)));

        iTempEnd = h->Results->NumOfCols();
            //  Notice we start at 1 (don't include bookmarks (for now)
        for(iTemp = 1; iTemp <= iTempEnd; iTemp++){
            CResults *crTemp = h->Results;
            DWORD   dTemp = crTemp->ReturnSize(iTemp);
            SV  *sv = 0;
            if (dTemp){
                sv = sv_2mortal(newSVpv(crTemp->operator[](iTemp), dTemp));
            }else{
                    //  If the data field has 0 size (is NULL or empty) then return undef.
                sv = &PL_sv_undef;
            }
            XPUSHs(sv);
        }
    }else{                                      
            //  Report the error
        ReturnError(h);
    }

    if (szBuf){
        delete [] szBuf;
    }
    PUTBACK;
}


XS(XS_WIN32__ODBC_DropCursor)
{
    dXSARGS;
    ODBC_TYPE * h;
    UWORD       uCloseType, uCloseSpecified = 0;
    RETCODE     retcode = 0;
    
    if(items < 1 || items > 2){
        CROAK("usage: ($Err, $Type) = ODBC_DropCursor($Connection [, $CloseType])\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    if (items > 1){
        uCloseSpecified = (UWORD)SvIV(ST(1));  
    }
    CleanError(h->Error);
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        uCloseType = h->uStmtCloseType;
        h->uStmtCloseType = (items > 1)? uCloseSpecified:SQL_DROP;
        retcode = ResetStmt(h);
        h->uStmtCloseType = uCloseType;
    }
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)1)));
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}

XS(XS_WIN32__ODBC_CursorName)
{
    dXSARGS;
    ODBC_TYPE * h;
    char    *szName;
    SWORD   sSize = 0;
    RETCODE retcode = 0;
    STRLEN  n_a;

    if(items < 1 || items > 2){
        CROAK("usage: ($Err, $Type) = ODBC_CursorName($Connection [, $Name])\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);

    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        if (items > 1){
            szName = SvPV(ST(1), n_a); 
            if (SQLSetCursorName(h->hstmt, (UCHAR *)szName, (SWORD)strlen(szName)) != SQL_SUCCESS){;
                _NT_ODBC_Error(h, "ODBC_CursorName", "1");
            }
        }
        szName = 0;
        if (!h->Error->ErrNum){
            if(SQL_SUCCESS == SQLGetCursorName(h->hstmt, (UCHAR *)szName, sSize, &sSize)){
                if(!(szName = new char [++sSize])){
                    ODBCError("Could not allocate memory", h, "ODBC_CursorName", "2");
                }else{
                    if(SQL_SUCCESS != SQLGetCursorName(h->hstmt, (UCHAR *)szName, sSize, &sSize)){
                        _NT_ODBC_Error(h, "ODBC_CursorName", "3");
                    }
                }
            }else{
                _NT_ODBC_Error(h, "ODBC_CursorName", "4");
            }
        }
    }else{
        szName = 0;
    }
    if (!h->Error->ErrNum){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVpv(szName, strlen(szName))));
    }else{
            //  Report the error
        ReturnError(h);
    }
    
    if (szName){
        delete [] szName;
    }

    PUTBACK;
}       


XS(XS_WIN32__ODBC_Clone) // ODBC_Connect(Connection string: input) returns connection #
{
    dXSARGS;
    ODBC_TYPE   *h, *hOld = 0;
    RETCODE retcode;           // Misc ODBC sh!t

    if(items != 1){
            //  We need at least 1 (DSN) entry. If more then we need them in pairs of
            //  two, hence (items & 1) make sure we have an odd number of entries...
            //  (dsn) + (ConnetOption, Value) [ + (ConnectOption, Value)] ...
        CROAK("usage: ($Connection, $Err, $ErrText) = ODBC_Clone($Num)\n");
    }
    hOld = _NT_ODBC_Verify(SvIV(ST(0)));

    PUSHMARK(sp);

            //  Allocate new ODBC connection
    if (!(h = NewODBC())){
        h = ODBCError("Could not allocate memory of an ODBC connection\n", (ODBC_TYPE *)0, "ODBC_Clone", "1");
    }else{
            //  Copy info from the Cloned ODBC connection
        strcpy(h->szUserDSN, hOld->szUserDSN);
        h->henv = hOld->henv;
        h->hdbc = hOld->hdbc;
        h->hdbc->iCount++;  
        if (h->szDSN = new char [strlen((const char *)hOld->szDSN) + 1]){
            strcpy(h->szDSN, (char *) hOld->szDSN);
        }else{
            _NT_ODBC_Error(h, "ODBC_Clone", "2");
            h->Error->ErrNum = 0;
            DeleteConn(h->conn);
        }
    }

    if (!h->Error->ErrNum){
        retcode = ResetStmt(h);
        if (retcode != SQL_SUCCESS){
            DeleteConn(h->conn);
        }
    }
    if (!h->Error->ErrNum){ // everything is happy
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVnv((double)h->conn)));
            //  Report the szError ONLY because it may contain state info.
        XPUSHs(sv_2mortal(newSVpv(h->Error->szError, strlen(h->Error->szError))));
    }else{
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
} 

XS(XS_WIN32__ODBC_GetSQLState)
{
    dXSARGS;
    ODBC_TYPE * h;
    
    if(items != 1){
        CROAK("usage: ($Err, $Type) = ODBC_GetSQLState($Connection)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));

    PUSHMARK(sp);

    if (h->Error->szSqlState){
        XPUSHs(sv_2mortal(newSVnv((double)0)));
        XPUSHs(sv_2mortal(newSVpv((char *)h->Error->szSqlState, strlen((const char *) h->Error->szSqlState))));
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}

XS(XS_WIN32__ODBC_GetStats)
{
    dXSARGS;
    ODBC_TYPE * h;
    int iTemp = 0;
    CMom    *cDaughter = 0;
    char    *Keys[] = {  "TotalActiveThreads",          //  Total number of threads attached to this dll
                         "TotalActiveODBCThreads",      //  Total num of threads with ODBC connections
                         "TotalActiveDebugConnections", //  Total number of active connections with active debugging
                         "TotalHistoryThreads",         //  Total history of threads that have connected to odbc connections
                         "TotalHistoryCurrentThread",   //  Total history of connections on current thread.
                         "TotalHistoryConnections",     //  Total history of all connections since dll initialization
                         "CurrentThreadID",             //  ID of current thread
                         "ConnectionErrNum",            //  Connections Error Number (if any)
                         "ConnectionErrText",           //  Connections Error Text (if any)
                         "ConnectionSQLState",          //  Connections SQLState (if any)
                         "ConnectionFunction",          //  Connections Function (if any)
                         "ConnectionLevel",             //  Connections Function level (if any)
                         "ConnectionDebug"};            //  Connections Debug state (if any)
    
    if(items > 1){
        CROAK("usage: %Results = ODBC_GetStats([$Connection])\n");
    }

    h = _NT_ODBC_Verify( (items)? SvIV(ST(0)):0);

    PUSHMARK(sp);

    if (h && !(h->Error->ErrNum)){
        cDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId());
        
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) giThread) ));

        iTemp++;
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) ((::cMom)? ::cMom->Total():0)) ));
        
        iTemp++;
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) giDebug) ));
        
        iTemp++;
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) ((::cMom)? (::cMom->iHistory):0)) ));

        iTemp++;
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) ((cDaughter)? (cDaughter->iHistory):0)) ));
        
        iTemp++;
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) ((::cMom)? ::cMom->iTotalHistory:0)) ));
            
        iTemp++;
        XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
        XPUSHs( sv_2mortal(newSVnv((double) GetCurrentThreadId())) );

        if (items){
            iTemp++;
            XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
            XPUSHs(sv_2mortal(newSVnv((double) h->Error->ErrNum)) );    

            iTemp++;
            XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
            XPUSHs(sv_2mortal(newSVpv((char *) h->Error->szSqlState, strlen((const char *) h->Error->szSqlState)) ));   
            
            iTemp++;
            XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
            XPUSHs(sv_2mortal(newSVpv((char *) h->Error->szError, strlen((const char *) h->Error->szError)) )); 
            
            iTemp++;
            XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
            XPUSHs(sv_2mortal(newSVpv((char *) h->Error->szFunction, strlen((const char *) h->Error->szFunction)) ));   
            
            iTemp++;
            XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
            XPUSHs(sv_2mortal(newSVpv((char *) h->Error->szFunctionLevel, strlen((const char *) h->Error->szFunctionLevel)) )); 
            
            iTemp++;
            XPUSHs(sv_2mortal(newSVpv((char *) Keys[iTemp], strlen((const char *) Keys[iTemp])) ));
            XPUSHs(sv_2mortal(newSVnv((double) h->iDebug) ));   
        }
    }else{
            //  Report the error
        ReturnError(h);
    }

    PUTBACK;
}

XS(XS_WIN32__ODBC_GetTypeInfo)
{
    dXSARGS;
    ODBC_TYPE * h;
    SWORD   sType;
    RETCODE retcode= 0;
    char    *szCommand = "GetTypeInfo()";
    
    if(items != 2){
        CROAK("usage: ($Err, $NumValue, $Value) = ODBC_GetTypeInfo($Connection, $Type)\n");
    }

    h = _NT_ODBC_Verify(SvIV(ST(0)));
    CleanError(h->Error);
    sType = (SWORD)SvIV(ST(1));
    PUSHMARK(sp);

    if(!h->Error->ErrNum){
        if (ResetStmt(h) == SQL_SUCCESS){
            if (h->szCommand){
                delete [] h->szCommand;
                h->szCommand = 0;
            }
            if (h->szCommand = new char [strlen(szCommand) + 1]){
                strcpy(h->szCommand, szCommand);
            }
            retcode = SQLGetTypeInfo(h->hstmt, sType);
            if (retcode != SQL_SUCCESS && retcode != SQL_SUCCESS_WITH_INFO){
                    _NT_ODBC_Error(h, "ODBC_GetTypeInfo", "1");
            }else{
                if(h->Results){
                    delete h->Results;
                }
                h->Results = new CResults(h);
            }
        }
    }
    if (!h->Error->ErrNum){ // everything is happy
        UCHAR   buff2[ODBC_BUFF_SIZE];
        SDWORD  bufflenout;
        int     x;

        XPUSHs(sv_2mortal(newSVnv((double)0)));
        retcode = SQLNumResultCols(h->hstmt, (short *)&h->numcols);
        for(x=1; x<=h->numcols; x++){
            SQLColAttributes(h->hstmt, x, SQL_COLUMN_NAME, buff2, ODBC_BUFF_SIZE, (short *)&bufflenout, NULL);
            XPUSHs(sv_2mortal(newSVpv((char *)buff2, strlen((const char*)buff2))));
        }
    }else{                                      
            //  Report the error
        ReturnError(h);
    }
    PUTBACK;
}


XS(XS_WIN32__ODBC_ShutDown)
{
    //  dXSARGS;
    TerminateThread();
}

void TerminateThread(){
    CMom    *cmDaughter;

    DEBUG_DUMP("TerminateThread(): Entering Critical Section gDCS")
#ifdef _DEBUG
    EnterCriticalSection(&gDCS);
    char szBuff[1000];
    sprintf(szBuff, "Thread %05i (total threads: %03i) terminating.\n", GetCurrentThreadId(), giThread);
        //  Entered Debug CS so no other debug messages interrupt us...
        //  ...since we are in DCS we *MUST* use DebugPrint() not DebugDump()
    DebugPrint(szBuff);
        //  If this thread has a CMom then delete it!
    DebugPrint("\t--> Checking for a daughter on this thread...\n");
#endif

    if (::cMom){
        if (cmDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId())){
        
#ifdef _DEBUG
            DebugPrint("\t--> Thread daughter about to be deleted...\n");
#endif

            delete cmDaughter;
        
#ifdef _DEBUG
            DebugPrint("\t--> Thread daughter has been deleted.\n\n");    
#endif

        }
#ifdef _DEBUG
        else{
            DebugPrint("\t--> No daughter on this thread.\n\n");
        }
#endif
    }

#ifdef _DEBUG
    LeaveCriticalSection(&gDCS);
#endif

    DEBUG_DUMP("TerminateThread(): Left Critical Section gDCS    ")
    return;
}

XS(XS_WIN32__ODBC_InitExtension)
{
    InitExtension();
}

int InitExtension(){
    CMom    *cmDaughter = 0;
    ODBC_TYPE   *h = 0;
    int iRetCode = 1;

#if defined(__CYGWIN__) || defined(__MINGW32__)
//  Otherwise, this is done in DllMain
    InitializeCriticalSection(&gDCS);
    InitializeCriticalSection(&gCS);
#endif

    if (! ::cMom){
        ::cMom = new CMom;
    }
    if (! ::cMom){
        iRetCode = FALSE;
    }else{
        if (cmDaughter = (CMom *) ::cMom->operator[](GetCurrentThreadId())){
            h = (ODBC_TYPE*) cmDaughter->operator[]((DWORD)0);
        }
        if(!h || !cmDaughter){
            
#ifdef _DEBUG
            DebugConnection("     =========> Creating Gratuitous ODBC structure...", 0);
#endif
            if (!(h = NewODBC())){
                iRetCode = FALSE;
            }else{
                strcpy(h->szUserDSN, "Gratuitous ODBC Structure");
            }

#ifdef _DEBUG
            DebugConnection("     =========> Finished creating gratuitous ODBC structure.", 0);
#endif

        }
    }
    return iRetCode;
}

#if defined(__cplusplus)
extern "C"
#endif
XS(boot_Win32__ODBC)
{
    dXSARGS;
    char* file = __FILE__;
    RETCODE iRetCode = 1;

#ifdef _DEBUG
    DebugConnection("==============\n\tRunning bootstrap code.", 0);
#endif
        //  This will force the creation of a daughter Mom and populate it with a
        //  default ODBC object.                    
    if (iRetCode = InitExtension()){    
        newXS("Win32::ODBC::constant",              XS_WIN32__ODBC_Constant, file);
        newXS("Win32::ODBC::ODBCConnect",           XS_WIN32__ODBC_Connect,  file);
        newXS("Win32::ODBC::ODBCExecute",           XS_WIN32__ODBC_Execute, file);
        newXS("Win32::ODBC::ODBCFetch",             XS_WIN32__ODBC_Fetch, file);
        newXS("Win32::ODBC::ODBCDisconnect",        XS_WIN32__ODBC_Disconnect, file);
        newXS("Win32::ODBC::ODBCGetError",          XS_WIN32__ODBC_GetError, file);
        newXS("Win32::ODBC::ODBCTableList",         XS_WIN32__ODBC_TableList, file);
        newXS("Win32::ODBC::ODBCColumnList",        XS_WIN32__ODBC_ColumnList, file);
        newXS("Win32::ODBC::ODBCMoreResults",       XS_WIN32__ODBC_MoreResults, file);
    
        newXS("Win32::ODBC::ODBCGetConnections",    XS_WIN32__ODBC_GetConnections, file);
        newXS("Win32::ODBC::ODBCGetMaxBufSize",     XS_WIN32__ODBC_MaxBufSize, file);
        newXS("Win32::ODBC::ODBCSetMaxBufSize",     XS_WIN32__ODBC_MaxBufSize, file);
        newXS("Win32::ODBC::ODBCGetStmtCloseType",  XS_WIN32__ODBC_GetStmtCloseType, file);
        newXS("Win32::ODBC::ODBCSetStmtCloseType",  XS_WIN32__ODBC_SetStmtCloseType, file);
    
        newXS("Win32::ODBC::ODBCDataSources",       XS_WIN32__ODBC_DataSources, file);
        newXS("Win32::ODBC::ODBCDrivers",           XS_WIN32__ODBC_Drivers, file);
    
        newXS("Win32::ODBC::ODBCGetStmtOption",     XS_WIN32__ODBC_StmtOption, file);
        newXS("Win32::ODBC::ODBCSetStmtOption",     XS_WIN32__ODBC_StmtOption, file);
        newXS("Win32::ODBC::ODBCSetConnectOption",  XS_WIN32__ODBC_SetConnectOption, file);
        newXS("Win32::ODBC::ODBCGetConnectOption",  XS_WIN32__ODBC_GetConnectOption, file);
    
        newXS("Win32::ODBC::ODBCRowCount",          XS_WIN32__ODBC_RowCount, file);
        newXS("Win32::ODBC::ODBCCleanError",        XS_WIN32__ODBC_CleanError, file);
        newXS("Win32::ODBC::Info",                  XS_WIN32__ODBC_Info, file);
        newXS("Win32::ODBC::ODBCColAttributes",     XS_WIN32__ODBC_ColAttributes, file);                                       
        newXS("Win32::ODBC::ODBCConfigDSN",         XS_WIN32__ODBC_ConfigDSN, file);                                       
        newXS("Win32::ODBC::ODBCGetFunctions",      XS_WIN32__ODBC_GetFunctions, file);
        newXS("Win32::ODBC::ODBCTransact",          XS_WIN32__ODBC_Transact, file);
        newXS("Win32::ODBC::ODBCGetDSN",            XS_WIN32__ODBC_GetDSN, file);
        newXS("Win32::ODBC::ODBCGetInfo",           XS_WIN32__ODBC_GetInfo, file);
        newXS("Win32::ODBC::ODBCDebug",             XS_WIN32__ODBC_Debug, file);
        newXS("Win32::ODBC::ODBCSetPos",            XS_WIN32__ODBC_SetPos, file);
        newXS("Win32::ODBC::ODBCGetData",           XS_WIN32__ODBC_GetData, file);
        newXS("Win32::ODBC::ODBCDropCursor",        XS_WIN32__ODBC_DropCursor, file);
        newXS("Win32::ODBC::ODBCSetCursorName",     XS_WIN32__ODBC_CursorName, file);
        newXS("Win32::ODBC::ODBCGetCursorName",     XS_WIN32__ODBC_CursorName, file);
        newXS("Win32::ODBC::ODBCClone",             XS_WIN32__ODBC_Clone, file);
        newXS("Win32::ODBC::ODBCGetSQLState",       XS_WIN32__ODBC_GetSQLState, file);
        newXS("Win32::ODBC::ODBCGetStats",          XS_WIN32__ODBC_GetStats, file);
        newXS("Win32::ODBC::ODBCGetTypeInfo",       XS_WIN32__ODBC_GetTypeInfo, file);

        newXS("Win32::ODBC::ODBCShutDown",          XS_WIN32__ODBC_ShutDown, file);
        newXS("Win32::ODBC::ODBCInit",              XS_WIN32__ODBC_InitExtension, file);

    }
#ifdef _DEBUG
    DebugConnection("Finished bootstrap code.\n\t==============", 0);
#endif

//  ST(0) = &sv_yes;
    XSRETURN(iRetCode);

}           

#ifdef  WIN32

    /* ===============  DLL Specific  Functions  ===================  */
    BOOL WINAPI
#  ifdef __BORLANDC__
    DllEntryPoint
#  else
    DllMain
#  endif
    (HINSTANCE  hinstDLL, DWORD fdwReason, LPVOID  lpvReserved){
        BOOL    bResult = TRUE;

        switch(fdwReason){
            case DLL_PROCESS_ATTACH:
            {
                ghDLL    = hinstDLL;
                giDebug  = 0;
                ghDebug  = 0;
                giThread++;

                //  The Debug CS
                InitializeCriticalSection(&gDCS);

                //  The Global CS
                InitializeCriticalSection(&gCS);

#ifdef _DEBUG
                DebugDump("DLL attaching to process.\n");
#endif
                break;
            }
            case DLL_THREAD_ATTACH:
            {
                /*
                    We will create a new CMom for this thread in the bootstrap
                    function. This way we are not creating CMom & primary
                    ODBC objects for every thread without reason
                */
                giThread++;

                //  Since we moved the code to create the threads ODBC object there should
                //  no longer be a need to enter the critical section gCS so let's remark
                //  it out for now.
//              EnterCriticalSection(&gCS);
#ifdef _DEBUG
                char    szBuff[100];
                DEBUG_DUMP("DLL_THREAD_ATTACH: Entering Critical Section gCS")
                sprintf(szBuff, "Thread %05i (total threads: %03i) starting.\n", GetCurrentThreadId(), giThread);
                DebugPrint(szBuff);
                DEBUG_DUMP("DLL_THREAD_ATTACH: Left Critical Section gCS    ")
#endif
//              LeaveCriticalSection(&gCS);

                break;
             
            }
            case DLL_THREAD_DETACH:
            {
                
#ifdef _DEBUG
                char    szBuff[100];
                //  Is there a need for this section go enter the critical section gCS?
                DEBUG_DUMP("DLL_THREAD_DETACH: Entering Critical Section gCS")
                EnterCriticalSection(&gCS);
                sprintf(szBuff, "Thread %05i (total threads: %03i) stopping.\n", GetCurrentThreadId(), giThread);
                DebugPrint(szBuff);
                LeaveCriticalSection(&gCS);
                DEBUG_DUMP("DLL_THREAD_DETACH: Left Critical Section gCS    ")
#endif

                //  TerminateThread();
                giThread--;
                break;
            }
            case DLL_PROCESS_DETACH:
            {
            
#ifdef _DEBUG
                DebugDump("Unloading DLL.\n");
#endif

                if (::cMom){
                    delete ::cMom;
                }
                if (ghDebug){
                    ghDebug = 0;
                    FreeConsole();
                }

                DeleteCriticalSection(&gCS);
                DeleteCriticalSection(&gDCS);
                ghDLL = 0;
                if (ghFile){
                    CloseHandle(ghFile);
                }
                break;
            }
            default:
                break;
        }
        return bResult;
    }

#endif
                 
/*
    To do list:
        -Convert this beast to OOP.
        done kinda -Create classes of reusable hEnv, hDbc, hStmt so we do not
         waste memory and connections.
        done -Configure/alter DSNs.
        done -Return an array of values that describe the total connection 
         string for a DSN. Similar to DataSources($DSN) but return the 
         connection string not just the driver string.
        done -return values that can have embedded nulls (binary data).
*/
