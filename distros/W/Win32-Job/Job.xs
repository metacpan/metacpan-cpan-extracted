#define _WIN32_WINNT 0x0500
#include <windows.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __CYGWIN__
#   define win32_get_osfhandle _get_osfhandle
#endif

#define NEWZ_CONST_INT 413
#define KILL_EXITCODE  293

#define AV_REAL_LEN(av) (av_len(av) + 1)

/* In case we're building on VC98, define these macros so we can still run
 * the code on the appropriate platforms */
#ifndef CREATE_BREAKAWAY_FROM_JOB
#define CREATE_BREAKAWAY_FROM_JOB     0x01000000
#endif
#ifndef JOB_OBJECT_LIMIT_BREAKAWAY_OK
#define JOB_OBJECT_LIMIT_BREAKAWAY_OK 0x00000800
#endif

/* For non-threaded Perl */
#ifndef pTHX
#define pTHX	/* empty */
#define aTHX	/* empty */
#define pTHX_	/* empty */
#define aTHX_	/* empty */
#endif

/* This structure contains the HANDLE for the job object, plus an
 * array of pointers to PROCESS_INFORMATION structures (one for each
 * process spawn()ed). We remember these so we can call CloseHandle()
 * during DESTROY(), and so we can call ResumeThread() on each of them
 * during the watch() and run() calls.
 */
typedef struct {
    HANDLE		hJob;	/* the job              */
    AV*			procs;	/* processes in the job */
    HV*			info;	/* process status info  */
} job_t;

typedef job_t *JOB_T;
typedef PROCESS_INFORMATION *PROC_T;

typedef struct {
    LARGE_INTEGER PerProcessUserTimeLimit;
    LARGE_INTEGER PerJobUserTimeLimit;
    DWORD LimitFlags;
    SIZE_T MinimumWorkingSetSize;
    SIZE_T MaximumWorkingSetSize;
    DWORD ActiveProcessLimit;
#ifdef _WIN64
    unsigned __int64 Affinity;
#else
    DWORD Affinity;
#endif
    DWORD PriorityClass;
    DWORD SchedulingClass;
}   MY_JOBOBJECT_BASIC_LIMIT_INFORMATION;

typedef struct {
    ULONGLONG ReadOperationCount;
    ULONGLONG WriteOperationCount;
    ULONGLONG OtherOperationCount;
    ULONGLONG ReadTransferCount;
    ULONGLONG WriteTransferCount;
    ULONGLONG OtherTransferCount;
} MY_IO_COUNTERS;

typedef struct {
    MY_JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
    MY_IO_COUNTERS IoInfo;
    SIZE_T ProcessMemoryLimit;
    SIZE_T JobMemoryLimit;
    SIZE_T PeakProcessMemoryUsed;
    SIZE_T PeakJobMemoryUsed;
}   MY_JOBOBJECT_EXTENDED_LIMIT_INFORMATION;

#define JobObjectExtendedLimitInformation 9
static HANDLE
create_job_object()
{
    MY_JOBOBJECT_EXTENDED_LIMIT_INFORMATION  jobinfo;
    HANDLE job = CreateJobObject(NULL, NULL);

    memset(&jobinfo, 0, sizeof(jobinfo));
    if (job && QueryInformationJobObject(job, JobObjectExtendedLimitInformation,
                                         &jobinfo, sizeof(jobinfo), NULL))
    {
        jobinfo.BasicLimitInformation.LimitFlags |= JOB_OBJECT_LIMIT_BREAKAWAY_OK;
        SetInformationJobObject(job, JobObjectExtendedLimitInformation,
                                &jobinfo, sizeof(jobinfo));
    }
    return job;
}


/* Called to resume all the threads by watch() and run() */
static void
resume_threads(pTHX_ AV *procs)
{
	I32 i, imax = AV_REAL_LEN(procs);
	for (i = 0; i < imax; i++) {
		STRLEN l;
		SV* tmp = *av_fetch(procs, i, 0);
		PROC_T inf = (PROC_T)SvPV(tmp, l);
		ResumeThread(inf->hThread);
	}
}

