/* Copyright 2000-2001 ActiveState
 *
 * This is a python extension module that embeds perl.
 */

#include <EXTERN.h>
#include <perl.h>
#include <Python.h>

#include "thrd_ctx.h"
#include "perlmodule.h"
#include "svrv_object.h"
#include "lang_lock.h"
#include "lang_map.h"

static PyObject *PerlError;
extern void xs_init (pTHXo);

#ifdef WIN32
SV* (*pnewPerlPyObject_inc)(PyObject *py);
#endif

#ifdef MULTI_PERL

PerlInterpreter *
new_perl(void)
{
    PerlInterpreter *p;
    char *embedding[] = { "", "-mPython::Object", "-e", "0", NULL };

    p = perl_alloc();
#if 0
    fprintf(stderr, "creating new perl %p\n", p); fflush(stderr);
#endif
    perl_construct(p);
#ifdef BOOT_FROM_PERL
    perl_parse(p, 0, 4, embedding, NULL);
#else
    perl_parse(p, xs_init, 4, embedding, NULL);
#endif
    perl_run(p);

#ifdef WIN32
    /* Object.dll will have been loaded by Perl now, so resolve its exported
     * functions explicitly.  This is needed so that we don't load two
     * independent copies of Object.dll, once via perl56.dll and another
     * time via perl.pyd.
     * XXX Other platforms probably need similar treatment. */
    {
	HMODULE m = GetModuleHandle("Object.dll");
	if (m) {
	    pnewPerlPyObject_inc = (SV* (*)(PyObject *py))GetProcAddress(m, "newPerlPyObject_inc");
	}
	else
	    return NULL;
    }
#endif

    return p;
}

void
free_perl(PerlInterpreter *p)
{
#if 0
    fprintf(stderr, "destructing perl %p\n", p); fflush(stderr);
#endif
    perl_destruct(p);
    perl_free(p);
    PERL_SET_CONTEXT(0);
}

#else /* MULTI_PERL */

#ifdef USE_ITHREADS
PerlInterpreter *main_perl = 0;
#endif /* USE_ITHREADS */

#endif /* MULTI_PERL */

#include "Python-Object/PerlPyErr.h"


void
propagate_errsv()
{
    STRLEN n_a;
    dCTXP;

    ASSERT_LOCK_BOTH;

    if (SvROK(ERRSV) && sv_derived_from(ERRSV, "Python::Err")) {
	IV tmp = SvIV((SV*)SvRV(ERRSV));
	PerlPyErr *py_err = INT2PTR(PerlPyErr *,tmp);
    
	/* We want to keep the Exception object valid also after restore,
	 * so increment reference counts first.
	 */
	Py_XINCREF(py_err->type);
	Py_XINCREF(py_err->value);
	Py_XINCREF(py_err->traceback);

	PyErr_Restore(py_err->type, py_err->value, py_err->traceback);
    }
    else {
	char *s;
	PYTHON_UNLOCK;
	s = SvPV(ERRSV, n_a);
	ENTER_PYTHON;
	PyErr_SetString(PerlError, s);
	PERL_LOCK;
    }

    ASSERT_LOCK_BOTH;
}


