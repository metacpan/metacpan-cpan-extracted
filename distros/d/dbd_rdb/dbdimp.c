#include <descrip>
#include <builtins>
#include <limits.h>
#include <float>
#include <lib$routines>
#include <starlet>
#include <ssdef>
#include <sql_literals>
#include <ints>
#include <libdtdef>
#include <descrip>


#include "rdb.h"
#include "dbdsql.h"
#include "sql.h"

#include <perl.h>

DBISTATE_DECLARE; 

extern int SQL_GET_ERROR_TEXT();
static int do_rdb_error( SV *h, long rdb_status, ... );
static int do_own_error( SV *h, char *fmt, ... );
static int do_vms_error( SV *h, int vms_status, char *text );
static void rdb_trace_msg( SV* h, char *msg, ... );
static int rdb_set_connection( imp_dbh_t *imp_dbh );
static int rdb_lookup_bool_attrib( HV *pattribs, char *key );
static sql_t_sqlda2 *prep_sqlda( sql_t_sqlda2 *in, int stringify );
static void free_sqlda( sql_t_sqlda2 *sqlda );
static void print_sqlda( SV *sth, sql_t_sqlda2 *sqlda );
static void rdb_store_sv_into_sqlpar( imp_sth_t *imp_sth, SV *val, 
		                      sql_t_sqlvar2 *sqlpar );
static void rdb_fetch_sv_from_sqlpar( imp_sth_t *imp_sth, 
                                      SV *sv, sql_t_sqlvar2 *sqlpar );
static int64 rdb_scaled_sv_to_int64( SV *val, int precision );
static void rdb_scaled_int64_to_pv( int64 val, int precision, SV *result );
static void rdb_set_date_format( SV* dbh, imp_dbh_t *imp_dbh, 
	                              char *format_str, int format_len );
static int64 rdb_convert_date_string( imp_sth_t *imp_sth,
			              char *date_str, int date_len );
static int64 rdb_convert_interval_string( imp_sth_t *imp_sth,
			                  char *date_str, int date_len );
static int rdb_bind_ph_idx ( SV *sth, imp_sth_t *imp_sth,
                             int par_idx, SV *par_value, IV sql_type, 
                             SV *attribs, int is_inout, IV maxlen);


/*
** Init
*/
void rdb_init( dbistate_t *dbistate ) {
    DBIS = dbistate;
}


/*
**  DB handle functions
*/

int rdb_db_login( SV *dbh, imp_dbh_t *imp_dbh, char *db,
		  char *user, char *password )
{

    long status;
    char connection_name[32];
    D_imp_drh_from_dbh;
    char user_buf[256];
    char pass_buf[256];

    imp_dbh->dbh = dbh;
    imp_drh->next_connection++;
    sprintf( connection_name, "CON_%d", imp_drh->next_connection );

    strncpy( user_buf, user, sizeof(user_buf)-1 );
    strncpy( pass_buf, password, sizeof(pass_buf)-1 );

    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t-->rdb_db_login(%s,%s,%s)\n", db, user, password );
	rdb_trace_msg( dbh, "\tconnection name is %s\n", connection_name );
    }
    DBDSQL_CONNECT_AUTH( &status, db, connection_name, user_buf, pass_buf );
    if ( status ) {
	do_rdb_error( dbh, status );
    } else {
	char *format_str;
	int format_len;

	imp_drh->current_connection = imp_drh->next_connection;
	imp_dbh->connection = imp_drh->next_connection;
	imp_dbh->statement_nr = 1;
	imp_dbh->cursor_nr = 1;
	imp_dbh->overflow_kills = 1;
	format_str = "|!Y4!MN0!D0|!H04!M0!S0!C2|";
	format_len = strlen(format_str);
	rdb_set_date_format( dbh, imp_dbh, format_str, format_len );

	DBIc_ACTIVE_on(imp_dbh);
    }
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "    <-- rdb_db_login\n" );
    }
    return ( !status ) ? 1 : 0;
}



int rdb_db_disconnect( SV *dbh, imp_dbh_t *imp_dbh )
{
    long status;
    D_imp_drh_from_dbh;
    int retval = 1;


    imp_dbh->dbh = dbh;
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t--> rdb_db_disconnect()\n" );
    }

    if ( rdb_set_connection( imp_dbh ) ) {
	DBDSQL_DISCONNECT( &status );
	if ( status ) {
	    do_rdb_error( dbh, status );
	    retval = 0;
	}
    } else {
	retval = 0;
    }
    imp_drh->current_connection = 0;

    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t<-- rdb_db_disconnect()\n" );
    }
    return retval;
}


int rdb_discon_all( SV *drh, imp_drh_t *imp_drh )
{
    long status;
    int retval = 1;

    if (dbis->debug > 2) {
	rdb_trace_msg( drh, "\t--> rdb_db_discon_all()\n" );
    }

    DBDSQL_DISCONNECT_ALL( &status );
    if ( status ) {
	do_rdb_error( drh, status );
	retval = 0;
    }
    imp_drh->current_connection = 0;
    imp_drh->next_connection = 0;

    if (dbis->debug > 2) {
	rdb_trace_msg( drh, "\t<-- rdb_db_discon_all()\n" );
    }
    return retval;
}


void rdb_db_destroy( SV *dbh, imp_dbh_t *imp_dbh ) {}


int rdb_db_commit( SV *dbh, imp_dbh_t *imp_dbh )
{
    long status;
    int retval = 1;

    imp_dbh->dbh = dbh;
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t--> rdb_db_commit()\n" );
    }
    if ( rdb_set_connection( imp_dbh ) ) {
	DBDSQL_COMMIT( &status );
	if ( status ) {
	    do_rdb_error( dbh, status );
	    retval = 0;
	}
    }
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t<-- rdb_db_commit()\n" );
    }
    return retval;
}

int rdb_db_rollback( SV *dbh, imp_dbh_t *imp_dbh )
{
    long status;
    int retval = 1;

    imp_dbh->dbh = dbh;
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t--> rdb_db_rollback()\n" );
    }
    if ( rdb_set_connection( imp_dbh ) ) {
	DBDSQL_ROLLBACK( &status );
	if ( status ) {
	    do_rdb_error( dbh, status );
	    retval = 0;
	}
    } else {
	retval = 0;
    }
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t<-- rdb_db_rollback()\n" );
    }
    return retval;
}


int rdb_db_do( SV *dbh, imp_dbh_t *imp_dbh, char *statement )
{
    long status;
    int row_count;
    sql_t_sqlca sqlca;

    imp_dbh->dbh = dbh;
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t--> rdb_db_do(%s)\n", statement );
    }
    if ( rdb_set_connection( imp_dbh ) ) {
	sql_t_varchar_w *stmt;
	int len;

	len = strlen(statement);
	if ( len > MAX_VARCHAR ) {
	    warn( "statement longer than MAX_VARCHAR was truncated" );
	    len = MAX_VARCHAR;
	}
	stmt = __ALLOCA( len+sizeof(sql_t_varchar_w) ); 
	strncpy( stmt->buf, statement, len );
	stmt->len = len;
	stmt->buf[ stmt->len ] = 0; // needed only for %s printing
	DBDSQL_DO( &sqlca, stmt );
	if ( sqlca.sqlcode && sqlca.sqlcode != 100 ) {
	    do_rdb_error( dbh, status, 
		          "statement text follows ...\n%s\n", 
			  stmt->buf, stmt->len );
	    row_count = -1;
	} else {
	    row_count = sqlca.sqlerrd[2];
	    if ( DBIc_is(imp_dbh,DBIcf_AutoCommit) ) {
		DBDSQL_COMMIT( &status );
		if ( status && status != SQLCODE_NOIMPTXN ) {
		    do_rdb_error( dbh, status );
		}
	    }
	}
    } else 
	row_count = -1;
	
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t<-- rdb_db_do (%d)\n", row_count );
    }
    return row_count;
}


