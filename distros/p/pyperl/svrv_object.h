/* Copyright 2000-2001 ActiveState
 */

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
