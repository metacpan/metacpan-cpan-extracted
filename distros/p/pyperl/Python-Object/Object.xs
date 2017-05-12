/* Copyright 2000-2001 ActiveState
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <Python.h>
#include "PerlPyErr.h"
#include "../lang_lock.h"
#include "../lang_map.h"
#include "../thrd_ctx.h"

/* so we can use different typemaps for borrowed/owned obj refs */
typedef PyObject NewPyObject;
typedef PyObject NewPyObjectX;

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
    dCTX;
    ASSERT_LOCK_BOTH;
    Py_XINCREF(pyo);
    PYTHON_UNLOCK;
    sv = newPerlPyObject_noinc(pyo);
    ENTER_PYTHON;
    PERL_LOCK;
    return sv;
}


static PyObject*
PerlPyObject_pyo_or_null(SV* sv)
{
    MAGIC *mg;
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


static PyObject*
PerlPyObject_pyo(SV* sv)
{
    MAGIC *mg;
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

static SV*
newPerlPyErr()
{
    SV* sv;
    PerlPyErr *err;

    ASSERT_LOCK_PERL;
    sv = newSV(0);
    Newz(8008, err, 1, PerlPyErr);
    sv_setref_pv(sv, "Python::Err", (void*)err);
    return sv;
}

static PerlPyErr *
PerlPyErr_err(SV* sv)
{
    ASSERT_LOCK_PERL;
    if (SvROK(sv) && sv_derived_from(sv, "Python::Err")) {
	IV tmp = SvIV((SV*)SvRV(sv));
	return INT2PTR(PerlPyErr *,tmp);
    }
    else
	croak("Not a Python::Err");

    /* NOT REACHED */
    return NULL;
}


void
croak_on_py_exception()
{
    /* Enter with python lock.
       Leave through croaking with the perl lock.
     */
    dCTX;
    SV* py_err_sv;
    PerlPyErr* py_err;
    ASSERT_LOCK_PYTHON;

    ENTER_PERL;
    py_err_sv = newPerlPyErr();
    py_err = PerlPyErr_err(py_err_sv);

    ENTER_PYTHON;
    PyErr_Fetch(&py_err->type, &py_err->value, &py_err->traceback);

    ENTER_PERL;
    if (py_err->type) {
	sv_setsv(ERRSV, py_err_sv);
	SvREFCNT_dec(py_err_sv);
	ASSERT_LOCK_PERL;
	croak(Nullch);
    }
    else {
	SvREFCNT_dec(py_err_sv);
	ASSERT_LOCK_PERL;
	croak("No python exception");
    }
}


MODULE = Python::Object		PACKAGE = Python

PROTOTYPES: DISABLE

NewPyObject *
object(sv)
     SV* sv
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     PERL_LOCK;
     RETVAL = sv2pyo(sv);
     PYTHON_UNLOCK;
     ASSERT_LOCK_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
int(sv)
     SV* sv
   PREINIT:
     long i;
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     i = SvIV(sv);
     ENTER_PYTHON;
     RETVAL = Py_BuildValue("l", i);
     ENTER_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
long(sv)
     SV* sv
   PREINIT:
     dCTX;
     STRLEN my_na;
     char *s;
   CODE:
     ASSERT_LOCK_PERL;
     s = SvPV(sv, my_na);
     ENTER_PYTHON;
     RETVAL = PyLong_FromString(s, NULL, 10);
     if (!RETVAL)
         croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
float(sv)
     SV* sv
   PREINIT:
     dCTX;
     double d;
   CODE:
     ASSERT_LOCK_PERL;
     d = SvNV(sv);
     ENTER_PYTHON;
     RETVAL = Py_BuildValue("d", d);
     ENTER_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
complex(real, imag)
     double real
     double imag
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyComplex_FromDoubles(real, imag);
     ENTER_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
list(...)
   PREINIT:
     dCTX;
     int i;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyList_New(items);
     if (!RETVAL)
         croak_on_py_exception();
     PERL_LOCK;
     for (i = 0; i < items; i++) {
	PyList_SetItem(RETVAL, i, sv2pyo(ST(i)));
     }
     PYTHON_UNLOCK;
     ASSERT_LOCK_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
tuple(...)
   PREINIT:
     dCTX;
     int i;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyTuple_New(items);
     if (!RETVAL)
         croak_on_py_exception();
     PERL_LOCK;
     for (i = 0; i < items; i++) {
	PyTuple_SetItem(RETVAL, i, sv2pyo(ST(i)));
     }
     PYTHON_UNLOCK;
     ASSERT_LOCK_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
dict(...)
   PREINIT:
     dCTX;
     int i;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyDict_New();
     if (!RETVAL)
         croak_on_py_exception();
     PERL_LOCK;
     for (i = 0; i < items; i += 2) {
        PyObject *key = sv2pyo(ST(i));
        PyObject *val;
        if (i < (items-1))
	    val = sv2pyo(ST(i+1));
	else {
	    if (PL_dowarn)
		warn("Odd number of elements in dict initializer");
            Py_INCREF(Py_None);
	    val = Py_None;
        }
	if (PyDict_SetItem(RETVAL, key, val) == -1) {
            Py_DECREF(RETVAL);
            PERL_UNLOCK;
            croak_on_py_exception();
        }
     }
     PYTHON_UNLOCK;
     ASSERT_LOCK_PERL;
   OUTPUT:
     RETVAL

void
PyO_transplant(self, donor)
     SV* self
     SV* donor
   CODE:
     /* This is only here to support the STORABLE_thaw implementation.
      * What this method does is to steal the pointer from another
      * Python::Object object.
      */
     ASSERT_LOCK_PERL;
     if (SvROK(donor) || sv_derived_from(donor, "Python::Object")) {
        MAGIC *mg;
        donor = SvRV(donor);
        mg = mg_find(donor, '~');
	if (SvIOK(donor) && mg && mg->mg_virtual == &vtbl_free_pyo) {
	   SV* self_sv = SvRV(self);
	   sv_setiv(self_sv, SvIV(donor));
           mg->mg_virtual = 0;  /* since sv_unmagic() would call it */
	   sv_unmagic(donor, '~');
	   SvOK_off(donor);

	   sv_magic(self_sv, 0, '~', 0, 0);
    	   mg = mg_find(self_sv, '~');
	   if (!mg)
		croak("Can't assign magic to Python::Object");
	    mg->mg_virtual = &vtbl_free_pyo;
            SvREADONLY(self_sv);
        }
        else
	   croak("Bad donor content");
     }
     else
	croak("Bad donor");


NewPyObjectX *
PyObject_GetAttr(o, attrname)
     PyObject *o
     SV *attrname
   PREINIT:
     dCTX;
     PyObject *py_attrname;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     PERL_LOCK;
     py_attrname = sv2pyo(attrname);
     PERL_UNLOCK;
     RETVAL = PyObject_GetAttr(o, py_attrname);
     Py_DECREF(py_attrname);
     if (!RETVAL)
         croak_on_py_exception();
   OUTPUT:
     RETVAL

int
PyObject_SetAttr(o, attrname, v)
     PyObject* o
     SV* attrname
     SV* v
   PREINIT:
     dCTX;
     PyObject *py_attrname;
     PyObject *py_v;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     PERL_LOCK;
     py_attrname = sv2pyo(attrname);
     py_v = sv2pyo(v);
     PERL_UNLOCK;
     RETVAL = PyObject_SetAttr(o, py_attrname, py_v);
     Py_DECREF(py_attrname);
     Py_DECREF(py_v);
     if (RETVAL == -1)
     	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL
     
int
PyObject_DelAttr(o, attrname)
     PyObject* o
     SV* attrname
   PREINIT:
     dCTX;
     PyObject *py_attrname;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     PERL_LOCK;
     py_attrname = sv2pyo(attrname);
     PERL_UNLOCK;
     RETVAL = PyObject_DelAttr(o, py_attrname);
     Py_DECREF(py_attrname);
     if (RETVAL == -1)
     	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyObject_HasAttr(o, attrname)
     PyObject* o
     SV* attrname
   PREINIT:
     dCTX;
     PyObject *py_attrname;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     PERL_LOCK;
     py_attrname = sv2pyo(attrname);
     PERL_UNLOCK;
     RETVAL = PyObject_HasAttr(o, py_attrname);
     Py_DECREF(py_attrname);
     ENTER_PERL;
   OUTPUT:
     RETVAL

NewPyObjectX *
PyObject_GetItem(o, key)
     PyObject *o
     SV *key
   PREINIT:
     dCTX;
     PyObject *py_key;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     if (PyList_Check(o) || PyTuple_Check(o)) {
	  int index;
	  ENTER_PERL;
	  index = SvIV(key);
	  ENTER_PYTHON;
	  RETVAL = PySequence_GetItem(o, index);
     }
     else {
	  PERL_LOCK;
          py_key = sv2pyo(key);
          PERL_UNLOCK;
          RETVAL = PyObject_GetItem(o, py_key);
          Py_DECREF(py_key);
     }
     if (!RETVAL)
     	croak_on_py_exception();
   OUTPUT:
     RETVAL

int
PyObject_SetItem(o, key, v)
     PyObject* o
     SV* key
     SV* v
   PREINIT:
     dCTX;
     PyObject *py_key;
     PyObject *py_v;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     PERL_LOCK;
     py_v   = sv2pyo(v);
     PERL_UNLOCK;
     if (PyList_Check(o) || PyTuple_Check(o)) {
	  int index;
	  ENTER_PERL;
	  index = SvIV(key);
	  ENTER_PYTHON;
	  RETVAL = PySequence_SetItem(o, index, py_v);
     }
     else {
          PERL_LOCK;
          py_key = sv2pyo(key);
          PERL_UNLOCK;
          RETVAL = PyObject_SetItem(o, py_key, py_v);
          Py_DECREF(py_key);
     }
     Py_DECREF(py_v);
     if (RETVAL == -1)
     	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyObject_DelItem(o, key)
     PyObject *o
     SV *key
   PREINIT:
     dCTX;
     PyObject *py_key;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     if (PyList_Check(o) || PyTuple_Check(o)) {
	  int index;
	  ENTER_PERL;
	  index = SvIV(key);
	  ENTER_PYTHON;
	  RETVAL = PySequence_DelItem(o, index);
     }
     else {
          PERL_LOCK;
          py_key = sv2pyo(key);
          PERL_UNLOCK;
          RETVAL = PyObject_DelItem(o, py_key);
          Py_DECREF(py_key);
     }
     if (RETVAL == -1)
     	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyObject_Compare(o1, o2)
     PyObject *o1
     PyObject *o2
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyObject_Compare(o1, o2);
     if (RETVAL == -1 && PyErr_Occurred())
	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyObject_Hash(o)
     PyObject *o
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyObject_Hash(o);
     if (RETVAL == -1)
	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

IV
id(o)
     PyObject *o
   CODE:
     ASSERT_LOCK_PERL;
     RETVAL = (IV)o;
   OUTPUT:
     RETVAL

int
PyObject_Length(o)
     PyObject *o
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyObject_Length(o);
     if (RETVAL == -1)
	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL


int
PyObject_IsTrue(o,...)
     PyObject *o
     # ... because bool overloading provide additional arguments
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyObject_IsTrue(o);
     ENTER_PERL;
   OUTPUT:
     RETVAL

NewPyObject *
PyObject_Type(o)
     PyObject *o
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyObject_Type(o);
     ENTER_PERL;
   OUTPUT:
     RETVAL

SV*
PyObject_Str(o,...)
     PyObject *o
     # ... because stringify overloading provide additional arguments
   ALIAS:
     Python::PyObject_Str  = 1
     Python::PyObject_Repr = 2
   PREINIT:
     dCTX;
     PyObject *str_o;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     str_o = (ix == 1) ? PyObject_Str(o) : PyObject_Repr(o);
     PERL_LOCK;
     if (str_o && PyString_Check(str_o)) {
	RETVAL = newSVpvn(PyString_AsString(str_o),
			  PyString_Size(str_o));	
     }
     else {
	RETVAL = newSV(0);
     }
     Py_XDECREF(str_o);
     PYTHON_UNLOCK;
     ASSERT_LOCK_PERL;
   OUTPUT:
     RETVAL

void
PyRun_SimpleString(str)
     char* str
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     if (PyRun_SimpleString(str) == -1) {
	/* There is no way to get at the python exception when using
	 * this entry point to the API
	 */
	ENTER_PERL;
	croak("PyRun_SimpleString failed");
     }
     ENTER_PERL;

NewPyObjectX *
eval(str,...)
     char* str
   ALIAS:
     Python::eval = 1
     Python::exec = 2
   PREINIT:
     dCTX;
     PyObject *globals = 0;
     PyObject *locals = 0;
   CODE:
     ENTER_PYTHON;
     if (items > 1) {
	globals = PerlPyObject_pyo(ST(1));
        if (items > 2) {
	    locals = PerlPyObject_pyo(ST(2));
	    if (items > 3) {
                ENTER_PERL;
		croak("Too many arguments");
            }
        }
     }
     if (!globals) {
	PyObject *m = PyImport_AddModule("__main__");
	if (m == NULL)
	    croak_on_py_exception();
	globals = PyModule_GetDict(m);
     }
     if (!locals)
        locals = globals;

     if (!PyDict_Check(locals) || !PyDict_Check(globals))
     {
	ENTER_PERL;
	croak("The 2nd and 3rd argument must be dictionaries");
     }

     if (PyDict_GetItemString(globals, "__builtins__") == NULL) {
	   if (PyDict_SetItemString(globals, "__builtins__",
			            PyEval_GetBuiltins()) != 0)
	       croak_on_py_exception();
     }

     RETVAL = PyRun_String(str, (ix == 1) ? Py_eval_input : Py_file_input,
	                   globals, locals);
     if (!RETVAL)
	croak_on_py_exception();
   OUTPUT:
     RETVAL
     

NewPyObjectX *
PyObject_CallObject(o, ...)
     PyObject *o
   PREINIT:
     dCTX;
     int i;
     PyObject *args = NULL;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     if (!PyCallable_Check(o)) {
	ENTER_PERL;
	croak("Can't call a non-callable object");
     }

     if (items > 1) {
         PERL_LOCK;
         args = PyTuple_New(items - 1);
         for (i = 1; i < items; i++) {
             PyTuple_SetItem(args, i-1, sv2pyo(ST(i)));
         }
         PERL_UNLOCK;
     }
     RETVAL = PyObject_CallObject(o, args);
     Py_XDECREF(args);
     if (!RETVAL)
     	croak_on_py_exception();
   OUTPUT:
     RETVAL

NewPyObjectX *
PyEval_CallObjectWithKeywords(o,...)
     PyObject *o
   PREINIT:
     dCTX;
     PyObject *alist = NULL;
     PyObject *kwdict = NULL;

     PyObject *t1 = NULL;
     PyObject *t2 = NULL;
   CODE:
     ASSERT_LOCK_PERL;
     if (items > 3) {
	croak("Too many arguments");
     }

     RETVAL = NULL;

     if (items >= 2) {
         /* make a tuple out of ST(1) */
	 alist = PerlPyObject_pyo_or_null(ST(1));
	 if (alist) {
	    ENTER_PYTHON;
	    if (!PyTuple_Check(alist)) {
		if (!PySequence_Check(alist)) {
		    PyErr_SetString(PyExc_TypeError,
				    "2nd argument must be a sequence");
	            goto done;
                }
		t1 = PySequence_Tuple(alist);
		if (t1 == NULL)
                    goto done;
		alist = t1;
	    }
	    ENTER_PERL;
         }
	 else {
            SV* sv = ST(1);
            if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
		AV* av = (AV*)SvRV(sv);
		int alen = av_len(av) + 1;
		int i;

		ENTER_PYTHON;
		t1 = PyTuple_New(alen);
		if (t1 == NULL)
		    goto done;

                ENTER_PERL;
		for (i = 0; i < items; i++) {
		    SV** svp;
                    ASSERT_LOCK_PERL;
		    svp = av_fetch(av, i, 0);
		    if (svp) {
		        PyObject *item;

                        PYTHON_LOCK;
                        item = sv2pyo(*svp);

                        PERL_UNLOCK;
     			PyTuple_SetItem(t1, i, item);

			ENTER_PERL;
                    }
		}
		alist = t1;
	    }
	    else if (SvOK(sv)) {  /* not an array */
		croak("2nd argument must be an array reference");
            }
         }
     }
     if (items == 3) {
        /* make a dict out of ST(2) */
	 kwdict = PerlPyObject_pyo_or_null(ST(2));
	 if (kwdict) {
	    ENTER_PYTHON;
	    if (!PyDict_Check(alist)) { 
            }
	    ENTER_PERL;
         }
	 else {
            SV* sv = ST(2);
            if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
		HV* hv = (HV*)SvRV(sv);
		HE* entry;

		ENTER_PYTHON;
                t2 =  PyDict_New();
		if (t2 == NULL)
		    goto done;

                ENTER_PERL;
		hv_iterinit(hv);
		while( (entry = hv_iternext(hv))) {
		    PyObject *key;
		    PyObject *val;

                    I32 klen;
                    char *kstr;
                    SV* val_sv;

                    ASSERT_LOCK_PERL;
                    kstr = hv_iterkey(entry, &klen);
                    val_sv = hv_iterval(hv, entry);

                    ENTER_PYTHON;
                    key = PyString_FromStringAndSize(kstr, klen);
                    if (key == NULL)
			goto done;

                    PERL_LOCK;
                    val = sv2pyo(val_sv);
                    PERL_UNLOCK;

		    if (PyDict_SetItem(t2, key, val) == -1)
			goto done;
                    ENTER_PERL;
                }
		kwdict = t2;
	    }
	    else if (SvOK(sv)) {  /* not a hash */
                ENTER_PYTHON;
		PyErr_SetString(PyExc_TypeError,
				"3rd argument must be a hash reference");
	        goto done;
            }
         }
     }

     ENTER_PYTHON;
     RETVAL = PyEval_CallObjectWithKeywords(o, alist, kwdict);
   done:
     Py_XDECREF(t1);
     Py_XDECREF(t2);
     if (!RETVAL)
	croak_on_py_exception();
   OUTPUT:
     RETVAL

