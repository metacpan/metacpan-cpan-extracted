
/* (C)opyleft 2001-2002 Frank DENIS <j@pureftpd.org>

cl /I.  /MD  /Tc example.c    libpuredb_write.lib     libpuredb_read.lib
example.exe

*/

#include <stdio.h>
#include <stdlib.h>

#include "puredb_p.h"
#include "puredb_read.h"
#include "puredb_write.h"



void main()
{
    PureDBW dbw;
    char *data;    
    PureDB db;
    off_t retpos;
    size_t retlen;
    int err;

    if (puredbw_open(&dbw, "puredb.index", "puredb.data", "puredb.pdb") != 0) {
        perror("Can't create the database");
        goto write_end;
    }
    if (puredbw_add_s(&dbw, "key", "content") != 0 ||
        puredbw_add_s(&dbw, "key2", "content2") != 0 ||
        puredbw_add_s(&dbw, "key42", "content42") != 0) {
        perror("Error while inserting key/data pairs");
        goto write_end;
    }
    if (puredbw_close(&dbw) != 0) {
        perror("Error while closing the database");
    }
    
write_end:
    puredbw_free(&dbw);
    printf("done creating database\n\n");


    
    if (puredb_open(&db, "puredb.pdb") != 0) {
        perror("Can't open the database");
        goto read_end;
    }


    printf("\nafter puredb_open");
    printf("#unsigned char *map '%s'\n", (char*) db.map );
    printf("#            int fd '%d'\n", (int) db.fd );
    printf("#  puredb_u32_t size'%d'\n", (puredb_u32_t) db.size );
    printf("\n");


    if ((err = puredb_find_s(&db, "key42", &retpos, &retlen)) != 0) {
        fprintf(stderr, "The key wasn't found [err=%d]\n", err);
        goto read_end;
    } else {
        printf("\n\n#ret %d\n#retpos %d\n#retlen %d\n", err, retpos, retlen);
    }

    printf("\nafter puredb_find_s");
    printf("#unsigned char *map '%s'\n", (char*) db.map );
    printf("#            int fd '%d'\n", (int) db.fd );
    printf("#  puredb_u32_t size'%d'\n", (puredb_u32_t) db.size );
    printf("\n");


    if ((data = puredb_read(&db, retpos, retlen)) != NULL) {
        printf("The maching data is : [%s]\n", data);
        puredb_read_free(data);
    }

    printf("\nafter puredb_read");
    printf("#unsigned char *map '%s'\n", (char*) db.map );
    printf("#            int fd '%d'\n", (int) db.fd );
    printf("#  puredb_u32_t size'%d'\n", (puredb_u32_t) db.size );
    printf("\n");

read_end:
    if (puredb_close(&db) != 0) {
        perror("The database couldn't be properly closed");
    }
    

}
