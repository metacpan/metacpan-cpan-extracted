#ifndef __PYCOMPAT_H
#define __PYCOMPAT_H

/*#if (PY_VERSION_HEX < 0x02050000)
typedef int Py_ssize_t;
#endif*/

#include <Python.h>

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

#if PY_MAJOR_VERSION < 3
#define PyUnicode_AsUTF8 PyString_AsString
#define PyUnicode_GetLength PyUnicode_GetSize
static inline char * PyUnicode_AsUTF8AndSize(PyObject *unicode, Py_ssize_t *size) {
    char *str = NULL;
    int ret = PyString_AsStringAndSize(unicode, &str, size);

    return str;
}

#endif

#endif
