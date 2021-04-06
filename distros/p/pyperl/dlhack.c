#include <Python.h>
#include <dlfcn.h>
#include "pycompat.h"

/* This is a fake perl module that will look for the real thing ('perl2.so')
 * in sys.path and then load this one with the RTLD_GLOBAL set in order to
 * make the symbols available for extension modules that perl might load.
 */

extern PyMODINIT_FUNC
#if PY_MAJOR_VERSION < 3
initperl()
#else
PyInit_perl()
#endif
{
    void* handle;
    int i, npath;
    size_t len;
    char buf[1024];
    struct stat sb;

    PyObject *path = PySys_GetObject("path");
    if (path == NULL || !PyList_Check(path)) {
	PyErr_SetString(PyExc_ImportError,
			"sys.path must be a list of directory names");
	return
#if PY_MAJOR_VERSION >= 3
	NULL
#endif
	;
    }

    npath = PyList_Size(path);
    for (i = 0; i < npath; i++) {
	PyObject *v = PyList_GetItem(path, i);
	if (!PyUnicode_Check(v))
	    continue;
	len = PyUnicode_GetLength(v);
	if (len + 10 >= sizeof(buf))
	    continue; /* Too long */
	strcpy(buf, PyUnicode_AsUTF8(v));
	if (buf[0] != '/')
	    continue; /* Not absolute */
	if (strlen(buf) != len)
	    continue; /* v contains '\0' */

	strcpy(buf+len, "/perl2" EXT_SUFFIX);

	if (!stat(buf, &sb) && (handle = dlopen(buf, RTLD_NOW | RTLD_GLOBAL)))
		break;
    }

    if (handle) {
	PyMODINIT_FUNC (*f)() = dlsym(handle, "PyInit_perl2");

	if (f)
	    return f();
	else
	    PyErr_SetString(PyExc_ImportError, "PyInit_perl2 entry point not found");
    }
    else
	PyErr_SetString(PyExc_ImportError, dlerror());

#if PY_MAJOR_VERSION >= 3
    return NULL;
#endif
}
