#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mysql/mysql.h>

#define CHUNK_SIZE 10

static MYSQL*
get_mysql_handler(pTHX_ SV* self) {
    HV *hv=(HV*)SvRV(self);
    SV **sql=hv_fetch(hv,"sql",3,0);

    if(!sql)
        return NULL;

    return (MYSQL*)SvIV(*sql);
}

static char*
build_query(pTHX_ MYSQL* mysql, SV* sv_qtemplate, SV* sv_values, STRLEN* ql) {
    static char *query=NULL;
    static unsigned long query_size=0;

    STRLEN qt_len;
    char const *qt;

    AV* values=(AV*)SvRV(sv_values);
    I32 value_index=0;

    char *query_ptr;

    /* Template might be double wrapped if we got it from the prepare
    */
    if(SvROK(sv_qtemplate)) {
        SV* sv=SvRV(sv_qtemplate);
        qt=SvPV(sv,qt_len);
    }
    else {
        qt=SvPV(sv_qtemplate,qt_len);
    }

    if(!query) {
        New(0,query,CHUNK_SIZE,char);
        query_size=CHUNK_SIZE;
    }
    query_ptr=query;

    for(; qt_len; qt_len--, qt++) {
        if(*qt!='?') {
            if(query_ptr-query+2>=query_size) {
                char *q=query;
                query_size+=CHUNK_SIZE;
                Renew(query,query_size,char);
                query_ptr=query+(query_ptr-q);
            }
            *query_ptr++=*qt;
        }
        else {
            SV** value_ptr=av_fetch(values,value_index++,0);
            SV* value;
            if(value_ptr) {
                value=*value_ptr;
                if(!SvIOK(value) && !SvNOK(value) &&
                   !SvPOK(value) && !SvROK(value))
                    value_ptr=NULL;
            }
            if(!value_ptr || value==&PL_sv_undef) {
                if(query_ptr-query+5>=query_size) {
                    char *q=query;
                    query_size+=CHUNK_SIZE;
                    Renew(query,query_size,char);
                    query_ptr=query+(query_ptr-q);
                }
                Copy("NULL",query_ptr,4,char);
                query_ptr+=4;
            }
            else {
                STRLEN v_len=0;
                char *v=SvPV(*value_ptr,v_len);
                if(query_ptr-query+v_len*2+3>=query_size) {
                    char *q=query;
                    query_size+=v_len*2+CHUNK_SIZE;
                    Renew(query,query_size,char);
                    query_ptr=query+(query_ptr-q);
                }
                *query_ptr++='\'';
                v_len=mysql_real_escape_string(mysql,query_ptr,v,v_len);
                query_ptr+=v_len;
                *query_ptr++='\'';
            }
        }
    }

    *query_ptr=0;

    *ql=query_ptr-query;

    return query;
}

MODULE = XAO::DO::FS::Glue::MySQL		PACKAGE = XAO::DO::FS::Glue::MySQL		

void
sql_print_refcnt (sv)
        SV*     sv;
    CODE:
        printf("sql_pr_ref=%u\n",SvREFCNT(sv));

void
sql_disconnect(self)
        SV*     self;
    CODE:
        MYSQL *mysql=get_mysql_handler(aTHX_ self);

        if(mysql) {
            HV *hv_self=(HV*)SvRV(self);
            hv_delete(hv_self,"sql",3,G_DISCARD);
            mysql_close(mysql);
        }

SV*
sql_error_text(self)
        SV*     self;
    CODE:
        MYSQL *mysql=get_mysql_handler(aTHX_ self);
        char const *error=mysql_error(mysql);
        RETVAL=newSVpv(error,0);
    OUTPUT:
        RETVAL

SV*
sql_real_connect(hostname,user,password,dbname)
        SV*     hostname;
        SV*     user;
        SV*     password;
        SV*     dbname;
    CODE:
        MYSQL *mysql=mysql_init(NULL);
        char *sh=(hostname == &PL_sv_undef) ? NULL : SvPV_nolen(hostname);
        char *su=(user == &PL_sv_undef) ? NULL : SvPV_nolen(user);
        char *sp=(password == &PL_sv_undef) ? NULL : SvPV_nolen(password);
        char *sd=(dbname == &PL_sv_undef) ? NULL : SvPV_nolen(dbname);
        if(mysql_real_connect(mysql,sh,su,sp,sd,0,NULL,0)) {
            RETVAL=newSViv((IV)mysql);
        }
        else {
            RETVAL=&PL_sv_undef;
        }
    OUTPUT:
        RETVAL