static void
free_threads(pTHX_ AV *procs)
{
	I32 i, imax = AV_REAL_LEN(procs);
	for (i = 0; i < imax; i++) {
		STRLEN l;
		SV* tmp = *av_fetch(procs, i, 0);
		PROC_T inf = (PROC_T)SvPV(tmp, l);
		CloseHandle(inf->hThread);
		CloseHandle(inf->hProcess);
	}
}

/* Called to remember/close files created with CreateFile */
static SV*
new_handle(pTHX_ HANDLE file)
{
	SV* rv = newSViv(0); /* blank SV */
	sv_setref_iv(rv, "Win32::Job::_handle", PTR2IV(file));
	return rv;
}

static void
get_status(pTHX_ JOB_T self, int wait)
{
	I32 i, imax = AV_REAL_LEN(self->procs);
	if (imax)
		hv_clear(self->info);
	for (i = 0; i < imax; i++) {
		STRLEN l;
		SV *tmp     = *av_fetch(self->procs, i, 0);
		PROC_T inf  = (PROC_T)SvPV(tmp, l);
		HV *proc    = newHV();
		HV *htime   = newHV();
		SV *ent     = newSVuv(inf->dwProcessId);
		DWORD ecode;
		FILETIME   stime, etime, ktime, utime;
		double            te,    tk,    tu;

		/* Wait for the process to finish terminating */
		if (wait)
			WaitForSingleObject(inf->hProcess, INFINITE);

		/* Get information about the process (only care about user and
		 * kernel times */
		GetExitCodeProcess(inf->hProcess, &ecode);
		GetProcessTimes(inf->hProcess, &stime, &etime, &ktime, &utime);
		{
		    ULARGE_INTEGER user, kernel, start, end, elapsed;

		    kernel.LowPart = ktime.dwLowDateTime;
		    kernel.HighPart = ktime.dwHighDateTime;
		    user.LowPart = utime.dwLowDateTime;
		    user.HighPart = utime.dwHighDateTime;
		    start.LowPart = stime.dwLowDateTime;
		    start.HighPart = stime.dwHighDateTime;
		    end.LowPart = etime.dwLowDateTime;
		    end.HighPart = etime.dwHighDateTime;
		    if (!end.QuadPart) { /* process is not finished yet */
			SYSTEMTIME now;
			GetSystemTime(&now);
			SystemTimeToFileTime(&now, &etime);
			end.LowPart = etime.dwLowDateTime;
			end.HighPart = etime.dwHighDateTime;
		    }

		    elapsed.QuadPart = end.QuadPart - start.QuadPart;

		    /* We must cast to signed __int64 because MSVC++ can't
		     * convert unsigned __int64 to double. It's probably okay;
		     * if the process is running long enough to overflow a
		     * signed 64-bit integer, it won't fit into a double
		     * anyway. */
		    tk = ((__int64) kernel.QuadPart) / 10000000.0;
		    tu = ((__int64)   user.QuadPart) / 10000000.0;
		    te = ((__int64)elapsed.QuadPart) / 10000000.0;
		}

		/* Create a tree structure like this:
		 * <pid>:
		 *    exitcode:  123
		 *    time:
		 *       user:    123
		 *       kernel:  123
		 *       elapsed: 123
		 */
		hv_store(htime, "user",    4, newSVnv(tu), 0);
		hv_store(htime, "kernel",  6, newSVnv(tk), 0);
		hv_store(htime, "elapsed", 7, newSVnv(te), 0);
		hv_store(proc, "exitcode", 8, newSVuv(ecode), 0);
		hv_store(proc, "time",     4, newRV_noinc((SV*)htime), 0);
		hv_store_ent(self->info, ent, newRV_noinc((SV*)proc), 0);
		SvREFCNT_dec(ent); /* free */
	}
}