NewPyObject *
PyImport_ImportModule(name)
     char* name
   PREINIT:
     dCTX;
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = PyImport_ImportModule(name);
     if (!RETVAL)
	croak_on_py_exception();
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyNumber_Check(o)
     SV* o
   PREINIT:
     dCTX;
     PyObject *pyo = PerlPyObject_pyo_or_null(o);
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = pyo ? PyNumber_Check(pyo) : 0;
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PySequence_Check(o)
     SV* o
   PREINIT:
     dCTX;
     PyObject *pyo = PerlPyObject_pyo_or_null(o);
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = pyo ? PySequence_Check(pyo) : 0;
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyMapping_Check(o)
     SV* o
   PREINIT:
     dCTX;
     PyObject *pyo = PerlPyObject_pyo_or_null(o);
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = pyo ? PyMapping_Check(pyo) : 0;
     ENTER_PERL;
   OUTPUT:
     RETVAL

int
PyCallable_Check(o)
     SV* o
   PREINIT:
     dCTX;
     PyObject *pyo = PerlPyObject_pyo_or_null(o);
   CODE:
     ASSERT_LOCK_PERL;
     ENTER_PYTHON;
     RETVAL = pyo ? PyCallable_Check(pyo) : 0;
     ENTER_PERL;
   OUTPUT:
     RETVAL


