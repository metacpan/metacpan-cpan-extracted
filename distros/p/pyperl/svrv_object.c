/* Copyright 2000-2001 ActiveState
 *
 * svrv_objects encapsulate a perl SvRV().
 */

#include <EXTERN.h>
#include <perl.h>
#include <Python.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "thrd_ctx.h"
#include "svrv_object.h"
#include "perlmodule.h"
#include "lang_lock.h"
#include "lang_map.h"
#include "try_perlapi.h"

#ifdef MULTI_PERL
static int
owned_by(PySVRV *self, refcounted_perl *my_perl)
{
    if (self->owned_by != my_perl) {
	PyErr_SetString(PyExc_ValueError,
			"perl reference accessed in wrong thread");
	return 0;
    }
    return 1;
}

#define CHECK_OWNED(ret) do { \
                            ASSERT_LOCK_PYTHON; \
                            if (!owned_by(self, ctx->perl)) \
                                return (ret); \
                         } while (0)

#define CHECK_OWNED_PY  CHECK_OWNED((PyObject*)NULL)
#define CHECK_OWNED_INT CHECK_OWNED(-1)



#else /* MULTI_PERL */

#define CHECK_OWNED     /* empty */
#define CHECK_OWNED_PY  /* empty */
#define CHECK_OWNED_INT /* empty */

#endif /* MULTI_PERL */


PyObject*
PySVRV_New(SV* rv)
{
	dCTXP;
    PySVRV *self;
    ASSERT_LOCK_BOTH;
    self = PyObject_NEW(PySVRV, &SVRVtype);
    if (self == NULL)
	return NULL;
    self->rv = SvREFCNT_inc(rv);
#ifdef MULTI_PERL
	self->owned_by = ctx->perl;
	ctx->perl->refcnt++;
#endif
    self->methodname = NULL;
    self->gimme = G_SCALAR;
    /* printf("created svrv object %p\n", self); */
    return (PyObject*)self;
}


static void
pysvrv_dealloc(PySVRV *self)
{
    /* printf("dead svrv object %p\n", self); */
    dCTXP;
#ifdef MULTI_PERL
    PerlInterpreter *old_perl = 0;
    if (my_perl != self->owned_by->my_perl) {
	old_perl = my_perl;
	my_perl = self->owned_by->my_perl;
	PERL_SET_CONTEXT(my_perl);
    }
#endif

    ASSERT_LOCK_PYTHON;
    ENTER_PERL;
    SvREFCNT_dec(self->rv);
    Safefree(self->methodname);

#ifdef MULTI_PERL
    if (old_perl)
	PERL_SET_CONTEXT(old_perl);

    if (--self->owned_by->refcnt == 0) {
	if (self->owned_by->thread_done) {
	    free_perl(self->owned_by->my_perl);
	    self->owned_by->my_perl = 0;
	    ENTER_PYTHON;
	    PyMem_Free((char*)(self->owned_by));
	    ENTER_PERL;
	}
    }
    self->owned_by = 0;
#endif

    ENTER_PYTHON;
#if PY_MAJOR_VERSION >= 1 && PY_MINOR_VERSION >= 6
    PyObject_DEL(self);
#else
    PyMem_DEL(self);
#endif
    ASSERT_LOCK_PYTHON;
}


static PyObject*
pysvrv_has_key(PySVRV *self, PyObject *args)
{
    char *key;
    int keylen;
    int exists;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "s#:has_key", &key, &keylen))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);
    exists = hv_exists((HV*)SvRV(self->rv), key, keylen);

    ENTER_PYTHON;
    return PyInt_FromLong(exists);
}


static PyObject*
do_hash_kv(HV* hv, bool do_keys, bool do_values)
{
    /* assumes we have the python lock only on entry */
    register HE *entry;
    register PyObject* list;
    int i;
    int len;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    assert(do_keys || do_values);

    ENTER_PERL;
    SET_CUR_PERL;
    len = HvKEYS(hv);
  
    ENTER_PYTHON;
    list = PyList_New(len);
    if (list == NULL) {
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    ENTER_PERL;
    i = 0;
    hv_iterinit(hv);
    while ( (entry = hv_iternext(hv))) {
	PyObject *k;
	if (do_keys) {
	    I32 klen;
	    char *kstr = hv_iterkey(entry, &klen);
	    ENTER_PYTHON;
	    k = PyString_FromStringAndSize(kstr, klen);
	    if (k == NULL)
		goto FAIL;
	    ENTER_PERL;
	}
	if (do_values) {
	    SV* val_sv = hv_iterval(hv, entry);
	    PyObject *v;

	    ENTER_PYTHON;
	    PERL_LOCK;
	    v = sv2pyo(val_sv);
	    PERL_UNLOCK;
	    if (do_keys) {
		PyObject *t = PyTuple_New(2);
		if (t == NULL) {
		    if (do_keys) Py_DECREF(k);
		    goto FAIL;
		}
		/* These can't fail :-) */
		PyTuple_SetItem(t, 0, k);
		PyTuple_SetItem(t, 1, v);
		v = t;
	    }
	    if (PyList_SetItem(list, i, v) == -1) {
		Py_DECREF(v);
		goto FAIL;
	    }
	    ENTER_PERL;
	}
	else if (PyList_SetItem(list, i, k) == -1) {
	    ENTER_PYTHON;
	    Py_DECREF(k);
	    goto FAIL;
	};
	i++;
    }

    ENTER_PYTHON;
    return list;

FAIL:
    Py_DECREF(list);
    ASSERT_LOCK_PYTHON;
    return NULL;
}

static PyObject*
pysvrv_keys(PySVRV *self, PyObject *args)
{
    dCTXP;
    SET_CUR_PERL;
    CHECK_OWNED_PY;

    ASSERT_LOCK_PYTHON;
    if (!PyArg_NoArgs(args))
	return NULL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);
    return do_hash_kv((HV*)SvRV(self->rv), TRUE, FALSE);
}

static PyObject*
pysvrv_values(PySVRV *self, PyObject *args)
{ 
    dCTXP;
    SET_CUR_PERL;
    CHECK_OWNED_PY;

    ASSERT_LOCK_PYTHON;
    if (!PyArg_NoArgs(args))
	return NULL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);
    return do_hash_kv((HV*)SvRV(self->rv), FALSE, TRUE);
}

static PyObject*
pysvrv_items(PySVRV *self, PyObject *args)
{
#ifdef DEBUGGING
    dCTXP;
    SET_CUR_PERL;
#endif
    ASSERT_LOCK_PYTHON;
    if (!PyArg_NoArgs(args))
	return NULL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);
    return do_hash_kv((HV*)SvRV(self->rv), TRUE, TRUE);
}

