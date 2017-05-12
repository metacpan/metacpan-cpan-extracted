#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* $Id: UnixODBC.xs,v 1.37 2008-01-20 10:30:11 kiesling Exp $ */

#include <sql.h>
#include <sqlext.h>
#include <sqlucode.h>
#ifndef __SQLTYPES_H  /* Make sure we have all of the definitions we need. */
#include "sqltypes.h"
#endif
/* from ini.h */
#define     INI_MAX_LINE            1000
#define     INI_MAX_PROPERTY_NAME   INI_MAX_LINE
#define     INI_MAX_PROPERTY_VALUE  INI_MAX_LINE


/* from odbcinstext.h */
typedef struct	tODBCINSTPROPERTY
{
	struct tODBCINSTPROPERTY *pNext; 
		/* pointer to next property, NULL if last property */
	char	szName[INI_MAX_PROPERTY_NAME+1];
	        /* property name */
	char	szValue[INI_MAX_PROPERTY_VALUE+1];
		/* property value */
	int	nPromptType; 
		/* PROMPTTYPE_TEXTEDIT, PROMPTTYPE_LISTBOX, 
		   PROMPTTYPE_COMBOBOX, PROMPTTYPE_FILENAME */
	char	**aPromptData;
		/* array of pointers terminated with a NULL value in array. */
	char	*pszHelp;
		/* help on this property (driver setups should keep it short)*/
	void	*pWidget;
		/* CALLER CAN STORE A POINTER TO ? HERE	*/
	int	bRefresh;
		/* app should refresh widget ie Driver Setup has changed 
			aPromptData or szValue  */
	void 	*hDLL;
		/* for odbcinst internal use... only first property has 
		valid one */
} ODBCINSTPROPERTY, *HODBCINSTPROPERTY;

char *odbcinst_system_file_path( void );


static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = UnixODBC               PACKAGE = UnixODBC              

PROTOTYPES: ENABLE

double
constant(sv,arg)
    PREINIT:
        STRLEN          len;
    INPUT:
        SV *            sv
        char *          s = SvPV(sv, len);
        int             arg
    CODE:
        RETVAL = constant(s,len,arg);
    OUTPUT:
        RETVAL

int
dm_log_open (program_name, logfilename)
        char *program_name;
        char *logfilename;
        CODE: 
                dm_log_open ( program_name, logfilename, 0 );
                RETVAL = 0;
        OUTPUT:
                RETVAL

int dm_log_close ()
        CODE:
                dm_log_close();
                RETVAL = 0;
        OUTPUT:
                RETVAL

SQLRETURN
SQLAllocHandle (handle_type, input_handle, output_handle)
        SQLSMALLINT handle_type
        SQLHANDLE input_handle
        SQLHANDLE output_handle
        CODE:
                RETVAL = 
                        SQLAllocHandle(handle_type, input_handle, 
                                &output_handle);
                sv_setiv (ST(2), (int) output_handle);
                                       
        OUTPUT:
                RETVAL

SQLRETURN 
SQLSetEnvAttr (env_handle, attribute, value, strlen)
        SQLHANDLE env_handle
        int attribute
        int value
        int strlen

        CODE:
	if ((attribute == SQL_ATTR_ODBC_VERSION) && 
	  (value == 2)) { value = SQL_OV_ODBC2; }
	if ((attribute == SQL_ATTR_ODBC_VERSION) && 
	  (value == 3)) { value = SQL_OV_ODBC3; }
        RETVAL = SQLSetEnvAttr (env_handle, attribute, 
	  (SQLPOINTER) value, strlen);

        OUTPUT:
                RETVAL



SQLRETURN
SQLSetConnectAttr (connect_handle,attribute,value,strlen)
        SQLHANDLE connect_handle
        SQLINTEGER attribute
        char *value
        SQLINTEGER strlen

        CODE:
        RETVAL = SQLSetConnectAttr (connect_handle, attribute, 
	         value, strlen);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLFreeConnect (handle)
        SQLHDBC handle;
        CODE:
                RETVAL = SQLFreeConnect (handle);
        OUTPUT: 
                RETVAL

SQLRETURN 
SQLFreeEnv (handle)
        SQLHDBC handle;
        CODE:
                RETVAL = SQLFreeEnv (handle);
        OUTPUT: 
                RETVAL