void
raise(type, value)
	SV* type
	SV* value
      PREINIT:
        dCTX;
	PyObject *type_pyo;
	PyObject *value_pyo;
      CODE:
        ASSERT_LOCK_PERL;
	PYTHON_LOCK;
	type_pyo = sv2pyo(type);
	value_pyo = sv2pyo(value);
	PERL_UNLOCK;
	PyErr_SetObject(type_pyo, value_pyo);
	croak_on_py_exception();

BOOT:
#ifdef BOOT_FROM_PERL
	Py_Initialize();
	initperl();
	{
	    dCTX;
	    PYTHON_UNLOCK;
	}
#endif


MODULE = Python::Object		PACKAGE = Python::Err

NewPyObject*
type(self)
	PerlPyErr *self
      ALIAS:
	Python::Err::type      = 1
	Python::Err::value     = 2
	Python::Err::traceback = 3
      PREINIT:
        dCTX;
      CODE:
        ASSERT_LOCK_PERL;
	switch (ix) {
	case 1:	RETVAL = self->type;      break;
	case 2:	RETVAL = self->value;     break;
	case 3:	RETVAL = self->traceback; break;
	default: croak("Unknown attribute (%d)", ix);
        }
        ENTER_PYTHON;
        Py_XINCREF(RETVAL);
        ENTER_PERL;
      OUTPUT:
	RETVAL