int
sql_real_do(self,qtemplate,values)
        SV*     self;
        SV*     qtemplate;
        SV*     values;
    CODE:
        MYSQL *mysql=get_mysql_handler(aTHX_ self);
        STRLEN query_len;
        char *query=build_query(aTHX_ mysql,qtemplate,values,&query_len);
        RETVAL=mysql_real_query(mysql,query,query_len);
        if(!RETVAL) {
            MYSQL_RES* mres=mysql_store_result(mysql);
            if(mres)
                mysql_free_result(mres);
        }
    OUTPUT:
        RETVAL

SV*
sql_real_execute(self,qtemplate,values)
        SV*     self;
        SV*     qtemplate;
        SV*     values;
    CODE:
        MYSQL *mysql=get_mysql_handler(aTHX_ self);
        STRLEN query_len;
        char *query=build_query(aTHX_ mysql,qtemplate,values,&query_len);
        if(mysql_real_query(mysql,query,query_len)) {
            RETVAL=&PL_sv_undef;
        }
        else {
            MYSQL_RES* mres=mysql_store_result(mysql);
            RETVAL=newSViv((IV)mres);
        }
    OUTPUT:
        RETVAL

SV*
sql_fetch_row (self,qr)
        SV*     self;
        SV*     qr;
    CODE:
        MYSQL_RES* mres=(MYSQL_RES*)SvIV(qr);
        MYSQL_ROW row;
        if(!mres || (row=mysql_fetch_row(mres))==NULL) {
            RETVAL=&PL_sv_undef;
        }
        else {
            AV *av=newAV();
            I32 num=mysql_num_fields(mres);
            unsigned long *row_l=mysql_fetch_lengths(mres);
            I32 i;
            for(i=0; i!=num; i++, row_l++) {
                char const *f=row[i];
                av_push(av,f ? newSVpv(row[i],*row_l) : &PL_sv_undef);
            }
            RETVAL=newRV_noinc((SV*)av);
        }
    OUTPUT:
        RETVAL

void
sql_finish (self,qr)
        SV*     self;
        SV*     qr;
    CODE:
        MYSQL_RES* mres=(MYSQL_RES*)SvIV(qr);
        mysql_free_result(mres);

SV*
sql_first_column (self,qr)
        SV*     self;
        SV*     qr;
    CODE:
        MYSQL_RES* mres=(MYSQL_RES*)SvIV(qr);
        AV* av=newAV();
        if(mres) {
            unsigned long *row_l;
            while(1) {
                MYSQL_ROW row=mysql_fetch_row(mres);
                if(!row)
                    break;
                row_l=mysql_fetch_lengths(mres);
                av_push(av,*row ? newSVpv(*row,*row_l) : &PL_sv_undef);
            }
            mysql_free_result(mres);
        }
        RETVAL=newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

SV*
sql_first_row (self,qr)
        SV*     self;
        SV*     qr;
    CODE:
        MYSQL_RES* mres=(MYSQL_RES*)SvIV(qr);
        MYSQL_ROW row;
        if(!mres || (row=mysql_fetch_row(mres))==NULL) {
            if(mres)
                mysql_free_result(mres);
            RETVAL=&PL_sv_undef;
        }
        else {
            AV *av=newAV();
            I32 num=mysql_num_fields(mres);
            unsigned long *row_l=mysql_fetch_lengths(mres);
            I32 i;
            for(i=0; i!=num; i++, row_l++) {
                char const *f=row[i];
                av_push(av,f ? newSVpv(row[i],*row_l) : &PL_sv_undef);
            }
            mysql_free_result(mres);
            RETVAL=newRV_noinc((SV*)av);
        }
    OUTPUT:
        RETVAL

SV*
sql_prepare (self,qtemplate)
        SV*     self;
        SV*     qtemplate;
    CODE:
        RETVAL=newRV_noinc(newSVsv(qtemplate));
    OUTPUT:
        RETVAL