int rdb_db_STORE_attrib( SV *dbh, imp_dbh_t *imp_dbh, 
	                 SV *keysv, SV *valuesv )
{
    char *key, *val;
    STRLEN len;

    imp_dbh->dbh = dbh;
    key = SvPV(keysv,len);
    val = SvPV(valuesv,len);

    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t--> rdb_db_STORE_attrib(%s,%s)\n", key, val );
    }

    if ( !strcmp( key, "PrintError" ) ) {
	if ( SvTRUE( valuesv ) ) {
	    DBIc_on( imp_dbh, DBIcf_PrintError );
	} else {    
	    DBIc_off( imp_dbh, DBIcf_PrintError );
	}
    } else if ( !strcmp( key, "RaiseError" ) ) {
	if ( SvTRUE( valuesv ) ) {
	    DBIc_on( imp_dbh, DBIcf_RaiseError );
	} else {    
	    DBIc_off( imp_dbh, DBIcf_RaiseError );
	}
    } else if ( !strcmp( key, "ChopBlanks" ) ) {
	if ( SvTRUE( valuesv ) ) {
	    DBIc_on( imp_dbh, DBIcf_ChopBlanks );
	} else {    
	    DBIc_off( imp_dbh, DBIcf_ChopBlanks );
	}
    } else if ( !strcmp( key, "AutoCommit" ) ) {
	if ( SvTRUE( valuesv ) ) {
	    DBIc_on( imp_dbh, DBIcf_AutoCommit );
	} else {    
	    DBIc_off( imp_dbh, DBIcf_AutoCommit );
	}
    } else if ( !strcmp( key, "rdb_overflow_kills" ) ) {
	if ( SvTRUE( valuesv ) ) {
	    imp_dbh->overflow_kills = 1;
	} else {    
	    imp_dbh->overflow_kills = 0;
	}
    } else if ( !strcmp( key, "DateFormat" ) || 
	        !strcmp( key, "rdb_dateformat" ) ) {
	int status;
	char *format_str;
	unsigned int format_len;

	if ( !SvPOK(valuesv) || !SvTRUE(valuesv) ) {
	    warn( "setting date_format to default: |!Y4!MN0!D0|!H04!M0!S0!C2|" );
	    format_str = "|!Y4!MN0!D0|!H04!M0!S0!C2|";
	    format_len = strlen(format_str);
	} else {
	    format_str = SvPV( valuesv, format_len );
	}
	rdb_set_date_format( dbh, imp_dbh, format_str, format_len );
    }
    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t<-- rdb_db_STORE_attrib\n" );
    }
    return 1;
}

SV* rdb_db_FETCH_attrib( SV *dbh, imp_dbh_t *imp_dbh, SV *keysv )
{
    char *key;
    STRLEN len;
    SV *val;
    char msg[256];

    imp_dbh->dbh = dbh;
    key = SvPV(keysv,len);

    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t--> rdb_db_FETCH_attrib(%s)\n", key );
    }

    if ( !strcmp( key, "PrintError" ) ) {
	if ( DBIc_is(imp_dbh,DBIcf_PrintError) ) {
	    val = &PL_sv_yes;
	} else {    
	    val = &PL_sv_no;
	}
    } else if ( !strcmp( key, "RaiseError" ) ) {
	if ( DBIc_is(imp_dbh,DBIcf_RaiseError) ) {
	    val = &PL_sv_yes;
	} else {    
	    val = &PL_sv_no;
	}
    } else if ( !strcmp( key, "ChopBlanks" ) ) {
	if ( DBIc_is(imp_dbh,DBIcf_ChopBlanks) ) {
	    val = &PL_sv_yes;
	} else {    
	    val = &PL_sv_no;
	}
    } else if ( !strcmp( key, "AutoCommit" ) ) {
	if ( DBIc_is(imp_dbh,DBIcf_AutoCommit) ) {
	    val = &PL_sv_yes;
	} else {    
	    val = &PL_sv_no;
	}
    } else if ( !strcmp( key, "DateFormat" ) || 
	        !strcmp( key, "rdb_dateformat" ) ) {
	val = newSVpv( imp_dbh->date_format, 0 );
    } else if ( !strcmp( key, "rdb_datelen" ) ) {
	val = newSViv( imp_dbh->date_len );
    } else if ( !strcmp( key, "rdb_overflow_kills" ) ) {
	val = (imp_dbh->overflow_kills) ? &PL_sv_yes : &PL_sv_no;
    } else {
	val = &PL_sv_undef;
    }

    if (dbis->debug > 2) {
	rdb_trace_msg( dbh, "\t<-- rdb_db_FETCH_attrib\n" );
    }
    return sv_2mortal(val);
}


/*
**  statement handle functions
*/

int rdb_st_prepare( SV *sth, imp_sth_t *imp_sth, char *statement, SV *pattribs)
{
    int retval = 1;
    long status;
    int len, bind_values;
    sql_t_sqlda2 *in_sqlda  = (sql_t_sqlda2 *)0;
    sql_t_sqlda2 *out_sqlda = (sql_t_sqlda2 *)0;
    sql_t_sqlca sqlca;
    D_imp_dbh_from_sth;
    sql_t_varchar_w *stmt;

    imp_sth->sth = sth;

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t-->rdb_st_prepare(%s)\n", statement );
    }

    if ( !rdb_set_connection( imp_dbh ) ) {
	retval = 0;
	goto done;
    }

    in_sqlda = __ALLOCA( sizeof(sql_t_sqlda2) + 254*sizeof(sql_t_sqlvar2) );
    memset (in_sqlda, 0, sizeof(sql_t_sqlda2) + 254*sizeof(sql_t_sqlvar2) );
    in_sqlda->sqln = 255;
    memcpy( in_sqlda->sqldaid, "SQLDA2  ", 8 );

    out_sqlda = __ALLOCA( sizeof(sql_t_sqlda2) + 254*sizeof(sql_t_sqlvar2) );
    memset (out_sqlda, 0, sizeof(sql_t_sqlda2) + 254*sizeof(sql_t_sqlvar2) );
    out_sqlda->sqln = 255;
    memcpy( out_sqlda->sqldaid, "SQLDA2  ", 8 );

    len = strlen(statement);
    if ( len > MAX_VARCHAR ) {
	warn( "statement longer than MAX_VARCHAR was truncated" );
	len = MAX_VARCHAR;
    }
    stmt = __ALLOCA( len+sizeof(sql_t_varchar_w) ); 
    strncpy( stmt->buf, statement, len );
    stmt->len = len;
    stmt->buf[ stmt->len ] = 0; // needed only for %s printing

    if ( pattribs && SvROK(pattribs) && SvTYPE( SvRV(pattribs) ) == SVt_PVHV ) {
	imp_sth->attribs = (HV *)SvRV(pattribs);
	SvREFCNT_inc(imp_sth->attribs);
    } else {
	imp_sth->attribs = (HV *)0;
    }

    sprintf( imp_sth->stmt_name, "STM_%d", imp_dbh->statement_nr++ );
    if ( dbis->debug > 3 ) {
	rdb_trace_msg( sth, "\tstatement name = %s\n", imp_sth->stmt_name );
    }
    DBDSQL_PREPARE( &sqlca, stmt, imp_sth->stmt_name );
    if ( sqlca.sqlcode ) {
	do_rdb_error( sth, status, 
	              "statement text follows ...\n%s\n", 
		      stmt->buf, stmt->len );
	retval = 0;
	goto done;
    }

    DBDSQL_DESCRIBE_MARKERS( &sqlca, imp_sth->stmt_name, in_sqlda );
    if ( sqlca.sqlcode ) {
	do_rdb_error( sth, sqlca.sqlcode );
	retval = 0;
	goto done;
    }
    imp_sth->in_sqlda = prep_sqlda( in_sqlda, 1 );
    imp_sth->in_meta_sqlda = prep_sqlda( in_sqlda, 0 );
    DBIc_NUM_PARAMS(imp_sth) = in_sqlda->sqld;
    imp_sth->is_select = (sqlca.sqlerrd[1] == 1);
    if ( dbis->debug > 3 ) {
	rdb_trace_msg( sth, "\tis_select = %d\n", imp_sth->is_select );
    }

    DBDSQL_DESCRIBE_SELECT( &sqlca, imp_sth->stmt_name, out_sqlda );
    if ( sqlca.sqlcode ) {
	do_rdb_error( sth, sqlca.sqlcode );
	retval = 0;
	goto done;
    }
    imp_sth->out_sqlda = prep_sqlda( out_sqlda, 1 );
    imp_sth->out_meta_sqlda = prep_sqlda( out_sqlda, 0 );
    DBIc_NUM_FIELDS(imp_sth) = out_sqlda->sqld;

    bind_values = DBIc_NUM_FIELDS(imp_sth) + DBIc_NUM_PARAMS(imp_sth);
    Newz( 1, imp_sth->bind_value, bind_values, SV * );

    if ( imp_sth->is_select ) {

	sprintf( imp_sth->cur_name, "CUR_%d", imp_dbh->cursor_nr++ );
        if ( dbis->debug > 3 ) {
	    rdb_trace_msg( sth, "\tcursor name = %s\n", imp_sth->cur_name );
	}
	if ( rdb_lookup_bool_attrib(imp_sth->attribs,"rdb_hold") ) {
	    DBDSQL_DECLARE_CURSOR_HOLD( &status, imp_sth->cur_name, imp_sth->stmt_name );
	} else {
	    DBDSQL_DECLARE_CURSOR( &status, imp_sth->cur_name, imp_sth->stmt_name );
	}
	if ( status ) {  
	    do_rdb_error( sth, status );
	    retval = 0;
	    goto done;
	}
    }	
    if (dbis->debug > 2) {
	rdb_trace_msg( sth, "\tnum-par = %d , num-sel = %d\n",
                 in_sqlda->sqld, out_sqlda->sqld );
    }

    DBIc_IMPSET_on(imp_sth);

    done:
    if (dbis->debug > 2) {
	rdb_trace_msg( sth, "\t<-- rdb_st_prepare\n" );
    }
    return retval;

}



