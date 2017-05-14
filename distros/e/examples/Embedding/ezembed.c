#include "EXTERN.h"
#include <string.h>
#include <perl.h>

/*perl_call ("foo",
       "s",    "hello",
       "i",    2,
       "d",    5.4,
       "OUT",
       "i",    &i,
       "s",    buf,
       NULL);
*/
typedef struct {
    char type;       
    void *pdata;
} Out_Param;


int
perl_eval_va (char *str, ...)
{
    /* Evals a string, returns -1 if unsuccessful, else returns
     *  the number of return params
     *  char buf[10]; int a;
     *  perl_eval_va ("$a = 10; ($a, $a+1)",
     *                "i", &a,
     *                "s", buf,
     *                 NULL);
     */
       
    SV*       sv     = newSVpv(str,0);
    va_list   vl;
    char      *p     = NULL;  
    int       i      = 0; 
    int       nret   = 0;     /* number of return params expected*/
    int       result = 0;
    Out_Param op[20];
    int ii; double d;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    va_start (vl, str);

    while (p = va_arg(vl, char *)) {
        if ((*p != 's') && (*p != 'i') && (*p != 'd')) {
            fprintf (stderr, "perl_eval_va: Unknown option \'%c\'.\n"
                              "Did you forget a trailing NULL ?\n", *p);
            return -1;
        }
        op[nret].pdata = (void*) va_arg(vl, char *);
        op[nret++].type = *p;
    }
    va_end(vl);
    PUTBACK;
    result = perl_eval_sv(sv, (nret == 0) ? G_DISCARD :
                              (nret == 1) ? G_SCALAR  :
                                            G_ARRAY  );

    SPAGAIN;
    if (SvTRUE(GvSV(errgv))) { /* errgv == $@ */
        fprintf (stderr, "Eval error: %s", SvPV(GvSV(errgv), na)) ;
        return -1;
    }
    SvREFCNT_dec(sv);
    /*printf ("nret: %d, result: %d\n", nret, result);*/
    if (nret > result)
        nret = result;

    for (i = --nret; i >= 0; i--) {
        switch (op[i].type) {
        case 's':
            str = POPp;
            /*printf ("String: %s\n", str);*/
            strcpy((char *)op[i].pdata, str);
            break;
        case 'i':
            ii = POPi;
            /*printf ("Int: %d\n", ii);*/
            *((int *)(op[i].pdata)) = ii;
            break;
        case 'd':
            d = POPn;
            /*printf ("Double: %f\n", d);*/
            *((double *) (op[i].pdata)) = d;
            break;
        }
   }
   FREETMPS ;
   LEAVE;
   return result;
}    

int
perl_call_va (char *subname, ...)
{
    char *p;
    char *str = NULL; int i = 0; double d = 0;
    int  nret = 0; /* number of return params expected*/
    int  ax;
    int ii=0;
    Out_Param op[20];
    va_list vl;
    int out = 0;
    int result = 0;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    va_start (vl, subname);
 
    /*printf ("Entering perl_call %s\n", subname);*/
    while (p = va_arg(vl, char *)) {
        /*printf ("Type: %s\n", p);*/
        switch (*p)
        {
        case 's' :
            if (out) {
                op[nret].pdata = (void*) va_arg(vl, char *);
                op[nret++].type = 's';
            } else {
                str = va_arg(vl, char *);
         /*printf ("IN: String %s\n", str);*/
         ii = strlen(str);
                XPUSHs(sv_2mortal(newSVpv(str,ii)));
            }
            break;
        case 'i' :
            if (out) {
                op[nret].pdata = (void*) va_arg(vl, int *);
                op[nret++].type = 'i';
            } else {
                ii = va_arg(vl, int);
         /*printf ("IN: Int %d\n", ii);*/
                XPUSHs(sv_2mortal(newSViv(ii)));
            }
            break;
        case 'd' :
            if (out) {
                op[nret].pdata = (void*) va_arg(vl, double *);
                op[nret++].type = 'd';
            } else {
               d = va_arg(vl, double);
               /*printf ("IN: Double %f\n", d);*/
               XPUSHs(sv_2mortal(newSVnv(d)));
            }
            break;
        case 'O':
            out = 1;  /* Out parameters starting */
            break;
        default:
             fprintf (stderr, "perl_eval_va: Unknown option \'%c\'.\n"
                               "Did you forget a trailing NULL ?\n", *p);
            return 0;
        }
    }
   
    va_end(vl);
 
    PUTBACK;
    result = perl_call_pv(subname, (nret == 0) ? G_DISCARD :
                                   (nret == 1) ? G_SCALAR  :
                                                 G_ARRAY  );
 
    
 
    SPAGAIN;
    /*printf ("nret: %d, result: %d\n", nret, result);*/
    if (nret > result)
        nret = result;
 
    for (i = --nret; i >= 0; i--) {
        switch (op[i].type) {
        case 's':
            str = POPp;
            /*printf ("String: %s\n", str);*/
            strcpy((char *)op[i].pdata, str);
            break;
        case 'i':
            ii = POPi;
            /*printf ("Int: %d\n", ii);*/
            *((int *)(op[i].pdata)) = ii;
            break;
        case 'd':
            d = POPn;
            /*printf ("Double: %f\n", d);*/
            *((double *) (op[i].pdata)) = d;
            break;
        }
    }
   
    FREETMPS ;
    LEAVE ;
    return result;
}
 