PyObject *
call_perl(char *method, SV* obj, I32 gimme,
	  PyObject *args,
	  PyObject *keywds)
{
    PyObject *m_obj = 0;
    SV* func = 0;
    int argfirst = 0;
    int i, arglen;
    int ret_count;
    PyObject *ret_val;
    int errsv;
    dCTXP;
    dSP;   /* perl stack */

    ASSERT_LOCK_PYTHON;
    SET_CUR_PERL;

    assert(PyTuple_Check(args));
    arglen = PyTuple_Size(args);

    if (method) {
	if (!*method) {
	    if (arglen < (obj ? 1 : 2)) {
		PyErr_SetString(PerlError, "Need both a method name and a object/class");
		ASSERT_LOCK_PYTHON;
		return NULL;
	    }
	    m_obj = PyTuple_GetItem(args, 0);
	    m_obj = PyObject_Str(m_obj); /* need decrement refcount after call */
	    assert(PyString_Check(m_obj));
	    method = PyString_AsString(m_obj);
	    argfirst = 1;
	}
	else if (!obj && !arglen) {
	    PyErr_SetString(PerlError, "Missing object/class");
	    ASSERT_LOCK_PYTHON;
	    return NULL;
	}
    }
    else if (obj) {
	func = obj;
	obj = 0;
    }
    else {
	if (arglen < 1) {
	    PyErr_SetString(PerlError, "Missing function argument");
	    ASSERT_LOCK_PYTHON;
	    return NULL;
	}
	PERL_LOCK;
	func = pyo2sv(PyTuple_GetItem(args, 0));
	argfirst = 1;
	PERL_UNLOCK;
    }

    if (keywds) {
	PyObject *o;
	assert(PyDict_Check(keywds));

	if ( (o = PyDict_GetItemString(keywds, "__wantarray__"))) {
	    gimme = (o == Py_None)     ? G_VOID :
		    PyObject_IsTrue(o) ? G_ARRAY :
		                         G_SCALAR;
	}
    }

    /* At this point we should know we have enough arguments to actually
     * call out, so we start setting up the stack
     */

    PERL_LOCK;
  
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    if (obj)
	XPUSHs(obj);

    for (i = argfirst; i < arglen; i++) {
	XPUSHs(sv_2mortal(pyo2sv(PyTuple_GET_ITEM(args, i))));
    }

    /* push keyword arguments too if there are any */
    if (keywds) {
	int pos = 0;
	PyObject *key;
	char *key_str;
	PyObject *val;
	while (PyDict_Next(keywds, &pos, &key, &val)) {
	    assert(PyString_Check(key));
	    key_str = PyString_AsString(key);
      
	    if (key_str[0] == '_' && key_str[1] == '_')
		continue;

	    XPUSHs(sv_2mortal(newSVpv(key_str, 0)));
	    XPUSHs(sv_2mortal(pyo2sv(val)));
	}
    }

    PUTBACK;

    PYTHON_UNLOCK;

    if (method)
	ret_count = perl_call_method(method, gimme | G_EVAL);
    else {
	ret_count = perl_call_sv(func, gimme | G_EVAL);
	if (argfirst == 1)
	    SvREFCNT_dec(func);
    }
    errsv = SvTRUE(ERRSV);

    SPAGAIN;

    ENTER_PYTHON;
    PERL_LOCK;

    if (errsv) {
	while (ret_count--)
	    POPs;
	propagate_errsv();
	ret_val = NULL;
    }
    else {
	if (gimme == G_ARRAY || ret_count > 1) {
	    ret_val = PyTuple_New(ret_count);
	    for (i = 0; i < ret_count; i++)
		PyTuple_SET_ITEM(ret_val, ret_count - 1 - i, sv2pyo(POPs));
	}
	else if (ret_count == 1) {
	    ret_val = sv2pyo(POPs);
	}
	else {
	    ret_val = Py_BuildValue("");  /* None */
	}
    }

    PYTHON_UNLOCK;

    PUTBACK;
    FREETMPS;
    LEAVE;

    ENTER_PYTHON;
    Py_XDECREF(m_obj);

    ASSERT_LOCK_PYTHON;
    return ret_val;
}


#ifdef MULTI_PERL

#include "opcode.c"