static PyObject*
pysvrv_update(PySVRV *self, PyObject *args)
{
    PyObject *o;
    PyObject *items;
    int i;
    PyObject *elem;
    HV* hv;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "O:update", &o))
	goto FAIL;

    if (!PyMapping_Check(o)) {
	PyErr_SetString(PyExc_TypeError,
			"hash.update() argument must be a mapping object");
	goto FAIL;
    }

    items = PyMapping_Items(o);
    if (items == NULL)
	goto FAIL;

    if (!PyList_Check(items)) {
	Py_DECREF(items);
	PyErr_SetString(PyExc_SystemError,
			"PyMapping_Items did not return a list");
    }

    ENTER_PERL;
    SET_CUR_PERL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);

    hv = (HV*)SvRV(self->rv);
    ENTER_PYTHON;

    for (i = 0; (elem = PyList_GetItem(items, i)); i++) {
	PyObject* key;
	PyObject* val;
	SV* key_sv;
	SV* val_sv;

	ASSERT_LOCK_PYTHON;
	if (!PySequence_Check(elem))
	    continue;
	key = PySequence_GetItem(elem, 0);
	if (!key) {
	    PyErr_Clear();
	    continue;
	}
	val = PySequence_GetItem(elem, 1);
	if (!val) {
	    PyErr_Clear();
	    continue;
	}

	PERL_LOCK;
	key_sv = pyo2sv(key);
	val_sv = pyo2sv(val);
	PYTHON_UNLOCK;

	if (!hv_store_ent(hv, key_sv, val_sv, 0))
	    SvREFCNT_dec(val_sv);
	SvREFCNT_dec(key_sv);
	ENTER_PYTHON;
    }
    PyErr_Clear();  /* index error */
    Py_DECREF(items);

    ASSERT_LOCK_PYTHON;
    Py_INCREF(Py_None);
    return Py_None;

FAIL:
    ASSERT_LOCK_PYTHON;
    return NULL;
}

static PyObject*
pysvrv_clear(PySVRV *self, PyObject *args)
{
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_NoArgs(args))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);
    hv_clear((HV*)SvRV(self->rv));

    ENTER_PYTHON;
    Py_INCREF(Py_None);
    return Py_None;
}

static PyObject*
pysvrv_copy(PySVRV *self, PyObject *args)
{
    HV* hv;
    HV* new_hv;
    HE* entry;
    SV* sv;
    PyObject *pyo;
    dCTXP;


    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_NoArgs(args))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);
    hv = (HV*)SvRV(self->rv);

    new_hv = newHV();
    hv_iterinit(hv);
    while ( (entry = hv_iternext(hv))) {
	sv = newSVsv(HeVAL(entry));
	if (!hv_store_ent(new_hv, hv_iterkeysv(entry), sv, 0))
	    SvREFCNT_dec(sv);
    }

    sv = newRV_noinc((SV*)new_hv);

    ENTER_PYTHON;
    PERL_LOCK;
    pyo = PySVRV_New(sv);
    SvREFCNT_dec(sv);  /* since PySVRV_New incremented it */
    PERL_UNLOCK;

    ASSERT_LOCK_PYTHON;
    return pyo;
}

static PyObject*
pysvrv_get(PySVRV *self, PyObject *args)
{
    char *key;
    int keylen;
    PyObject *failobj = Py_None;
    SV** svp;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "s#|O:get", &key, &keylen, &failobj))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVHV);

    svp = hv_fetch((HV*)SvRV(self->rv), key, keylen, 0);

    ENTER_PYTHON;
    if (svp) {
	PyObject *tmp;
	PERL_LOCK;
	tmp = sv2pyo(*svp);
	PERL_UNLOCK;
	return tmp;
    }

    Py_INCREF(failobj);
    ASSERT_LOCK_PYTHON;
    return failobj;
}



/* The following function as adapted from Larry Wall's pp_splice in
 * the perl source.  If will remove len elements at offset and
 * make room for newlen new elements by filling the space with &sv_undef.
 */
static int
array_splice(AV* av, I32 offset, I32 len, I32 newlen)
{
    /* This function assumes that we hold the perl lock only, when it is
     * called.  On normal return it will not change lock status, but on
     * errors it swith to python lock mode, set execption state and return -1.
     */

    I32 asize;
    I32 diff, after, i;
    SV **src;
    SV **dst;
    dCTXP;

    ASSERT_LOCK_PERL;
    SET_CUR_PERL;
/* #define SPLICE_DEBUG  /* */
    asize = av_len(av) + 1;
    if (offset < 0)
	offset += asize;
    if (offset < 0 || offset > asize) {
	ENTER_PYTHON;
	PyErr_SetString(PyExc_IndexError, "perl array index out of range");
	return -1;
    }

    if (len < 0) {
	len += asize - offset;
	if (len < 0)
	    len = 0;
    }

    if (newlen < 0) {
	ENTER_PYTHON;
	PyErr_BadInternalCall();
	return -1;
    }

    after = asize - offset - len;
    if (after < 0) {
	len += after;
	after = 0;
	if (!AvALLOC(av))
	    av_extend(av, 0);
    }
    
    diff = newlen - len;
    if (newlen && !AvREAL(av) && AvREIFY(av))
	av_reify(av);

#ifdef SPLICE_DEBUG
    printf("splice(offset=%d, len=%d, diff=%d, after=%d, fill=%d, max=%d, pre=%d)\n",
	   offset, len, diff, after, AvFILLp(av), AvMAX(av), AvARRAY(av) - AvALLOC(av));
#endif

    /* free old stuff */
    src = &AvARRAY(av)[offset];
    for (i = len; i; i--) {
#ifdef SPLICE_DEBUG
	printf("   free #%d\n", src - AvARRAY(av));
#endif
	SvREFCNT_dec(*src);
	*src = &PL_sv_undef;
	src++;
    }
  
    if (diff < 0) {                       /* shrinking the area */
	AvFILLp(av) += diff;
	if (offset < after) {		/* easier to pull up */
	    if (offset)			/* esp. if nothing to pull */
		Move(AvARRAY(av), AvARRAY(av)-diff, offset, SV*);
	    SvPVX(av) = (char*)(AvARRAY(av) - diff);
	    AvMAX(av) += diff;
	    dst = AvARRAY(av) + diff;
	}
	else {
	    if (after) {			/* anything to pull down? */
		src = AvARRAY(av) + offset + len;
		dst = src + diff;		/* diff is negative */
		Move(src, dst, after, SV*);
	    }
	    dst = &AvARRAY(av)[AvFILLp(av)+1];
	}
	i = -diff;
    }
    else if (diff > 0) {				/* expanding */
	/* push up or down? */
	if (offset < after && diff <= AvARRAY(av) - AvALLOC(av)) {
	    if (offset) {
		src = AvARRAY(av);
		dst = src - diff;
		Move(src, dst, offset, SV*);
	    }
	    SvPVX(av) = (char*)(AvARRAY(av) - diff);  /* diff is positive */
	    AvMAX(av) += diff;
	    AvFILLp(av) += diff;
	    dst = AvARRAY(av) + offset;
	}
	else {
	    if (AvFILLp(av) + diff > AvMAX(av))	/* oh, well */
		av_extend(av, AvFILLp(av) + diff);
	    AvFILLp(av) += diff;
	    if (after) {
		src = AvARRAY(av) + offset + len;
		dst = src + diff;
		Move(src, dst, after, SV*);
		dst = src;
	    }
	    else 
		dst = AvARRAY(av) + AvFILLp(av);
	}
	i = diff;
    }

    /* clear moved away area */
    while (i) {
	dst[--i] = &PL_sv_undef;
#ifdef SPLICE_DEBUG
	printf("   clear #%d\n", dst - AvARRAY(av) + i);
#endif
    }

#ifdef SPLICE_DEBUG
    printf("   -->(fill=%d, max=%d, pre=%d)\n",
	   AvFILLp(av), AvMAX(av), AvARRAY(av) - AvALLOC(av));
#endif

    ASSERT_LOCK_PERL;
    return 0;
}


