/* Copyright 2000-2001 ActiveState
 */

#include <XSUB.h>

/* Python < 2.5 compat */
#if PY_VERSION_HEX < 0x02050000 && !defined(PY_SSIZE_T_MIN)
typedef int Py_ssize_t;
#define PY_SSIZE_T_MAX INT_MAX
#define PY_SSIZE_T_MIN INT_MIN
typedef Py_ssize_t (*lenfunc)(PyObject *);
typedef PyObject *(*ssizeargfunc)(PyObject *, Py_ssize_t);
typedef PyObject *(*ssizessizeargfunc)(PyObject *, Py_ssize_t, Py_ssize_t);
typedef int(*ssizeobjargproc)(PyObject *, Py_ssize_t, PyObject *);
typedef int(*ssizessizeobjargproc)(PyObject *, Py_ssize_t, Py_ssize_t, PyObject *);
typedef Py_ssize_t (*readbufferproc)(PyObject *, Py_ssize_t, void **);
typedef Py_ssize_t (*writebufferproc)(PyObject *, Py_ssize_t, void **);
typedef Py_ssize_t (*segcountproc)(PyObject *, Py_ssize_t *);
typedef Py_ssize_t (*charbufferproc)(PyObject *, Py_ssize_t, char **);
#endif

typedef struct {
    PyObject_HEAD
    SV* rv;               /* always an owned SvRV */
#ifdef MULTI_PERL
    /* We want to prevent SV* to leak between interpreters */
    refcounted_perl *owned_by;
#endif
    char* methodname;     /* when set, we are a method object */
    I32  gimme;           /* GIMME_V, aka wantarray */
} PySVRV;

extern PyTypeObject SVRVtype;

#define PySVRV_Check(v)  ((v)->ob_type == &SVRVtype)
#define PySVRV_RV(v)     (((PySVRV*)(v))->rv)

PyObject* PySVRV_New(SV* rv);
