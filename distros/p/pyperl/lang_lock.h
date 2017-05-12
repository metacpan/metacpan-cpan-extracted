/* Copyright 2000-2001 ActiveState
 */

/* #define NO_PERL_LOCK /**/
/* #define LOCK_DEBUG /**/

#if !defined(NO_PERL_LOCK) && defined(WITH_THREAD)
 #define DO_THREAD /* a simpler macro to test for in files that include this */
#endif

#ifdef LOCK_DEBUG

#ifdef DO_THREAD
  /* XXX these test are not valid in a multi-thread environment.
   * Should test if the current thread has the given lock.
   */
  #error "LOCK_DEBUG with real threads doesn't work"
  extern int perl_lock_held();
  #define PERL_LOCK_HELD   perl_lock_held()
  #define PYTHON_LOCK_HELD (last_py_tstate == NULL)
#else /* DO_THREAD */
  #define PERL_LOCK_HELD   perl_lock_held
  #define PYTHON_LOCK_HELD python_lock_held
#endif /* DO_THREAD */

extern void Lock_Fatal_Error(const char*, const char*, int);
#define LOCK_FATAL_ERROR(msg)  Lock_Fatal_Error(msg, __FILE__, __LINE__)

/* Poor mans Eiffel :-) */

#define ASSERT_LOCK_PERL \
          do { \
              if (!PERL_LOCK_HELD || PYTHON_LOCK_HELD) \
		LOCK_FATAL_ERROR("Only perl lock should be held"); \
          } while (0)

#define ASSERT_LOCK_PYTHON \
          do { \
              if (PERL_LOCK_HELD || !PYTHON_LOCK_HELD) \
		LOCK_FATAL_ERROR("Only python lock should be held"); \
          } while (0)

#define ASSERT_LOCK_BOTH \
          do { \
              if (!PERL_LOCK_HELD || !PYTHON_LOCK_HELD) \
		LOCK_FATAL_ERROR("Both perl and python lock should be held"); \
          } while (0)

#else /* LOCK_DEBUG */

/* All assertions expand to nothing */
#define ASSERT_LOCK_PERL
#define ASSERT_LOCK_PYTHON
#define ASSERT_LOCK_BOTH

extern void lang_lock_init(void);

#endif /* LOCK_DEBUG */




#ifdef DO_THREAD

#ifdef MULTI_PERL

extern perl_key last_py_tstate;

/* These assume that the thread specific 'ctx' pointer is
 * in scope.
 */
#define ENTER_PERL   do { ctx->last_py_state = PyEval_SaveThread(); \
                     } while (0)
#define ENTER_PYTHON do { PyEval_RestoreThread(ctx->last_py_state); \
                     } while (0)
#define PERL_LOCK    /* nothing */
#define PERL_UNLOCK  /* nothing */
#define PYTHON_LOCK   ENTER_PYTHON
#define PYTHON_UNLOCK ENTER_PERL

#else /* MULTI_PERL */

/* This stuff is similar to the threading macros you find in _tkinter.c,
 * but not exactly the same :-)
 */

#include "pythread.h"
extern PyThread_type_lock perl_lock;
extern PyThreadState *last_py_tstate;


/* The locking rules are:

     1) All code should be protected by one (or more) locks.
     2) When we execute python code we should have the python lock and
        *not* have the perl lock
     3) When we execute perl code we should have the perl lock and *not*
        the python lock
     4) You can have both locks while executing API functions that does
        not risk invoking arbitrary perl/python code.
     5) Lot of API functions might invoke perl/python callbacks through
        hooks, overloading or tying.  These must only be invoked with
        the correct single lock.
*/

/* This one should only be called when you are sure you have the python lock,
   and not the perl lock.  The result is that you have perl lock.
 */
#define ENTER_PERL   do { PyThreadState *tstate;               \
                          ASSERT_LOCK_PYTHON;                  \
                          tstate = PyEval_SaveThread();        \
                          PyThread_acquire_lock(perl_lock, 1); \
                          last_py_tstate = tstate;             \
                     } while (0)

/* This one should only be called when you are sure you have the perl lock,
   and not the python lock.  The result is that you have the python lock.
 */
#define ENTER_PYTHON do { PyThreadState *tstate;               \
                          ASSERT_LOCK_PERL;                    \
                          tstate = last_py_tstate;             \
                          last_py_tstate = NULL;               \
                          PyThread_release_lock(perl_lock);    \
                          PyEval_RestoreThread(tstate);        \
                     } while (0)

/* These can only be called while you have the python lock */
#define PERL_LOCK    do { ASSERT_LOCK_PYTHON; \
                          while (!PyThread_acquire_lock(perl_lock, 0)) { \
			      ENTER_PERL; \
			      ENTER_PYTHON; \
                          } \
                     } while (0)
#define PERL_UNLOCK  do { ASSERT_LOCK_BOTH; \
                          PyThread_release_lock(perl_lock); \
                     } while (0)

/* These can only be called while you have the perl lock */
#define PYTHON_LOCK do { ENTER_PYTHON; PERL_LOCK; } while (0)
#define PYTHON_UNLOCK \
     do { ASSERT_LOCK_BOTH; \
          if (last_py_tstate != NULL) \
             Py_FatalError("PYTHON_UNLOCK: non-NULL tstate"); \
          last_py_tstate = PyEval_SaveThread(); \
     } while (0)

/* The reason PYTHON_LOCK is defined as it is, is that we should always
 * obtain locks in the same sequence in order to avoid potential deadlock.
 */
#endif /* MULTI_PERL */

#else /* DO_THREAD */

#ifdef LOCK_DEBUG

extern int perl_lock_held;
extern int python_lock_held;

#define ENTER_PERL \
          do { \
	    ASSERT_LOCK_PYTHON; \
	    python_lock_held = 0; \
	    perl_lock_held = 1; \
          } while (0) \

#define ENTER_PYTHON \
          do { \
	    ASSERT_LOCK_PERL; \
	    python_lock_held = 1; \
	    perl_lock_held = 0; \
          } while (0)

#define PERL_LOCK \
          do { \
	    ASSERT_LOCK_PYTHON; \
	    perl_lock_held = 1; \
          } while (0)

#define PERL_UNLOCK \
          do { \
	    ASSERT_LOCK_BOTH; \
	    perl_lock_held = 0; \
          } while (0)

#define PYTHON_LOCK \
          do { \
	    ASSERT_LOCK_PERL; \
	    python_lock_held = 1; \
          } while (0)

#define PYTHON_UNLOCK \
          do { \
	    ASSERT_LOCK_BOTH; \
	    python_lock_held = 0; \
          } while (0)

#else /* LOCK_DEBUG */

/* No threads and no debug, all macros expand to nothing */

#define ENTER_PERL
#define ENTER_PYTHON
#define PERL_LOCK
#define PERL_UNLOCK
#define PYTHON_UNLOCK
#define PYTHON_LOCK

#endif /* LOCK_DEBUG */

#endif /* DO_THREAD */
