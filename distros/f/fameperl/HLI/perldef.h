/* EXPIRE takes form CCYYMMDD */
#define EXPIRE 19980231

/* Perl 5.6 and above use different defines */
#define na PL_na
#define sv_yes PL_sv_yes
#define sv_no PL_sv_no

#ifdef WIN32

/* Windows NT ANSI C++ commpiler */

#define WIN32PREFIX CPerl *pPerl,
#define WIN32PASS pPerl,

/* redef croak to get around compiler problems */
#define croak printf
#define class classcode

#define CAN_PROTOTYPE

/* #define HLILIB */
/* #define HLILIB_INC */

#else

/* UNIX */

#define WIN32PREFIX
#define WIN32PASS
/* include HLILIB file rather than link as in Win32 version */
#ifdef HLILIB
#define HLILIB_INC
#endif

#endif

/* prototyping */

#ifdef CAN_PROTOTYPE

#define HAS_PROTOTYPE

void u_cfmlsts(int *, int, char *, int *, int *);
void u_cfmrdfa(int *, int, char *, int, int *, int *, int *, float *, int, float *);
void u_cfmrrng(int *, int, char *, int *, float *, int, float *);
void u_cfmwrng(int *, int, char *, int *, float *, int, float *);
void d_cfmini(int *);

int famegettype(int, char *);
int famegetfreq(int, char *);
int famegetclass(int, char *);

#ifdef HLILIB
void hlierr(char *, int);
char *getsta(int);
char *getcls(int);
char *gettyp(int);
char *getbas(int);
char *getobs(int);
char *getfrq(int);
char *getobs(int);
#endif

static double constant(char *, int);

#endif