SQLRETURN   
SQLConnect(ConnectionHandle,DSN,NameLength1,UserName,NameLength2,Authentication, NameLength3)
        SQLHDBC ConnectionHandle
        char *DSN
        SQLSMALLINT NameLength1
        char *UserName
        SQLSMALLINT NameLength2
        char *Authentication
        SQLSMALLINT NameLength3
        CODE:
                RETVAL = SQLConnect (ConnectionHandle,
                                     (SQLCHAR*) DSN, NameLength1,
                                     (SQLCHAR*) UserName, NameLength2,
                                     (SQLCHAR*) Authentication, NameLength3);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLGetDiagRec (handle_type,handle,rec_number,sqlstate,native,message_text,buffer_length,text_length_ptr)
        SQLSMALLINT handle_type;
        SQLHANDLE   handle
        SQLSMALLINT rec_number;
        char *sqlstate;
        SQLINTEGER native;
        char *message_text;
        SQLSMALLINT buffer_length;
        SQLSMALLINT text_length_ptr;

	PREINIT:
	SQLCHAR *st = (SQLCHAR*) safemalloc (buffer_length);
	SQLCHAR *text = (SQLCHAR*) safemalloc (buffer_length);
	SQLINTEGER *nat = (SQLINTEGER*) safemalloc (sizeof(int));
	SQLSMALLINT *len = (SQLSMALLINT*) safemalloc (sizeof(int));

        CODE:
        RETVAL = SQLGetDiagRec ( handle_type, 
                                 handle, rec_number, st,
                                 nat, text, buffer_length,
                                 len );
        sv_setpv (ST(3), st);
	sv_setiv (ST(4), *nat);
        sv_setpv (ST(5), text);
        sv_setiv (ST(7), *len);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLDisconnect (connect_handle)
        SQLHDBC connect_handle
        CODE:
                RETVAL = SQLDisconnect (connect_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetInfo(connection_handle,info_type,info_value,buffer_length,string_length)
        SQLHDBC connection_handle
        SQLUSMALLINT info_type
	SQLPOINTER info_value
        SQLSMALLINT buffer_length
        SQLSMALLINT string_length
        PREINIT:
        char *info = safemalloc (buffer_length);
        SQLSMALLINT *length = (SQLSMALLINT*) safemalloc(sizeof(int));
        CODE:
                RETVAL = SQLGetInfo (connection_handle,
                                        info_type,
                                        (SQLPOINTER) info,
                                        buffer_length,
                                        length);
		if (buffer_length > 0) {
	                sv_setpv (ST(2), info);
		} else {
			sv_setiv (ST(2), *info);
		}
		if (string_length) {sv_setiv (ST(4), *length);}
        OUTPUT:
                RETVAL 

SQLRETURN 
SQLFreeHandle (handle_type,handle)
        SQLSMALLINT handle_type
        SQLHANDLE handle
        CODE:
                RETVAL = SQLFreeHandle (handle_type, handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLDataSources(environment_handle,direction,server_name,buffer_length1,name_length1,description,buffer_length2,name_length2)
        SQLHENV environment_handle
        SQLUSMALLINT direction;
        char *server_name;
        SQLSMALLINT buffer_length1;
        SQLSMALLINT name_length1;
        char *description;
        SQLSMALLINT buffer_length2;
        SQLSMALLINT name_length2;
	PREINIT:
	SQLCHAR *server = (SQLCHAR*) safemalloc (buffer_length1);
	SQLCHAR *desc = (SQLCHAR*) safemalloc (buffer_length2);
	SQLSMALLINT *length1 = (SQLSMALLINT*) safemalloc (sizeof(int));
	SQLSMALLINT *length2 = (SQLSMALLINT*) safemalloc (sizeof(int));
        CODE:
	RETVAL = SQLDataSources(environment_handle,
                                        direction,  
                                        server,
                                        buffer_length1,
                                        length1,
                                        desc,
                                        buffer_length2,
                                        length2);
                sv_setpv (ST(2), server);
                sv_setpv (ST(5), desc);
                sv_setiv (ST(4), *length1);
                sv_setiv (ST(7), *length2);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLAllocConnect( environment_handle, connection_handle )
        SQLHENV environment_handle = (SQLHENV) SvIV (ST(0));
        SQLHDBC connection_handle;
        CODE:
                RETVAL = SQLAllocConnect (environment_handle,
                                          &connection_handle);
                sv_setiv (ST(1), (int) connection_handle);
        OUTPUT:
                RETVAL
                
 
SQLRETURN 
SQLAllocEnv (environment_handle)
        SQLHENV environment_handle;
        CODE:
                RETVAL = SQLAllocEnv ( &environment_handle );
                sv_setiv (ST(0), (int) environment_handle);
        OUTPUT:
                RETVAL

SQLRETURN SQLAllocHandleStd(handle_type,input_handle,output_handle)
    SQLSMALLINT handle_type
    SQLHANDLE input_handle
    SQLHANDLE output_handle
        CODE:
                RETVAL = SQLAllocHandleStd (handle_type,
                                            input_handle,
                                            &output_handle);
                sv_setiv (ST(2), (int) output_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLAllocStmt( connection_handle, statement_handle )
        SQLHDBC connection_handle;
        SQLHSTMT statement_handle;
        CODE:
                RETVAL = SQLAllocStmt (connection_handle,
                                        &statement_handle );
                sv_setiv (ST(1), (int) statement_handle );
        OUTPUT:
                RETVAL

SQLRETURN 
SQLExecDirect(statement_handle,statement_text,text_length )
        SQLHSTMT statement_handle;
        char *statement_text;
        SQLINTEGER text_length;
        CODE:
                RETVAL = SQLExecDirect(statement_handle,
                                        (SQLCHAR*) statement_text,
                                        text_length);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLNumResultCols(statement_handle,column_count)
        SQLHSTMT statement_handle
        SQLSMALLINT column_count
        PREINIT:
        SQLSMALLINT *ncolumns = (SQLSMALLINT*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLNumResultCols(statement_handle, 
                                         ncolumns);
                sv_setiv (ST(1), *ncolumns);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLRowCount(statement_handle,rowcount)
        SQLHSTMT statement_handle
        SQLLEN rowcount
        PREINIT:
	SQLLEN *nrows = (SQLLEN*) safemalloc (sizeof(SQLLEN));
        CODE:
                RETVAL = SQLRowCount(statement_handle, nrows);
                sv_setiv (ST(1), *nrows);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLFetch(statement_handle)
        SQLHSTMT statement_handle;
        CODE:
                RETVAL = SQLFetch (statement_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetData(statement_handle,column_number,target_type,target_value,buffer_length,strlen_or_ind )
        SQLHSTMT statement_handle
        SQLUSMALLINT column_number
        SQLSMALLINT target_type
	char *target_value
        SQLINTEGER buffer_length
        SQLINTEGER strlen_or_ind
        PREINIT:
        SQLPOINTER buf = (SQLPOINTER) safemalloc(buffer_length);
        SQLINTEGER *strlen = (SQLINTEGER*) safemalloc (sizeof(int));
        CODE:
        RETVAL = SQLGetData (statement_handle, 
                                column_number,
                                target_type,
                                buf,
                                buffer_length,
                                strlen);
                sv_setpv (ST(3), buf);
                sv_setiv (ST(5), *strlen);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLGetConnectAttr(connection_handle,attribute,value,buffer_length,string_length)
        SQLHDBC connection_handle
        SQLINTEGER attribute
        SQLPOINTER value
        SQLINTEGER buffer_length
        SQLINTEGER string_length
        PREINIT:
        char *buf = safemalloc (buffer_length);
        SQLINTEGER *length = (SQLINTEGER*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLGetConnectAttr (connection_handle,
                                            attribute,
                                            buf,
                                            buffer_length,
                                            length);
		if (buffer_length <= 0) { /* numeric */
			sv_setiv (ST(2), *buf);
		} else {
	                sv_setpv (ST(2), buf);
		}
                if (string_length) { sv_setiv (ST(4), *length); }

        OUTPUT:
                RETVAL

SQLRETURN 
SQLDrivers(henv,fdirection,sz_driver_desc,cb_driver_desc_max,pcb_driver_desc,sz_driver_attributes,cb_drvr_attr_max,pcb_drvr_attr )
        SQLHENV henv
        SQLUSMALLINT fdirection
        char *sz_driver_desc
        SQLSMALLINT cb_driver_desc_max
        SQLSMALLINT pcb_driver_desc
        char *sz_driver_attributes
        SQLSMALLINT cb_drvr_attr_max
        SQLSMALLINT pcb_drvr_attr
        PREINIT: 
        SQLCHAR *desc = (SQLCHAR*) safemalloc (cb_driver_desc_max);
        SQLSMALLINT *desclength = (SQLSMALLINT*) safemalloc (sizeof(int));
        SQLCHAR *attr = (SQLCHAR*) safemalloc (cb_drvr_attr_max);
        SQLSMALLINT *attrlength = (SQLSMALLINT*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLDrivers(henv, fdirection, desc,
                                cb_driver_desc_max, desclength,
                                attr, cb_drvr_attr_max, attrlength);
                sv_setpv (ST(2), desc);
                sv_setiv (ST(4), *desclength);
                sv_setpv (ST(5), attr);
                sv_setiv (ST(7), *attrlength);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLFreeStmt(statement_handle,option)
        SQLHSTMT statement_handle
        SQLUSMALLINT option
        CODE:
                RETVAL = SQLFreeStmt (statement_handle, option);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLColAttribute (statement_handle,column_number,field_identifier,character_attribute,buffer_length,string_length,numeric_attribute )
        SQLHSTMT statement_handle
        SQLUSMALLINT column_number
        SQLUSMALLINT field_identifier
        char *character_attribute
        SQLSMALLINT buffer_length
        SQLSMALLINT string_length
        SQLPOINTER numeric_attribute
        PREINIT:
        SQLPOINTER char_buf = (SQLPOINTER) safemalloc (buffer_length);
        SQLSMALLINT *strlen = (SQLSMALLINT*) safemalloc (sizeof(int));
        int *num_attr = (int*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLColAttribute ( statement_handle,
                                column_number,
                                field_identifier,
                                char_buf,
                                buffer_length,
                                strlen,
                                num_attr );
                sv_setpv (ST(3), char_buf);
                sv_setiv (ST(5), *strlen);
                sv_setiv (ST(6), *num_attr);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetStmtAttr(statement_handle,attribute,value,buffer_length,string_length)
        SQLHSTMT statement_handle
        SQLINTEGER attribute
	SQLPOINTER value
        SQLINTEGER buffer_length
        SQLINTEGER string_length
        PREINIT:
                char *buf = safemalloc (SQL_MAX_MESSAGE_LENGTH);
                int *length = (int*) safemalloc(sizeof(int));
        CODE:
                RETVAL = SQLGetStmtAttr (statement_handle,
                                         attribute,
                                         (SQLPOINTER) buf,
                                         buffer_length,
                                         (SQLINTEGER*) length );
	if ((attribute == SQL_ATTR_ASYNC_ENABLE) ||
            (attribute == SQL_ATTR_CONCURRENCY) || 
	    (attribute == SQL_ATTR_SIMULATE_CURSOR) ||
	    (attribute == SQL_ATTR_CURSOR_TYPE) ||
	    (attribute == SQL_ATTR_ENABLE_AUTO_IPD) ||
	    (attribute == SQL_ATTR_RETRIEVE_DATA) ||
	    (attribute == SQL_ATTR_NOSCAN) ||
	    (attribute == SQL_ATTR_QUERY_TIMEOUT) ||
	    (attribute == SQL_ATTR_PARAMSET_SIZE) ||
	    (attribute == SQL_ATTR_MAX_ROWS) ||
	    (attribute == SQL_ATTR_ROW_NUMBER) ||
	    (attribute == SQL_ATTR_PARAM_BIND_TYPE) ||
            (attribute == SQL_ATTR_MAX_LENGTH)) {
		sv_setiv (ST(2), *buf);
	} else {
                sv_setpv (ST(2), buf);
	}
	if (string_length) {sv_setiv (ST(4), *length);}
        OUTPUT:
                RETVAL

SQLRETURN 
SQLSetStmtAttr(statement_handle,attribute,value,string_length)
        SQLHSTMT statement_handle
        SQLINTEGER attribute
        char *value
        SQLINTEGER string_length
        CODE:
                RETVAL = SQLSetStmtAttr (statement_handle,
                                         attribute,
                                         (SQLPOINTER) value,
                                         string_length);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLSetStmtOption(statement_handle,option,val)
        SQLHSTMT statement_handle
        SQLUSMALLINT option
        SQLINTEGER val
        CODE:
                RETVAL = SQLSetStmtOption (statement_handle,
                                           option,
                                           val);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetFunctions(connection_handle,function_id,supported)
        SQLHDBC connection_handle
        SQLUSMALLINT function_id
        PREINIT:
	SQLUSMALLINT *supported = (SQLUSMALLINT*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLGetFunctions (connection_handle,
                                          function_id,
                                          supported);
                sv_setiv (ST(2), *supported);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetTypeInfo(statement_handle,data_type)
        SQLHSTMT statement_handle
        SQLSMALLINT data_type
        CODE:
                RETVAL = SQLGetTypeInfo (statement_handle,
                                           data_type);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetEnvAttr(environment_handle,attribute,value,buffer_length,string_length)
        SQLHENV environment_handle
        SQLINTEGER attribute
	SQLPOINTER value
        SQLINTEGER buffer_length
	SQLINTEGER string_length
        PREINIT:
                char *buf = safemalloc (buffer_length);
		SQLINTEGER *length = (SQLINTEGER *) safemalloc(sizeof(int));
        CODE:
                RETVAL = SQLGetEnvAttr (environment_handle,
                                        attribute,
                                        buf,
                                        buffer_length,
                                        length);
                sv_setiv (ST(2), *buf);
                if (string_length) { sv_setiv (ST(4), *length); }
        OUTPUT:
                RETVAL

SQLRETURN 
SQLPrepare(statement_handle,statement_text,text_length )
        SQLHSTMT statement_handle
        char *statement_text
        SQLINTEGER text_length
        CODE:
                RETVAL = SQLPrepare (statement_handle,
                                     (SQLCHAR*) statement_text,
                                     text_length);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLExecute (statement_handle)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        CODE:
                RETVAL = SQLExecute (statement_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLNativeSql(hdbc,sz_sql_str_in,cb_sql_str_in,sz_sql_str,cb_sql_str_max,pcb_sql_str )
        SQLHDBC hdbc
        char *sz_sql_str_in
        SQLINTEGER cb_sql_str_in
	char *sz_sql_str
        SQLINTEGER cb_sql_str_max
	SQLINTEGER pcb_sql_str
        PREINIT:
	SQLCHAR *buf = (SQLCHAR*) safemalloc (cb_sql_str_max);
        SQLINTEGER *strlen = (SQLINTEGER*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLNativeSql (hdbc,
                                       (SQLCHAR*) sz_sql_str_in,
                                       cb_sql_str_in,
                                       buf,
                                       cb_sql_str_max,
                                       strlen);
                sv_setpv (ST(3), buf);
                sv_setiv (ST(5), *strlen);          
        OUTPUT:
                RETVAL

SQLRETURN 
SQLSetCursorName (statement_handle,cursor_name,name_length)
        SQLHSTMT statement_handle
        char *cursor_name
        SQLSMALLINT name_length
        CODE:
                RETVAL = SQLSetCursorName (statement_handle,
                                           (SQLCHAR*) cursor_name,
                                           name_length);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetCursorName (statement_handle,cursor_name,buffer_length,name_length)
        SQLHSTMT statement_handle
	char *cursor_name
        SQLSMALLINT buffer_length
	SQLSMALLINT name_length
        PREINIT:
                SQLCHAR *buf = (SQLCHAR*) safemalloc (buffer_length);
                SQLSMALLINT *strlen = (SQLSMALLINT*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLGetCursorName (statement_handle, buf, buffer_length,
                                           strlen);
                sv_setpv (ST(1), buf);
                sv_setiv (ST(3), *strlen);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLSetScrollOptions(statement_handle,f_concurrency,crow_keyset,crow_rowset)
        SQLHSTMT statement_handle
        SQLUSMALLINT f_concurrency
        SQLINTEGER crow_keyset
        SQLUSMALLINT crow_rowset
        CODE:
                RETVAL = SQLSetScrollOptions (statement_handle,
                                              f_concurrency,
                                              crow_keyset,
                                              crow_rowset);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLFetchScroll(statement_handle,fetch_orientation,fetch_offset)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        SQLSMALLINT fetch_orientation = (SQLSMALLINT) SvIV (ST(1));
        SQLINTEGER fetch_offset = (SQLINTEGER) SvIV (ST(2));
        CODE:
                RETVAL = SQLFetchScroll (statement_handle,
                                         fetch_orientation,
                                         fetch_offset);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLDescribeCol(statement_handle,column_number,column_name,buffer_length,name_length,data_type,column_size,decimal_digits,nullable )
        SQLHSTMT statement_handle
        SQLSMALLINT column_number
        char *column_name
        SQLSMALLINT buffer_length
        SQLSMALLINT name_length
        SQLSMALLINT data_type
        SQLSMALLINT column_size
        SQLSMALLINT decimal_digits
        SQLSMALLINT nullable
        PREINIT:
        SQLCHAR *colname = (SQLCHAR*) safemalloc (buffer_length);
        SQLSMALLINT *namelen = (SQLSMALLINT*) safemalloc (sizeof(int));
        SQLSMALLINT *datatype = (SQLSMALLINT*) safemalloc (sizeof(int));
        SQLULEN *colsize = (SQLULEN*) safemalloc (sizeof(int));
        SQLSMALLINT *decimal = (SQLSMALLINT*) safemalloc (sizeof(int));
        SQLSMALLINT *null = (SQLSMALLINT*) safemalloc (sizeof(int));
        CODE:
                RETVAL = SQLDescribeCol (statement_handle,
                                         column_number,
                                         colname,
                                         buffer_length,
                                         namelen,
                                         datatype,
                                         colsize,
                                         decimal,
                                         null);
                sv_setpv (ST(2), colname);
                sv_setiv (ST(4), *namelen);
                sv_setiv (ST(5), *datatype);
                sv_setiv (ST(6), *colsize);
                sv_setiv (ST(7), *decimal);
                sv_setiv (ST(8), *null);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLSetPos(statement_handle,irow,foption,flock)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        SQLINTEGER irow = (SQLINTEGER) SvIV (ST(1));
        SQLUSMALLINT foption = (SQLUSMALLINT) SvIV (ST(1));
        SQLUSMALLINT flock = (SQLUSMALLINT) SvIV (ST(2));
        CODE:
                RETVAL = SQLSetPos (statement_handle,
                                    irow,
                                    foption,
                                    flock);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLMoreResults (statement_handle)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        CODE:
                RETVAL = SQLMoreResults (statement_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetDiagField (handle_type,handle,rec_number,diag_identifier,diag_info_ptr,buffer_length,string_length_ptr)
        SQLSMALLINT handle_type = (SQLSMALLINT) SvIV (ST(0));
        SQLHANDLE handle = (SQLHANDLE) SvIV (ST(1));
        SQLSMALLINT rec_number = (SQLSMALLINT) SvIV (ST(2));
        SQLSMALLINT diag_identifier = (SQLSMALLINT) SvIV (ST(3));
        SQLSMALLINT buffer_length = (SQLSMALLINT) SvIV (ST(5));
        PREINIT:
        char * diag_info_ptr = safemalloc (buffer_length);
        int * string_length_ptr = safemalloc (sizeof (int));
        CODE:
                RETVAL = SQLGetDiagField (handle_type,
                                          handle,
                                          rec_number,
                                          diag_identifier,
                                          (SQLPOINTER) diag_info_ptr,
                                          buffer_length,
                                          (SQLSMALLINT *)string_length_ptr);
                sv_setpv (ST(4), diag_info_ptr);
                sv_setiv (ST(6), *string_length_ptr);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLColumnPrivileges(statement_handle,catalog_name,name_length1,schema_name,name_length2,table_name,name_length3,column_name,name_length4 )
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT name_length1 = (SQLSMALLINT) SvIV (ST(2));
        char *schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT name_length2 = (SQLSMALLINT) SvIV (ST(4));
        char *table_name = SvPV (ST(5), PL_na);
        SQLSMALLINT name_length3 = (SQLSMALLINT) SvIV (ST(6));
        char *column_name = SvPV (ST(7), PL_na);
        SQLSMALLINT name_length4 = SvIV (ST(8));
        CODE:
                RETVAL = SQLColumnPrivileges (statement_handle,
                                              (SQLCHAR*) catalog_name,
                                              name_length1,
                                              (SQLCHAR*) schema_name,
                                              name_length2,
                                              (SQLCHAR*) table_name,
                                              name_length3,
                                              (SQLCHAR*) column_name,
                                              name_length4);
        OUTPUT:
                RETVAL
        
SQLRETURN 
SQLColumns(statement_handle,catalog_name,name_length1,schema_name,name_length2,table_name,name_length3,column_name,name_length4 )
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT name_length1 = (SQLSMALLINT) SvIV (ST(2));
        char *schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT name_length2 = (SQLSMALLINT) SvIV (ST(4));
        char *table_name = SvPV (ST(5), PL_na);
        SQLSMALLINT name_length3 = (SQLSMALLINT) SvIV (ST(6));
        char *column_name = SvPV (ST(7), PL_na);
        SQLSMALLINT name_length4 = SvIV (ST(8));
        CODE:
                RETVAL = SQLColumns (statement_handle,
                                     (SQLCHAR*) catalog_name,
                                     name_length1,
                                     (SQLCHAR*) schema_name,
                                     name_length2,
                                     (SQLCHAR*) table_name,
                                     name_length3,
                                     (SQLCHAR*) column_name,
                                     name_length4);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLForeignKeys(statement_handle,szpk_catalog_name,cbpk_catalog_name,szpk_schema_name,cbpk_schema_name,szpk_table_name,cbpk_table_name,szfk_catalog_name,cbfk_catalog_name,szfk_schema_name,cbfk_schema_name,szfk_table_name,cbfk_table_name)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *szpk_catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT cbpk_catalog_name = (SQLSMALLINT) SvIV (ST(1));
        char *szpk_schema_name = SvPV (ST(2), PL_na);
        SQLSMALLINT cbpk_schema_name = (SQLSMALLINT) SvIV (ST(3));
        char *szpk_table_name = SvPV (ST(4), PL_na);
        SQLSMALLINT cbpk_table_name = (SQLSMALLINT) SvIV (ST(5));
        char *szfk_catalog_name = SvPV (ST(6), PL_na);
        SQLSMALLINT cbfk_catalog_name = (SQLSMALLINT) SvIV (ST(7));
        char *szfk_schema_name = SvPV (ST(8), PL_na);
        SQLSMALLINT cbfk_schema_name = (SQLSMALLINT) SvIV (ST(9));
        char *szfk_table_name = SvPV (ST(10), PL_na);
        SQLSMALLINT cbfk_table_name = (SQLSMALLINT) SvIV (ST(11));
        CODE:
                RETVAL = SQLForeignKeys (statement_handle, 
                                         (SQLCHAR*) szpk_catalog_name,
                                         cbpk_catalog_name,
                                         (SQLCHAR*) szpk_schema_name,
                                         cbpk_schema_name,
                                         (SQLCHAR*) szpk_table_name,
                                         cbpk_table_name,
                                         (SQLCHAR*) szfk_catalog_name,
                                         cbfk_catalog_name,
                                         (SQLCHAR*) szfk_schema_name,
                                         cbfk_schema_name,
                                         (SQLCHAR*) szfk_table_name,
                                         cbfk_table_name);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLPrimaryKeys(statement_handle,sz_catalog_name,cb_catalog_name,sz_schema_name,cb_schema_name,sz_table_name,cb_table_name )
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *sz_catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT cb_catalog_name = SvIV (ST(2));
        char *sz_schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT cb_schema_name = SvIV (ST(4));
        char *sz_table_name = SvPV (ST(5), PL_na);
        SQLSMALLINT cb_table_name = SvIV (ST(6));
        CODE:
                RETVAL = SQLPrimaryKeys (statement_handle,
                                         (SQLCHAR*) sz_catalog_name,
                                         cb_catalog_name,
                                         (SQLCHAR*) sz_schema_name,
                                         cb_schema_name,
                                         (SQLCHAR*) sz_table_name,
                                         cb_table_name);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLProcedureColumns(statement_handle,sz_catalog_name,cb_catalog_name,sz_schema_name,cb_schema_name,sz_proc_name,cb_proc_name,sz_column_name,cb_column_name)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *sz_catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT cb_catalog_name = (SQLSMALLINT) SvIV (ST(2));
        char *sz_schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT cb_schema_name = (SQLSMALLINT) SvIV (ST(4));
        char *sz_proc_name = SvPV (ST(5), PL_na);
        SQLSMALLINT cb_proc_name = (SQLSMALLINT) SvIV (ST(6));
        char *sz_column_name = SvPV (ST(7), PL_na);
        SQLSMALLINT cb_column_name = (SQLSMALLINT) SvIV (ST(8));
        CODE:
                RETVAL = SQLProcedureColumns (statement_handle,
                                              (SQLCHAR*) sz_catalog_name,
                                              cb_catalog_name,
                                              (SQLCHAR*) sz_schema_name,
                                              cb_schema_name,
                                              (SQLCHAR*) sz_proc_name,
                                              cb_proc_name,
                                              (SQLCHAR*) sz_column_name,
                                              cb_column_name);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLProcedures(statement_handle,sz_catalog_name,cb_catalog_name,sz_schema_name,cb_schema_name,sz_proc_name,cb_proc_name)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *sz_catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT cb_catalog_name = (SQLSMALLINT) SvIV (ST(2));
        char *sz_schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT cb_schema_name = (SQLSMALLINT) SvIV (ST(4));
        char *sz_proc_name = SvPV (ST(5), PL_na);
        SQLSMALLINT cb_proc_name = SvIV (ST(6));
        CODE:
                RETVAL = SQLProcedures (statement_handle, 
                                        (SQLCHAR*) sz_catalog_name,
                                        cb_catalog_name,
                                        (SQLCHAR*) sz_schema_name,
                                        cb_schema_name, 
                                        (SQLCHAR*) sz_proc_name,
                                        cb_proc_name);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLSpecialColumns(statement_handle,identifier_type,catalog_name,name_length1,schema_name,name_length2,table_name,name_length3,scope,nullable)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        SQLUSMALLINT identifier_type = (SQLUSMALLINT) SvIV (ST(1));
        char *catalog_name = SvPV (ST(2), PL_na); 
        SQLSMALLINT name_length1 = (SQLSMALLINT) SvIV (ST(3));
        char *schema_name = SvPV (ST(4), PL_na);
        SQLSMALLINT name_length2 = (SQLSMALLINT) SvIV (ST(5));
        char *table_name = SvPV (ST(6), PL_na);
        SQLSMALLINT name_length3 = (SQLSMALLINT) SvIV (ST(7));
        SQLUSMALLINT scope = (SQLUSMALLINT) SvIV (ST(8));
        SQLUSMALLINT nullable = (SQLUSMALLINT) SvIV (ST(9));
        CODE:
                RETVAL = SQLSpecialColumns (statement_handle,
                                            identifier_type,
                                            (SQLCHAR*) catalog_name,
                                            name_length1,
                                            (SQLCHAR*) schema_name,
                                            name_length2,
                                            (SQLCHAR*) table_name,
                                            name_length3,
                                            scope,
                                            nullable);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLStatistics(statement_handle,catalog_name,name_length1,schema_name,name_length2,table_name,name_length3,unique,reserved )
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT name_length1 = (SQLSMALLINT) SvIV (ST(2));
        char *schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT name_length2 = (SQLSMALLINT) SvIV (ST(4));
        char *table_name = SvPV (ST(5), PL_na);
        SQLSMALLINT name_length3 = (SQLSMALLINT) SvIV (ST(6)); 
        SQLUSMALLINT unique = (SQLUSMALLINT) SvIV (ST(7));
        SQLUSMALLINT reserved = (SQLUSMALLINT) SvIV (ST(8));
        CODE:
                RETVAL = SQLStatistics (statement_handle,
                                        (SQLCHAR*) catalog_name,
                                        name_length1,
                                        (SQLCHAR*) schema_name,
                                        name_length2,
                                        (SQLCHAR*) table_name,
                                        name_length3,
                                        unique,
                                        reserved);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLTables(statement_handle,catalog_name,name_length1,schema_name,name_length2,table_name,name_length3,table_type,name_length4)
        SQLHSTMT statement_handle
        char *catalog_name
        SQLSMALLINT name_length1
        char *schema_name
        SQLSMALLINT name_length2
        char *table_name
        SQLSMALLINT name_length3
        char *table_type
        SQLSMALLINT name_length4
        CODE:
        RETVAL = SQLTables (statement_handle,
                            (SQLCHAR*) catalog_name,
                            name_length1,
                            (SQLCHAR*) schema_name,
                            name_length2,
                            (SQLCHAR*) table_name,
                            name_length3,
                            (SQLCHAR*) table_type,
                            name_length4);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLTablePrivileges(statement_handle,sz_catalog_name,cb_catalog_name,sz_schema_name,cb_schema_name,sz_table_name,cb_table_name)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *sz_catalog_name = SvPV (ST(1), PL_na);
        SQLSMALLINT cb_catalog_name = (SQLSMALLINT) SvIV (ST(2));
        char *sz_schema_name = SvPV (ST(3), PL_na);
        SQLSMALLINT cb_schema_name = (SQLSMALLINT) SvIV (ST(4));
        char *sz_table_name = SvPV (ST(5), PL_na);
        SQLSMALLINT cb_table_name = (SQLSMALLINT) SvIV (ST(6));
        CODE:
                RETVAL = SQLTablePrivileges (statement_handle,
                                             (SQLCHAR*) sz_catalog_name,
                                             cb_catalog_name,
                                             (SQLCHAR*) sz_schema_name,
                                             cb_schema_name,
                                             (SQLCHAR*) sz_table_name,
                                             cb_table_name);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLCloseCursor(statement_handle)
        SQLHSTMT statement_handle
        CODE:
                RETVAL = SQLCloseCursor (statement_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLCancel(statement_handle)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        CODE:
                RETVAL = SQLCancel (statement_handle);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLEndTran(handle_type,handle,completion_type)
        SQLSMALLINT handle_type = (SQLSMALLINT) SvIV (ST(0));
        SQLHANDLE handle = (SQLHANDLE) SvIV (ST(1));
        SQLSMALLINT completion_type = (SQLSMALLINT) SvIV (ST(2));
        CODE:
                RETVAL = SQLEndTran (handle_type,
                                     handle,
                                     completion_type);
        OUTPUT:
                RETVAL

SQLRETURN SQLError(environment_handle,connection_handle,statement_handle,sqlstate,native_error,message_text,buffer_length,text_length )
        SQLHENV environment_handle
        SQLHDBC connection_handle
        SQLHSTMT statement_handle
        char *sqlstate
        int native_error
        char *message_text
        int buffer_length
	int text_length
        PREINIT:
                SQLCHAR *st = safemalloc (buffer_length);
                SQLINTEGER native ;
                SQLCHAR *text = safemalloc (buffer_length);
                SQLSMALLINT length;
        CODE:
                RETVAL = SQLError (environment_handle,
                                   connection_handle,
                                   statement_handle,
                                   st, 
                                   &native,
                                   text,
                                   buffer_length,
                                   &length);
                sv_setpv (ST(3), st);
                sv_setiv (ST(4), native);
                sv_setpv (ST(5), text);
                sv_setiv (ST(7), length);
        OUTPUT:
                RETVAL

SQLRETURN 
SQLGetConnectOption(connection_handle,option,value)
        SQLHDBC connection_handle
        SQLUSMALLINT option
        SQLPOINTER value
	PREINIT:
	char *buf = safemalloc (SQL_MAX_MESSAGE_LENGTH * sizeof (char));
        CODE:
                RETVAL = SQLGetConnectOption (connection_handle,
                                              option,
                                              (SQLPOINTER) buf);
	if ((option == SQL_ATTR_TRACE) ||
	    (option == SQL_ACCESS_MODE) ||
	    (option == SQL_AUTOCOMMIT) ||
	    (option == SQL_ODBC_CURSORS)) {
		sv_setiv (ST(2), *buf);
	} else {
		sv_setpv (ST(2), buf);
	}
        OUTPUT:
                RETVAL

SQLRETURN 
SQLSetConnectOption(connection_handle,option,value)
        SQLHDBC connection_handle
        SQLUSMALLINT option
	unsigned value
        CODE:
                RETVAL = SQLSetConnectOption (connection_handle,
                                              option,
                                              value);
        OUTPUT:
                RETVAL


SQLRETURN 
SQLPutData(statement_handle,data,strlen_or_ind)
        SQLHSTMT statement_handle = (SQLHSTMT) SvIV (ST(0));
        char *data = SvPV (ST(1), PL_na);
        SQLINTEGER strlen_or_ind = SvIV (ST(2));
        CODE:
                RETVAL = SQLPutData (statement_handle, 
                                     (SQLPOINTER) data,
                                     (SQLINTEGER) strlen_or_ind);
        OUTPUT:
                RETVAL


SQLCHAR*
__odbcinst_system_file_path (path)
	char *path
        CODE: 
	sv_setpv (ST(0), odbcinst_system_file_path ());



SQLRETURN 
__SQLValidDSN(dsn)
	char *dsn
	CODE:
		RETVAL = SQLValidDSN (dsn);
	OUTPUT:
		RETVAL

AV *
__SQLGetInstalledDrivers ()
	PREINIT:
	char *tbuf, *nbuf = (SQLCHAR*) safemalloc (SQL_MAX_MESSAGE_LENGTH);
	int i, r, nret;
	char *p, *j;
	SV **s;
	CODE:
	RETVAL = newAV();
        r = SQLGetInstalledDrivers (nbuf, SQL_MAX_MESSAGE_LENGTH, &nret);
	nbuf[nret]=0;
	j = nbuf;
	i = 0;
	for (p = j; p < &nbuf[nret]; j = p + 1, ++i) {
		p = strchr (j, 0);
		New (1, (SQLCHAR *)tbuf, p - j + 1, char);
		strncpy (tbuf, j, p - j);
		tbuf[p - j] = 0;
		av_extend (RETVAL, i);
		s = av_store (RETVAL, i, newSVpv(tbuf, p - j));
		if (!s) av_store (RETVAL, i, &PL_sv_undef);
		safefree(tbuf);
	}
	
	safefree(nbuf);
	OUTPUT:
		RETVAL
        CLEANUP:
                SvREFCNT_dec (RETVAL);


HV *
__ODBCINSTConstructPropertyValues (driver)
	SV *driver;
	PREINIT:
	ODBCINSTPROPERTY *h = (ODBCINSTPROPERTY *) 
          safemalloc (sizeof (ODBCINSTPROPERTY));
	ODBCINSTPROPERTY *h1, *htmp;
	SV *valueSv, **r1;
	char *val;
	HV *h2 = newHV ();
	int r;
	CODE:
        r = ODBCINSTConstructProperties (SvPV(driver, PL_na), h);
	h1 = h -> pNext;
	while (h1) {
	  valueSv = newSVpv (h1 -> szValue, strlen (h1 -> szValue));
	  if (!valueSv) {
            warn ("ConstructProperties: invalid hash value.");
            XSRETURN_UNDEF;
          }
	  r1 = hv_store (h2, h1 -> szName, 
            strlen (h1 -> szName), valueSv, 0);
	  h1 = h1 -> pNext;
        }
	RETVAL = h2;
	h1 = h;
	while (h1) {
	  htmp = h1 -> pNext;
	  safefree (h1);
	  h1 = htmp;
        }
         
	OUTPUT:
		RETVAL
        CLEANUP:
                SvREFCNT_dec (RETVAL);

HV *
__ODBCINSTConstructPropertyHelp (driver)
	SV *driver;
	PREINIT:
	ODBCINSTPROPERTY *h = (ODBCINSTPROPERTY *) 
          safemalloc (sizeof (ODBCINSTPROPERTY));
	ODBCINSTPROPERTY *h1, *htmp;
	SV *valueSv, **r1;
	char *val;
	HV *h2 = newHV ();
	int r;
	CODE:
        r = ODBCINSTConstructProperties (SvPV(driver, PL_na), h);
	h1 = h -> pNext;
	while (h1) {
	  if (h1 -> pszHelp) {
	    valueSv = newSVpv (h1 -> pszHelp, strlen (h1 -> pszHelp));
	    if (!valueSv) {
              warn ("ConstructPropertyHelp: invalid hash value.");
              XSRETURN_UNDEF;
            }
	    r1 = hv_store (h2, h1 -> szName, 
              strlen (h1 -> szName), valueSv, 0);
          }
          h1 = h1 -> pNext;
        }
	RETVAL = h2;
	h1 = h;
	while (h1) {
	  htmp = h1 -> pNext;
	  safefree (h1);
	  h1 = htmp;
        }
         
	OUTPUT:
		RETVAL
        CLEANUP:
                SvREFCNT_dec (RETVAL);

HV *
__ODBCINSTConstructPropertyPrompt (driver)
	SV *driver;
	PREINIT:
	ODBCINSTPROPERTY *h = (ODBCINSTPROPERTY *) 
          safemalloc (sizeof (ODBCINSTPROPERTY));
	ODBCINSTPROPERTY *h1, *htmp;
	SV *valueSv, **r1;
	char *val;
	HV *h2 = newHV ();
	int r;
	CODE:
        r = ODBCINSTConstructProperties (SvPV(driver, PL_na), h);
	h1 = h -> pNext;
	while (h1) {
	    valueSv = newSViv (h1 -> nPromptType);
	    if (!valueSv) {
              warn ("ConstructPropertyHelp: invalid hash value.");
              XSRETURN_UNDEF;
            }
	    r1 = hv_store (h2, h1 -> szName, 
              strlen (h1 -> szName), valueSv, 0);
            h1 = h1 -> pNext;
        }
	RETVAL = h2;
	h1 = h;
	while (h1) {
	  htmp = h1 -> pNext;
	  safefree (h1);
	  h1 = htmp;
        }
         
	OUTPUT:
		RETVAL
        CLEANUP:
                SvREFCNT_dec (RETVAL);

HV *
__ODBCINSTConstructPropertyPromptData (driver)
	SV *driver;
	PREINIT:
	ODBCINSTPROPERTY *h = (ODBCINSTPROPERTY *) 
          safemalloc (sizeof (ODBCINSTPROPERTY));
	char *prompts = (char *)safemalloc (SQL_MAX_MESSAGE_LENGTH);
	ODBCINSTPROPERTY *h1, *htmp;
	SV *valueSv, **r1;
	char *val;
	HV *h2 = newHV ();
	int r, i;
	CODE:
        r = ODBCINSTConstructProperties (SvPV(driver, PL_na), h);
	h1 = h -> pNext;
	while (h1) {
	  if (h1 -> aPromptData) {

	    *prompts = 0;

	    for (i = 0; h1 -> aPromptData[i]; i++) {
	      if (*prompts) {
                sprintf (prompts, "%s%s\n", prompts, h1 -> aPromptData[i]);
              } else {
                sprintf (prompts, "%s\n", h1 -> aPromptData[i]);
              }

            }

	    valueSv = newSVpv (prompts, strlen (prompts));
	    if (!valueSv) {
              warn ("ConstructPropertyHelp: invalid hash value.");
              XSRETURN_UNDEF;
            }
	    r1 = hv_store (h2, h1 -> szName, 
              strlen (h1 -> szName), valueSv, 0);
          } 
          h1 = h1 -> pNext;
        }
	RETVAL = h2;
	h1 = h;
	while (h1) {
	  htmp = h1 -> pNext;
	  safefree (h1);
	  h1 = htmp;
        }
         
	OUTPUT:
		RETVAL
        CLEANUP:
                SvREFCNT_dec (RETVAL);

unsigned int
__SQLGetConfigMode ()
	PREINIT:
		unsigned int mode, r;
	CODE:
		r = SQLGetConfigMode (&mode);
		RETVAL = mode;
	OUTPUT:
		RETVAL	
	

unsigned int
__SQLSetConfigMode (mode)
	unsigned int mode;
	CODE:
		RETVAL = SQLSetConfigMode (mode);
	OUTPUT:
		RETVAL	
	

