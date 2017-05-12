#ifndef __SQL_INCLUDED
#define __SQL_INCLUDED

#pragma __member_alignment __save
#pragma __nomember_alignment 

#define MAX_VARCHAR 65269

typedef struct _sql_t_sqlvar2 {
    short int sqltype;
    short sqllen;
    short sqlprcsn;
    int sqloctet_len;
    char *sqldata;
    int *sqlind;
    int sqlchrono_scale;
    int sqlchrono_precision;
    short int sqlname_len;
    char sqlname [128];
    char sqlchar_set_name [128];
    char sqlchar_set_schema [128];
    char sqlchar_set_catalog [128];
    } sql_t_sqlvar2;
typedef struct _sql_t_sqlda2 {
    char sqldaid [8];
    int sqldabc;
    short int sqln;
    short int sqld;
    sql_t_sqlvar2 sqlvar [1];           /* occurs sqlln times               */
    } sql_t_sqlda2;

typedef struct sqlca {
    char sqlcaid [8];
    int sqlcabc;
    int sqlcode;
    struct  {
        short int sqlerrml;
        char sqlerrmc [70];
        } sqlerrm;
    int sqlerrd [6];
    struct  {
        char sqlwarn0;
        char sqlwarn1;
        char sqlwarn2;
        char sqlwarn3;
        char sqlwarn4;
        char sqlwarn5;
        char sqlwarn6;
        char sqlwarn7;
        } sqlwarn;
    char sqlext [8];
    } sql_t_sqlca;


typedef struct {
    int len;
    char buf[1];
} sql_t_varchar;

typedef struct {
    unsigned short len;
    char buf[1];
} sql_t_varchar_w;
 

#pragma __member_alignment __restore

#endif
