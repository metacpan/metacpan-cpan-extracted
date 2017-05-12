
/* (C)opyleft 2001-2002 Frank DENIS <j@pureftpd.org> */

#define snprintf _snprintf
#include <config.h>
#include "puredb_p.h"
#include "puredb_read.h"
#include "puredb_write.h"
#include <time.h>
//#include <errno.h>

int main(void)
{
    char key[42];
    char data[42];    
    unsigned long curkey = 0UL; /* more crap , wtf is 0ULL*/
    unsigned long nbrec  = 0UL;
    PureDBW dbw;
    PureDB db;
    off_t retpos;
    size_t retlen;
    char *founddata;
    int pass = 0;
    unsigned int seed = 0U;
    unsigned int randomrounds = 42000;

    printf("Starting regression tests\n\nDatabase creation (wait) ... ");
    fflush(stdout);
    if (puredbw_open(&dbw, "puredb.index", "puredb.data", "puredb.pdb") != 0) {
        perror("Can't create the database");
        goto end;
    }    
    seed = (unsigned int) time(NULL);
    srand(seed);
    do {
        curkey += (rand() & 0x4fff);
        snprintf(key, sizeof key, "%llu", curkey);
        snprintf(data, sizeof data, "%llu", curkey ^ 0x12345678abcdefUL); // wtf ULL again?
        if (puredbw_add_s(&dbw, key, data) != 0) {
            goto end;
        }
        nbrec++;
    } while (curkey < (unsigned long) 0xfffffff0); // long long
//    } while (curkey < (unsigned long) 0xffff0); // long long
    if (puredbw_close(&dbw) != 0) {
        goto end;
    }
    pass++;
    end:
    puredbw_free(&dbw);
    if (pass == 0) {
        puts("Failure :(");
        unlink("puredb.index");
        unlink("puredb.data");
        unlink("puredb.pdb");
        return -1;
    } else {
        printf("Success! %llu records have been written\n", nbrec);
        pass = 0;
    }    
    printf("Database lookups (wait) ... ");
    fflush(stdout);
    if (puredb_open(&db, "puredb.pdb") != 0) {
        perror("Can't open the database");
        goto end2;
    }
    curkey = 0UL;    //0ULL
    srand(seed);
    do {
        curkey += (rand() & 0x4fff);
        snprintf(key, sizeof key, "%llu", curkey);
        snprintf(data, sizeof data, "%llu", curkey ^ 0x12345678abcdefUL);//ULL
        if (puredb_find_s(&db, key, &retpos, &retlen) != 0) {
            fprintf(stderr, "The key wasn't found\n");
            goto end2;
        }
        if ((founddata = puredb_read(&db, retpos, retlen)) != NULL) {
            if (strcmp(founddata, data) != 0) {
                fprintf(stderr, "Wrong data\n");
                goto end2;
            }
            puredb_read_free(founddata);
        }
    } while (curkey < 0xfffffff0);
    printf("also trying non-existent data ... ");
    fflush(stdout);
    do {
        curkey <<= 1;
        curkey ^= (unsigned long) rand(); // long long
        snprintf(key, sizeof key, "%llu", curkey);
        if (puredb_find_s(&db, key, &retpos, &retlen) == 0) {
            founddata = puredb_read(&db, retpos, retlen);
            puredb_read_free(founddata);
        }
        randomrounds--;
    } while (randomrounds > 0U);
    pass++;
    end2:
    if (puredb_close(&db) != 0) {
        perror("The database couldn't be properly closed");
    }
    unlink("puredb.pdb");    
    if (pass == 0) {
        puts("Failure :(");
        return -1;
    } else {
        puts("Success!");
    }
    
    return 0;
}
