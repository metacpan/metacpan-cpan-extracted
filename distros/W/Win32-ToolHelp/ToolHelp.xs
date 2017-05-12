#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Impl/Impl.h"

#undef XS_VERSION
#define XS_VERSION "0.32"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant_M(char *name, int len, int arg)
{
    if (1 + 3 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 3]) {
    case 'M':
	if (strEQ(name + 1, "AX_MODULE_NAME32")) {	/* M removed */
#ifdef MAX_MODULE_NAME32
	    return MAX_MODULE_NAME32;
#else
	    goto not_there;
#endif
	}
    case 'P':
	if (strEQ(name + 1, "AX_PATH")) {	/* M removed */
#ifdef MAX_PATH
	    return MAX_PATH;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    switch (name[0 + 0]) {
    case 'M':
	return constant_M(name, len, arg);
    case 'W':
	if (strEQ(name + 0, "WIN32_TOOLHELP_IMPL_VER")) {	/*  removed */
#ifdef WIN32_TOOLHELP_IMPL_VER
	    return WIN32_TOOLHELP_IMPL_VER;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Win32::ToolHelp		PACKAGE = Win32::ToolHelp		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL


void
GetProcesses()
	INIT:
		AV* a;
		SV* s;
		HANDLE h;
		PROCESSENTRY32 p;
	PPCODE:
		for (h = GetFirstProcess(&p);
			 h != INVALID_HANDLE_VALUE;
			 h = GetNextProcess(h, &p))
		{
			a = (AV*) sv_2mortal((SV*) newAV());
			av_push(a, newSViv(p.cntUsage));
			av_push(a, newSViv(p.th32ProcessID));
			av_push(a, newSViv(p.th32DefaultHeapID));
			av_push(a, newSViv(p.th32ModuleID));
			av_push(a, newSViv(p.cntThreads));
			av_push(a, newSViv(p.th32ParentProcessID));
			av_push(a, newSViv(p.pcPriClassBase));
			av_push(a, newSViv(p.dwFlags));
			av_push(a, newSVpv(p.szExeFile, strlen(p.szExeFile)));
			XPUSHs(sv_2mortal(newRV((SV*) a)));
		}


void
GetProcessModules(pid)
		unsigned long pid
	INIT:
		AV* a;
		SV* s;
		HANDLE h;
		MODULEENTRY32 m;
	PPCODE:
		for (h = GetFirstModule(pid, &m);
			 h != INVALID_HANDLE_VALUE;
			 h = GetNextModule(h, &m))
		{
			a = (AV*) sv_2mortal((SV*) newAV());
			av_push(a, newSViv(m.th32ModuleID));
			av_push(a, newSViv(m.th32ProcessID));
			av_push(a, newSViv(m.GlblcntUsage));
			av_push(a, newSViv(m.ProccntUsage));
			av_push(a, newSViv((IV) m.modBaseAddr));
			av_push(a, newSViv(m.modBaseSize));
			av_push(a, newSViv((IV) m.hModule));
			av_push(a, newSVpv(m.szModule, strlen(m.szModule)));
			av_push(a, newSVpv(m.szExePath, strlen(m.szExePath)));
			XPUSHs(sv_2mortal(newRV((SV*) a)));
		}
