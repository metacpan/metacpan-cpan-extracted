#include <EXTERN.h>
#include <perl.h>
#include <Python.h>

#include "pyo.h"
#include "lang_lock.h"
#include "thrd_ctx.h"
#include "perlmodule.h"

static int
magic_free_pyo(pTHX_ SV *sv, MAGIC *mg)
{
    dCTX;
    PyObject *pyo = INT2PTR(PyObject *, SvIV(sv));
#ifdef REF_TRACE
    printf("Unbind pyo %p\n", pyo);
#endif
    ENTER_PYTHON;
    Py_DECREF(pyo);
    ENTER_PERL;
    return 0;
}

MGVTBL vtbl_free_pyo = {0, 0, 0, 0, magic_free_pyo};

SV*
newPerlPyObject_noinc(PyObject *pyo)
{
    SV* rv;
    SV* sv;
    MAGIC *mg;
    dCTXP;

    ASSERT_LOCK_PERL;

    if (!pyo)
        croak("Missing pyo reference argument");

    rv = newSV(0);

    sv = newSVrv(rv, "Python::Object");
    sv_setiv(sv, (IV)pyo);
    sv_magic(sv, 0, '~', 0, 0);
    mg = mg_find(sv, '~');
    if (!mg) {
        SvREFCNT_dec(rv);
	croak("Can't assign magic to Python::Object");
    }
    mg->mg_virtual = &vtbl_free_pyo;
    SvREADONLY(sv);
#ifdef REF_TRACE
    printf("Bind pyo %p\n", pyo);
#endif

    ASSERT_LOCK_PERL;

    return rv;
}

SV*
newPerlPyObject_inc(PyObject *pyo)
{
    SV* sv;
    dCTXP;
    ASSERT_LOCK_BOTH;
    Py_XINCREF(pyo);
    PYTHON_UNLOCK;
    sv = newPerlPyObject_noinc(pyo);
    ENTER_PYTHON;
    PERL_LOCK;
    return sv;
}


PyObject*
PerlPyObject_pyo_or_null(SV* sv)
{
    MAGIC *mg;
    dCTXP;

    ASSERT_LOCK_PERL;

    if (SvROK(sv) && sv_derived_from(sv, "Python::Object")) {
        sv = SvRV(sv);
        mg = mg_find(sv, '~');
        if (SvIOK(sv) && mg && mg->mg_virtual == &vtbl_free_pyo) {
	    IV ival = SvIV(sv);
	    return INT2PTR(PyObject *, ival);
        }
    }
    return INT2PTR(PyObject *, 0);
}


PyObject*
PerlPyObject_pyo(SV* sv)
{
    MAGIC *mg;
    dCTXP;

    ASSERT_LOCK_PERL;

    if (SvROK(sv) && sv_derived_from(sv, "Python::Object")) {
        sv = SvRV(sv);
        mg = mg_find(sv, '~');
        if (SvIOK(sv) && mg && mg->mg_virtual == &vtbl_free_pyo) {
	    IV ival = SvIV(sv);
	    if (!ival)
		croak("Null Python::Object content");
	    return INT2PTR(PyObject *, ival);
        }
        else
            croak("Bad Python::Object content");
    }
    else
	croak("Not a Python::Object");

    /* NOT REACHED */
    return NULL;
}