int rdb_st_execute( SV *sth, imp_sth_t *imp_sth )
{
    long status;
    D_imp_dbh_from_sth;
    int row_count;
    sql_t_sqlca sqlca;

    imp_sth->sth = sth;

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_st_execute\n" );
    }

    if ( !rdb_set_connection( imp_dbh ) ) {
	goto done;
    }

    for( int i = 0; i < DBIc_NUM_PARAMS(imp_sth); i++ ) {
	sql_t_sqlvar2 *sqlpar;

	if ( imp_sth->bind_value[i] ) {
	    sqlpar = imp_sth->in_sqlda->sqlvar + i;
	    rdb_store_sv_into_sqlpar( imp_sth,imp_sth->bind_value[i], sqlpar );
	}
    }
    if ( imp_sth->is_select ) {
	if ( dbis->debug > 3 ) print_sqlda( sth, imp_sth->in_sqlda );
	DBDSQL_OPEN_CURSOR( &status, imp_sth->cur_name, imp_sth->in_sqlda );
	if ( status ) {
	    do_rdb_error( sth, status );
	    goto done;
	}
	row_count = -1;
    } else {
	if ( dbis->debug > 3 && DBIc_NUM_PARAMS(imp_sth) )
	    print_sqlda( sth, imp_sth->in_sqlda );
	if ( dbis->debug > 3 && DBIc_NUM_FIELDS(imp_sth) )
	    print_sqlda( sth, imp_sth->out_sqlda );
	DBDSQL_EXECUTE( &sqlca, imp_sth->stmt_name, 
	                imp_sth->in_sqlda, imp_sth->out_sqlda );

	if ( sqlca.sqlcode ) {
	    do_rdb_error( sth, sqlca.sqlcode );
	    goto done;
	}
	row_count = sqlca.sqlerrd[2];
	if ( DBIc_is(imp_dbh,DBIcf_AutoCommit) ) {
	    DBDSQL_COMMIT( &status );
	    if ( status && status != SQLCODE_NOIMPTXN ) {
		do_rdb_error( sth, status );
		goto done;
	    }
	}

	for( int i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++ ) {
	    sql_t_sqlvar2 *sqlpar;
	    int params = DBIc_NUM_PARAMS(imp_sth);
	    if ( imp_sth->bind_value[params + i] ) {
		sqlpar = imp_sth->out_sqlda->sqlvar + i;
		rdb_fetch_sv_from_sqlpar( imp_sth, 
			                  imp_sth->bind_value[params + i], 
					  sqlpar );
	    }
	}

    }    
    DBIc_ACTIVE_on(imp_sth);
    done:
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_st_execute (%d)\n",
		       SvIV(DBIc_ERR(imp_sth)) );
    }
    return SvIV(DBIc_ERR(imp_sth)) ? -2 : row_count;
}


void rdb_st_destroy( SV *sth, imp_sth_t *imp_sth )
{
    long status;
    int i;

    imp_sth->sth = sth;

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_st_destroy\n" );
    }
    if ( imp_sth ) {
	if ( imp_sth->stmt_name ) {
	    if ( dbis->debug > 3 ) {
		rdb_trace_msg( sth, "\trelease of stmt %s\n",
		               imp_sth->stmt_name  );
	    }
	    DBDSQL_RELEASE( &status, (char *)imp_sth->stmt_name );
	    if ( status ) {
		do_rdb_error( sth, status );
	    }
	}
	if ( imp_sth->attribs ) {
	    SvREFCNT_dec( imp_sth->attribs );
	}
	if ( imp_sth->bind_value ) {
	    for( int i = 0; 
		 i < DBIc_NUM_FIELDS(imp_sth)+DBIc_NUM_PARAMS(imp_sth); i++ ) {
		if ( imp_sth->bind_value[i] ) {
		    SvREFCNT_dec( imp_sth->bind_value[i] );
		}
	    }
	    Safefree( imp_sth->bind_value );
	}

	if ( imp_sth->in_sqlda ) {
	    free_sqlda( imp_sth->in_sqlda );
	    imp_sth->in_sqlda = ( sql_t_sqlda2 *)0;
	    free_sqlda( imp_sth->in_meta_sqlda );
	    imp_sth->in_meta_sqlda = ( sql_t_sqlda2 *)0;
	}
	if ( imp_sth->out_sqlda ) {
	    free_sqlda( imp_sth->out_sqlda );
	    imp_sth->out_sqlda = ( sql_t_sqlda2 *)0;
	    free_sqlda( imp_sth->out_meta_sqlda );
	    imp_sth->out_meta_sqlda = ( sql_t_sqlda2 *)0;
	}
	DBIc_IMPSET_off(imp_sth);
    }
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_st_destroy\n" );
    }
}