static PyObject *
array_item(AV* av, I32 index)
{
    /* Assumes python lock */
    SV** svp;
    I32 size;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    ENTER_PERL;
    SET_CUR_PERL;
    svp = av_fetch(av, index, 0);
    if (svp) {
	PyObject *tmp;
	int status = try_SvGETMAGIC(*svp);
	ENTER_PYTHON;
	if (status == -1)
	    goto FAIL;
	PERL_LOCK;
	tmp = sv2pyo(*svp);
	PERL_UNLOCK;
	ASSERT_LOCK_PYTHON;
	return tmp;
    }

    ENTER_PYTHON;
    if (PyErr_Occurred())
	goto FAIL;

    /* av_fetch also returns 0 for empty slots filled with PL_av_undef,
     * so we need to compensate for that by testing if we actually are
     * within bounds.
     */
    ENTER_PERL;
    size = try_array_len(av);

    ENTER_PYTHON;
    if (size == -1)
	goto FAIL;

    if (index < size  && index >= -size) {
	ASSERT_LOCK_PYTHON;
	return Py_BuildValue("");
    }

    PyErr_SetString(PyExc_IndexError, "perl array index out of range");
FAIL:
    ASSERT_LOCK_PYTHON;
    return NULL;
}


static PyObject*
pysvrv_append(PySVRV *self, PyObject *args)
{
    PyObject *v;
    AV* av;
    SV* sv;
    SV** svp;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "O:append", &v))
	return NULL;

    PERL_LOCK;
    SET_CUR_PERL;
    sv = pyo2sv(v);

    PYTHON_UNLOCK;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);
    svp = av_store(av, av_len(av)+1, sv);
    if (!svp) {
	SvREFCNT_dec(sv);
	ENTER_PYTHON;
	PyErr_SetString(PyExc_RuntimeError, "av_store failed");
	return NULL;
    }

    ENTER_PYTHON;
    Py_INCREF(Py_None);
    ASSERT_LOCK_PYTHON;
    return Py_None;
}

static PyObject*
pysvrv_insert(PySVRV *self, PyObject *args)
{
    int i;
    PyObject *v;
    AV* av;
    SV* sv;
    SV** svp;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "iO:insert", &i, &v))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);
    if (array_splice(av, i, 0, 1) == -1) {
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    ENTER_PYTHON;
    PERL_LOCK;
    sv = pyo2sv(v);
    PYTHON_UNLOCK;

    svp = av_store(av, i, sv);
    if (!svp) {
	SvREFCNT_dec(sv);
	ENTER_PYTHON;
	PyErr_SetString(PyExc_RuntimeError, "av_store failed");
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    ENTER_PYTHON;
    Py_INCREF(Py_None);
    ASSERT_LOCK_PYTHON;
    return Py_None;
}

static PyObject*
pysvrv_extend(PySVRV *self, PyObject *args)
{
    PyObject *o;
    AV* av;
    int n, i;
    STRLEN size;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;

    if (!PyArg_ParseTuple(args, "O:extend", &o))
	goto FAIL;

    if (!PySequence_Check(o)) {
	PyErr_SetString(PyExc_TypeError,
			"array.extend() argument must be a sequence");
	goto FAIL;
    }

    n = PySequence_Length(o);
    if (n < 0)
	goto FAIL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);
    size = av_len(av) + 1;
    if (n)
	av_extend(av, (size-1) + n);

    /* Special case for a.extend(a) */
    if (PySVRV_Check(o) && SvRV(((PySVRV*)o)->rv) == (SV*)av) {
	SV** svp;
	for (i = 0; i < size; i++) {
	    svp = av_fetch(av, i, 0);
	    if (svp) {
		if (av_store(av, size + i, *svp))
		    SvREFCNT_inc(*svp);
	    }
	}
	ENTER_PYTHON;
	goto DONE;
    }

    ENTER_PYTHON;
    for (i = 0;; i++) {
	PyObject *item;

	ASSERT_LOCK_PYTHON;
	item = PySequence_GetItem(o, i);

	if (item) {
	    SV* item_sv;
	    PERL_LOCK;
	    item_sv = pyo2sv(item);
	    PYTHON_UNLOCK;
	    if (!av_store(av, size + i, item_sv)) {
		SvREFCNT_dec(item_sv);
		ENTER_PYTHON;
		PyErr_SetString(PyExc_RuntimeError, "av_store failed");
		goto FAIL;
	    }
	    ENTER_PYTHON;
	}
	else {
	    if (PyErr_ExceptionMatches(PyExc_IndexError)) {
		PyErr_Clear();
		break;
	    }
	    /* Something else bad happened */
	    goto FAIL;
	}
    }

DONE:
    ASSERT_LOCK_PYTHON;
    Py_INCREF(Py_None);
    return Py_None;

FAIL:
    /* XXX can we undo whatever we already might have stored in av??? */
    ASSERT_LOCK_PYTHON;
    return NULL;
}