SV*
as_string(self,...)
	PerlPyErr *self
        # ... because stringify overloading provide additional arguments
      PREINIT:
        dCTX;
	PyObject *str;
      CODE:
        ASSERT_LOCK_PERL;
        ENTER_PYTHON;
	str = PyObject_Str(self->type);
        PERL_LOCK;
	RETVAL = newSVpv("", 0);
        if (str && PyString_Check(str)) {
	    sv_catpv(RETVAL, "python.");
            sv_catpv(RETVAL, PyString_AsString(str));
        }
        else
            sv_catpv(RETVAL, "python");
        Py_XDECREF(str);
        str = 0;
        PERL_UNLOCK;

        if (self->value &&
            (str = PyObject_Str(self->value)) &&
            PyString_Check(str))
        {
	    PERL_LOCK;
            sv_catpv(RETVAL, ": ");
            sv_catpv(RETVAL, PyString_AsString(str));
            PERL_UNLOCK;
        }
        Py_XDECREF(str);
        ENTER_PERL;
	if (*SvEND(RETVAL) != '\n')
	    sv_catpvn(RETVAL, "\n", 1);
      OUTPUT:
	RETVAL

int
as_bool(self,...)
	PerlPyErr *self
        # ... because bool overloading provide additional arguments
      CODE:
        ASSERT_LOCK_PERL;
	RETVAL = 1;
      OUTPUT:
        RETVAL

