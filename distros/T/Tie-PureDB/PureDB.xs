#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include <errno.h>

#include "PureDB.h"
#include "puredb_read.h"
#include "puredb_write.h"

#undef PERL_UNUSED_VAR

/*
//perlmonks.org/?node_id=248697#panic: leave_scope inconsistency. (need help creating Tie::PureDB)
//http://www.manning.com/jenness/
//http://www.manning.com/getpage.html?project=jenness&filename=forum.html
//http://www.manning.com/ao/eep/eepao.html
//http://www.manning.com/ao/readforum.html?forum=eepao
// = malloc(sizeof(PureDB));
//// = malloc(sizeof(PureDB));
//puredb_read_free(founddata);Safefree(founddata);
//E:\new\Win32API-Registry-0.23

            sv_setpvf(
                get_sv("!", TRUE),
                "Error Reading '%s', '%s', '%s' : %s",
                    file_index,
                    file_data,
                    file_final,
                    strerror(errno)
            );

perl E:\dev\PureDB\4.Tie-PureDB-0.02\leak.t
E:\dev\PureDB\4.Tie-PureDB-0.02\leak.t
##            sv_setsv(get_sv("!", TRUE),newSVpvf("Error reading '%s'",dbfile));
##            sv_setpvf(get_sv("!", TRUE),"Error reading '%s'",dbfile);
##            sv_setsv(get_sv("@", TRUE),newSVpvf("Error reading '%s'",dbfile));

*/

#ifdef PureDEBUG
#include "perlio.h"

void ReadDebug2(char * what, off_t off, size_t len) {
    PerlIO_printf(PerlIO_stderr(),"\n\
#/////////////////////////////////\n\
#What               '%s'          \n\
#       off_t offset'%d'          \n\
#      size_t length'%d'          \n\n",
    what, off, len
    );
}
void ReadDebug(char * from, IV myIv, PureDB* foy) {
    PerlIO_printf(PerlIO_stderr(),"\n\
#/////////////////////////////////\n\
#From               '%s'          \n\
#                   '%d'          \n\
#       PTR2IV(foy) '%d'          \n\
#unsigned char *map '%s'          \n\
#            int fd '%d'          \n\
#  puredb_u32_t size'%d'          \n\n",
    from,
    myIv,
    PTR2IV(foy),
    (char*) foy->map ,
    (int) foy->fd,
    (puredb_u32_t) foy->size
    );

}
#endif




MODULE = Tie::PureDB    PACKAGE = Tie::PureDB::Read

PROTOTYPES: ENABLE

BOOT:
    sv_setpv(get_sv("Tie::PureDB::version", TRUE), the_puredb_PACKAGE_STRING );


void
xs_new(dbfile)
    INPUT:
        char * dbfile
    PREINIT:
        PureDB * db;
        int ret;

    PPCODE:
    {
        New(0,db,1,PureDB);
        ret = puredb_open(db, dbfile);

        if( ret != 0 ) {
            puredb_close(db);
            Safefree(db);
        } else {
            XPUSHs(sv_2mortal(newSViv(PTR2IV(db))));
        }
    }


IV
xs_puredb_getsize(db)
    CASE:
        IV db;
    PREINIT:
        PureDB* foy;
    CODE:
        foy = INT2PTR(PureDB*,db);
        RETVAL = foy->size;
    OUTPUT:
        RETVAL


void
xs_puredb_find(db, tofind )
    CASE:
        IV db;
        SV* tofind;

        PREINIT:
            size_t retlen;
            off_t retpos;
            int ret;
            PureDB* foy;

        PPCODE:
        {
            foy = INT2PTR(PureDB*,db);

            ret = puredb_find(foy, SvPVX((SV*)tofind), sv_len((SV*)tofind), &retpos, &retlen );

            switch(ret){
                case 0:
                    EXTEND(SP,2);
                    PUSHs(sv_2mortal(newSViv((IV) retpos)));
                    PUSHs(sv_2mortal(newSViv((IV) retlen)));

                    break;

                case -1:
                    sv_setpvf(get_sv("!", TRUE),"Key '%s' was not found", tofind);
                    break;

                case -2:
                    sv_setpvf(get_sv("!", TRUE),"the database is corrupted", tofind);
                    break;

                case -3:
                    sv_setpvf(get_sv("!", TRUE),"a system error occured: %s", strerror(errno));
                    break;
            }
        }


void
xs_puredb_read(db, offset, len)
    CASE:
        IV db;
        off_t offset
        size_t len
    PREINIT:
        char* founddata;
        PureDB* foy;
    PPCODE:
    {
        foy = (PureDB*) db;
        if( ( founddata = puredb_read(foy, offset, len) ) != NULL ) {
#ifdef PureDEBUG
    ReadDebug( "xs_puredb_read" , db, foy );
    ReadDebug2( founddata, offset, len );
#endif
            XPUSHs(sv_2mortal( newSVpvn(founddata,len) ));
        } else {
            sv_setpvf(get_sv("!", TRUE),"Unknown error reading offset=%d, lenth=%d ",offset,len);
        }

    }


void
xs_free(db)
    CASE:
        IV db;
    PREINIT:
        PureDB* foy;
        CODE:
        {
            foy = INT2PTR(PureDB*,db);
            puredb_close(foy);
            Safefree(foy);
        }



MODULE = Tie::PureDB    PACKAGE = Tie::PureDB::Write

PROTOTYPES: ENABLE

void
xs_new(file_index, file_data, file_final)
    INPUT:
        char * file_index
        char * file_data
        char * file_final

    PREINIT:
        PureDBW * dbw;
        int ret;

    PPCODE:
    {
        New(0,dbw,1,PureDBW);
        ret = puredbw_open( dbw, file_index, file_data, file_final );

        if( ret != 0 ) {
            puredbw_close(dbw);
            Safefree(dbw);
        } else {
            EXTEND(SP,1);
            PUSHs(sv_2mortal(newSViv(PTR2IV(dbw))));
        }
    }






void
xs_puredbw_add(dbw, key, content)
    CASE:
        IV dbw;
        SV* key;
        SV* content;
    PREINIT:
        PureDBW* foy;
        int ret;
    PPCODE:
        foy = INT2PTR(PureDBW*,dbw);
        ret = puredbw_add(foy, SvPVX(key), sv_len(key), SvPVX(content), sv_len(content));

        if( ret != 0 ) {
            sv_setpvf(
                get_sv("!", TRUE),
                "Error adding '%s' => '%s' (ret=%d)(%s)",
                    SvPVX(key),
                    SvPVX(content),
                    ret,
                    strerror(errno)
            );
        } else {
            XPUSHs(&PL_sv_yes);
        }

void
xs_free(dbw)
    CASE:
        IV dbw;
    PREINIT:
        PureDBW* foy;
        int ret;
    CODE:
        foy = INT2PTR(PureDBW*,dbw);
        puredbw_close(foy);
        puredbw_free(foy);
        Safefree(foy);