static PyObject*
pysvrv_pop(PySVRV *self, PyObject *args)
{
    AV* av;
    I32 len;
    int i = -1;
    SV* sv;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "|i:pop", &i))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);
    len = av_len(av);

    if (len == -1) {
	ENTER_PYTHON;
	PyErr_SetString(PyExc_IndexError, "pop from empty list");
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    if (i == -1 || i == len) {
	SV* tmp = av_pop(av);
	PyObject *o;
	ENTER_PYTHON;
	PERL_LOCK;
	o = sv2pyo(tmp);
	PERL_UNLOCK;
	ASSERT_LOCK_PYTHON;
	return o;
    }
    else {
	PyObject* pyo;
	ENTER_PYTHON;
	pyo = array_item(av, i);
	if (!pyo) {
	    ASSERT_LOCK_PYTHON;
	    return NULL;
	}
	ENTER_PERL;
	if (array_splice(av, i, 1, 0) == -1) {
	    Py_DECREF(pyo);
	    ASSERT_LOCK_PYTHON;
	    return NULL;
	}
	ENTER_PYTHON;
	return pyo;
    }
}

static int
array_index(AV* av, PyObject *v)
{
    I32 i;
    I32 len;
    SV** svp;
    dCTXP;

    ASSERT_LOCK_PERL;
    SET_CUR_PERL;

    len = av_len(av);
    for (i = 0; i <= len; i++) {
	ASSERT_LOCK_PERL;
	svp = av_fetch(av, i, 0);
	if (svp) {
	    PyObject *x;
	    int cmp;
	    ENTER_PYTHON;
	    PERL_LOCK;
	    x = sv2pyo(*svp);
	    PERL_UNLOCK;
	    cmp = PyObject_Compare(x, v);
	    Py_DECREF(x);
	    if (cmp == 0) {
		ENTER_PERL;
		return i;
	    }
	    if (cmp == -1 && PyErr_Occurred()) {
		ENTER_PERL;
		return -1;
	    }
	    ENTER_PERL;
	}
	else if (v == Py_None) {
	    ASSERT_LOCK_PERL;
	    return i;
	}
    }
    ASSERT_LOCK_PERL;
    return -1;
}

static PyObject*
pysvrv_remove(PySVRV *self, PyObject *args)
{
    AV* av;
    PyObject *v;
    int index;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "O:index", &v))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);

    index = array_index(av, v);

    if (index == -1) {
	ENTER_PYTHON;
	if (!PyErr_Occurred())
	    PyErr_SetString(PyExc_ValueError,
			    "perlarray.remove(x): x not in list");
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    array_splice(av, index, 1, 0);

    ENTER_PYTHON;
    Py_INCREF(Py_None);
    ASSERT_LOCK_PYTHON;
    return Py_None;
}

static PyObject*
pysvrv_index(PySVRV *self, PyObject *args)
{
    AV* av;
    PyObject *v;
    int index;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_ParseTuple(args, "O:index", &v))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);

    index = array_index(av, v);

    ENTER_PYTHON;
    if (index == -1) {
	if (!PyErr_Occurred())
	    PyErr_SetString(PyExc_ValueError,
			    "perlarray.index(x): x not in list");
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    ASSERT_LOCK_PYTHON;
    return PyInt_FromLong((long)index);
}

static PyObject*
pysvrv_count(PySVRV *self, PyObject *args)
{
    AV* av;
    I32 len, i;
    PyObject *v;
    SV** svp;
    int count = 0;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    SET_CUR_PERL;

    if (!PyArg_ParseTuple(args, "O:count", &v))
	return NULL;

    ENTER_PERL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);

    len = av_len(av);
    for (i = 0; i <= len; i++) {
	ASSERT_LOCK_PERL;
	svp = av_fetch(av, i, 0);
	if (svp) {
	    PyObject *x;
	    int cmp;
	    ENTER_PYTHON;
	    PERL_LOCK;
	    x = sv2pyo(*svp);
	    PERL_UNLOCK;
	    cmp = PyObject_Compare(x, v);
	    Py_DECREF(x);
	    if (cmp == 0)
		count++;
	    if (cmp == -1 && PyErr_Occurred()) {
		ASSERT_LOCK_PYTHON;
		return NULL;
	    }
	    ENTER_PERL;
	}
	else if (v == Py_None)
	    count++;
    }
    ENTER_PYTHON;
    return PyInt_FromLong((long)count);
}

static PyObject*
pysvrv_reverse(PySVRV *self, PyObject *args)
{
    AV* av;
    I32 len, i;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    if (!PyArg_NoArgs(args))
	return NULL;

    ENTER_PERL;
    SET_CUR_PERL;

    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);

    if (SvREADONLY(av)) {
	ENTER_PYTHON;
	PyErr_SetString(PyExc_TypeError, "read only array can be modified");
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    if (SvTIED_mg((SV*)av, 'P')) {
	ENTER_PYTHON;
	PyErr_SetString(PyExc_TypeError, "tied array");
	ASSERT_LOCK_PYTHON;
	return NULL;
    }

    len = av_len(av);
  
    if (len > 0) {
	for (i = (len-1) / 2; i >= 0; i--) {
	    SV* tmp;
	    I32 other = len - i;
	    /* swap them */
	    tmp = AvARRAY(av)[i];
	    AvARRAY(av)[i] = AvARRAY(av)[other];
	    AvARRAY(av)[other] = tmp;
	}
    }

    ENTER_PYTHON;
    Py_INCREF(Py_None);
    ASSERT_LOCK_PYTHON;
    return Py_None;
}

static PyObject*
pysvrv_sort(PySVRV *self, PyObject *args)
{
    ASSERT_LOCK_PYTHON;
    PyErr_SetString(PyExc_NotImplementedError, "array sort");
    return NULL;
}

/* only useful for debugging (and test suite) */
static PyObject*
pysvrv_av_alloc(PySVRV *self, PyObject *args)
{
    AV* av;
    PyObject *t;
    long left, middle, right;

    dCTXP;

    ASSERT_LOCK_PYTHON;
    SET_CUR_PERL;
    CHECK_OWNED_PY;

    if (!PyArg_NoArgs(args))
	return NULL;

    ENTER_PERL;
    assert(SvTYPE(SvRV(self->rv)) == SVt_PVAV);
    av = (AV*)SvRV(self->rv);

    left = AvARRAY(av) - AvALLOC(av);  /* extra allocated at beginning */
    middle = AvFILLp(av) + 1;          /* used */
    right  = AvMAX(av) - AvFILLp(av);  /* extra allocated at end */

    ENTER_PYTHON;
    t = PyTuple_New(3);
    if (t == NULL) 
	return NULL;

    PyTuple_SetItem(t, 0, PyInt_FromLong(left));
    PyTuple_SetItem(t, 1, PyInt_FromLong(middle));
    PyTuple_SetItem(t, 2, PyInt_FromLong(right));
    ASSERT_LOCK_PYTHON;
    return t;
}