int rdb_st_finish( SV *sth, imp_sth_t *imp_sth )
{
    int retval = 1;
    long status;
    D_imp_dbh_from_sth;
    char msg[256];

    imp_sth->sth = sth;

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_st_finish\n" );
    }

    if ( !rdb_set_connection( imp_dbh ) ) {
	retval = 0;
	goto done;
    }

    DBIc_ACTIVE_off(imp_sth);
    if ( imp_sth->is_select ) {
	if ( dbis->debug > 3 ) {
	    rdb_trace_msg( sth, "\tclose cursor %s\n", imp_sth->cur_name );
	}
	DBDSQL_CLOSE_CURSOR( &status, imp_sth->cur_name );
	if ( status ) {
	    do_rdb_error( sth, status );
	    retval = 0;
	    goto done;
	}
    }
    done:
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_st_finish\n" );
    }
    return retval;
}

int rdb_st_blob_read( SV *sth, imp_sth_t *imp_sth,
                      int field, long offset, long len, 
		      SV *destrv, long destoffset )
{
    return -2;
}


AV *dbd_st_fetch( SV *sth, imp_sth_t *imp_sth )
{
    D_imp_dbh_from_sth;
    AV *av;
    int num_fields;
    int chop_blanks;
    int i;
    long status;
    sql_t_sqlvar2 *sqlpar;


    imp_sth->sth = sth;

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_st_fetch\n" );
    }

    if ( !rdb_set_connection( imp_dbh ) ) {
	av = Nullav;
	goto done;
    }

    if ( !DBIc_is(imp_sth,DBIcf_ACTIVE) ) {
	av = Nullav;
	warn( "statment is inactive, fetch impossible" );
	goto done;
    }
    if ( !imp_sth->is_select ) {
	av = Nullav;
	croak( "statement is not a SELECT, fetch impossible" );
	goto done;
    }

    num_fields = DBIc_NUM_FIELDS(imp_sth);

    if ( dbis->debug > 3 ) {
	rdb_trace_msg( sth, "    Statement: %s, Cursor: %s, fields: %d\n",
		 imp_sth->stmt_name, imp_sth->cur_name, num_fields );
    }

    DBDSQL_FETCH_CURSOR( &status, imp_sth->cur_name, imp_sth->out_sqlda );
    if ( status ) {
	if ( status == 100 ) {
            rdb_st_finish( sth, imp_sth );
	    if ( dbis->debug > 3 ) {
		rdb_trace_msg( sth, "\treached end of cursor\n" );
	    }
	    if ( DBIc_is(imp_dbh,DBIcf_AutoCommit) ) {
		DBDSQL_COMMIT( &status );
		if ( status && status != SQLCODE_NOIMPTXN ) {
		    do_rdb_error( sth, status );
		    av = Nullav;
		    goto done;
		}
	    }
	    av = Nullav;
	    goto done;
	} else {
	    do_rdb_error( sth, status );
	    av = Nullav;
	    goto done;
	}
    }	
    av = DBIS->get_fbav(imp_sth);
    for ( i = 0; i < num_fields; i++ ) {
	sqlpar = imp_sth->out_sqlda->sqlvar + i;
	rdb_fetch_sv_from_sqlpar( imp_sth, AvARRAY(av)[i], sqlpar );
    }				

    done:
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_st_fetch\n" );
    }
    return av;
}    



int rdb_st_STORE_attrib( SV *sth, imp_sth_t *imp_sth, 
	                 SV *keysv, SV *valuesv )
{
    
    return 1;
}

SV* rdb_st_FETCH_attrib( SV *sth, imp_sth_t *imp_sth, 
	                 SV *keysv )
{
    D_imp_dbh_from_sth;
    char *key;
    STRLEN len;
    int i;
    SV *val;    
    AV *av;

    imp_sth->sth = sth;
    key = SvPV(keysv,len);

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_st_FETCH_attrib(%s)\n", key );
    }

    if ( !strcmp( key, "CursorName" ) && imp_sth->is_select ) {
	val = newSVpv( imp_sth->cur_name, 0 );
    } else if ( !strcmp( key, "NUM_OF_FIELDS" ) ) {
	val = newSViv( DBIc_NUM_FIELDS(imp_sth) );
    } else if ( !strcmp( key, "NUM_OF_PARAMS" ) ) {
	val = newSViv( DBIc_NUM_PARAMS(imp_sth) );
    } else if ( !strcmp( key, "Active" ) ) {
	val = newSViv( DBIc_is(imp_sth,DBIcf_ACTIVE) );
    } else if ( !strcmp ( key, "NAME" ) ||
	        !strcmp ( key, "NAME_lc" ) ||
		!strcmp ( key, "NAME_uc" ) ) {
	for ( av = newAV(), i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++ ) {
	    if ( !strcmp( key, "NAME_lc" ) ) {
		for ( char *p = imp_sth->out_meta_sqlda->sqlvar[i].sqlname;
		      *p; p++ ) *p = tolower(*p);
	    } else {
		for ( char *p = imp_sth->out_meta_sqlda->sqlvar[i].sqlname;
		      *p; p++ ) *p = toupper(*p);
	    }
	    val = newSVpv(imp_sth->out_meta_sqlda->sqlvar[i].sqlname, 0 );
	    if ( !av_store( av, i, val ) )
		SvREFCNT_dec(val);
	}
	val = newRV_noinc( (SV*) av );
    } else if ( !strcmp ( key, "TYPE" ) ) {
	for ( av = newAV(), i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++ ) {
	    val = newSViv(imp_sth->out_meta_sqlda->sqlvar[i].sqltype );
	    if ( !av_store( av, i, val ) )
		SvREFCNT_dec(val);
	}
	val = newRV_noinc( (SV*) av );
    } else if ( !strcmp ( key, "SCALE" ) ) {
	for ( av = newAV(), i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++ ) {
	    switch ( imp_sth->out_meta_sqlda->sqlvar[i].sqltype ) {
		case SQLDA_INTEGER:
		case SQLDA_FLOAT:
		case SQLDA_TINYINT:
		case SQLDA_SMALLINT:
		case SQLDA_QUADWORD:
		    val = newSViv( imp_sth->out_meta_sqlda->sqlvar[i].sqlprcsn );
		    break;
		default:
		    val = &sv_undef;
		    break;
	    }
	    if ( !av_store( av, i, val ) )
		SvREFCNT_dec(val);
	}
	val = newRV_noinc( (SV*) av );
    } else if ( !strcmp ( key, "NULLABLE" ) ) {
	for ( av = newAV(), i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++ ) {
	    val = newSViv( 2 );
	    if ( !av_store( av, i, val ) )
		SvREFCNT_dec(val);
	}
	val = newRV_noinc( (SV*) av );
    } else if ( !strcmp ( key, "PRECISION" ) ) {
	for ( av = newAV(), i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++ ) {
	    int prec;

	    switch ( imp_sth->out_meta_sqlda->sqlvar[i].sqltype ) {

		case SQLDA_VARBYTE:
		case SQLDA_VARCHAR:
		    prec = imp_sth->out_meta_sqlda->sqlvar[i].sqloctet_len - sizeof(int); 
		    // assuming sql_t_varchar
		    break;
		case SQLDA_CHAR:
		    prec = imp_sth->out_meta_sqlda->sqlvar[i].sqloctet_len;
		    break;
		case SQLDA_FLOAT:
		    switch( imp_sth->out_meta_sqlda->sqlvar[i].sqloctet_len ) {
			case 4:
			    prec = FLT_DIG; break;
			case 8:
			    prec = DBL_DIG; break;
			default:
			    croak( "unknown float data size in FETCH of sth-PRECISION\n" );
			    break;
		    }			    
		    break;
		case SQLDA_INTEGER:
		case SQLDA_SMALLINT:
		case SQLDA_TINYINT:
		case SQLDA_QUADWORD:
		    switch( imp_sth->out_meta_sqlda->sqlvar[i].sqloctet_len ) {
			case 1:
			    prec = 2; break;
			case 2:
			    prec = 4; break;
			case 4:
			    prec = 9; break;
			case 8:
			    prec = 18; break;
			default:
			    croak( "unknown integer data size in FETCH of sth-PRECISION\n" );
			    break;
		    }			    
		    break;
		case SQLDA_DATE:
		case SQLDA2_DATETIME:
		    prec = imp_dbh->date_len;
		    break;
		case SQLDA2_INTERVAL:
		    if ( dbis->debug > 3 ) {
			rdb_trace_msg( sth, "\tchrono scale: %d, chron prec: %d\n",
		                       imp_sth->out_meta_sqlda->sqlvar[i].sqlchrono_scale,
				       imp_sth->out_meta_sqlda->sqlvar[i].sqlchrono_precision );
		    }
		    prec = 
		      // longest possible format is:
		      // DAY(scale) TO SECOND(prec) because
		      // YEAR(scale) TO MONTH(prec) is shorter
		      1 + // leading sign
		      imp_sth->out_meta_sqlda->sqlvar[i].sqlchrono_scale +
		      imp_sth->out_meta_sqlda->sqlvar[i].sqlchrono_precision +
		      4 + // delimiters are : : : . 
		      6;  // HH MM SS
		    break;
		default:
		    prec = 0;
		    break;
	    }
	    val = newSViv( prec );
	    if ( !av_store( av, i, val ) )
		SvREFCNT_dec(val);
	}
	val = newRV_noinc( (SV*) av );
    } else {
	warn( "unknown attribute asked for in rdb_st_FETCH_attrib\n" );
	val = &sv_undef;
    }	

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_st_FETCH_attrib\n" );
    }

    return sv_2mortal(val);
}




