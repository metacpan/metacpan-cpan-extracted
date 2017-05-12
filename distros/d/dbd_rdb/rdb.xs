
#include "Rdb.h"

DBISTATE_DECLARE;

MODULE = DBD::RDB    PACKAGE = DBD::RDB

INCLUDE: Rdb.xsi


MODULE = DBD::RDB      PACKAGE = DBD::RDB::db

void
_do(dbh, statement)
    SV *	dbh
    SV *	statement
    CODE:
    {
    STRLEN lna;
    D_imp_dbh(dbh);
    char *stmt = (SvOK(statement)) ? SvPV(statement,lna) : "";
    ST(0) = sv_2mortal(newSViv(rdb_db_do(dbh, imp_dbh, stmt)));
    }

