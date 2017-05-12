#include <Python.h>
#include <dlfcn.h>

/* This is a fake perl module that will look for the real thing ('perl2.so')
 * in sys.path and then load this one with the RTLD_GLOBAL set in order to
 * make the symbols available for extension modules that perl might load.
 */

extern void initperl()
{
    void* handle;
    int i, npath, len;
    char buf[1024];

    PyObject *path = PySys_GetObject("path");
    if (path == NULL || !PyList_Check(path)) {
	PyErr_SetString(PyExc_ImportError,
			"sys.path must be a list of directory names");
	return;
    }

    npath = PyList_Size(path);
    for (i = 0; i < npath; i++) {
	PyObject *v = PyList_GetItem(path, i);
	if (!PyString_Check(v))
	    continue;
	len = PyString_Size(v);
	if (len + 10 >= sizeof(buf))
	    continue; /* Too long */
	strcpy(buf, PyString_AsString(v));
	if (buf[0] != '/')
	    continue; /* Not absolute */
	if (strlen(buf) != len)
	    continue; /* v contains '\0' */
	strcpy(buf+len, "/perl2.so");

	handle = dlopen(buf, RTLD_NOW | RTLD_GLOBAL);
	if (handle) {
	    void (*f)() = dlsym(handle, "initperl2");
	    if (f) {
		f();
	    }
	    else {
		PyErr_SetString(PyExc_ImportError, "initperl2 entry point not found");
	    }
	    return;
	}
    }
    PyErr_SetString(PyExc_ImportError, "perl2.so not found");
}
