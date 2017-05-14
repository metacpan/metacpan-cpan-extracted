#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
int my_foo;
int foo_get (SV *sv, MAGIC *mg)
{
    sv_setiv(sv, my_foo);   /* return my_foo's value */
    printf ("GET foo => %d\n", my_foo);
    return 1;
}
int foo_set (SV *sv, MAGIC *mg)
{
    my_foo = SvIV(sv);     /* set my_foo's value     */
    printf ("SET foo => %d\n", my_foo);
    return 1;
}

MGVTBL foo_accessors = {   /* Custom virtual table */
    foo_get,
    foo_set,
    NULL,
    NULL,
    NULL
};
void t () 
{
    MAGIC *m;
    /* Create a variable*/
    char *var = "main::foo";
    SV *sv = perl_get_sv(var,TRUE);
    /* Upgrade the sv to a magical variable*/
    sv_magic(sv, NULL, '~', var, strlen(var));
    /* sv_magic adds a MAGIC structure (of type '~') to the SV. 
       Get it and set the virtual table pointer */
    m = mg_find(sv, '~');
    m->mg_virtual = &foo_accessors;
    SvMAGICAL_on(sv);
    sv_dump(sv);
}

void t1 ()
{
    sv_dump(perl_get_sv("main::foo",FALSE));
}



MODULE = Book  PACKAGE = Book

void
t ()
     

void
t1 ()