int rdb_bind_ph( SV *sth, imp_sth_t *imp_sth,
                 SV *par_name, SV *par_value, IV sql_type, 
                 SV *attribs, int is_inout, IV maxlen)
{
    int status;
    int par_idx;
    int matched = 0;

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_bind_ph\n" );
    }

    if (SvGMAGICAL(par_name))
        mg_get(par_name);

    if ( SvNIOKp(par_name) ) {
	par_idx = (int)SvIV(par_name);
	status = rdb_bind_ph_idx( sth, imp_sth, par_idx, par_value,
			          sql_type, attribs, is_inout, maxlen );
	if ( status ) matched++;

    } else if ( SvPOKp(par_name) ) {
	unsigned int len;
	char *name;
	sql_t_sqlvar2 *sqlpar;

	name = SvPV( par_name, len );
	if ( dbis->debug > 3 ) {
	    rdb_trace_msg( sth, "\tsearch for param %s (%d)\n",
		           name, DBIc_NUM_PARAMS(imp_sth) );
	}
	sqlpar = imp_sth->in_sqlda->sqlvar;
	for ( int i = 0; i < DBIc_NUM_PARAMS(imp_sth); i++, sqlpar++ ) {
	    if ( dbis->debug > 3 ) {
		rdb_trace_msg( sth, "\tchecking %s\n",
		               sqlpar->sqlname );
	    }
	    if (  !strcmp( name, sqlpar->sqlname ) ) {
		status = rdb_bind_ph_idx( sth, imp_sth, i+1, par_value,
		                          sql_type, attribs, is_inout, maxlen );
		if ( !status ) goto done;
		matched++;
	    }
	}

	if ( dbis->debug > 3 ) {
	    rdb_trace_msg( sth, "\tsearch for field %s (%d)\n",
		           name, DBIc_NUM_FIELDS(imp_sth) );
	}
	sqlpar = imp_sth->out_sqlda->sqlvar;
	for ( int i = 0; i < DBIc_NUM_FIELDS(imp_sth); i++, sqlpar++ ) {
	    if ( dbis->debug > 3 ) {
		rdb_trace_msg( sth, "\tchecking %s\n",
		               sqlpar->sqlname );
	    }
	    if (  !strcmp( name, sqlpar->sqlname ) ) {
		status = rdb_bind_ph_idx( sth, imp_sth, 
			                  i+1+DBIc_NUM_FIELDS(imp_sth),
				          par_value, sql_type, attribs,
				          is_inout, maxlen );
		if ( !status ) goto done;
		matched++;
	    }
	}
	if ( !matched ) {
	    do_own_error( sth, "param index %s not matched with SQL params",
			  name );
	}		
    } else {
	do_own_error( sth, "param index in rdb_bind_ph has wrong type\n" );
    }
    done:
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_bind_ph (%d,%d)\n", 
		       SvIV(DBIc_ERR(imp_sth)), matched );
    }
    return SvIV(DBIc_ERR(imp_sth)) ? 0 : 1;
}



static
int rdb_bind_ph_idx ( SV *sth, imp_sth_t *imp_sth,
                      int par_idx, SV *par_value, IV sql_type, 
                      SV *attribs, int is_inout, IV maxlen)
{
    int status;
    sql_t_sqlvar2 *sqlpar;
    D_imp_dbh_from_sth;

    imp_sth->sth = sth;
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t--> rdb_bind_ph_idx\n" );
    }

    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "       bind %d <== %s (type %ld",
		 par_idx, neatsvpv(par_value,0), (long)sql_type);
	if (is_inout) {
	    rdb_trace_msg( sth, ", inout 0x%lx, maxlen %ld",
		     (long)par_value, (long)maxlen);
	}
	if (attribs) {
	    rdb_trace_msg( sth, ", attribs: %s", neatsvpv(attribs,0));
	}
	rdb_trace_msg( sth, ")\n" );
    }


    if ( !par_idx ) { 
	do_own_error( sth, "param index 0 in rdb_bind_ph is illegal\n" );
	goto done;
    }
    par_idx -= 1;

    if ( is_inout ) {
	if ( imp_sth->is_select && par_idx >= DBIc_NUM_PARAMS(imp_sth) ) {
	    do_own_error( sth,
		   "stmt is SELECT, inout-bind for fields is forbidden\n" );
	    goto done;
	}
	imp_sth->bind_value[par_idx] = par_value;
	SvREFCNT_inc( imp_sth->bind_value[par_idx] );
    } else {
	if ( par_idx >= DBIc_NUM_PARAMS(imp_sth) ) {
	    do_own_error( sth, "non-inout bind for fields is forbidden\n" );
	    goto done;
	}
	sqlpar = imp_sth->in_sqlda->sqlvar + par_idx;
	rdb_store_sv_into_sqlpar( imp_sth, par_value, sqlpar );
    }

    done:
    if ( dbis->debug > 2 ) {
	rdb_trace_msg( sth, "\t<-- rdb_bind_ph_idx (%d)\n", 
		       SvIV(DBIc_ERR(imp_sth)) );
    }
    return SvIV(DBIc_ERR(imp_sth)) ? 0 : 1;
}

/*
**  Error handling
*/

static int do_rdb_error( SV *h, long rdb_status, ... )
{

    D_imp_xxh(h);

    if ( rdb_status ) {
	int arg_count;
	char err_buf[10000];
	int err_len, sqlerr_len;
	struct dsc$descriptor_s err_dsc;
	va_list ap;

	SV *errstr = DBIc_ERRSTR(imp_xxh);
	va_start( ap, rdb_status );
	va_count( arg_count );	
	err_len = 0;
	if ( arg_count > 2 ) {
	    char *fmt = va_arg( ap, char * );
	    err_len = vsprintf( err_buf, fmt, ap );
	}	    
	SQL_GET_ERROR_TEXT( err_buf+err_len, sizeof(err_buf)-err_len,
		            &sqlerr_len );
	sv_setpvn( errstr, err_buf, err_len+sqlerr_len );
	sv_setiv( DBIc_ERR(imp_xxh), (IV)rdb_status );
        DBIh_EVENT2( h, ERROR_event, DBIc_ERR(imp_xxh), errstr );
    }
    return 0;
}


