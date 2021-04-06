/* Copyright 2001 ActiveState
 */

extern SV* newPerlPyObject_noinc(PyObject *pyo);
extern SV* newPerlPyObject_inc(PyObject *pyo);
extern PyObject* PerlPyObject_pyo(SV* sv);
extern PyObject* PerlPyObject_pyo_or_null(SV* sv);

extern MGVTBL vtbl_free_pyo;
