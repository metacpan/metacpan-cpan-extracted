/* Copyright 2000-2001 ActiveState
 *
 * This file contains various conversion function to map
 * between perl and python datatypes.
 */

#include <EXTERN.h>
#include <perl.h>
#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include "pycompat.h"
#include "lang_map.h"
#include "lang_lock.h"
#include "thrd_ctx.h"
#include "svrv_object.h"
#include "pyo.h"

/* when the pyo2sv or sv2py functions are called, both the perl and the python
 * lock need to be held.  These functions must guaranty that they will not
 * trigger execution of any perl or python code (like stringify overload or
 * attribute access), but only execute pure api calls.
 */

SV*
pyo2sv(PyObject *o)
{
    dCTXP;

    ASSERT_LOCK_BOTH;

    if (o == Py_None) {
	return newSV(0);
    }
    else if (PyUnicode_Check(o)) {
	return newSVpvn(PyUnicode_AsUTF8(o), PyUnicode_GetLength(o));
    }
    else if (PyLong_Check(o)) {
	return newSViv(PyLong_AsLong(o));
    }
    else if (PyLong_Check(o)) {
	unsigned long tmp = PyLong_AsUnsignedLong(o);
	if (tmp == (unsigned long)-1 && PyErr_Occurred()) {
	    /* overflow, don't convert after all */
	    PyErr_Clear();
	    return newPerlPyObject_inc(o);
	}
	return newSVuv(tmp);
    }
    else if (PyFloat_Check(o)) {
	return newSVnv(PyFloat_AsDouble(o));
    }
    else if (PySVRV_Check(o)
#ifdef MULTI_PERL
             && ((PySVRV*)o)->owned_by == ctx->perl
#endif
            )
    {
	return SvREFCNT_inc(PySVRV_RV(o));
    }
    else {
	return newPerlPyObject_inc(o);
    }
}


PyObject*
sv2pyo(SV* sv)
{
    PyObject* po;
    dCTXP;

    ASSERT_LOCK_BOTH;

    if (SvPOK(sv)) {
	STRLEN len;
	char *s = SvPV(sv, len);
	po = Py_BuildValue("s#", s, len);
    }
    else if (SvNOK(sv)) {
	po = Py_BuildValue("d", SvNV(sv));
    }
    else if (SvIOK(sv)) {
	po = Py_BuildValue("l", SvIV(sv));
    }
    else if (SvROK(sv) && sv_derived_from(sv, "Python::Object")) {
        IV ival = SvIV(SvRV(sv));
	if (ival) {
	    po = INT2PTR(PyObject*, ival);
	    Py_INCREF(po);
	}
	else {
	    /* Bad PyObject substitution */
	    po = Py_BuildValue("");
	}
    }
    else if (SvROK(sv)) {
	po = PySVRV_New(sv);
    }
    else if (!SvOK(sv)) {
	po = Py_BuildValue("");
    }
    else {
        /* XXX Let's just stringify all other stuff for now. */
	STRLEN len;
	char *s;

	/* Switch to perl only mode in case there are some stringify
         * overloading taking place here.  Is that actually possible?
         */
	PYTHON_UNLOCK;
	s = SvPV(sv, len);
	PYTHON_LOCK;
	po = Py_BuildValue("s#", s, len);
    }

    ASSERT_LOCK_BOTH;
    return po; 
}