static PyObject *
safecall(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    char *root;
    char *op_mask;
    int op_mask_len;
    char op_mask_buf[OP_MASK_BUF_SIZE];
    PyObject *realargs;
    PyObject *ret;
    GV *gv;
    dCTXP;

    if (!PyArg_ParseTuple(args, "ss#O!:safecall",
			  &root, &op_mask, &op_mask_len,
			  &PyTuple_Type, &realargs))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;
    /* This code is adapted from Opcode::_safe_call_sv() */

    ENTER;
    opmask_addlocal(aTHX_ op_mask, op_mask_len, op_mask_buf);

    save_aptr(&PL_endav);
    PL_endav = (AV*)sv_2mortal((SV*)newAV()); /* ignore END blocks for now */

    save_hptr(&PL_defstash);		/* save current default stash	*/
    save_hptr(&PL_curstash);
    /* the assignment to global defstash changes our sense of 'main'	*/

    if (ctx->root_stash) {
	PL_defstash = PL_curstash = ctx->root_stash;
    }
    else {
	save_hptr(&ctx->root_stash);
	ctx->root_stash = PL_defstash;
    }

    PL_defstash = gv_stashpv(root, GV_ADDWARN); /* should exist already	*/
    PL_curstash = PL_defstash;

    /* defstash must itself contain a main:: so we'll add that now	*/
    /* take care with the ref counts (was cause of long standing bug)	*/
    /* XXX I'm still not sure if this is right, GV_ADDWARN should warn!	*/
    gv = gv_fetchpv("main::", GV_ADDWARN, SVt_PVHV);
    sv_free((SV*)GvHV(gv));
    GvHV(gv) = (HV*)SvREFCNT_inc(PL_defstash);

    /* %INC must be clean for use/require in compartment */
    save_hash(PL_incgv);
    GvHV(PL_incgv) = (HV*)SvREFCNT_inc(GvHV(gv_HVadd(gv_fetchpv("INC",TRUE,SVt_PVHV))));
    
    ENTER_PYTHON; /* just so call_perl can change it back :-( */
    ret = call_perl(0, 0, G_SCALAR, realargs, keywds);

    ENTER_PERL;
    LEAVE;

    ENTER_PYTHON;
    return ret;
}

static void
restore_unsafe_env(thread_ctx *ctx)
{
    PerlInterpreter *my_perl = ctx->perl->my_perl;

    save_hptr(&PL_defstash);
    save_hptr(&PL_curstash);
    save_hptr(&ctx->root_stash);
    PL_defstash = PL_curstash = ctx->root_stash;
    ctx->root_stash = 0;

    /* Remove opmask */
    SAVEVPTR(PL_op_mask);
    PL_op_mask = 0;
}


static PyObject *
unsafe_call_perl(char *method, SV* obj, I32 gimme,
		 PyObject *args,
		 PyObject *keywds)
{
    dCTXP;
    PyObject *res;
    int leave_needed = 0;
    if (ctx->root_stash) {
	/* reenter from safe, set back root */
	ENTER;
	leave_needed++;
	restore_unsafe_env(ctx);
    }
    res = call_perl(method, obj, gimme, args, keywds);
    if (leave_needed)
	LEAVE;  /* restore safe env */
    return res;
}

#define CALL_PERL          unsafe_call_perl
#define RESTORE_UNSAFE_ENV if (ctx->root_stash) restore_unsafe_env(ctx)
#else /* MULTI_PERL */

#define CALL_PERL          call_perl
#define RESTORE_UNSAFE_ENV /*empty*/

#endif /* MULTI_PERL */


static PyObject *
call(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    return CALL_PERL(0, 0, G_SCALAR, args, keywds);
}


static PyObject *
call_tuple(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    return CALL_PERL(0, 0, G_ARRAY, args, keywds);
}


static PyObject *
callm(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    return CALL_PERL("", 0, G_SCALAR, args, keywds);
}


static PyObject *
callm_tuple(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    return CALL_PERL("", 0, G_ARRAY, args, keywds);
}


static PyObject *
eval(self, args)
     PyObject *self;
     PyObject *args;
{
    char* code;
    SV* res_sv;
    PyObject* res_pyo;
    int errsv;
    dCTXP;

    ASSERT_LOCK_PYTHON;
  
    if (!PyArg_ParseTuple(args, "s:perl.eval", &code))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    ENTER;
    SAVETMPS;
    RESTORE_UNSAFE_ENV;

    res_sv = perl_eval_pv(code, FALSE);
    errsv = SvTRUE(ERRSV);
  
    ENTER_PYTHON;
    PERL_LOCK;

    if (errsv) {
	propagate_errsv();
	res_pyo = NULL;
    }
    else {
	res_pyo = sv2pyo(res_sv);
    }

    PYTHON_UNLOCK;

    FREETMPS;
    LEAVE;

    ENTER_PYTHON;
    return res_pyo;
}