/* Kills the threads running in the Job, collecting information about how long
 * each process has been running at the same time. */
static void
kill_threads(pTHX_ JOB_T self)
{
	TerminateJobObject(self->hJob, KILL_EXITCODE);
	get_status(aTHX_ self, 1); /* get status (and wait for the exitcode) */
	free_threads(aTHX_ self->procs);
	av_clear(self->procs);
}

/* This function checks an SV* to see if it contains an IO* structure. This
 * code is taken from sv.c's sv_2io(). Unfortunately, *that* code throws
 * exceptions, and I just want to know if it will work or not, without having
 * to set up a new frame. */
static int /* bool */
sv_isio(pTHX_ SV *sv)
{
	IO *io;
	GV *gv;
	STRLEN n_a;

	switch (SvTYPE(sv)) {
	case SVt_PVIO:
		io = (IO*)sv;
		return 1;
	case SVt_PVGV:
		gv = (GV*)sv;
		io = GvIO(gv);
		if (!io)
			return 0;
		return 1;
	default:
		if (!SvOK(sv))
			return 0;
		if (SvROK(sv))
			return sv_isio(aTHX_ SvRV(sv));
		gv = gv_fetchpv(SvPV(sv,n_a), FALSE, SVt_PVIO);
		if (gv)
			return 1;
		else
			return 0;
	}
	return 0;
}

MODULE = Win32::Job	PACKAGE = Win32::Job::_handle

PROTOTYPES: DISABLE

void
DESTROY(SV* self)
    PREINIT:
	IV iv;
	HANDLE h;
    CODE:
	iv = SvIV(SvRV(self));
	h  = INT2PTR(HANDLE, iv);
	if (h) CloseHandle(h);

MODULE = Win32::Job	PACKAGE = Win32::Job

PROTOTYPES: DISABLE

JOB_T
new(klass)
	SV*	klass
    PREINIT:
	JOB_T	job;
    CODE:
	Newz(NEWZ_CONST_INT, job, 1, job_t);
	job->hJob  = create_job_object();
	job->procs = newAV();
	job->info  = newHV();
	RETVAL = job;
	if (!RETVAL)
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void
DESTROY(self)
	JOB_T	self
    CODE:
	kill_threads(aTHX_ self);
	CloseHandle(self->hJob);
	SvREFCNT_dec(self->procs);
	SvREFCNT_dec(self->info);
	Safefree(self);

void
kill(self)
	JOB_T	self
    CODE:
	kill_threads(aTHX_ self);