static PyMethodDef mapp_methods[] = {
    {"has_key",	(PyCFunction)pysvrv_has_key, METH_VARARGS},
    {"keys",	(PyCFunction)pysvrv_keys,    0},
    {"items",	(PyCFunction)pysvrv_items,   0},
    {"values",	(PyCFunction)pysvrv_values,  0},
    {"update",	(PyCFunction)pysvrv_update,  METH_VARARGS},
    {"clear",	(PyCFunction)pysvrv_clear,   0},
    {"copy",	(PyCFunction)pysvrv_copy,    0},
    {"get",     (PyCFunction)pysvrv_get,     METH_VARARGS},
  {NULL, NULL} /* sentinel */
};

static PyMethodDef list_methods[] = {
    {"append",	(PyCFunction)pysvrv_append,  METH_VARARGS},
    {"insert",	(PyCFunction)pysvrv_insert,  METH_VARARGS},
    {"extend",  (PyCFunction)pysvrv_extend,  METH_VARARGS},
    {"pop",	(PyCFunction)pysvrv_pop,     METH_VARARGS},
    {"remove",	(PyCFunction)pysvrv_remove,  METH_VARARGS},
    {"index",	(PyCFunction)pysvrv_index,   METH_VARARGS},
    {"count",	(PyCFunction)pysvrv_count,   METH_VARARGS},
    {"reverse",	(PyCFunction)pysvrv_reverse, 0},
    {"sort",	(PyCFunction)pysvrv_sort,    METH_VARARGS},
    {"av_alloc",(PyCFunction)pysvrv_av_alloc,0},
  {NULL, NULL} /* sentinel */
};


static PyObject*
pysvrv_getattr(PySVRV *self, char *name)
{
    PyObject *val;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    SET_CUR_PERL;

    if (strcmp(name, "__wantarray__") == 0) {
	if (self->gimme == G_VOID)
	    val = Py_BuildValue(""); /* None */
	else 
	    val = PyInt_FromLong((long)(self->gimme == G_ARRAY));
    }
    else if (strcmp(name, "__methodname__") == 0) {
	if (self->methodname)
	    val = PyString_FromString(self->methodname);
	else
	    val = Py_BuildValue(""); /* None */
    }
    else if (strcmp(name, "__class__") == 0) {
	SV *sv;
	ENTER_PERL;
	sv =  SvRV(self->rv);
	if (SvOBJECT(sv)) {
	    char *klass = HvNAME(SvSTASH(sv));
	    ENTER_PYTHON;
	    val = PyString_FromString(klass);
	}
	else {
	    ENTER_PYTHON;
	    val = Py_BuildValue("");
	}
    }
    else if (strcmp(name, "__type__") == 0) {
	char *tmp;
	ENTER_PERL;
	tmp = sv_reftype(SvRV(self->rv), 0);
	ENTER_PYTHON;
	val = PyString_FromString(tmp);
    }
    else if (strcmp(name, "__value__") == 0) {
	SV *sv = SvRV(self->rv);
	switch (SvTYPE(sv)) {
	case SVt_PVAV:
	case SVt_PVHV:
	case SVt_PVCV:
	    PyErr_SetString(PyExc_AttributeError, name);
	    val = NULL;
	    break;
	default:
	    PERL_LOCK;
	    val = sv2pyo(sv); 
	    PERL_UNLOCK;
	}
    }
    else if (strcmp(name, "__readonly__") == 0) {
	val = PyInt_FromLong(SvREADONLY(SvRV(self->rv)) != 0);
    }
    else if (self->methodname) {
	PyErr_SetString(PyExc_AttributeError, name);
	val = NULL;
    }
    else if (SvOBJECT(SvRV(self->rv))) {
	PySVRV *method_obj;
	int len;
	PERL_LOCK;
	method_obj = (PySVRV *)PySVRV_New(self->rv);
	len = strlen(name);

	New(999, method_obj->methodname, len+1, char);
	Copy(name, method_obj->methodname, len+1, char);

	if (len > 6 && strEQ(name+len-6, "_tuple")) {
	    method_obj->methodname[len-6] = '\0';
	    method_obj->gimme  = G_ARRAY;
	}
	else {
	    method_obj->gimme  = self->gimme;
	}
	PERL_UNLOCK;
	val = (PyObject *)method_obj;
    }
    else if (SvTYPE(SvRV(self->rv)) == SVt_PVAV) {
	val = Py_FindMethod(list_methods, (PyObject *)self, name);
    }
    else if (SvTYPE(SvRV(self->rv)) == SVt_PVHV) {
	val = Py_FindMethod(mapp_methods, (PyObject *)self, name);
    }
    else {
	PyErr_SetString(PyExc_AttributeError, name);
	val = NULL;
    }

    ASSERT_LOCK_PYTHON;
    return val;
}

static int
pysvrv_setattr(PySVRV *self, char *name, PyObject *val)
{
    int status;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_INT;
    SET_CUR_PERL;

    if (strcmp(name, "__wantarray__") == 0) {
	if (val == Py_None)
	    self->gimme = G_VOID;
	else
	    self->gimme = PyObject_IsTrue(val) ? G_ARRAY : G_SCALAR;
	status = 0;
    }
    else if (strcmp(name, "__methodname__") == 0) {
	if (PyString_Check(val)) {
	    PERL_LOCK;
	    Safefree(self->methodname);
	    New(998, self->methodname, PyString_GET_SIZE(val)+1, char);
	    Copy(PyString_AS_STRING(val), self->methodname,
		 PyString_GET_SIZE(val)+1, char);
	    PERL_UNLOCK;
	    status = 0;
	}
	else {
	    PyErr_SetString(PyExc_TypeError, "__methodname__ must be string");
	    status = -1;
	}
    }
    else if (strcmp(name, "__class__") == 0) {
	if (PyString_Check(val)) {
	    char *klass = PyString_AsString(val);
	    ENTER_PERL;
	    sv_bless(self->rv, gv_stashpv(klass, 1));
	    ENTER_PYTHON;
	    status = 0;
	}
	else if (val == Py_None) {
	    /* unbless */
	    PyErr_SetString(PyExc_NotImplementedError, "unbless");
	    status = -1;
	}
	else {
	    PyErr_SetString(PyExc_TypeError, "__class__ must be string");
	    status = -1;
	}
    }
    else if (strcmp(name, "__value__") == 0) {
	SV *sv;
	SV *val_sv;
	PERL_LOCK;
	sv = SvRV(self->rv);
	switch (SvTYPE(sv)) {
	case SVt_PVAV:
	case SVt_PVHV:
	case SVt_PVCV:
	    PERL_UNLOCK;
	    PyErr_SetString(PyExc_AttributeError, name);
	    status = -1;
	    break;
	default:
	    val_sv = pyo2sv(val);
	    SvSetMagicSV(sv, val_sv);
	    SvREFCNT_dec(val_sv);
	    PERL_UNLOCK;
	    status = 0;
	}
    }
    else if (strcmp(name, "__readonly__") == 0) {
	/* to give write access to this attribute is not really a good idea,
	 * but it can be fun for experimentation.
	 */
	if (PyObject_IsTrue(val))
	    SvREADONLY_on(SvRV(self->rv));
	else
	    SvREADONLY_off(SvRV(self->rv));
	status = 0;
    }
    else {
	PyErr_SetString(PyExc_AttributeError, name);
	status = -1;
    }

    ASSERT_LOCK_PYTHON;
    return status;
}


