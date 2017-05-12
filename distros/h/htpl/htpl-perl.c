#include "htpl.h"
#include <EXTERN.h>
#include <perl.h>
void xs_init _((void));
static PerlInterpreter *my_perl;

           int perlrun(argc, argv)
           char **argv;
           int argc;
           {
               int code;
               char *myself = argv[0];
               my_perl = perl_alloc();
               perl_construct(my_perl);
               code = perl_parse(my_perl, xs_init, argc, argv, (char **)NULL);
               if (!code) code = perl_run(my_perl);
               perl_destruct(my_perl);
               perl_free(my_perl);
               return code;
           }

int runperl(argc, argv, output, postdata, error, redir)
    int redir;
    char **argv;
    int argc;
    STR output;
    STR postdata;
    STR error; {

    int oin, oout, oerr;
    int nin, nout, nerr;

    int tin, tout, terr;

    int code;

    int chld;

    if (redir) {

        nin = open(postdata, O_RDONLY);
        oin = dup(0);
        dup2(nin, 0);
        close(nin);

        nout = creat(output, 0777);
        oout = dup(1);
        dup2(nout, 1);
        close(nout);

        nerr = creat(error, 0777);
        oerr = dup(2);
        dup2(nerr, 2);
        close(nerr);
    }
    code = perlrun(argc, argv);

    fflush(NULL);
    if (redir) {
        dup2(oin, 0);
        close(oin);

        dup2(oout,1);
        close(oout);

        dup2(oerr, 2);
        close(oerr);
    }


    return code;
}