IV
spawn(self, svexe, args, ...)
	JOB_T	self
	SV*	svexe
	char*	args
    PREINIT:
	char*			exe;
	char*			cwd = "."; /* cwd of the child process */
	HV *			opts;
	AV *			files;
	STARTUPINFO		st;
	PROC_T			procinfo;
	BOOL			ok;
	SV *			ary_entry;
	DWORD			createflags = (CREATE_SUSPENDED |
					       CREATE_BREAKAWAY_FROM_JOB);
	char pbuf[MAX_PATH];   /* static buffer for 'exe' */
	void *env = NULL;
    CODE:
	files = (AV*)sv_2mortal((SV*)newAV());

	/* Store procinfo in an SV, to avoid worrying about memory */
	ary_entry = NEWSV(NEWZ_CONST_INT, sizeof(PROCESS_INFORMATION));
	SvPOK_on(ary_entry);
	SvCUR_set(ary_entry, sizeof(PROCESS_INFORMATION));
	*(SvEND(ary_entry)) = 0; /* NULL-terminated */
	procinfo = (PROC_T)SvPVX(ary_entry);

	/* Check whether 'exe' is NULL */
	SvGETMAGIC(svexe); /* so SvOK() works */
	if (SvOK(svexe))
	    exe = SvPV(svexe, PL_na);
	else
	    exe = NULL;

	/* Set up a lame-oh STARTUPINFO structure */
	memset(&st, 0, sizeof(STARTUPINFO));
	st.cb = sizeof(STARTUPINFO);
	st.dwFlags = STARTF_USESTDHANDLES;
	st.hStdInput  = GetStdHandle(STD_INPUT_HANDLE);
	st.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
	st.hStdError  = GetStdHandle(STD_ERROR_HANDLE);
	st.lpDesktop = NULL;
	st.lpTitle = NULL;
	st.lpReserved = NULL;
	st.cbReserved2 = 0;
	st.lpReserved2 = NULL;

	/* Munge `exe' if there are no path separator in it */
	if (exe && !strchr(exe, '/') && !strchr(exe, '\\')) {
	    char *exts[] = { ".exe", ".com", ".bat", NULL };
	    char *ext = strchr(exe, '.'); /* is there an extension? */
	    char *path = PerlEnv_getenv("PATH");
	    char *curr = path;
	    char *endp = strchr(curr, ';');
	    size_t len;
	    Stat_t sbuf;
	    while (endp) {
		len = endp - curr;
		strncpy(pbuf, curr, len);
		pbuf[len] = '\0';
		if (pbuf[len-1] != '\\' && pbuf[len-1] != '/')
		    strcat(pbuf, "/");
		strcat(pbuf, exe);

		/* If the extension was given, check it */
		if (ext) {
		    if (PerlLIO_stat(pbuf, &sbuf) == 0) {
			exe = pbuf;
			goto exe_found; /* break */
		    }
		}
		/* otherwise try each of the three extensions */
		else {
		    int i;
		    len = strlen(pbuf);
		    for (i = 0; exts[i]; ++i) {
			strcpy(pbuf + len, exts[i]);
			/* check for file existence */
			if (PerlLIO_stat(pbuf, &sbuf) == 0) {
			    exe = pbuf;
			    goto exe_found; /* break; break */
			}
		    }
		}

		/* select the next one */
		curr = endp + 1;
		endp = strchr(curr, ';');
	    }
	}
