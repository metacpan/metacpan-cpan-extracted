/* Edit this file in -*- C -*- Mode */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <sql.h>
#include <sqlrds.h>

/*
 * V. Khera 09-AUG-1996
 *
 * Perl interface to Velocis SQL database engine.
 * Copyright 1996 Vivek Khera (vivek@khera.org).
 *
 * This module is distributed under the same terms as Perl itself.  See
 * the license file that came with it.
 *
 * $Id: SQL.xs,v 1.2 1996/09/19 22:34:28 khera Exp $
 */

/* name of package variable to hold error string values on error */
#define ERRORSTR "Velocis::errorstr"
#define ERRORSTATE "Velocis::errorstate"

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
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	if (strEQ(name, "SQL_CDATA"))
#ifdef SQL_CDATA
	    return SQL_CDATA;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_ROWID"))
#ifdef SQL_ROWID
	    return SQL_ROWID;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_CHAR"))
#ifdef SQL_CHAR
	    return SQL_CHAR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DECIMAL"))
#ifdef SQL_DECIMAL
	    return SQL_DECIMAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DATE"))
#ifdef SQL_DATE
	    return SQL_DATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_DOUBLE"))
#ifdef SQL_DOUBLE
	    return SQL_DOUBLE;
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
	if (strEQ(name, "SQL_REAL"))
#ifdef SQL_REAL
	    return SQL_REAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_SMALLINT"))
#ifdef SQL_SMALLINT
	    return SQL_SMALLINT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIME"))
#ifdef SQL_TIME
	    return SQL_TIME;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SQL_TIMESTAMP"))
#ifdef SQL_TIMESTAMP
	    return SQL_TIMESTAMP;
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
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

/* structures to hold a statement and also the results of a query row */
#define rNAMELEN 33
typedef struct 
{
  UCHAR name[rNAMELEN];
  void *value;
  SWORD type;
  SDWORD len;
} COL_RESULT;

typedef struct
{
  HSTMT sh;
  HDBC conn;			/* link back to connection for this handle */
  SWORD num_cols;
  COL_RESULT *cols;
} *QUERY;

/* there is only one environment per process invocation */
static HENV eh;

/* set the Perl error variables appropriately upon error */
/* conn and stmt may either or both be NULL */
static void
sql_error(HDBC conn, HSTMT stmt)
{
  char sqlstate[6], msg[80];
  SWORD outlen;
  SV *sve = perl_get_sv(ERRORSTR,TRUE|0x04);
  SV *svs = perl_get_sv(ERRORSTATE,TRUE|0x04);
  SQLError(eh, conn, stmt, sqlstate, NULL, msg, sizeof(msg), &outlen);
  sv_setpv(sve,msg);
  sv_setpv(svs,sqlstate);
}


/*
 * the only function in this module is the db_connect() function.  it returns
 * a handle to the connection from which queries are done.
 */
MODULE = Velocis::SQL		PACKAGE = Velocis::SQL

BOOT:
SQLAllocEnv(&eh);

double
constant(name,arg)
	char *		name
	int		arg

HDBC
db_connect(dbname,user,pass)
	char *dbname;
	char *user;
	char *pass;
    PROTOTYPE: $$$
    CODE:
	int status;
	SQLAllocConnect(eh, &RETVAL);
	status = SQLConnect(RETVAL,dbname,SQL_NTS,user,SQL_NTS,pass,SQL_NTS);
	if (status != SQL_SUCCESS) {
	  /* some error */
	  sql_error(RETVAL,NULL);
	  SQLFreeConnect(RETVAL);
	  RETVAL=NULL;
	}
    OUTPUT:
	RETVAL

MODULE = Velocis::SQL	PACKAGE = HDBC	PREFIX=hdbc_

void
hdbc_DESTROY(c)
	HDBC c;
    PROTOTYPE: $
    CODE:
    /* called automatically when handle ceases to exist */
	/* printf("Destroyed connection handle\n"); */
	SQLDisconnect(c);
	SQLFreeConnect(c);