static int do_own_error( SV *h, char *fmt, ... )
{

    D_imp_xxh(h);

    int arg_count;
    char err_buf[10000];
    int err_len;
    struct dsc$descriptor_s err_dsc;
    va_list ap;

    SV *errstr = DBIc_ERRSTR(imp_xxh);
    va_start( ap, fmt );
    err_len = vsprintf( err_buf, fmt, ap );
    sv_setpvn( errstr, err_buf, err_len );
    sv_setiv( DBIc_ERR(imp_xxh), (IV)-1 );
    DBIh_EVENT2( h, ERROR_event, DBIc_ERR(imp_xxh), errstr );

    return 0;
}



static int do_vms_error( SV *h, int vms_status, char *text )
{
    char err_buf[1024];
    short int err_txtlen;
    struct dsc$descriptor_s err_dsc;
    int status;
    SV *errstr;
    D_imp_xxh(h);

    errstr = DBIc_ERRSTR(imp_xxh);
    sv_setpv( errstr, text );
    if ( !(vms_status & 1) ) {
	err_dsc.dsc$a_pointer = err_buf,
	err_dsc.dsc$w_length = sizeof(err_buf) - 1;
	err_dsc.dsc$b_dtype = DSC$K_DTYPE_T;
	err_dsc.dsc$b_class = DSC$K_CLASS_S;
	status = SYS$GETMSG ( vms_status, &err_txtlen, &err_dsc, 0, 0 );
	sv_catpvn( errstr, err_buf, err_txtlen );
    }
    sv_setiv( DBIc_ERR(imp_xxh), (IV)vms_status );
    DBIh_EVENT2( h, ERROR_event, DBIc_ERR(imp_xxh), errstr );
    return 0;
}



static void rdb_trace_msg( SV* h, char *fmt, ... )
{
    dSP;
    char buf[70000];
    int len;
    va_list ap;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(h);

    va_start(ap,fmt);
    len = vsprintf( buf, fmt, ap );
    XPUSHs(sv_2mortal(newSVpv(buf,len)));
    PUTBACK;
    call_pv( "DBI::trace_msg", G_DISCARD );
    FREETMPS;
    LEAVE;
}

/*
**  RDB utility functions
*/

static int rdb_set_connection( imp_dbh_t *imp_dbh )
{
    long status;
    D_imp_drh_from_dbh;
    char msg[256];

    if ( imp_drh->current_connection != imp_dbh->connection ) {
	char connection_name[32];
	
	sprintf( connection_name, "CON_%d", imp_dbh->connection );
	DBDSQL_SET_CONNECTION( &status, connection_name );
        if (dbis->debug > 3) {
	    sprintf( msg, "    set connect %s, %d\n", connection_name,
                     status );
	    rdb_trace_msg( imp_dbh->dbh, msg );
	}
	if ( !status ) {
	    imp_drh->current_connection = imp_dbh->connection;
	    return 1;
	} else
	    return 0;
    }
    return 1;
}	
    
/*
**  Perl utilities
*/

static int rdb_lookup_bool_attrib( HV *attribs, char *key )
{
    int retval = 0;

    if ( attribs ) {
	int klen = strlen(key);
	SV **pval;

	if ( hv_exists( attribs, key, klen ) ) {
	    pval = hv_fetch( attribs, key, klen, 0 );
	    if ( pval ) {
		retval = SvTRUE( *pval );
	    }
	}
    }	
    return retval;
}    

/*
**  SQLDA structure handling
*/

static sql_t_sqlda2 *prep_sqlda( sql_t_sqlda2 *in, int stringify )
{
    int i, sqlda_size;
    sql_t_sqlvar2 *sqlpar;
    sql_t_sqlda2 *out;
    
    sqlda_size = sizeof(sql_t_sqlda2);
    if (in->sqld > 1 )
	sqlda_size +=  (in->sqld-1)*sizeof(sql_t_sqlvar2);
    Newc( 1, out, 1, char[sqlda_size], sql_t_sqlda2 );
    memcpy( out, in, sqlda_size );
    out->sqln = in->sqld;

    for ( i = 0; i < out->sqld; i++ ) {
	sqlpar = out->sqlvar + i;
	if ( stringify ) {
	    switch ( sqlpar->sqltype ) {
		case SQLDA2_INTERVAL:
		    sqlpar->sqltype = SQLDA_VARCHAR;
		    sqlpar->sqllen = 28;
		    sqlpar->sqloctet_len = 32;
		    break;
	    }
	}
	Newz( 1, sqlpar->sqldata, sqlpar->sqloctet_len+sizeof(int), char );
	sqlpar->sqlind = (int *) ( sqlpar->sqldata + sqlpar->sqloctet_len );
	sqlpar->sqlname[ sqlpar->sqlname_len ] = 0;
    }
    return out;
}

static void free_sqlda( sql_t_sqlda2 *sqlda )
{
    int i;

    for ( i = 0; i < sqlda->sqld; i++ ) {
	if ( sqlda->sqlvar[i].sqldata ) {
	    Safefree( sqlda->sqlvar[i].sqldata );
	}
    }
    Safefree( sqlda );    
}


static void print_sqlda( SV *sth, sql_t_sqlda2 *sqlda )
{
    int i, j;
    sql_t_sqlvar2 *sqlpar;

    for ( i = 0; i < sqlda->sqld; i++ ) {
	sqlpar = sqlda->sqlvar + i;
	rdb_trace_msg( sth, "    par %d name %s type %d precision %d size %d len %d\n", 
		i, 
		sqlpar->sqlname,
		sqlpar->sqltype,
		sqlpar->sqlprcsn,
		sqlpar->sqloctet_len,
		sqlpar->sqllen );
    }
}