static PyObject*
pysvrv_call(PySVRV *self, PyObject *arg, PyObject *kw)
{
    dCTX;
    PyObject *res;
    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    res = call_perl(self->methodname, self->rv, self->gimme, arg, kw);
    ASSERT_LOCK_PYTHON;
    return res;
}


static PyObject*
pysvrv_repr(PySVRV *self)
{
    SV* tmp_sv;
    SV* sv;
    PyObject* o;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    /* We don't CHECK_OWNED here and hope for the best :-) */
    ENTER_PERL;
    SET_CUR_PERL;

    tmp_sv = newSVpvn("<", 1);
    sv = SvRV(self->rv);
    if (self->methodname) {
	sv_catpvf(tmp_sv, "method %s of ", self->methodname);
    }

    sv_catpvn(tmp_sv, "perl ", 5);
    if (SvOBJECT(sv)) {
	sv_catpvf(tmp_sv, "%s=", HvNAME(SvSTASH(sv)));
    }
    sv_catpvf(tmp_sv, "%s(0x%p) ref at %p",
	      sv_reftype(sv, 0), sv, self);

#if 0
    sv_catpvf(tmp_sv, " (%s)", self->gimme == G_VOID   ? "G_VOID" :
	      self->gimme == G_SCALAR ? "G_SCALAR" :
	      self->gimme == G_ARRAY  ? "G_ARRAY"  : "?");
#endif
  
    sv_catpvn(tmp_sv, ">", 1);
    ENTER_PYTHON;

    o = PyString_FromStringAndSize(SvPVX(tmp_sv), SvCUR(tmp_sv));
    SvREFCNT_dec(tmp_sv);

    ASSERT_LOCK_PYTHON;
    return o;
}


static void
type_error(char *msg, SV* sv)
{
    SV* tmp;
    dCTXP;

    ASSERT_LOCK_PYTHON;

    ENTER_PERL;
    SET_CUR_PERL;

    tmp = newSVpvf("%s perl %s", msg, sv_reftype(sv, 0));

    ENTER_PYTHON;
    PyErr_SetString(PyExc_TypeError, SvPVX(tmp));

    PERL_LOCK;
    SvREFCNT_dec(tmp);
    PERL_UNLOCK;

    ASSERT_LOCK_PYTHON;
}


static int
pysvrv_length(PySVRV *self)
{
    SV* sv;
    int len;
    dCTX;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_INT;

    ENTER_PERL;
    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	len = try_array_len((AV*)sv);
    }
    else if (SvTYPE(sv) == SVt_PVHV) {
	len = HvKEYS(sv); /* XXX support tied hashes */
    }
    else {
	ENTER_PYTHON;
	type_error("Can't count", sv);
	len = -1;
	ENTER_PERL;  /* just so we can change back :-( */
    }
    ENTER_PYTHON;

    ASSERT_LOCK_PYTHON;
    return len;
}

static int
pysvrv_nonzero(PySVRV *self)
{
    SV* sv;
    int v;
    dCTX;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_INT;

    ENTER_PERL;
    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	v = try_array_len((AV*)sv) != 0;
    }
    else if (SvTYPE(sv) == SVt_PVHV) {
	v = HvKEYS(sv) != 0; /* XXX support tied hashes */
    }
    else {
	v = 1;
    }
    ENTER_PYTHON;

    ASSERT_LOCK_PYTHON;
    return v;
}


static PyObject *
pysvrv_item(PySVRV *self, int index)
{
    SV* sv;
    PyObject *item;
    dCTX;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;

    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	item = array_item((AV*)sv, index);
    }
    else {
	type_error("Can't sequence index", sv);
	item = NULL;
    }

    ASSERT_LOCK_PYTHON;
    return item;
}


static PyObject*
pysvrv_subscript(PySVRV *self, PyObject *key)
{
    SV* sv;
    PyObject *val = key;  /* just something different than null */
    dCTXP;

    ASSERT_LOCK_PYTHON;
    SET_CUR_PERL;
    CHECK_OWNED_PY;
    assert(key);

    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	I32 index;
	if (PyInt_Check(key))
	    index = PyInt_AsLong(key);
	else if (PyLong_Check(key)) {
	    index = PyLong_AsLong(key);
	    if (index == -1 && PyErr_Occurred())
		val = NULL;
	}
	else {
	    PyErr_SetString(PyExc_TypeError, "perl array index must be integer");
	    val = NULL;
	}
	if (val)
	    val = array_item((AV*)sv, index); 
    }
    else if (SvTYPE(sv) == SVt_PVHV) {
	HV* hv = (HV*)sv;
	if (PyString_Check(key)) {
	    SV** svp;
	    ENTER_PERL;
	    svp = hv_fetch(hv, PyString_AsString(key), PyString_Size(key), 0);
	    if (svp) {
		SvGETMAGIC(*svp);
		PYTHON_LOCK;
		val = sv2pyo(*svp);
		PERL_UNLOCK;
	    }
	    else {
		ENTER_PYTHON;
		PyErr_SetObject(PyExc_KeyError, key);
		val = NULL;
	    }
	}
	else {
	    PyErr_SetString(PyExc_TypeError, "perl hash key must be string");
	    val = NULL;
	}
    }
    else {
	type_error("Can't index", sv);
	val = NULL;
    }

    assert(val != key);
    ASSERT_LOCK_PYTHON;
    return val;
}


