/* Copyright 2000-2001 ActiveState
 */

void propagate_errsv(void);
PyObject *call_perl(char *method, SV* obj, I32 gimme,
		    PyObject *args, PyObject *keywds);


#ifdef USE_ITHREADS
 #ifdef MULTI_PERL
   #define SET_CUR_PERL /* empty */
   extern PerlInterpreter* new_perl(void);
   extern void free_perl(PerlInterpreter*);
 #else /* MULTI_PERL */
   extern PerlInterpreter *main_perl;
   #define SET_CUR_PERL do { \
          if (my_perl != main_perl) { \
             my_perl = main_perl; \
             PERL_SET_CONTEXT(my_perl); \
          } \
       } while (0)
   /* we should probably also restore old my_perl if it was not neither
    * NULL nor main_perl, but that can wait.
    */
 #endif /* MULTI_PERL */
#else /* USE_ITHREADS */
   #define SET_CUR_PERL /* empty */
#endif /* USE_ITHREADS */