static void rdb_store_sv_into_sqlpar( imp_sth_t *imp_sth, SV *val,
		                      sql_t_sqlvar2 *sqlpar )
{

    D_imp_dbh_from_sth;

    if ( SvGMAGICAL(val) )
        mg_get(val);

    if ( !SvOK(val) ) {
	//
	//  parameter value is undef -> store NULL
	//
	*(sqlpar->sqlind) = -1;
    } else {
	*(sqlpar->sqlind) = 0;
	switch ( sqlpar->sqltype ) {
	    char *p, *end_p;
	    unsigned int len;
	    sql_t_varchar *varchar;
	    int64 int_val;
	    double double_val;
   	    float float_val;

	    case SQLDA_VARCHAR:
	    case SQLDA_VARBYTE:
		    p = SvPV(val,len);
		    if ( len > sqlpar->sqllen )
			len = sqlpar->sqllen;
		    varchar = (sql_t_varchar *) sqlpar->sqldata;
		    memcpy( varchar->buf, p, len );
		    varchar->len = len;
		    break;
	    case SQLDA_CHAR:
		    p = SvPV(val,len);
		    if ( len > sqlpar->sqllen )
			len = sqlpar->sqllen;
		    memcpy( sqlpar->sqldata, p, sqlpar->sqllen );
		    while ( len < sqlpar->sqllen ) {
			sqlpar->sqldata[len++] = ' ';
		    }
		    break;
	    case SQLDA_TINYINT:
		    int_val = rdb_scaled_sv_to_int64( val, sqlpar->sqlprcsn );
		    if ( imp_dbh->overflow_kills &&
			 ( int_val > SCHAR_MAX || int_val < SCHAR_MIN ) ) {
			do_own_error( imp_sth->sth,
			  "integer overflow during conversion into TINYINT\n" );
		    }
		    * ( (char *)sqlpar->sqldata ) = int_val;
		    break;
	    case SQLDA_SMALLINT:
		    int_val = rdb_scaled_sv_to_int64( val, sqlpar->sqlprcsn );
		    if ( imp_dbh->overflow_kills &&
			 ( int_val > SHRT_MAX || int_val < SHRT_MIN ) ) {
			do_own_error( imp_sth->sth,
			  "integer overflow during conversion into SMALLINT\n" );
		    }
		    * ( (short *)sqlpar->sqldata ) = int_val;
		    break;
	    case SQLDA_INTEGER:
		    int_val = rdb_scaled_sv_to_int64( val, sqlpar->sqlprcsn );
		    if ( imp_dbh->overflow_kills &&
			 ( int_val > INT_MAX || int_val < INT_MIN ) ) {
			do_own_error( imp_sth->sth,
			  "integer overflow during conversion into INTEGER\n" );
		    }
		    * ( (int *)sqlpar->sqldata ) = int_val;
		    break;
	    case SQLDA_QUADWORD:
		    int_val = rdb_scaled_sv_to_int64( val, sqlpar->sqlprcsn );
		    * ( (int64 *)sqlpar->sqldata ) = int_val;
		    break;
	    case SQLDA_FLOAT:
		    double_val = SvNV(val);
		    if ( sqlpar->sqloctet_len == 8 ) {
			* ( (double *)sqlpar->sqldata ) = double_val;
		    } else {
			if ( double_val > 0 && double_val > FLT_MAX ||
			     double_val < 0 && -double_val > FLT_MAX ) {
			    if ( imp_dbh->overflow_kills ) {
				do_own_error( imp_sth->sth,
				"floating overflow during conversion of %e into FLOAT (max: +-%e)\n",
				double_val, FLT_MAX );
			    }
			    double_val = (double_val>0) ? FLT_MAX: -FLT_MAX;
			} else if ( double_val > 0 && double_val < FLT_MIN ||
			            double_val < 0 && -double_val < FLT_MIN ) {
			    if ( imp_dbh->overflow_kills ) {
				do_own_error( imp_sth->sth,
				    "floating underflow during conversion of %e into FLOAT (min: +-%e)\n",
				    abs (double_val), FLT_MIN );
			    }
			    double_val = (double_val>0) ? FLT_MAX: -FLT_MAX;
			}
			float_val = (float)double_val;
			* ( (float *)sqlpar->sqldata ) = float_val;
		    }
		    break;		
	    case SQLDA_DATE:
	    case SQLDA2_DATETIME:
		    p = SvPV(val,len);
		    *(int64 *)(sqlpar->sqldata) = 
			rdb_convert_date_string( imp_sth, p, len );
		    break;
	    default:
		    do_own_error( imp_sth->sth,
			    "unknown SQLTYPE %d in rdb_store_sv_into_sqlpar\n",
                            sqlpar->sqltype );
		    break;
	}
    }				
}


static void rdb_fetch_sv_from_sqlpar( imp_sth_t *imp_sth, 
                                      SV *sv, sql_t_sqlvar2 *sqlpar )
{
    D_imp_dbh_from_sth;

    if ( !*( sqlpar->sqlind ) ) {
	//
	// not NULL
	//
	switch( sqlpar->sqltype ) {
	    int len, status;
	    int64 int_val;
	    char time_buf[64];
	    struct dsc$descriptor_s time_dsc;
	    sql_t_varchar *varchar_val;
	    double double_val;

	    case SQLDA_VARCHAR:
	    case SQLDA_VARBYTE:
		varchar_val = (sql_t_varchar *) sqlpar->sqldata;
		sv_setpvn( sv, varchar_val->buf, varchar_val->len );
		break;		
	    case SQLDA_CHAR:
		if ( DBIc_is( imp_sth, DBIcf_ChopBlanks ) ) {
		    for ( len = sqlpar->sqllen; 
		          len && sqlpar->sqldata[len-1] == ' '; 
		          len-- );
		} else {
		   len = sqlpar->sqllen;
		}
		sv_setpvn( sv, sqlpar->sqldata, len );
		break;
	    case SQLDA_TINYINT:
		int_val = *( (char *) sqlpar->sqldata );
		if ( sqlpar->sqlprcsn ) {
		    rdb_scaled_int64_to_pv( int_val, sqlpar->sqlprcsn, sv );
		} else {
		    sv_setiv( sv, int_val );
		}
		break;
	    case SQLDA_SMALLINT:
		int_val = *( (short *) sqlpar->sqldata );
		if ( sqlpar->sqlprcsn ) {
		    rdb_scaled_int64_to_pv( int_val, sqlpar->sqlprcsn, sv );
		} else {
		    sv_setiv( sv, int_val );
		}
		break;
	    case SQLDA_INTEGER:
		int_val = *( (int *) sqlpar->sqldata );
		if ( sqlpar->sqlprcsn ) {
		    rdb_scaled_int64_to_pv( int_val, sqlpar->sqlprcsn, sv );
		} else {
		    sv_setiv( sv, int_val );
		}
		break;
	    case SQLDA_QUADWORD:
		int_val = *( (int64 *) sqlpar->sqldata );
	        rdb_scaled_int64_to_pv( int_val, sqlpar->sqlprcsn, sv );
		break;
	    case SQLDA_FLOAT:
		if ( sqlpar->sqloctet_len == 8 ) {
		    double_val = *( (double *) sqlpar->sqldata );
		} else {
		    char numbuf[40];

		    float float_val = *( (float *) sqlpar->sqldata );
		    sprintf( numbuf, "%.6e", float_val );
		    sscanf( numbuf, "%le", &double_val );
		}
		sv_setnv( sv, double_val );
		break;		
	    case SQLDA_DATE:
	    case SQLDA2_DATETIME:
		time_dsc.dsc$b_dtype = DSC$K_DTYPE_T;
		time_dsc.dsc$b_class = DSC$K_CLASS_S;
		time_dsc.dsc$a_pointer = time_buf;
		time_dsc.dsc$w_length = sizeof(time_buf);
		status = LIB$FORMAT_DATE_TIME ( &time_dsc, 
						(int64 *) sqlpar->sqldata, 
						&imp_dbh->date_out_context,
						&time_dsc.dsc$w_length,
						0 );
		if ( !( status & 1) ) {
		    do_vms_error( imp_sth->sth, status,
			  "LIB$FORMAT_DATE_TIME in rdb_fetch_sv_from_sqlpar\n" );
		    time_dsc.dsc$w_length = 0;
		}
		sv_setpvn( sv, time_dsc.dsc$a_pointer,
			   time_dsc.dsc$w_length );
		break;		
	    case SQLDA2_INTERVAL:
		time_dsc.dsc$b_dtype = DSC$K_DTYPE_T;
		time_dsc.dsc$b_class = DSC$K_CLASS_S;
		time_dsc.dsc$a_pointer = time_buf;
		time_dsc.dsc$w_length = sizeof(time_buf);
		status = SYS$ASCTIM ( &time_dsc.dsc$w_length,
				      &time_dsc, 
				      (int64 *) sqlpar->sqldata, 
				      0 );
		if ( !( status & 1) ) {
		    do_vms_error( imp_sth->sth, status,
			  "SYS$ASCTIM in rdb_fetch_sv_from_sqlpar\n" );
		    time_dsc.dsc$w_length = 0;
		}
		sv_setpvn( sv, time_dsc.dsc$a_pointer,
			   time_dsc.dsc$w_length );
		break;		
	    default:
		do_own_error( imp_sth->sth,
		   "unknown SLQTYPE %d in rdb_fetch_sv_from_sqlpar\n",
		   sqlpar->sqltype );
		break;
	}
    } else {
	//
	//  NULL value
	//
	sv_setsv( sv, &sv_undef );
    }
}				