static int
pysvrv_ass_sub(PySVRV *self, PyObject *key, PyObject *val)
{
    SV* sv;
    int status;  /* return value */
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_INT;
    SET_CUR_PERL;

    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	AV* av = (AV*)sv;
	I32 len;
	I32 index;
	SV* val_sv;
	SV** svp;

	if (PyInt_Check(key))
	    index = PyInt_AsLong(key);
	else if (PyLong_Check(key)) {
	    index = PyLong_AsLong(key);
	    if (index == -1 && PyErr_Occurred())
		goto FAIL;
	}
	else {
	    PyErr_SetString(PyExc_TypeError, "perl array index must be integer");
	    goto FAIL;
	}

	ENTER_PERL;
	if (!val) {
	    /* delete */
	    status = array_splice(av, index, 1, 0);
	    if (status == -1)
		ENTER_PERL;  /* Blææ!! */
	}
	else {
	    len = av_len(av);

	    ENTER_PYTHON;
	    if (index < (-len-1) || index > len) {
		PyErr_SetString(PyExc_IndexError, "perl array assignment index out of range");
		goto FAIL;
	    }

	    PERL_LOCK;
	    val_sv = pyo2sv(val);

	    PYTHON_UNLOCK;
	    svp = av_store(av, index, val_sv);
	    if (!svp) {
		SvREFCNT_dec(val_sv);
		ENTER_PYTHON;
		PyErr_SetString(PyExc_RuntimeError, "av_store failed");
		goto FAIL;
	    }
	    status = 0;
	}
	ENTER_PYTHON;
    }
    else if (SvTYPE(sv) == SVt_PVHV) {
	HV* hv = (HV*)sv;
	if (PyString_Check(key)) {
	    char *key_str = PyString_AsString(key);
	    int   key_len = PyString_Size(key);
	    if (val) {
		SV* val_sv;
		SV** svp;

		PERL_LOCK;
		val_sv = pyo2sv(val);
	
		PYTHON_UNLOCK;
		svp = hv_store(hv, key_str, key_len, val_sv, 0);
		if (svp) {
		    if (try_SvSETMAGIC(*svp) == -1) {
			ENTER_PYTHON;
			goto FAIL;
		    }
                }
		ENTER_PYTHON;
		if (!svp) {
		    SvREFCNT_dec(val_sv);
		    PyErr_SetString(PyExc_RuntimeError, "av_store failed");
		    goto FAIL;
		}
	    }
	    else {
		SV* sv;
		int key_deleted;

		ENTER_PERL;
		/* Since hv_delete gives us a mortal copy, we set up a block
		 * to get rid of it.
		 */
		ENTER;
		SAVETMPS;

		sv = hv_delete(hv, key_str, key_len, 0);
		key_deleted = (sv != NULL);

		FREETMPS;  /* sv invalidated */
		LEAVE;

		ENTER_PYTHON;
		if (!key_deleted) {
		    PyErr_SetObject(PyExc_KeyError, key);
		    goto FAIL;
		}
	    }
	    status = 0;
	}
	else {
	    PyErr_SetString(PyExc_TypeError, "perl hash key must be string");
	    status = -1;
	}
    }
    else {
	type_error("Can't index", sv);
    FAIL:
	status = -1;
    }

    ASSERT_LOCK_PYTHON;
    return status;
}


static PyObject *
pysvrv_concat(PySVRV *self, PyObject *other)
{
    SV* sv1;
    PyObject *pyo_res;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    SET_CUR_PERL;

    sv1 = SvRV(self->rv);
    if (SvTYPE(sv1) == SVt_PVAV) {
	if (other && PySVRV_Check(other)) {
	    SV* sv2 = SvRV(((PySVRV*)other)->rv);
#ifdef MULTI_PERL
	    if (!owned_by((PySVRV*)other, ctx->perl)) {
		pyo_res = NULL;
		goto DONE;
	    }
#endif
	    if (SvTYPE(sv2) == SVt_PVAV) {
		AV* av1 = (AV*)sv1;
		AV* av2 = (AV*)sv2;
		AV* res;
		I32 i, len1, len2;
		SV** svp;
		SV* sv;

		ENTER_PERL;
		res = newAV();
		len1 = av_len(av1) + 1;
		len2 = av_len(av2) + 1;

		av_extend(res, len1 + len2 - 1);

		for (i = 0; i < len1; i++) {
		    svp = av_fetch(av1, i, 0);
		    if (svp) {
			sv = newSVsv(*svp);
			if (!av_store(res, i, sv))
			    SvREFCNT_dec(sv);
		    }
		}

		for (i = 0; i < len2; i++) {
		    svp = av_fetch(av2, i, 0);
		    if (svp) {
			sv = newSVsv(*svp);
			if (!av_store(res, i+len1, sv))
			    SvREFCNT_dec(sv);
		    }
		}

		sv = newRV_noinc((SV*)res);
		ENTER_PYTHON;
		PERL_LOCK;
		pyo_res = PySVRV_New(sv);
		SvREFCNT_dec(sv);  /* since PySVRV_New incremented it */
		PERL_UNLOCK;
		goto DONE;
	    }
	}
	PyErr_SetString(PyExc_TypeError,
			"illegal argument type for perl array concatenation");
	pyo_res = NULL;
    }
    else {
	type_error("Can't concat", sv1);
	pyo_res = NULL;
    }

DONE:
    ASSERT_LOCK_PYTHON;
    return pyo_res;
}


static PyObject *
pysvrv_repeat(PySVRV *self, int n)
{
    SV* sv;
    PyObject *pyo_res;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    ENTER_PERL;
    SET_CUR_PERL;

    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	AV* av = (AV*)sv;
	I32 size = av_len(av)+1;
	AV* res;
	I32 res_size;
	I32 i, j;
	SV** svp;
	SV* sv;

	if (n < 0)
	    n = 0;
    
	if (size == 0 || n == 0) {
	    res = newAV();
	}
	else {
	    res_size = size * n;
	    if (res_size / size != n) {/* check for overflow */
		ENTER_PYTHON;
		return PyErr_NoMemory();
	    }

	    res = newAV();
	    av_extend(res, res_size-1);

	    for (i = 0; i < size; i++) {
		SV** svp = av_fetch(av, i, 0);
		if (svp) {
		    for (j = 0; j < n; j++) {
			sv = newSVsv(*svp);
			if (!av_store(res, i + j*size, sv))
			    SvREFCNT_dec(sv);
		    }
		}
	    }
	}
	sv = newRV_noinc((SV*)res);
	ENTER_PYTHON;
	PERL_LOCK;
	pyo_res = PySVRV_New(sv);
	SvREFCNT_dec(sv);  /* since PySVRV_New incremented it */
	PERL_UNLOCK;
    }
    else {
	ENTER_PYTHON;
	type_error("Can't repeat", sv);
	pyo_res = NULL;
    }

    ASSERT_LOCK_PYTHON;
    return pyo_res;
}