exe_found:

	/* Modify the `st' structure depending on what options are passed in
	 * the `opts' hash */
	if (items >= 4 && SvROK(ST(3)) && SvTYPE(SvRV(ST(3))) == SVt_PVHV) {
	    opts = (HV*)SvRV(ST(3));
	    if (hv_exists(opts, "cwd", 3))
		cwd = SvPV_nolen((SV*)*hv_fetch(opts, "cwd", 3, 0));
	    if (hv_exists(opts, "new_console", 11) &&
		    SvTRUE((SV*)*hv_fetch(opts, "new_console", 11, 0)))
		createflags |= CREATE_NEW_CONSOLE;
	    if (hv_exists(opts, "window_attr", 11)) {
		char *tmp = SvPV_nolen(*hv_fetch(opts, "window_attr", 11, 0));
		if (strEQ(tmp, "minimized")) {
		    st.wShowWindow = SW_SHOWMINIMIZED;
		    st.dwFlags |= STARTF_USESHOWWINDOW;
		}
		else if (strEQ(tmp, "maximized")) {
		    st.wShowWindow = SW_SHOWMAXIMIZED;
		    st.dwFlags |= STARTF_USESHOWWINDOW;
		}
		else if (strEQ(tmp, "hidden")) {
		    st.wShowWindow = SW_HIDE;
		    st.dwFlags |= STARTF_USESHOWWINDOW;
		}
	    }
	    if (hv_exists(opts, "new_group", 10) &&
		    SvTRUE((SV*)*hv_fetch(opts, "new_group", 10, 0)))
		createflags |= CREATE_NEW_PROCESS_GROUP;
	    if (hv_exists(opts, "no_window", 9) &&
		    SvTRUE((SV*)*hv_fetch(opts, "no_window", 9, 0)))
		createflags |= CREATE_NO_WINDOW;
	    if (hv_exists(opts, "stdin", 5)) {
		SV *tmp = (SV*)*hv_fetch(opts, "stdin", 5, 0);
		if (sv_isio(aTHX_ tmp)) {
		    int fd = PerlIO_fileno(IoIFP(sv_2io(tmp)));
		    st.hStdInput = (HANDLE)win32_get_osfhandle(fd);
		}
		else {
		    HANDLE t = CreateFile(
			    SvPV_nolen(tmp),
			    GENERIC_READ,
			    FILE_SHARE_READ,
			    NULL, /* safe on W2K and XP */
			    OPEN_EXISTING,
			    FILE_ATTRIBUTE_NORMAL,
			    NULL
		    );
		    if (t == INVALID_HANDLE_VALUE)
			XSRETURN_UNDEF;
		    st.hStdInput = t;
		    av_push(files, new_handle(aTHX_ st.hStdInput));
		}
		SetHandleInformation(st.hStdInput, HANDLE_FLAG_INHERIT,
				     HANDLE_FLAG_INHERIT);
	    }
	    if (hv_exists(opts, "stdout", 6)) {
		SV *tmp = (SV*)*hv_fetch(opts, "stdout", 6, 0);
		if (sv_isio(aTHX_ tmp)) {
		    int fd = PerlIO_fileno(IoOFP(sv_2io(tmp)));
		    st.hStdOutput = (HANDLE)win32_get_osfhandle(fd);
		}
		else {
		    HANDLE t = CreateFile(
			    SvPV_nolen(tmp),
			    GENERIC_WRITE,
			    FILE_SHARE_WRITE|FILE_SHARE_READ,
			    NULL,
			    OPEN_ALWAYS,
			    FILE_ATTRIBUTE_NORMAL,
			    NULL
			    );
		    if (t == INVALID_HANDLE_VALUE)
			XSRETURN_UNDEF;
		    st.hStdOutput = t;
		    av_push(files, new_handle(aTHX_ st.hStdOutput));
		}
		SetHandleInformation(st.hStdOutput, HANDLE_FLAG_INHERIT,
				     HANDLE_FLAG_INHERIT);
	    }
	    if (hv_exists(opts, "stderr", 6)) {
		SV *tmp = (SV*)*hv_fetch(opts, "stderr", 6, 0);
		if (sv_isio(aTHX_ tmp)) {
		    int fd = PerlIO_fileno(IoOFP(sv_2io(tmp)));
		    st.hStdError = (HANDLE)win32_get_osfhandle(fd);
		}
		else {
		    HANDLE t = CreateFile(
			    SvPV_nolen(tmp),
			    GENERIC_WRITE,
			    FILE_SHARE_WRITE|FILE_SHARE_READ,
			    NULL,
			    OPEN_ALWAYS,
			    FILE_ATTRIBUTE_NORMAL,
			    NULL
			    );
		    if (t == INVALID_HANDLE_VALUE)
			XSRETURN_UNDEF;
		    st.hStdError = t;
		    av_push(files, new_handle(aTHX_ st.hStdError));
		}
		SetHandleInformation(st.hStdError, HANDLE_FLAG_INHERIT,
				     HANDLE_FLAG_INHERIT);
	    }
	}
#ifdef PERL_IMPLICIT_SYS
	env = PerlEnv_get_childenv();
#endif
	ok = CreateProcess(
	    exe,		/* search PATH to find executable */
	    args,		/* executable, and its arguments  */
	    NULL,		/* process security    */
	    NULL,		/* thread security     */
	    TRUE,		/* inherit handles     */
	    createflags,	/* creation flags      */
	    env,		/* inherit environment */
	    cwd,		/* current directory   */
	    &st,
	    procinfo
	);
#ifdef PERL_IMPLICIT_SYS
	PerlEnv_free_childenv(env);