/*
**  Data type conversion
*/
static void rdb_scaled_int64_to_pv( int64 val, int precision, SV *result )
{
    char numbuf[24];
    int len, i;
    int negative;

    negative = 0;
    if ( val < 0 ) {
	val = -val;
	negative = 1;
    }
    len = sprintf( numbuf, "%022lld", val );
    if ( precision ) {
	strcpy( numbuf+len-precision+1, numbuf+len-precision);
	numbuf[len-precision] = '.';
	len++;
    }
    for ( i = 0; i < len && numbuf[i] == '0' &&
                            numbuf[i+1] && numbuf[i+1] != '.'; i++ );

    if ( negative ) {
	numbuf[--i] = '-';
    }
    sv_setpvn( result, numbuf+i, len-i );
}



static int64 rdb_scaled_sv_to_int64( SV *val, int precision )
{
    char *p, *end_p, numbuf[64];
    unsigned int len;
    int i, j, zeroed;
    int round_it;
    int64 num;

    p = SvPV(val,len);

    round_it = 0;
    strtoq ( p, &end_p, 10 );
    for( i = 0; p < end_p; i++, p++ )
       numbuf[i] = *p;
    if ( *p++ == '.' ) {
	for ( j = zeroed = 0; j < precision; j++, i++, p++ ) {
	    if ( isdigit(*p) ) {
		numbuf[i] = *p;
	    } else {
		numbuf[i] = '0';
		zeroed = 1;
	    }
	}
	if ( !zeroed && isdigit(*p) && *p >= '5' ) 
	    round_it = 1;
    } else {
	for ( j = 0; j < precision; j++, i++ ) {
	    numbuf[i] = '0';
	}
    }
    numbuf[i] = 0;
    num = strtoq( numbuf, &end_p, 10 );
    if ( round_it ) {
	if ( num > 0 ) {
	    num++;
	} else {
	    num--;
	}
    }
    return num;
}



static void rdb_set_date_format( SV* dbh, imp_dbh_t *imp_dbh, 
	                         char *format_str, int format_len )
{
    int status;
    struct dsc$descriptor_s format_dsc;
    int64 now;
    char now_str[256], msg[256];
    struct dsc$descriptor_s now_dsc;

    if (dbis->debug > 3) {
	sprintf( msg, "    --> rdb_set_date_format(%s)\n", format_str );
        rdb_trace_msg( dbh, msg );
    }

    strncpy( imp_dbh->date_format, format_str, 
	     sizeof(imp_dbh->date_format) );

    format_dsc.dsc$b_dtype = DSC$K_DTYPE_T;
    format_dsc.dsc$b_class = DSC$K_CLASS_S;
    format_dsc.dsc$a_pointer = format_str;
    format_dsc.dsc$w_length = format_len;
    imp_dbh->date_in_context = 0;
    status = LIB$INIT_DATE_TIME_CONTEXT( &imp_dbh->date_in_context,
		    &LIB$K_INPUT_FORMAT, &format_dsc );
    if ( !( status & 1 ) )
	do_vms_error( dbh, status, 
		"LIB$INIT_DATE_TIME_CONTEXT (in) in rdb_set_date_format\n" );

    imp_dbh->date_out_context = 0;
    status = LIB$INIT_DATE_TIME_CONTEXT( &imp_dbh->date_out_context,
		    &LIB$K_OUTPUT_FORMAT, &format_dsc );
    if ( !( status & 1 ) )
	do_vms_error( dbh, status, 
		"LIB$INIT_DATE_TIME_CONTEXT (out) in rdb_set_date_format\n" );

    now_dsc.dsc$a_pointer = now_str;
    now_dsc.dsc$w_length = sizeof(now_str);
    now_dsc.dsc$b_dtype = DSC$K_DTYPE_T;
    now_dsc.dsc$b_class = DSC$K_CLASS_S;
    SYS$GETTIM( &now );
    LIB$FORMAT_DATE_TIME( &now_dsc, &now, &imp_dbh->date_out_context,
			  &imp_dbh->date_len, 0 );
    if (dbis->debug > 3) {
	sprintf( msg, "    date_format max length is %d\n", imp_dbh->date_len );
        rdb_trace_msg( dbh, msg );
	sprintf( msg, "    <-- set_date_format\n" );
        rdb_trace_msg( dbh, msg );
    }
}

static int64 rdb_convert_date_string( imp_sth_t *imp_sth,
			              char *date_str, int date_len )
{
    static int initialized = 0;
#   define FMTS 9
    static char *formats[FMTS] = { "|!DB-!MAAU-!Y4|!H04:!M0:!S0.!C2|",
	                           "|!DB.!MAAU.!Y4|!H04:!M0:!S0.!C2|",
	                           "|!D0.!MN0.!Y4|!H04:!M0:!S0.!C2|",
	                           "|!D0.!MN0.!Y2|!H04:!M0:!S0.!C2|",
	                           "|!D0-!MN0-!Y4|!H04:!M0:!S0.!C2|",
	                           "|!D0-!MN0-!Y2|!H04:!M0:!S0.!C2|",
	                           "|!Y4.!MN0.!D0|!H04:!M0:!S0.!C2|",
	                           "|!Y4!MN0!D0|!H04!M0!S0!C7|",
	                           "|!Y4!MN0!D0|!H04:!M0:!S0.!C7|" };
    static int contexts[FMTS];
    struct dsc$descriptor_s date_dsc = { 0, DSC$K_DTYPE_T, DSC$K_CLASS_S,
                                         (char *)0 };
    int64 date;
    int i, status;
    D_imp_dbh_from_sth;

    if ( !initialized ) {
	struct dsc$descriptor_s fmt = { 0, DSC$K_DTYPE_T, DSC$K_CLASS_S,
	                                (char *)0 };

	for ( int i = 0; i < FMTS; i++ ) {
	    fmt.dsc$a_pointer = formats[i];
	    fmt.dsc$w_length = strlen( formats[i] );
	    status = LIB$INIT_DATE_TIME_CONTEXT( contexts + i,
					         &LIB$K_INPUT_FORMAT,
					         &fmt );
	    if ( !( status & 1 ) ) {
		do_vms_error( imp_sth->sth, status,
		    "LIB$INIT_DATE_TIME_CONTEXT in rdb_convert_date_string\n" );
	    }
	}
	initialized = 1;
    }
    for ( i = -1, status = 0; i < FMTS && !(status & 1) ; i++ ) {
	int context;

	if ( i == -1 ) {
	    context = imp_dbh->date_in_context;
	} else {
	    context = contexts[i];
	}
	date_dsc.dsc$a_pointer = date_str;
	date_dsc.dsc$w_length = date_len;
	status = LIB$CONVERT_DATE_STRING( &date_dsc,
				          &date,
					  &context, 0, 0, 0 );
    }
    if ( !( status & 1 ) ) {
	do_vms_error( imp_sth->sth, status, 
	    "LIB$CONVERT_DATE_STRING in rdb_convert_date_string\n" );
    }
    return date;
}    	


static int64 rdb_convert_interval_string( imp_sth_t *imp_sth,
			                  char *date_str, int date_len )
{
    struct dsc$descriptor_s date_dsc = { 0, DSC$K_DTYPE_T, DSC$K_CLASS_S,
                                         (char *)0 };
    int64 date;
    int status;

    date_dsc.dsc$a_pointer = date_str;
    date_dsc.dsc$w_length = date_len;
    status = SYS$BINTIM( &date_dsc, &date );
    if ( !( status & 1 ) ) {
	do_vms_error( imp_sth->sth, status, 
	    "SYS$BINTIM in rdb_convert_interval_string\n" );
    }
    return -date;
}