static PyObject *
pysvrv_slice(PySVRV *self, int ilow, int ihigh)
{
    SV* sv;
    PyObject *pyo_res;
    dCTXP;

    ASSERT_LOCK_PYTHON;
    CHECK_OWNED_PY;
    ENTER_PERL;
    SET_CUR_PERL;

    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	AV* av = (AV*)sv;
	I32 size = av_len(av)+1;
	AV* res;
	I32 i;
	SV** svp;
	SV* sv;

	if (ilow < 0)
	    ilow = 0;
	if (ihigh > size)
	    ihigh = size;
	if (ihigh < ilow)
	    ihigh = ilow;

	res = newAV();
	if (ihigh != ilow)
	    av_extend(av, ihigh - ilow - 1);

	for (i = ilow; i < ihigh; i++) {
	    svp = av_fetch(av, i, 0);
	    if (svp) {
		sv = newSVsv(*svp);
		if (!av_store(res, i-ilow, sv))
		    SvREFCNT_dec(sv);
	    }
	    else if (i == ihigh - 1) {
		/* in order to get the perl array to get the right length
		 * we need to to special case the last element.
		 */
		sv = newSV(0);
		if (!av_store(res, i-ilow, sv))
		    SvREFCNT_dec(sv);
	    }
	}

	sv = newRV_noinc((SV*)res);
	ENTER_PYTHON;
	PERL_LOCK;
	pyo_res = PySVRV_New(sv);
	SvREFCNT_dec(sv);  /* since PySVRV_New incremented it */
	PERL_UNLOCK;
    }
    else {
	ENTER_PYTHON;
	type_error("Can't slice", sv);
	pyo_res = NULL;
    }

    ASSERT_LOCK_PYTHON;
    return pyo_res;
}

static int
pysvrv_ass_slice(PySVRV *self, int ilow, int ihigh, PyObject *v)
{
    SV* sv;
    int status;  /* return value */
    dCTXP;

    CHECK_OWNED_INT;
    ASSERT_LOCK_PYTHON;
    ENTER_PERL;
    SET_CUR_PERL;

    sv = SvRV(self->rv);
    if (SvTYPE(sv) == SVt_PVAV) {
	AV* av = (AV*)sv;
	I32 size = av_len(av)+1;
	int n;
	AV* av2;
	SV** svp;

	if (v == NULL)
	    n = 0;
	else if (PySVRV_Check(v) && SvTYPE(SvRV(((PySVRV *)v)->rv)) == SVt_PVAV) {
#ifdef MULTI_PERL
	    if (!owned_by((PySVRV*)v, ctx->perl)) {
		ENTER_PYTHON;
		goto FAIL;
	    }
#endif
	    av2 = (AV*)SvRV(((PySVRV *)v)->rv);
	    n = av_len(av2)+1;
	}
	else {
	    ENTER_PYTHON;
	    PyErr_SetString(PyExc_TypeError, "Slice assignment type mismatch");
	    goto FAIL;
	}

	if (ilow < 0)
	    ilow = 0;
	if (ihigh > size)
	    ihigh = size;
	if (ihigh < ilow)
	    ihigh = ilow;

	/* printf("slice assign(%d:%d, %d)\n", ilow, ihigh, n); */

	if (array_splice(av, ilow, ihigh-ilow, n) == -1)
	    goto FAIL;
    
	/* Copy elements from av2 */
	while (n) {
	    n--;
	    svp = av_fetch(av2, n, 0);
	    if (svp) {
		SV* sv = newSVsv(*svp);
		if (!av_store(av, ilow+n, sv)) {
		    /* XXX might be to late to throw an exception :-( */
		    SvREFCNT_dec(sv);
		}
	    }
	}
	ENTER_PYTHON;
	status = 0;
    }
    else {
	ENTER_PYTHON;
	type_error("Can't slice", sv);
    FAIL:
	status = -1;
    }

    ASSERT_LOCK_PYTHON;
    return status;
}

static PyNumberMethods pysvrv_as_number = {
	0,	/*nb_add*/
	0,	/*nb_subtract*/
	0,	/*nb_multiply*/
	0,	/*nb_divide*/
	0,	/*nb_remainder*/
	0,	/*nb_divmod*/
	0,	/*nb_power*/
	0,	/*nb_negative*/
	0,	/*nb_positive*/
	0,	/*nb_absolute*/
	(inquiry)pysvrv_nonzero,	/*nb_nonzero*/
	0,	/*nb_invert*/
	0,	/*nb_lshift*/
	0,	/*nb_rshift*/
	0,	/*nb_and*/
	0,	/*nb_xor*/
	0,	/*nb_or*/
	0,	/*nb_coerce*/
	0,	/*nb_int*/
	0,	/*nb_long*/
	0,	/*nb_float*/
	0,	/*nb_oct*/
	0, 	/*nb_hex*/
};

static PyMappingMethods pysvrv_as_mapping = {
    (inquiry)pysvrv_length, /* mp_length */
    (binaryfunc)pysvrv_subscript, /* mp_subscript */
    (objobjargproc)pysvrv_ass_sub, /* mp_ass_subscript */
};

static PySequenceMethods pysvrv_as_sequence = {
    (inquiry)pysvrv_length, /*sq_length*/
    (binaryfunc)pysvrv_concat, /*sq_concat*/
    (intargfunc)pysvrv_repeat, /*sq_repeat*/
    (intargfunc)pysvrv_item, /*sq_item*/
    (intintargfunc)pysvrv_slice, /*sq_slice*/
    0, /*sq_ass_item*/
    (intintobjargproc)pysvrv_ass_slice, /*sq_ass_slice*/
#if PY_MAJOR_VERSION >= 1 && PY_MINOR_VERSION >= 6
    0, /*sq_contains*/
#endif
};


//XXX must compile as a C++ file on Windows
PyTypeObject SVRVtype = {
    PyObject_HEAD_INIT(&PyType_Type)
    0,			         /* Number of items for varobject */
    "perl ref",		         /* Name of this type */
    sizeof(PyTypeObject),	 /* Basic object size */
    0,			         /* Item size for varobject */
    (destructor)pysvrv_dealloc,  /*tp_dealloc*/
    0,                           /*tp_print*/
    (getattrfunc)pysvrv_getattr, /*tp_getattr*/
    (setattrfunc)pysvrv_setattr, /*tp_setattr*/
    0,                           /*tp_compare*/
    (reprfunc)pysvrv_repr,       /*tp_repr*/
    &pysvrv_as_number,	         /*tp_as_number*/
    &pysvrv_as_sequence,         /*tp_as_sequence*/
    &pysvrv_as_mapping,	         /*tp_as_mapping*/
    0,                           /*tp_hash*/
    (ternaryfunc)pysvrv_call,    /*tp_call*/
};

#ifdef __cplusplus
}
#endif