#endif
	if (!ok)
	    XSRETURN_UNDEF;

	/* Add the new process to the list of processes */
	av_push(self->procs, ary_entry);

	/* Add the new process to the Job */
	if (!AssignProcessToJobObject(self->hJob, procinfo->hProcess))
	    XSRETURN_UNDEF;

	/* Return the new PID */
	RETVAL = procinfo->dwProcessId;

    OUTPUT:
	RETVAL

int
run(self, timeout, ...)
	JOB_T	self
	double	timeout
    PREINIT:
	BOOL	which = 1; /* wait for ALL processes to complete */
	HANDLE *hlist;
	DWORD	ret, dwTimeout;
	I32	i, imax;
    CODE:
	if (items >= 3 && !SvTRUE(ST(2)))
	    which = 0;     /* wait for ANY process to complete */
	imax = AV_REAL_LEN(self->procs);
	Newz(NEWZ_CONST_INT, hlist, imax, HANDLE);
	SAVEFREEPV(hlist);

	if (!timeout)
	    dwTimeout = INFINITE;
	else
	    dwTimeout = (DWORD) (timeout * 1000.0);
        for (i = 0; i < imax; i++) {
	    STRLEN l;
	    SV *tmp = *av_fetch(self->procs, i, 0);
	    PROC_T inf = (PROC_T)SvPV(tmp, l);
	    hlist[i] = inf->hProcess;
	}
	resume_threads(aTHX_ self->procs);
	ret = WaitForMultipleObjects(imax, hlist, which, dwTimeout);
	RETVAL = 0;
	if (ret >= WAIT_OBJECT_0 && ret <= WAIT_OBJECT_0 + imax) {
	    RETVAL = 1; /* finished */
	}
	kill_threads(aTHX_ self);
    OUTPUT:
	RETVAL

int
watch(self, callback, interval, ...)
	JOB_T	self
	SV*	callback
	double	interval
    PREINIT:
	BOOL	which = 1; /* wait for ALL processes to complete */
	DWORD	ret, dwInterval;
	HANDLE *hlist;
	I32	i, imax;
        IV      stop;
    CODE:
	imax = AV_REAL_LEN(self->procs);
	Newz(NEWZ_CONST_INT, hlist, imax, HANDLE);
	SAVEFREEPV(hlist); /* free hlist on pseudo-scope exit */

	if (items >= 4 && !SvTRUE(ST(3)))
	    which = 0;     /* wait for ANY process to complete */
	if (!interval)
	    XSRETURN_UNDEF; /* you suck, programmer! */
	dwInterval = (DWORD)interval * 1000;
	for (i = 0; i < imax; i++) {
	    STRLEN l;
	    SV *tmp = *av_fetch(self->procs, i, 0);
	    PROC_T inf = (PROC_T)SvPV(tmp, l);
	    hlist[i] = inf->hProcess;
	}
	resume_threads(aTHX_ self->procs);
	RETVAL = 0;
	do {
	    SV *sv_self = ST(0); /* copy of self as an SV */
	    stop = 0;
	    ret = WaitForMultipleObjects(imax, hlist, which, dwInterval);

	    /* Call user's function if we've timed out (else break) */
	    if (ret == WAIT_TIMEOUT) {
		I32 count;

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		XPUSHs(sv_self);
		PUTBACK;

		count = call_sv(callback, G_SCALAR | G_EVAL);

		SPAGAIN;
		if (count != 1)
		    croak("Watchdog callback did not returned >1 result.");
		stop = POPi;
		PUTBACK;

		FREETMPS;
		LEAVE;
	    }
	    else {
		stop = 1;
		RETVAL = 1;
	    }
	} while (!stop);

	/* Kill the processes */
	kill_threads(aTHX_ self);

    OUTPUT:
	RETVAL

HV*
status(self)
	JOB_T	self
    CODE:
	get_status(aTHX_ self, 0); /* query w/o waiting for processes */
	RETVAL = self->info;
    OUTPUT:
	RETVAL