static PyObject *
require(self, args)
     PyObject *self;
     PyObject *args;
{
    char *module;
    SV *code;
    SV *res_sv;
    PyObject *res_pyo;
    STRLEN n_a;
    int errsv;
    dCTXP;

    ASSERT_LOCK_PYTHON;
  
    if (!PyArg_ParseTuple(args, "s:perl.require", &module))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    ENTER;
    SAVETMPS;
    RESTORE_UNSAFE_ENV;

    code = newSVpv("require ", 0);
    sv_catpv(code, module);

    res_sv = perl_eval_pv(SvPVx(code, n_a), FALSE);
    SvREFCNT_dec(code);
    errsv = SvTRUE(ERRSV);

    ENTER_PYTHON;
    PERL_LOCK;

    if (errsv) {
	propagate_errsv();
	res_pyo = NULL;
    }
    else {
	res_pyo = sv2pyo(res_sv);
    }

    PYTHON_UNLOCK;

    FREETMPS;
    LEAVE;

    ENTER_PYTHON;
    return res_pyo;
}


static PyObject *
defined(self, args)
     PyObject *self;
     PyObject *args;
{
    char *name;
    char type;
    SV* sv;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    if (!PyArg_ParseTuple(args, "s:perl.defined", &name))
	return NULL;
    ENTER_PERL;
    SET_CUR_PERL;

    ENTER;
    RESTORE_UNSAFE_ENV;

    if (isIDFIRST(*name)) {
	type = '&';
    }
    else {
	type = *name;
	name++;
    }

    if (*name) {
	switch (type) {
	case '$': sv =      perl_get_sv(name, 0); break;
	case '@': sv = (SV*)perl_get_av(name, 0); break;
	case '%': sv = (SV*)perl_get_hv(name, 0); break;
	case '&': sv = (SV*)perl_get_cv(name, 0); break;
	default:
	    LEAVE;
	    ENTER_PYTHON;
	    PyErr_Format(PerlError, "Bad type spec '%c'", type);
	    return NULL;
	}
    }
    else {
	LEAVE;
	ENTER_PYTHON;
	PyErr_Format(PerlError, "Missing identifier name");
	return NULL;
    }
    LEAVE;
    ENTER_PYTHON;
    return Py_BuildValue("i", (sv != 0));
}


static PyObject *
get_ref(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    char *name;
    int create = 0;
    char type;
    SV* sv;
    PyObject* pyo;
    static char *kwlist[] = { "name", "create", NULL };
    dCTXP;

    ASSERT_LOCK_PYTHON;

    /* Establish 'name' and 'create' */
    if (!PyArg_ParseTupleAndKeywords(args, keywds, "s|i:perl.get_ref", kwlist,
				     &name, &create))
	return NULL;

    PERL_LOCK;
    SET_CUR_PERL;

    ENTER;
    RESTORE_UNSAFE_ENV;

    /* We assume that none of the stuff below can trigger perl code to
     * start running, so it is safe to hold both locks while doing this work.
     */

    if (isIDFIRST(*name)) {
	type = '&';
    }
    else {
	type = *name;
	name++;
    }

    if (*name) {
	switch (type) {
	case '$': sv =      perl_get_sv(name, create); break;
	case '@': sv = (SV*)perl_get_av(name, create); break;
	case '%': sv = (SV*)perl_get_hv(name, create); break;
	case '&': sv = (SV*)perl_get_cv(name, create); break;
	default:
	    LEAVE;
	    PERL_UNLOCK;
	    PyErr_Format(PerlError, "Bad type spec '%c'", type);
	    return NULL;
	}
	if (!sv) {
	    LEAVE;
	    PERL_UNLOCK;
	    PyErr_Format(PerlError, "No perl object named %s", name);
	    return NULL;
	}
	SvREFCNT_inc(sv);
    }
    else {
	switch (type) {
	case '$': sv =      newSV(0); break;
	case '@': sv = (SV*)newAV();  break;
	case '%': sv = (SV*)newHV();  break;
	default:
	    LEAVE;
	    PERL_UNLOCK;
	    PyErr_Format(PerlError, "Bad type spec '%c'", type);
	    return NULL;
	}
    }

    sv = newRV_noinc(sv);
    pyo = PySVRV_New(sv);
    SvREFCNT_dec(sv);  /* since PySVRV_New incremented it */
    LEAVE;

    PERL_UNLOCK;
    ASSERT_LOCK_PYTHON;

    return pyo;
}


