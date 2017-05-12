/* 
 * mm.h --
 *
 *	This is the header file for the module that implements
 *	command structure lookups.
 *
 * Copyright (c) 1997,1998 Jeffrey Hobbs
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef _MM_H_
#define _MM_H_

#include <string.h>
#include <stdlib.h>
#include <tk.h>

/* Make sure this syncs with Makefile.in */
#define MM_MAJOR_VERSION	1
#define MM_MINOR_VERSION	0
#define MM_RELEASE_SERIAL	0
#define MM_VERSION		"1.0"
#define MM_PATCH_LEVEL		"1.0.0"

/* Now we start defining package specific stuff */

#define MM_ERROR	0
#define MM_VALUE	(1<<0)
#define MM_PROC		(1<<1)
#define MM_OBJPROC	(1<<2)
#define MM_SUBPROC	(1<<3)

#define MM_LAST		((char *) NULL)

#define MM_OVERWRITE	(1<<0)
#define MM_MERGE	(1<<1)

/* structure for use in parsing general major/minor commands */
typedef struct {
    char *name;		/* name of the command/value */
    Tcl_CmdProc *proc;	/* >0 because 0 represents an error or proc */
    int type;		/* whether it is proc or just value */
    ClientData data;	/* optional clientData arg */
} MajorMinor_Cmd;

extern int	MM_GetProcExact _ANSI_ARGS_((const MajorMinor_Cmd *cmds,
					     const char *name,
					     Tcl_CmdProc **proc));
extern void	MM_GetError _ANSI_ARGS_((Tcl_Interp *interp,
					 const MajorMinor_Cmd *cmds,
					 const char *arg));
extern int	MM_GetProc _ANSI_ARGS_((Tcl_Interp *interp,
					MajorMinor_Cmd *cmds,
					const char *arg,
					MajorMinor_Cmd **cmd));
extern int	MM_HandleArgs _ANSI_ARGS_((ClientData clientData,
					   Tcl_Interp *interp,
					   MajorMinor_Cmd *cmds,
					   int argc, char **argv));
extern int	MM_HandleCmds _ANSI_ARGS_((ClientData clientData,
					   Tcl_Interp *interp,
					   int argc, char **argv));
extern MajorMinor_Cmd *MM_InitCmds _ANSI_ARGS_((Tcl_Interp *interp, char *name,
					 MajorMinor_Cmd *cmds,
					 ClientData clientData, int flags));
extern int	MM_InsertCmd _ANSI_ARGS_((Tcl_Interp *interp,
					  MajorMinor_Cmd *cmds,
					  const char *name,
					  Tcl_CmdProc **proc,
					  int type));
extern int	MM_RemoveCmd _ANSI_ARGS_((Tcl_Interp *interp,
					  MajorMinor_Cmd *cmds,
					  const char *name));

EXTERN int	Majmin_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int	Majmin_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int	Tcl_MajminCmd _ANSI_ARGS_((ClientData clientData,
			Tcl_Interp *interp, int argc, char **argv));

/* structure for use in parsing table commands/values */
typedef struct {
  char *name;		/* name of the command/value */
  int value;		/* >0 because 0 represents an error or proc */
} Cmd_Struct;

extern char *	Cmd_GetName _ANSI_ARGS_((const Cmd_Struct *cmds, int val));
extern int	Cmd_GetValue _ANSI_ARGS_((const Cmd_Struct *cmds,
					  Arg arg));
extern void	Cmd_GetError _ANSI_ARGS_((Tcl_Interp *interp,
					  const Cmd_Struct *cmds,
					  Arg arg));
extern int	Cmd_Parse _ANSI_ARGS_((Tcl_Interp *interp, Cmd_Struct *cmds,
				       const char *arg));

extern int	Cmd_OptionSet _ANSI_ARGS_((ClientData clientData,
					   Tcl_Interp *interp,
					   Tk_Window unused, Arg  value,
					   char *widgRec, int offset));
extern Arg	Cmd_OptionGet _ANSI_ARGS_((ClientData clientData,
					   Tk_Window unused, char *widgRec,
					   int offset,
					   Tcl_FreeProc **freeProcPtr));
extern int	Cmd_BitSet _ANSI_ARGS_((ClientData clientData,
					Tcl_Interp *interp,
					Tk_Window unused, Arg value,
					char *widgRec, int offset));
extern char *	Cmd_BitGet _ANSI_ARGS_((ClientData clientData,
					Tk_Window unused, char *widgRec,
					int offset,
					Tcl_FreeProc **freeProcPtr));

#endif /* _MM_H_ */
