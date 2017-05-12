#ifndef __DBDIMP_INCLUDED
#define __DBDIMP_INCLUDED

#include "sql.h"

   struct imp_drh_st {
        dbih_drc_t com;         /* MUST be first element in structure   */

       /* Insert your driver handle attributes here */
	SV *drh;
	int current_connection;
	int next_connection;
   };

   struct imp_dbh_st {
       dbih_dbc_t com;          /* MUST be first element in structure   */

       /* Insert your database handle attributes here */
	SV *dbh;
	int connection;
	int statement_nr;
	int cursor_nr;
	int overflow_kills;
	char date_format[256];
	int date_len;
        unsigned int date_in_context;
        unsigned int date_out_context;
   };

   struct imp_sth_st {
       dbih_stc_t com;          /* MUST be first element in structure   */

       /* Insert your statement handle attributes here */
	SV *sth;
	sql_t_varchar_w *stmt;
	char stmt_name[16];
	int is_select;
	char cur_name[16];
	HV *attribs;
	sql_t_sqlda2 *in_sqlda;
	sql_t_sqlda2 *out_sqlda;
	sql_t_sqlda2 *in_meta_sqlda;
	sql_t_sqlda2 *out_meta_sqlda;
	SV **bind_attribs;
	SV **bind_value;
   };

   /*  Rename functions for avoiding name clashes; prototypes are  */
   /*  in dbd_xst.h                                                */
   #define dbd_init		rdb_init
   #define dbd_db_login		rdb_db_login
   #define dbd_bind_ph		rdb_bind_ph
   #define dbd_db_commit	rdb_db_commit
   #define dbd_db_destroy	rdb_db_destroy
   #define dbd_db_disconnect    rdb_db_disconnect
   #define dbd_db_FETCH_attrib  rdb_db_fetch_attrib
   #define dbd_db_rollback      rdb_db_rollback
   #define dbd_db_STORE_attrib  rdb_db_store_attrib
   #define dbd_discon_all	rdb_discon_all
   #define dbd_st_blob_read     rdb_st_blob_read
   #define dbd_st_destroy	rdb_st_destroy
   #define dbd_st_execute	rdb_st_execute
   #define dbd_st_fetch		rdb_st_fetch
   #define dbd_st_FETCH_attrib  rdb_st_fetch_attrib
   #define dbd_st_finish	rdb_st_finish
   #define dbd_st_prepare	rdb_st_prepare
   #define dbd_st_STORE_attrib  rdb_st_store_attrib

//   #define dbd_db_do            rdb_db_do
   int rdb_db_do                _((SV *dbh, imp_dbh_t *imp_dbh, char *stmt ));


#endif