QUERY
hdbc_execute(c,command)
	HDBC c;
	char *command;
    PROTOTYPE: $$
    CODE:
	RETVAL = (QUERY)malloc(sizeof(*RETVAL));
	if (RETVAL) {
	  RETCODE status;
	  RETVAL->cols = NULL;
	  RETVAL->num_cols = 0;
	  status = SQLAllocStmt(c, &RETVAL->sh);
	  if (status != SQL_SUCCESS) {
	    /* indicate error */
	    sql_error(c,RETVAL->sh);
	    free(RETVAL);
	    RETVAL=NULL;
	  } else {
	    /*
	     * with a query, allocate & bind space for the return values
	     * for other statements, just execute them
	     */
	    if (SQLExecDirect(RETVAL->sh, command, SQL_NTS) != SQL_SUCCESS) {
	      sql_error(c,RETVAL->sh);
	      SQLFreeStmt(RETVAL->sh, SQL_DROP);
	      free(RETVAL);
	      RETVAL=NULL;
	    } else {	/* still valid... check if is SELECT */
	      UWORD stype;
	      SQLDescribeStmt(RETVAL->sh,&stype);
	      if (stype == sqlSELECT) {
		/* allocate & bind space for return values */
		int i;
		UDWORD size;
		SQLNumResultCols(RETVAL->sh, &RETVAL->num_cols);
		RETVAL->cols = (COL_RESULT *)malloc(RETVAL->num_cols
						    * sizeof(COL_RESULT));
		/* should probably check return values from malloc() */
		for (i = 0; i < RETVAL->num_cols; ++i) {
		  SQLDescribeCol(RETVAL->sh, i+1, RETVAL->cols[i].name,
				 rNAMELEN, NULL, &RETVAL->cols[i].type, &size,
				 NULL, NULL);
		  RETVAL->cols[i].value = malloc(size+1);
		  SQLBindCol(RETVAL->sh,i+1,SQL_C_CHAR,RETVAL->cols[i].value,
			     size+1,&RETVAL->cols[i].len);
		} /* for */
	      } /* check for SELECT */
	    } /* stmt execute */
	  } /* stmt Alloc */
	} /* malloc */
    OUTPUT:
	RETVAL

MODULE = Velocis::SQL	PACKAGE = QUERY	PREFIX=query_

void
query_DESTROY(q)
	QUERY q;
    PROTOTYPE: $
    PREINIT:
	int i;
    CODE:
	/* called automatically when handle ceases to exist */
	/* printf("Destroyed query handle\n"); */
	SQLFreeStmt(q->sh, SQL_DROP);
	if (q->cols) {		/* only if it is a SELECT */
	  /* printf("Destroyed query handle dataspace\n"); */
	  for (i = 0; i < q->num_cols; ++i) {
	    free(q->cols[i].value);
	  }
	  free(q->cols);
	}


long
query_numrows(q)
	QUERY q;
    PROTOTYPE: $
    PREINIT:
	SDWORD value = 0;
    CODE:
	if (q) SQLRowCount(q->sh,&value);
	RETVAL = value;
    OUTPUT:
	RETVAL

long
query_numcolumns(q)
	QUERY q;
    PROTOTYPE: $
    CODE:
	if (q)
	    RETVAL = q->num_cols;
	else
	    RETVAL = 0;
    OUTPUT:
	RETVAL

int
query_columntype(q,i)
	QUERY q;
	int i;
    PROTOTYPE: $$
    CODE:
	if (q && q->cols && i < q->num_cols) {
	  RETVAL = q->cols[i].type;
	} else {
	  RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

char *
query_columnname(q,i)
	QUERY q;
	int i;
    PROTOTYPE: $$
    CODE:
	if (q && q->cols && i < q->num_cols) {
	  RETVAL = q->cols[i].name;
	} else {
	  RETVAL = NULL;
	}
    OUTPUT:
	RETVAL

int
query_columnlength(q,i)
	QUERY q;
	int i;
    PROTOTYPE: $$
    CODE:
	if (q && q->cols && i < q->num_cols) {
	  RETVAL = q->cols[i].len;
	} else {
	  RETVAL = NULL;
	}
    OUTPUT:
	RETVAL


void
query_fetchrow(q)
	QUERY q;
    PROTOTYPE: $
    PPCODE:
    if (q && q->num_cols > 0) {
      /* return empty list when no more data or if not SELECT */
      RETCODE status = SQLFetch(q->sh);
      if (status == SQL_SUCCESS) {
	int cur = 0;
	EXTEND(sp,q->num_cols);
	while(cur < q->num_cols) {
	  if (q->cols[cur].len == SQL_NULL_DATA)
	    PUSHs(&sv_undef);
	  else {
	    PUSHs(sv_2mortal((SV*)newSVpv(q->cols[cur].value,0)));
	  }
	  ++cur;
	}
      } else if (status != SQL_NO_DATA_FOUND) {
	/* set error variables unless we just ran out of data */
	sql_error(q->conn,q->sh);
      }
    }
