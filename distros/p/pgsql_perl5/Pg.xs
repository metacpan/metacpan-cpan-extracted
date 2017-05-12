/*-------------------------------------------------------
 *
 * $Id: Pg.xs,v 1.10 2000/04/04 19:08:46 mergl Exp $
 *
 * Copyright (c) 1997, 1998  Edmund Mergl
 *
 *-------------------------------------------------------*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <stdio.h>
#include <fcntl.h>

#include "libpq-fe.h"

typedef struct pg_conn *PG_conn;
/*
typedef struct pg_result *PG_result;
*/

typedef struct pg_results
{
  PGresult *result;
  int row;
} PGresults;

typedef struct pg_results *PG_results;


static double
constant(name, arg)
char *name;
int arg; {
    errno = 0;
    switch (*name) {
      case 'P':
	if (strEQ(name, "PGRES_CONNECTION_OK"))
	  return 0;
	if (strEQ(name, "PGRES_CONNECTION_BAD"))
	  return 1;
	if (strEQ(name, "PGRES_INV_SMGRMASK"))
	  return 0x0000ffff;
	if (strEQ(name, "PGRES_INV_ARCHIVE"))
	  return 0x00010000;
	if (strEQ(name, "PGRES_INV_WRITE"))
	  return 0x00020000;
	if (strEQ(name, "PGRES_INV_READ"))
	  return 0x00040000;
	if (strEQ(name, "PGRES_InvalidOid"))
	  return 0;
	if (strEQ(name, "PGRES_EMPTY_QUERY"))
	  return 0;
	if (strEQ(name, "PGRES_COMMAND_OK"))
	  return 1;
	if (strEQ(name, "PGRES_TUPLES_OK"))
	  return 2;
	if (strEQ(name, "PGRES_COPY_OUT"))
	  return 3;
	if (strEQ(name, "PGRES_COPY_IN"))
	  return 4;
	if (strEQ(name, "PGRES_BAD_RESPONSE"))
	  return 5;
	if (strEQ(name, "PGRES_NONFATAL_ERROR"))
	  return 6;
	if (strEQ(name, "PGRES_FATAL_ERROR"))
	  return 7;
	break;
      default:
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}




MODULE = Pg		PACKAGE = Pg

PROTOTYPES: DISABLE


double
constant(name,arg)
	char *		name
	int		arg


PG_conn
connectdb(conninfo)
	char *	conninfo
	CODE:
		/* convert dbname to lower case if not surrounded by double quotes */
		char *ptr = strstr(conninfo, "dbname");
		if (ptr) {
		    ptr += 6;
		    while (*ptr && *ptr != '=') {
		        ptr++;
		    }
		    while (*ptr && (*ptr == ' ' || *ptr == '\t')) {
		        ptr++;
		    }
		    if (*ptr == '"') {
		        *ptr++ = ' ';
		        while (*ptr && *ptr != '"') {
		            ptr++;
		        }
		        if (*ptr == '"') {
		            *ptr++ = ' ';
		        }
		    } else {
		        while (*ptr && *ptr != ' ' && *ptr != '\t') {
		            *ptr = tolower(*ptr);
		            ptr++;
		        }
		    }
		}
	RETVAL = PQconnectdb((const char *)conninfo);
	OUTPUT:
		RETVAL


PG_conn
setdbLogin(pghost, pgport, pgoptions, pgtty, dbname, login, pwd)
	char *	pghost
	char *	pgport
	char *	pgoptions
	char *	pgtty
	char *	dbname
	char *	login
	char *	pwd
	CODE:
		RETVAL = PQsetdbLogin(pghost, pgport, pgoptions, pgtty, dbname, login, pwd);
	OUTPUT:
		RETVAL


PG_conn
setdb(pghost, pgport, pgoptions, pgtty, dbname)
	char *	pghost
	char *	pgport
	char *	pgoptions
	char *	pgtty
	char *	dbname
	CODE:
		RETVAL = PQsetdb(pghost, pgport, pgoptions, pgtty, dbname);
	OUTPUT:
		RETVAL


HV *
conndefaults()
	CODE:
		PQconninfoOption *infoOption;
		RETVAL = newHV();
        	if (infoOption = PQconndefaults()) {
		    while (infoOption->keyword != NULL) {
		        if (infoOption->val != NULL) {
		            hv_store(RETVAL, infoOption->keyword, strlen(infoOption->keyword), newSVpv(infoOption->val, 0), 0);
		        } else {
		            hv_store(RETVAL, infoOption->keyword, strlen(infoOption->keyword), newSVpv("", 0), 0);
		        }
		        infoOption++;
		    }
		}
	OUTPUT:
		RETVAL


char *
resStatus(status)
	ExecStatusType	status
	CODE:
		RETVAL = (char *)PQresStatus(status);
	OUTPUT:
		RETVAL




MODULE = Pg		PACKAGE = PG_conn		PREFIX = PQ

PROTOTYPES: DISABLE


void
DESTROY(conn)
	PG_conn	conn
	CODE:
	        PQfinish(conn);


void
PQreset(conn)
	PG_conn	conn


int
PQrequestCancel(conn)
	PG_conn	conn


char *
PQdb(conn)
	PG_conn	conn


char *
PQuser(conn)
	PG_conn	conn


char *
PQpass(conn)
	PG_conn	conn


char *
PQhost(conn)
	PG_conn	conn


char *
PQport(conn)
	PG_conn	conn


char *
PQtty(conn)
	PG_conn	conn


char *
PQoptions(conn)
	PG_conn	conn


ConnStatusType
PQstatus(conn)
	PG_conn	conn


char *
PQerrorMessage(conn)
	PG_conn	conn


int
PQsocket(conn)
	PG_conn	conn


int
PQbackendPID(conn)
	PG_conn	conn


void
PQtrace(conn, debug_port)
	PG_conn	conn
	FILE *	debug_port


void
PQuntrace(conn)
	PG_conn	conn


void
PQsetNoticeProcessor(conn, proc, arg)
	PG_conn	conn
	void *	proc
	void *	arg


PG_results
PQexec(conn, query)
	PG_conn	conn
	char *	query
	CODE:
		RETVAL = (PG_results)calloc(1, sizeof(PGresults));
		if (RETVAL) {
		    RETVAL->result = PQexec((PGconn *)conn, query);
		    if (!RETVAL->result) {
		        RETVAL->result = PQmakeEmptyPGresult((PGconn *)conn, PGRES_FATAL_ERROR);
		    }
		}
	OUTPUT:
		RETVAL


void
PQnotifies(conn)
	PG_conn	conn
	PREINIT:
		PGnotify *notify;
	PPCODE:
		notify = PQnotifies(conn);
		if (notify) {
		    XPUSHs(sv_2mortal(newSVpv((char *)notify->relname, 0)));
		    XPUSHs(sv_2mortal(newSViv(notify->be_pid)));
		     free(notify);
		}


int
PQsendQuery(conn, query)
	PG_conn	conn
	char *	query


PG_results
PQgetResult(conn)
	PG_conn	conn
	CODE:
	RETVAL = (PG_results)calloc(1, sizeof(PGresults));
		if (RETVAL) {
		    RETVAL->result = PQgetResult((PGconn *)conn);
		    if (!RETVAL->result) {
		         RETVAL->result = PQmakeEmptyPGresult((PGconn *)conn, PGRES_FATAL_ERROR);
		    }
		}
	OUTPUT:
		RETVAL


int
PQisBusy(conn)
	PG_conn	conn


int
PQconsumeInput(conn)
	PG_conn	conn


int
PQgetline(conn, string, length)
	PREINIT:
		SV *bufsv = SvROK(ST(1)) ? SvRV(ST(1)) : ST(1);
	INPUT:
		PG_conn	conn
		int	length
		char *	string = sv_grow(bufsv, length);
	CODE:
		RETVAL = PQgetline(conn, string, length);
	OUTPUT:
		RETVAL
		string


int
PQputline(conn, string)
	PG_conn	conn
	char *	string


int
PQgetlineAsync(conn, buffer, bufsize)
	PREINIT:
		SV *bufsv = SvROK(ST(1)) ? SvRV(ST(1)) : ST(1);
	INPUT:
		PG_conn	conn
		int	bufsize
		char *	buffer = sv_grow(bufsv, bufsize);
	CODE:
		RETVAL = PQgetline(conn, buffer, bufsize);
	OUTPUT:
		RETVAL
		buffer


int
PQputnbytes(conn, buffer, nbytes)
	PG_conn	conn
	char *	buffer
	int	nbytes


int
PQendcopy(conn)
	PG_conn	conn


PG_results
PQmakeEmptyPGresult(conn, status)
	PG_conn	conn
	ExecStatusType	status
	CODE:
		RETVAL = (PG_results)calloc(1, sizeof(PGresults));
		if (RETVAL) {
		    RETVAL->result = PQmakeEmptyPGresult((PGconn *)conn, status);
		}
	OUTPUT:
		RETVAL


int
lo_open(conn, lobjId, mode)
	PG_conn	conn
	Oid	lobjId
	int	mode


int
lo_close(conn, fd)
	PG_conn	conn
	int	fd


void
lo_read(conn, fd, buf, len)
	    PG_conn	conn
	    int	fd
	    char *	buf
	    int	len
	PREINIT:
	    SV *bufsv = SvROK(ST(2)) ? SvRV(ST(2)) : ST(2);
	    int ret;
	CODE:
	    buf = SvGROW(bufsv, len + 1);
	    ret = lo_read(conn, fd, buf, len);
	    if (ret > 0) {
	        SvCUR_set(bufsv, ret);
	        *SvEND(bufsv) = '\0';
	        sv_setpvn(ST(2), buf, ret);
	        SvSETMAGIC(ST(2));
	    }
	    ST(0) = (-1 != ret) ? sv_2mortal(newSViv(ret)) : &PL_sv_undef;


int
lo_write(conn, fd, buf, len)
	PG_conn	conn
	int	fd
	char *	buf
	int	len


int
lo_lseek(conn, fd, offset, whence)
	PG_conn	conn
	int	fd
	int	offset
	int	whence


Oid
lo_creat(conn, mode)
	PG_conn	conn
	int	mode


int
lo_tell(conn, fd)
	PG_conn	conn
	int	fd


int
lo_unlink(conn, lobjId)
	PG_conn	conn
	Oid	lobjId


Oid
lo_import(conn, filename)
	PG_conn	conn
	char *	filename


int
lo_export(conn, lobjId, filename)
	PG_conn	conn
	Oid	lobjId
	char *	filename




MODULE = Pg		PACKAGE = PG_results		PREFIX = PQ

PROTOTYPES: DISABLE


void
DESTROY(res)
	PG_results	res
	CODE:
		/* printf("DESTROY result\n"); */
		PQclear(res->result);
		Safefree(res);

ExecStatusType
PQresultStatus(res)
	PG_results	res
	CODE:
		RETVAL = PQresultStatus(res->result);
	OUTPUT:
		RETVAL


char *
PQresultErrorMessage(res)
	PG_results	res
	CODE:
		RETVAL = (char *)PQresultErrorMessage(res->result);
	OUTPUT:
		RETVAL


int
PQntuples(res)
	PG_results	res
	CODE:
		RETVAL = PQntuples(res->result);
	OUTPUT:
		RETVAL


int
PQnfields(res)
	PG_results	res
	CODE:
		RETVAL = PQnfields(res->result);
	OUTPUT:
		RETVAL


int
PQbinaryTuples(res)
	PG_results	res
	CODE:
		RETVAL = PQbinaryTuples(res->result);
	OUTPUT:
		RETVAL


char *
PQfname(res, field_num)
	PG_results	res
	int	field_num
	CODE:
		RETVAL = PQfname(res->result, field_num);
	OUTPUT:
		RETVAL


int
PQfnumber(res, field_name)
	PG_results	res
	char *	field_name
	CODE:
		RETVAL = PQfnumber(res->result, field_name);
	OUTPUT:
		RETVAL


Oid
PQftype(res, field_num)
	PG_results	res
	int	field_num
	CODE:
		RETVAL = PQftype(res->result, field_num);
	OUTPUT:
		RETVAL


short
PQfsize(res, field_num)
	PG_results	res
	int	field_num
	CODE:
		RETVAL = PQfsize(res->result, field_num);
	OUTPUT:
		RETVAL


int
PQfmod(res, field_num)
	PG_results	res
	int	field_num
	CODE:
		RETVAL = PQfmod(res->result, field_num);
	OUTPUT:
		RETVAL


char *
PQcmdStatus(res)
	PG_results	res
	CODE:
		RETVAL = PQcmdStatus(res->result);
	OUTPUT:
		RETVAL


char *
PQoidStatus(res)
	PG_results	res
	CODE:
		RETVAL = (char *)PQoidStatus(res->result);
	OUTPUT:
		RETVAL


char *
PQcmdTuples(res)
	PG_results	res
	CODE:
		RETVAL = (char *)PQcmdTuples(res->result);
	OUTPUT:
		RETVAL


char *
PQgetvalue(res, tup_num, field_num)
	PG_results	res
	int	tup_num
	int	field_num
	CODE:
		RETVAL = PQgetvalue(res->result, tup_num, field_num);
	OUTPUT:
		RETVAL


int
PQgetlength(res, tup_num, field_num)
	PG_results	res
	int	tup_num
	int	field_num
	CODE:
		RETVAL = PQgetlength(res->result, tup_num, field_num);
	OUTPUT:
		RETVAL


int
PQgetisnull(res, tup_num, field_num)
	PG_results	res
	int	tup_num
	int	field_num
	CODE:
		RETVAL = PQgetisnull(res->result, tup_num, field_num);
	OUTPUT:
		RETVAL


void
PQfetchrow(res)
	PG_results	res
	PPCODE:
		if (res && res->result) {
		    int cols = PQnfields(res->result);
		    if (PQntuples(res->result) > res->row) {
		        int col = 0;
		        EXTEND(sp, cols);
		        while (col < cols) {
		            if (PQgetisnull(res->result, res->row, col)) {
		                PUSHs(&PL_sv_undef);
		            } else {
		                char *val = PQgetvalue(res->result, res->row, col);
		                PUSHs(sv_2mortal((SV*)newSVpv(val, 0)));
		            }
		            ++col;
		        }
		        ++res->row;
		    }
		}


void
PQprint(res, fout, header, align, standard, html3, expanded, pager, fieldSep, tableOpt, caption, ...)
	FILE *	fout
	PG_results	res
	pqbool	header
	pqbool	align
	pqbool	standard
	pqbool	html3
	pqbool	expanded
	pqbool	pager
	char *	fieldSep
	char *	tableOpt
	char *	caption
	PREINIT:
		PQprintOpt ps;
                STRLEN len;
		int i;
	CODE:
		ps.header    = header;
		ps.align     = align;
		ps.standard  = standard;
		ps.html3     = html3;
		ps.expanded  = expanded;
		ps.pager     = pager;
		ps.fieldSep  = fieldSep;
		ps.tableOpt  = tableOpt;
		ps.caption   = caption;
		Newz(0, ps.fieldName, items + 1 - 11, char*);
		for (i = 11; i < items; i++) {
		    ps.fieldName[i - 11] = (char *)SvPV(ST(i), len);
		}
		PQprint(fout, res->result, &ps);
		Safefree(ps.fieldName);


void
PQdisplayTuples(res, fp, fillAlign, fieldSep, printHeader, quiet)
	PG_results	res
	FILE *	fp
	int	fillAlign
	char *	fieldSep
	int	printHeader
	int	quiet
	CODE:
		PQdisplayTuples(res->result, fp, fillAlign, (const char *)fieldSep, printHeader, quiet);


void
PQprintTuples(res, fout, printAttName, terseOutput, width)
	PG_results	res
	FILE *	fout
	int	printAttName
	int	terseOutput
	int	width
	CODE:
		PQprintTuples(res->result, fout, printAttName, terseOutput, width);