static PyObject *
array(self, args, keywds)
     PyObject *self;
     PyObject *args;
     PyObject *keywds;
{
    PyObject *o;
    int n, i;
    AV* av;
    SV* sv;
    PyObject *pyo;  /* return value */
    dCTXP;

    ASSERT_LOCK_PYTHON;

    /* Takes any sequence object and turn it into an perl array */
    if (!PyArg_ParseTuple(args, "O:perl.array", &o))
	return NULL;

    if (!PySequence_Check(o)) {
	PyErr_SetString(PyExc_TypeError, "perl.array() argument must be a sequence");
	return NULL;
    }

    n = PySequence_Length(o);
    if (n < 0)
	return NULL;

    PERL_LOCK;
    SET_CUR_PERL;

    av = newAV();
    if (n) {
	av_extend(av, n-1);
	i = 0;

	for (i = 0;; i++) {
	    PyObject *item;

	    PERL_UNLOCK;
	    item = PySequence_GetItem(o, i);
	    PERL_LOCK;

	    if (item) {
		SV* item_sv = pyo2sv(item);
		if (!av_store(av, i, item_sv)) {
		    SvREFCNT_dec(item_sv);
		    SvREFCNT_dec(av);
		    PERL_UNLOCK;
		    PyErr_SetString(PyExc_RuntimeError, "av_store failed");
		    ASSERT_LOCK_PYTHON;
		    return NULL;
		}
	    }
	    else {
		if (PyErr_ExceptionMatches(PyExc_IndexError)) {
		    PyErr_Clear();
		    break;
		}
		/* Something else bad happened */
		SvREFCNT_dec(av);
		PERL_UNLOCK;
		ASSERT_LOCK_PYTHON;
		return NULL;
	    }
	}
    }

    sv = newRV_inc((SV*)av);
    pyo = PySVRV_New(sv);
    SvREFCNT_dec(sv);  /* since PySVRV_New incremented it */

    PERL_UNLOCK;

    ASSERT_LOCK_PYTHON;
    return pyo;
}

static PyMethodDef PerlMethods[] = {
    { "call",        call,        METH_VARARGS|METH_KEYWORDS},
    { "call_tuple",  call_tuple,  METH_VARARGS|METH_KEYWORDS},
    { "callm",       callm,       METH_VARARGS|METH_KEYWORDS},
    { "callm_tuple", callm_tuple, METH_VARARGS|METH_KEYWORDS},
#ifdef MULTI_PERL
    { "safecall",    safecall,    METH_VARARGS|METH_KEYWORDS},
#endif
    { "eval",        eval,        METH_VARARGS},
    { "require",     require,     METH_VARARGS},
    { "defined",     defined,     METH_VARARGS},
    { "get_ref",     get_ref,     METH_VARARGS|METH_KEYWORDS},
    { "array",       array,       METH_VARARGS},
    { NULL, NULL } /* Sentinel */
};


void
#ifdef DL_HACK
initperl2()
#else
initperl()
#endif
{
    PyObject *m, *d;
#ifndef MULTI_PERL
    char *embedding[] = { "", "-mPython::Object", "-e", "0" };
#if !defined(USE_ITHREADS)
    PerlInterpreter *main_perl;
#endif

    main_perl = perl_alloc();
    perl_construct(main_perl);
    perl_parse(main_perl, xs_init, 4, embedding, NULL);
    perl_run(main_perl);

    fake_inittry();
#else
    thrd_ctx_init();
#endif /* MULTI_PERL */

#ifdef DO_THREAD
    lang_lock_init();
#endif

    /* XXX what need to be done if this stuff is used to embed python
     * in perl?  Should we also destruct my_perl?  A good idea if
     * python itself was embedded before we imported perl.
     */

    m = Py_InitModule("perl", PerlMethods);
    d = PyModule_GetDict(m);
    PerlError = PyErr_NewException("perl.PerlError", NULL, NULL);
    PyDict_SetItemString(d, "PerlError", PerlError);
#ifdef MULTI_PERL
    PyDict_SetItemString(d, "MULTI_PERL", PyInt_FromLong(1));
#else
    PyDict_SetItemString(d, "MULTI_PERL", PyInt_FromLong(0));
#endif
}
