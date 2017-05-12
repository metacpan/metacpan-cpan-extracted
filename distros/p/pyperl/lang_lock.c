/* Copyright 2000-2001 ActiveState
 */

#include <EXTERN.h>
#include <perl.h>
#include <Python.h>

#include "lang_lock.h"

#ifdef DO_THREAD

#ifdef MULTI_PERL
perl_key last_py_tstate;

void
lang_lock_init()
{
#ifdef WIN32
    if ((last_py_tstate = TlsAlloc()) == TLS_OUT_OF_INDEXES) {
#else
    /* This is pthread specific code.  This need to be fixed. */
    if (pthread_key_create(&last_py_tstate, 0)) {
#endif
	Py_FatalError("Can't create TSD key for py_tstate");
    }
}

#else /* MULTI_PERL */
PyThread_type_lock perl_lock = 0;
PyThreadState *last_py_tstate = NULL;

void
lang_lock_init()
{
    perl_lock = PyThread_allocate_lock();
}

#ifdef LOCK_DEBUG
int
perl_lock_held()
{
    /* XXX should actually test if lock is already held by the
     * current thread....  This code does not do that!
     */
    if (!PyThread_acquire_lock(perl_lock, 0))
	return 1;
    PyThread_release_lock(perl_lock);
    return 0;
}
#endif /* LOCK_DEBUG */
#endif /* MULTI_PERL */


#else /* DO_THREAD */

#ifdef MULTI_PERL
  #error "Can't build with MULTI_PERL without threading support"
#endif

#ifdef LOCK_DEBUG
  /* This assumes that we embed perl in python
     (and not the other way around)
   */
  int perl_lock_held = 0;
  int python_lock_held = 1;
#endif /* LOCK_DEBUG */
#endif /* DO_THREAD */


#ifdef LOCK_DEBUG
void
Lock_Fatal_Error(const char* msg, const char* file, int line)
{
    char buf[1024];
    sprintf(buf, "%s at %s line %d", msg, file, line);
    Py_FatalError(buf);
}
#endif /* LOCK_DEBUG */