void
DESTROY(self)
	PerlPyErr *self
      PREINIT:
        dCTX;
      CODE:
	/* printf("Destructing Python::Err %p\n", self); */
	ASSERT_LOCK_PERL;
	ENTER_PYTHON;
	Py_XDECREF(self->type);
	Py_XDECREF(self->value);
	Py_XDECREF(self->traceback);
	ENTER_PERL;
	Safefree(self);
	ASSERT_LOCK_PERL;

SV*
Exception(...)
      ALIAS:
	Python::Err::Exception = 1
	Python::Err::StandardError = 2
	Python::Err::ArithmeticError = 3
	Python::Err::LookupError = 4
	Python::Err::AssertionError = 5
	Python::Err::AttributeError = 6
	Python::Err::EOFError = 7
	Python::Err::FloatingPointError = 8
	Python::Err::EnvironmentError = 9
	Python::Err::IOError = 10
	Python::Err::OSError = 11
	Python::Err::ImportError = 12
	Python::Err::IndexError = 13
	Python::Err::KeyError = 14
	Python::Err::KeyboardInterrupt = 15
	Python::Err::MemoryError = 16
	Python::Err::NameError = 17
	Python::Err::OverflowError = 18
	Python::Err::RuntimeError = 19
	Python::Err::NotImplementedError = 20
	Python::Err::SyntaxError = 21
	Python::Err::SystemError = 22
	Python::Err::SystemExit = 23
	Python::Err::TypeError = 24
	Python::Err::UnboundLocalError = 25
	Python::Err::UnicodeError = 26
	Python::Err::ValueError = 27
	Python::Err::ZeroDivisionError = 28
      PREINIT:
        dCTX;
	PyObject* e;
      CODE:
        ASSERT_LOCK_PERL;
        if (items > 1)
	    croak("Usage: Python::Err:Exception( [ OBJ ] )");
	switch (ix) {
	case  1: e = PyExc_Exception; break;
	case  2: e = PyExc_StandardError; break;
	case  3: e = PyExc_ArithmeticError; break;
	case  4: e = PyExc_LookupError; break;
	case  5: e = PyExc_AssertionError; break;
	case  6: e = PyExc_AttributeError; break;
	case  7: e = PyExc_EOFError; break;
	case  8: e = PyExc_FloatingPointError; break;
	case  9: e = PyExc_EnvironmentError; break;
	case 10: e = PyExc_IOError; break;
	case 11: e = PyExc_OSError; break;
	case 12: e = PyExc_ImportError; break;
	case 13: e = PyExc_IndexError; break;
	case 14: e = PyExc_KeyError; break;
	case 15: e = PyExc_KeyboardInterrupt; break;
	case 16: e = PyExc_MemoryError; break;
	case 17: e = PyExc_NameError; break;
	case 18: e = PyExc_OverflowError; break;
	case 19: e = PyExc_RuntimeError; break;
	case 20: e = PyExc_NotImplementedError; break;
	case 21: e = PyExc_SyntaxError; break;
	case 22: e = PyExc_SystemError; break;
	case 23: e = PyExc_SystemExit; break;
	case 24: e = PyExc_TypeError; break;
#if PY_MAJOR_VERSION >= 1 && PY_MINOR_VERSION >= 6
	case 25: e = PyExc_UnboundLocalError; break;
	case 26: e = PyExc_UnicodeError; break;
#endif
	case 27: e = PyExc_ValueError; break;
	case 28: e = PyExc_ZeroDivisionError; break;
	default: croak("Bad exception selector (%d)", ix); break;
	}
	if (items) {
            SV* argsv = ST(0);
	    PyObject* arg;
            if (SvROK(argsv) && sv_derived_from(argsv, "Python::Err")) {
	        arg = PerlPyErr_err(argsv)->type;
             }
             else {
		arg = PerlPyObject_pyo_or_null(argsv);
             }
            /* XXX should actually do a ISA test here */
	    RETVAL = boolSV(arg == e);
	}
	else {
	    PYTHON_LOCK;
	    RETVAL = newPerlPyObject_inc(e);
	    PYTHON_UNLOCK;
        }
	ASSERT_LOCK_PERL;
      OUTPUT:
	RETVAL


MODULE = Python::Object		PACKAGE = Python::Object
