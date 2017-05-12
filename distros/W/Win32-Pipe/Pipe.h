
#define	SYNTAX_ERROR	999
#define CROAK(xxxx)													\
				PUSHMARK(sp);										\
				XPUSHs(sv_2mortal(newSVnv((double)SYNTAX_ERROR)));	\
				XPUSHs(sv_2mortal(newSVpv(xxxx, strlen(xxxx))));	\
				PUTBACK;											\
				return;												\

#define	PIPE_TIMEOUT	5000

#define	VERNAME		"Pipe extension for Win32 Perl"
//#define VERSION		"v960610"
#define VERDATE		__DATE__
#define VERAUTH     "Dave Roth <rothd@roth.net>"
#define VERCRED		"Copyright (c) 1996 Dave Roth.\n"	
					 
int	Error(int iErrorNum, char *szErrorText);
