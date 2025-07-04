/*   intrpvar.h 
 *
 *    Copyright (C) 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
 *    2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#include "handy.h"

/* These variables are per-interpreter in threaded/multiplicity builds,
 * global otherwise.

 * Don't forget to re-run regen/embed.pl to propagate changes! */

/* New variables must be added to the very end for binary compatibility. */

/* DON'T FORGET to add your variable also to perl_clone()! (in sv.c) */

/* The 'I' prefix is only needed for vars that need appropriate #defines
 * generated when built with or without MULTIPLICITY.  It is also used
 * to generate the appropriate export list for win32.  If the variable
 * needs to be initialized, use PERLVARI.
 *
 * When building without MULTIPLICITY, these variables will be truly global.
 *
 * Important ones in the first cache line (if alignment is done right) */

PERLVAR(I, stack_sp,	SV **)		/* top of the stack */
PERLVAR(I, op,		OP *)		/* currently executing op */
PERLVAR(I, curpad,	SV **)		/* active pad (lexicals+tmps) */

PERLVAR(I, stack_base,	SV **)
PERLVAR(I, stack_max,	SV **)

PERLVAR(I, savestack,	ANY *)		/* items that need to be restored when
                                           LEAVEing scopes we've ENTERed */
PERLVAR(I, savestack_ix, I32)
PERLVAR(I, savestack_max, I32)

PERLVAR(I, scopestack,	I32 *)		/* scopes we've ENTERed */
PERLVAR(I, scopestack_ix, I32)
PERLVAR(I, scopestack_max, I32)

PERLVAR(I, tmps_stack,	SV **)		/* mortals we've made */
PERLVARI(I, tmps_ix,	SSize_t,	-1)
PERLVARI(I, tmps_floor,	SSize_t,	-1)
PERLVAR(I, tmps_max,	SSize_t)        /* first unalloced slot in tmps stack */

PERLVAR(I, markstack,	Stack_off_t *)	/* stack_sp locations we're
                                           remembering */
PERLVAR(I, markstack_ptr, Stack_off_t *)
PERLVAR(I, markstack_max, Stack_off_t *)

PERLVARI(I, sub_generation, U32, 1)	/* incr to invalidate method cache */

#ifdef PERL_HASH_RANDOMIZE_KEYS
#ifdef USE_PERL_PERTURB_KEYS
PERLVARI(I, hash_rand_bits_enabled, U8, 1) /* used to randomize hash stuff
                                              0. no-random
                                              1. random
                                              2. deterministic */
#endif
PERLVARI(I, hash_rand_bits, UV, 0)      /* used to randomize hash stuff */
#endif
PERLVAR(I, strtab,	HV *)		/* shared string table */
/* prog counter for the currently executing OP_MULTIDEREF Used to signal
 * to S_find_uninit_var() where we are */
PERLVAR(I, multideref_pc, UNOP_AUX_item *)

/* Fields used by magic variables such as $@, $/ and so on */
PERLVAR(I, curpm,	PMOP *)		/* what to do \ interps in REs from */
PERLVAR(I, curpm_under,        PMOP *)                /* what to do \ interps in REs from */

PERLVAR(I, tainting,	bool)		/* ? doing taint checks */
PERLVARI(I, tainted,	bool, FALSE)	/* using variables controlled by $< */

/* PL_delaymagic is currently used for two purposes: to assure simultaneous
 * updates in ($<,$>) = ..., and to assure atomic update in push/unshift
 * @ISA, It works like this: a few places such as pp_push set the DM_DELAY
 * flag; then various places such as av_store() skip mg_set(ary) if this
 * flag is set, and various magic vtable methods set flags like
 * DM_ARRAY_ISA if they've seen something of that ilk. Finally when
 * control returns to pp_push or whatever, it sees if any of those flags
 * have been set, and if so finally calls mg_set().
 *
 * NB: PL_delaymagic is automatically saved and restored by JMPENV_PUSH
 * / POP. This removes the need to do ENTER/SAVEI16(PL_delaymagic)/LEAVE
 * in hot code like pp_push.
 */
PERLVAR(I, delaymagic,	U16)		/* ($<,$>) = ... */

/*
=for apidoc_section $warning
=for apidoc mn|U8|PL_dowarn

The C variable that roughly corresponds to Perl's C<$^W> warning variable.
However, C<$^W> is treated as a boolean, whereas C<PL_dowarn> is a
collection of flag bits.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, dowarn,	U8)

#if defined (PERL_UTF8_CACHE_ASSERT) || defined (DEBUGGING)
#  define PERL___I -1
#else
#  define PERL___I 1
#endif
PERLVARI(I, utf8cache, I8, PERL___I)	/* Is the utf8 caching code enabled? */
#undef PERL___I

/*
=for apidoc_section $GV
=for apidoc Amn|GV *|PL_defgv

The GV representing C<*_>.  Useful for access to C<$_>.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, localizing,  U8)             /* are we processing a local() list?
                                           0 = no, 1 = localizing, 2 = delocalizing */
PERLVAR(I, in_eval,	U8)		/* trap "fatal" errors? */
PERLVAR(I, defgv,	GV *)           /* the *_ glob */

/*
=for apidoc_section $GV
=for apidoc Amn|HV*|PL_curstash

The stash for the package code will be compiled into.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

/* Stashes */
PERLVAR(I, defstash,	HV *)		/* main symbol table */
PERLVAR(I, curstash,	HV *)		/* symbol table for current package */

/*
=for apidoc_section $COP
=for apidoc Amn|COP*|PL_curcop

The currently active COP (control op) roughly representing the current
statement in the source.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, curcop,	COP *)
PERLVAR(I, curstack,	AV *)		/* THE STACK */
PERLVAR(I, curstackinfo, PERL_SI *)	/* current stack + context */
PERLVAR(I, mainstack,	AV *)		/* the stack when nothing funny is
                                           happening */

/* memory management */
PERLVAR(I, sv_count,	IV)		/* how many SV* are currently allocated */

PERLVAR(I, sv_root,	SV *)		/* storage for SVs belonging to interp */
PERLVAR(I, sv_arenaroot, SV *)		/* list of areas for garbage collection */

/* fake PMOP that PL_curpm points to while in (?{}) so $1 et al are visible */
PERLVARI(I, reg_curpm, PMOP*, NULL)

/* the currently active slab in a chain of slabs of regmatch states,
 * and the currently active state within that slab. This stack of states
 * is shared amongst re-entrant calls to the regex engine */

PERLVARI(I, regmatch_slab, regmatch_slab *,	NULL)
PERLVAR(I, regmatch_state, regmatch_state *)

PERLVAR(I, comppad,	PAD *)		/* storage for lexically scoped temporaries */

/*
=for apidoc_section $SV
=for apidoc Amn|SV|PL_sv_undef
This is the C<undef> SV.  It is readonly.  Always refer to this as
C<&PL_sv_undef>.

=for apidoc Amn|SV|PL_sv_no
This is the C<false> SV.  It is readonly.  See C<L</PL_sv_yes>>.  Always refer
to this as C<&PL_sv_no>.

=for apidoc Amn|SV|PL_sv_yes
This is the C<true> SV.  It is readonly.  See C<L</PL_sv_no>>.  Always refer to
this as C<&PL_sv_yes>.

=for apidoc Amn|SV|PL_sv_zero
This readonly SV has a zero numeric value and a C<"0"> string value. It's
similar to C<L</PL_sv_no>> except for its string value. Can be used as a
cheap alternative to C<mXPUSHi(0)> for example.  Always refer to this as
C<&PL_sv_zero>. Introduced in 5.28.

=cut
*/

#ifdef MULTIPLICITY
PERLVAR(I, sv_yes,	SV)
PERLVAR(I, sv_undef,	SV)
PERLVAR(I, sv_no,	SV)
PERLVAR(I, sv_zero,	SV)
#else
/* store the immortals as an array to ensure they are contiguous in
 * memory: makes SvIMMORTAL_INTERP(sv) possible */
PERLVARA(I, sv_immortals, 4, SV)
#endif

PERLVAR(I, padname_undef,	PADNAME)
PERLVAR(I, padname_const,	PADNAME)

/*
=for apidoc_section $SV
=for apidoc Cmn||PL_Sv

A scratch pad SV for whatever temporary use you need.  Chiefly used as a
fallback by macros on platforms where L<perlapi/PERL_USE_GCC_BRACE_GROUPS>> is
unavailable, and which would otherwise evaluate their SV parameter more than
once.

B<BUT BEWARE>, if this is used in a situation where something that is using it
is in a call stack with something else that is using it, this variable would
get zapped, leading to hard-to-diagnose errors.

These days using an inline function is generally preferred instead.

=cut
*/
PERLVAR(I, Sv,		SV *)

PERLVAR(I, parser,	yy_parser *)	/* current parser state */

PERLVAR(I, stashcache,	HV *)		/* Cache to speed up S_method_common */


/*
=for apidoc_section $string
=for apidoc Amn|STRLEN|PL_na

A scratch pad variable in which to store a C<STRLEN> value.  If would have been
better named something like C<PL_temp_strlen>.

It is is typically used with C<SvPV> when one is actually planning to discard
the returned length, (hence the length is "Not Applicable", which is how this
variable got its name).

B<BUT BEWARE>, if this is used in a situation where something that is using it
is in a call stack with something else that is using it, this variable would
get zapped, leading to hard-to-diagnose errors.

It is usually more efficient to either declare a local variable and use that
instead, or to use the C<SvPV_nolen> macro.

=cut
*/

PERLVAR(I, na,		STRLEN)		/* for use in SvPV when length is
                                           Not Applicable */

/* stat stuff */
PERLVAR(I, statcache,	Stat_t)		/* _ */
PERLVAR(I, statgv,	GV *)
PERLVARI(I, statname,	SV *,	NULL)

/*
=for apidoc_section $io
=for apidoc mn|SV*|PL_rs

The input record separator - C<$/> in Perl space.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=for apidoc_section $io
=for apidoc mn|GV*|PL_last_in_gv

The GV which was last used for a filehandle input operation.  (C<< <FH> >>)

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=for apidoc_section $io
=for apidoc mn|GV*|PL_ofsgv

The glob containing the output field separator - C<*,> in Perl space.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, rs,		SV *)		/* input record separator $/ */
PERLVAR(I, last_in_gv,	GV *)		/* GV used in last <FH> */
PERLVAR(I, ofsgv,	GV *)		/* GV of output field separator *, */
PERLVAR(I, defoutgv,	GV *)		/* default FH for output */
PERLVARI(I, chopset,	const char *, " \n-")	/* $: */
PERLVAR(I, formtarget,	SV *)
PERLVAR(I, bodytarget,	SV *)
PERLVAR(I, toptarget,	SV *)


PERLVAR(I, restartop,	OP *)		/* propagating an error from croak? */
PERLVAR(I, restartjmpenv, JMPENV *)	/* target frame for longjmp in die */

PERLVAR(I, top_env,	JMPENV *)	/* ptr to current sigjmp environment */
PERLVAR(I, start_env,	JMPENV)		/* empty startup sigjmp environment */
PERLVARI(I, errors,	SV *,	NULL)	/* outstanding queued errors */

/* statics "owned" by various functions */
PERLVAR(I, hv_fetch_ent_mh, HE*)	/* owned by hv_fetch_ent() */

PERLVAR(I, lastgotoprobe, OP*)		/* from pp_ctl.c */

/* sort stuff */
PERLVAR(I, sortcop,	OP *)		/* user defined sort routine */
PERLVAR(I, sortstash,	HV *)		/* which is in some package or other */
PERLVAR(I, firstgv,	GV *)		/* $a */
PERLVAR(I, secondgv,	GV *)		/* $b */

/* float buffer */
PERLVAR(I, efloatbuf,	char *)
PERLVAR(I, efloatsize,	STRLEN)

PERLVARI(I, dumpindent,	U16,	4)	/* number of blanks per dump
                                           indentation level */

/*
=for apidoc_section $embedding
=for apidoc Amn|U8|PL_exit_flags

Contains flags controlling perl's behaviour on exit():

=over

=item * C<PERL_EXIT_DESTRUCT_END>

If set, END blocks are executed when the interpreter is destroyed.
This is normally set by perl itself after the interpreter is
constructed.

=item * C<PERL_EXIT_ABORT>

Call C<abort()> on exit.  This is used internally by perl itself to
abort if exit is called while processing exit.

=item * C<PERL_EXIT_WARN>

Warn on exit.

=item * C<PERL_EXIT_EXPECTED>

Set by the L<perlfunc/exit> operator.

=back

=for apidoc Amnh||PERL_EXIT_EXPECTED
=for apidoc Amnh||PERL_EXIT_ABORT
=for apidoc Amnh||PERL_EXIT_DESTRUCT_END
=for apidoc Amnh||PERL_EXIT_WARN

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, exit_flags,	U8)		/* was exit() unexpected, etc. */

PERLVAR(I, utf8locale,	bool)		/* utf8 locale detected */

#if defined(USE_LOCALE) && defined(USE_LOCALE_THREADS)
PERLVARI(I, locale_mutex_depth, int, 0)     /* Emulate general semaphore */
#endif

#ifdef USE_LOCALE_CTYPE
PERLVAR(I, warn_locale, SV *)
PERLVARI(I, in_utf8_CTYPE_locale, bool, false)
PERLVARI(I, in_utf8_turkic_locale, bool, false)
#endif

PERLVARA(I, colors,6,	char *)		/* values from PERL_RE_COLORS env var */

/*
=for apidoc_section $optree_construction
=for apidoc Amn|peep_t|PL_peepp

Pointer to the per-subroutine peephole optimiser.  This is a function
that gets called at the end of compilation of a Perl subroutine (or
equivalently independent piece of Perl code) to perform fixups of
some ops and to perform small-scale optimisations.  The function is
called once for each subroutine that is compiled, and is passed, as sole
parameter, a pointer to the op that is the entry point to the subroutine.
It modifies the op tree in place.

The peephole optimiser should never be completely replaced.  Rather,
add code to it by wrapping the existing optimiser.  The basic way to do
this can be seen in L<perlguts/Compile pass 3: peephole optimization>.
If the new code wishes to operate on ops throughout the subroutine's
structure, rather than just at the top level, it is likely to be more
convenient to wrap the L</PL_rpeepp> hook.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVARI(I, peepp,	peep_t, Perl_peep)

/*
=for apidoc_section $optree_construction
=for apidoc Amn|peep_t|PL_rpeepp

Pointer to the recursive peephole optimiser.  This is a function
that gets called at the end of compilation of a Perl subroutine (or
equivalently independent piece of Perl code) to perform fixups of some
ops and to perform small-scale optimisations.  The function is called
once for each chain of ops linked through their C<op_next> fields;
it is recursively called to handle each side chain.  It is passed, as
sole parameter, a pointer to the op that is at the head of the chain.
It modifies the op tree in place.

The peephole optimiser should never be completely replaced.  Rather,
add code to it by wrapping the existing optimiser.  The basic way to do
this can be seen in L<perlguts/Compile pass 3: peephole optimization>.
If the new code wishes to operate only on ops at a subroutine's top level,
rather than throughout the structure, it is likely to be more convenient
to wrap the L</PL_peepp> hook.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVARI(I, rpeepp,	peep_t, Perl_rpeep)

/*
=for apidoc_section $optrees
=for apidoc Amn|Perl_ophook_t|PL_opfreehook

When non-C<NULL>, the function pointed by this variable will be called each time an OP is freed with the corresponding OP as the argument.
This allows extensions to free any extra attribute they have locally attached to an OP.
It is also assured to first fire for the parent OP and then for its kids.

When you replace this variable, it is considered a good practice to store the possibly previously installed hook and that you recall it inside your own.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVARI(I, opfreehook,	Perl_ophook_t, 0) /* op_free() hook */

PERLVARI(I, watchaddr,	char **, 0)
PERLVAR(I, watchok,	char *)

PERLVAR(I, perldb,	U32)

PERLVAR(I, signals,	U32)	/* Using which pre-5.8 signals */

PERLVAR(I, reentrant_retint, int)	/* Integer return value from reentrant functions */

/* pseudo environmental stuff */
PERLVAR(I, origargc,	int)
PERLVAR(I, origargv,	char **)
PERLVAR(I, envgv,	GV *)
PERLVAR(I, incgv,	GV *)
PERLVAR(I, hintgv,	GV *)
PERLVAR(I, origfilename, char *)
PERLVARI(I, xsubfilename, const char *, NULL)
PERLVAR(I, diehook,	SV *)
PERLVAR(I, warnhook,	SV *)
/* keyword hooks*/
PERLVARI(I, hook__require__before, SV *,NULL)
PERLVARI(I, hook__require__after, SV *,NULL)

/* switches */
PERLVAR(I, patchlevel,	SV *)
PERLVAR(I, localpatches, const char * const *)
PERLVARI(I, splitstr,	char *, NULL)

PERLVAR(I, minus_c,	bool)
PERLVAR(I, minus_n,	bool)
PERLVAR(I, minus_p,	bool)
PERLVAR(I, minus_l,	bool)
PERLVAR(I, minus_a,	bool)
PERLVAR(I, minus_F,	bool)
PERLVAR(I, doswitches,	bool)
PERLVAR(I, minus_E,	bool)

PERLVAR(I, inplace,	char *)
PERLVAR(I, e_script,	SV *)

PERLVAR(I, basetime,	Time_t)		/* $^T */

PERLVARI(I, maxsysfd,	I32,	MAXSYSFD)
                                        /* top fd to pass to subprocesses */
PERLVAR(I, statusvalue,	I32)		/* $? */
#ifdef VMS
PERLVAR(I, statusvalue_vms, U32)
#else
PERLVAR(I, statusvalue_posix, I32)
#endif

PERLVARI(I, sig_pending, int, 0)	/* Number if highest signal pending */
PERLVAR(I, psig_pend, int *)		/* per-signal "count" of pending */

/* shortcuts to various I/O objects */
PERLVAR(I, stdingv,	GV *)		/*  *STDIN      */
PERLVAR(I, stderrgv,	GV *)		/*  *STDERR     */
PERLVAR(I, argvgv,	GV *)		/*  *ARGV       */
PERLVAR(I, argvoutgv,	GV *)		/*  *ARGVOUT    */
PERLVAR(I, argvout_stack, AV *)

/* shortcuts to regexp stuff */
PERLVAR(I, replgv,	GV *)		/*  *^R         */

/* shortcuts to misc objects */
PERLVAR(I, errgv,	GV *)		/*  *@          */

/* shortcuts to debugging objects */
PERLVAR(I, DBgv,	GV *)		/*  *DB::DB     */
PERLVAR(I, DBline,	GV *)		/*  *DB::line   */

/*
=for apidoc_section $debugging
=for apidoc mn|GV *|PL_DBsub
When Perl is run in debugging mode, with the B<-d> switch, this GV contains
the SV which holds the name of the sub being debugged.  This is the C
variable which corresponds to Perl's $DB::sub variable.  See
C<L</PL_DBsingle>>.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=for apidoc mn|SV *|PL_DBsingle
When Perl is run in debugging mode, with the B<-d> switch, this SV is a
boolean which indicates whether subs are being single-stepped.
Single-stepping is automatically turned on after every step.  This is the C
variable which corresponds to Perl's $DB::single variable.  See
C<L</PL_DBsub>>.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=for apidoc mn|SV *|PL_DBtrace
Trace variable used when Perl is run in debugging mode, with the B<-d>
switch.  This is the C variable which corresponds to Perl's $DB::trace
variable.  See C<L</PL_DBsingle>>.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, DBsub,	GV *)		/*  *DB::sub    */
PERLVAR(I, DBsingle,	SV *)		/*  $DB::single */
PERLVAR(I, DBtrace,	SV *)		/*  $DB::trace  */
PERLVAR(I, DBsignal,	SV *)		/*  $DB::signal */
PERLVAR(I, dbargs,	AV *)		/* args to call listed by caller function */

PERLVARA(I, DBcontrol,    DBVARMG_COUNT, IV) /* IV versions of $DB::single, trace, signal */

/* symbol tables */
PERLVAR(I, debstash,	HV *)		/* symbol table for perldb package */
PERLVAR(I, globalstash,	HV *)		/* global keyword overrides imported here */
PERLVAR(I, curstname,	SV *)		/* name of current package */
PERLVAR(I, beginav,	AV *)		/* names of BEGIN subroutines */
PERLVAR(I, endav,	AV *)		/* names of END subroutines */
PERLVAR(I, unitcheckav,	AV *)		/* names of UNITCHECK subroutines */
PERLVAR(I, checkav,	AV *)		/* names of CHECK subroutines */
PERLVAR(I, initav,	AV *)		/* names of INIT subroutines */

/* subprocess state */
PERLVAR(I, fdpid,	AV *)		/* keep fd-to-pid mappings for my_popen */

/* internal state */
PERLVARI(I, op_mask,	char *,	NULL)	/* masked operations for safe evals */

/* current interpreter roots */
PERLVAR(I, main_cv,	CV *)
PERLVAR(I, main_root,	OP *)
PERLVAR(I, main_start,	OP *)
PERLVAR(I, eval_root,	OP *)
PERLVAR(I, eval_start,	OP *)

/* runtime control stuff */
PERLVARI(I, curcopdb,	COP *,	NULL)

PERLVAR(I, filemode,	int)		/* so nextargv() can preserve mode */
PERLVAR(I, lastfd,	int)		/* what to preserve mode on */
PERLVAR(I, oldname,	char *)		/* what to preserve mode on */
/* Elements in this array have ';' appended and are injected as a single line
   into the tokeniser. You can't put any (literal) newlines into any program
   you stuff in into this array, as the point where it's injected is expecting
   a single physical line. */
PERLVAR(I, preambleav,	AV *)
PERLVAR(I, mess_sv,	SV *)
PERLVAR(I, ors_sv,	SV *)		/* output record separator $\ */

/* funky return mechanisms */
PERLVAR(I, forkprocess,	int)		/* so do_open |- can return proc# */

/* statics moved here for shared library purposes */
PERLVARI(I, gensym,	I32,	0)	/* next symbol for getsym() to define */
PERLVARI(I, cv_has_eval, bool, FALSE)	/* PL_compcv includes an entereval or similar */
PERLVAR(I, taint_warn,	bool)		/* taint warns instead of dying */
PERLVARI(I, laststype,	U16,	OP_STAT)

PERLVARI(I, laststatval, int,	-1)

PERLVAR(I, modcount,	I32)		/* how much op_lvalue()ification in
                                           assignment? */

/* interpreter atexit processing */
PERLVARI(I, exitlistlen, I32, 0)	/* length of same */
PERLVARI(I, exitlist,	PerlExitListEntry *, NULL)
                                        /* list of exit functions */

/*
=for apidoc_section $HV
=for apidoc Amn|HV*|PL_modglobal

C<PL_modglobal> is a general purpose, interpreter global HV for use by
extensions that need to keep information on a per-interpreter basis.
In a pinch, it can also be used as a symbol table for extensions
to share data among each other.  It is a good idea to use keys
prefixed by the package name of the extension that owns the data.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/

PERLVAR(I, modglobal,	HV *)		/* per-interp module data */

/* these used to be in global before 5.004_68 */
PERLVARI(I, profiledata, U32 *,	NULL)	/* table of ops, counts */

PERLVAR(I, compiling,	COP)		/* compiling/done executing marker */

PERLVAR(I, compcv,	CV *)		/* currently compiling subroutine */
PERLVAR(I, comppad_name, PADNAMELIST *)	/* variable names for "my" variables */
PERLVAR(I, comppad_name_fill,	PADOFFSET)/* last "introduced" variable offset */
PERLVAR(I, comppad_name_floor,	PADOFFSET)/* start of vars in innermost block */

#ifdef HAVE_INTERP_INTERN
PERLVAR(I, sys_intern,	struct interp_intern)
                                        /* platform internals */
#endif

/* more statics moved here */
PERLVAR(I, DBcv,	CV *)		/* from perl.c */
PERLVARI(I, generation,	int,	100)	/* scan sequence# for OP_AASSIGN
                                           compile-time common elem detection */

PERLVAR(I, unicode, U32)	/* Unicode features: $ENV{PERL_UNICODE} or -C */

PERLVARI(I, in_clean_objs,bool,    FALSE)	/* from sv.c */
PERLVARI(I, in_clean_all, bool,    FALSE)	/* ptrs to freed SVs now legal */
PERLVAR(I, nomemok,	bool)		/* let malloc context handle nomem */
PERLVARI(I, savebegin,	bool,	FALSE)	/* save BEGINs for compiler	*/


PERLVAR(I, delaymagic_uid,	Uid_t)	/* current real user id, only for delaymagic */
PERLVAR(I, delaymagic_euid,	Uid_t)	/* current effective user id, only for delaymagic */
PERLVAR(I, delaymagic_gid,	Gid_t)	/* current real group id, only for delaymagic */
PERLVAR(I, delaymagic_egid,	Gid_t)	/* current effective group id, only for delaymagic */
PERLVARI(I, an,		U32,	0)	/* malloc sequence number */

/* Perl_Ibreakable_sub_generation_ptr was too long for VMS, hence "gen"  */
PERLVARI(I, breakable_sub_gen, U32, 0)

#ifdef DEBUGGING
    /* exercise wrap-around */
    #define PERL_COP_SEQMAX (U32_MAX-50)
#else
    #define PERL_COP_SEQMAX 0
#endif
PERLVARI(I, cop_seqmax,	U32,	PERL_COP_SEQMAX) /* statement sequence number */
#undef PERL_COP_SEQMAX

PERLVARI(I, evalseq,	U32,	0)	/* eval sequence number */
PERLVAR(I, origalen,	U32)
#ifdef PERL_USES_PL_PIDSTATUS
PERLVAR(I, pidstatus,	HV *)		/* pid-to-status mappings for waitpid */
#endif
PERLVAR(I, osname,	char *)		/* operating system */

PERLVAR(I, sighandlerp,	 Sighandler_t)
/* these two are provided only to solve library linkage issues; they
 * should not be hooked by user code */
PERLVAR(I, sighandler1p, Sighandler1_t)
PERLVAR(I, sighandler3p, Sighandler3_t)

PERLVARA(I, body_roots,	PERL_ARENA_ROOTS_SIZE, void*) /* array of body roots */

PERLVAR(I, debug,	volatile U32)	/* flags given to -D switch */

PERLVARI(I, padlist_generation, U32, 1)	/* id to identify padlist clones */

PERLVARI(I, runops,	runops_proc_t, RUNOPS_DEFAULT)

PERLVAR(I, subname,	SV *)		/* name of current subroutine */

PERLVAR(I, subline,	I32)		/* line this subroutine began on */
PERLVAR(I, min_intro_pending, PADOFFSET)/* start of vars to introduce */

PERLVAR(I, max_intro_pending, PADOFFSET)/* end of vars to introduce */
PERLVAR(I, padix,	PADOFFSET)	/* lowest unused index - 1
                                           in current "register" pad */
PERLVAR(I, constpadix,	PADOFFSET)	/* lowest unused for constants */

PERLVAR(I, padix_floor,	PADOFFSET)	/* how low may inner block reset padix */

#if defined(USE_POSIX_2008_LOCALE) && defined(MULTIPLICITY)
PERLVARI(I, cur_locale_obj, locale_t, LC_GLOBAL_LOCALE)
#endif
#ifdef USE_PL_CURLOCALES

/* Some configurations do not allow perl to query libc to find out what the
 * locale for a given category is.  On such platforms this array contains that
 * information, indexed by the perl-defined category index.
 * Note that this array keeps the actual locale for each category.  LC_NUMERIC
 * is almost always toggled into the C locale, and the locale it nominally is
 * is stored as PL_numeric_name. */
PERLVARA(I, curlocales, LOCALE_CATEGORIES_COUNT_ + 1, const char *)

#endif
#ifdef USE_PL_CUR_LC_ALL
PERLVARI(I, cur_LC_ALL, const char *, NULL)
#endif
#ifdef USE_LOCALE_COLLATE

/* The memory needed to store the collxfrm transformation of a string with
 * length 'x' is predicted by the linear equation mx+b; m=mult, b=base */
PERLVARI(I, collxfrm_mult,Size_t, 0)	/* Expansion factor in *xfrm();
                                           0 => unknown or bad, depending on
                                           base */
PERLVAR(I, collxfrm_base, Size_t)	/* Basic overhead in *xfrm();
                                           mult == 0, base == 0 => need to compute
                                           mult == 0, base != 0 => ill-formed;
                                         */
PERLVAR(I, collation_name, char *)	/* Name of current collation */
PERLVARI(I, collation_ix, PERL_UINTMAX_T, 0)	/* Collation generation index */
PERLVARI(I, strxfrm_NUL_replacement, U8, 0)  /* Code point to replace NULs */
PERLVARI(I, strxfrm_is_behaved, bool, TRUE)
                            /* Assume until proven otherwise that it works */
PERLVARI(I, strxfrm_max_cp, U8, 0)      /* Highest collating cp in locale */
PERLVARI(I, collation_standard, bool, TRUE)
                                        /* Assume simple collation */
PERLVAR(I, in_utf8_COLLATE_locale, bool)
#endif /* USE_LOCALE_COLLATE */

PERLVARI(I, langinfo_sv, SV *, NULL)         /* For Perl_langinfo8? */
PERLVARI(I, scratch_langinfo, SV *, NULL)     /* For internal use */
PERLVARI(I, setlocale_buf, char *, NULL)
PERLVARI(I, setlocale_bufsize, Size_t, 0)

#if   defined(USE_LOCALE_THREADS) && ! defined(USE_THREAD_SAFE_LOCALE)
PERLVARI(I, less_dicey_locale_buf, char *, NULL)
PERLVARI(I, less_dicey_locale_bufsize, Size_t, 0)
#endif

#ifdef PERL_SAWAMPERSAND
PERLVAR(I, sawampersand, U8)		/* must save all match strings */
#endif

/* current phase the interpreter is in
   for ordering this structure to remove holes, we're assuming that this is 4
   bytes.  */
PERLVARI(I, phase,	enum perl_phase, PERL_PHASE_CONSTRUCT)

PERLVARI(I, in_load_module, bool, FALSE)	/* to prevent recursions in PerlIO_find_layer */

PERLVARI(I, eval_begin_nest_depth, U32, 0)

PERLVAR(I, unsafe,	bool)
PERLVAR(I, colorset,	bool)		/* PERL_RE_COLORS env var is in use */

/*
=for apidoc_section $embedding
=for apidoc Amn|signed char|PL_perl_destruct_level

This value may be set when embedding for full cleanup.

Possible values:

=over

=item * 0 - none

=item * 1 - full

=item * 2 or greater - full with checks.

=back

If C<$ENV{PERL_DESTRUCT_LEVEL}> is set to an integer greater than the
value of C<PL_perl_destruct_level> its value is used instead.

On threaded perls, each thread has an independent copy of this variable;
each initialized at creation time with the current value of the creating
thread's copy.

=cut
*/
/* mod_perl is special, and also assigns a meaning -1 */
PERLVARI(I, perl_destruct_level, signed char,	0)

PERLVAR(I, pad_reset_pending, bool)	/* reset pad on next attempted alloc */

PERLVARI(I, srand_called, bool, false)      /* has random_state been initialized yet? */
PERLVARI(I, srand_override, U32, 0)         /* Should we use a deterministic sequence? */
PERLVARI(I, srand_override_next, U32, 0)    /* Next item in the sequence */

PERLVARI(I, numeric_underlying, bool, TRUE)
                                        /* Assume underlying locale numerics */
PERLVARI(I, numeric_underlying_is_standard, bool, TRUE)

PERLVARI(I, numeric_standard, int, TRUE)    /* Assume C locale numerics */
PERLVAR(I, numeric_name, char *)     /* Name of current numeric locale */
PERLVAR(I, numeric_radix_sv, SV *)	/* The radix separator */
PERLVAR(I, underlying_radix_sv, SV *)	/* The radix in the program's current underlying locale */

#ifdef USE_POSIX_2008_LOCALE
PERLVARI(I, scratch_locale_obj, locale_t, 0)
#endif

#ifdef USE_LOCALE_CTYPE

PERLVARI(I, ctype_name, const char *, NULL)   /* Name of current ctype locale */

#  endif

/* Array of signal handlers, indexed by signal number, through which the C
   signal handler dispatches.  */
PERLVAR(I, psig_ptr,	SV **)
/* Array of names of signals, indexed by signal number, for (re)use as the first
   argument to a signal handler.   Only one block of memory is allocated for
   both psig_name and psig_ptr.  */
PERLVAR(I, psig_name,	SV **)

#if defined(PERL_IMPLICIT_SYS)
PERLVAR(I, Mem,		const struct IPerlMem **)
PERLVAR(I, MemShared,	const struct IPerlMem **)
PERLVAR(I, MemParse,	const struct IPerlMem **)
PERLVAR(I, Env,		const struct IPerlEnv **)
PERLVAR(I, StdIO,	const struct IPerlStdIO **)
PERLVAR(I, LIO,		const struct IPerlLIO **)
PERLVAR(I, Dir,		const struct IPerlDir **)
PERLVAR(I, Sock,	const struct IPerlSock **)
PERLVAR(I, Proc,	const struct IPerlProc **)
#endif

PERLVAR(I, ptr_table,	PTR_TBL_t *)
PERLVARI(I, beginav_save, AV *, NULL)	/* save BEGIN{}s when compiling */

PERLVAR(I, body_arenas, void *)		/* pointer to list of body-arenas */


#if defined(USE_ITHREADS)
PERLVAR(I, regex_pad,     SV **)	/* Shortcut into the array of
                                           regex_padav */
PERLVAR(I, regex_padav,   AV *)		/* All regex objects, indexed via the
                                           values in op_pmoffset of pmop.
                                           Entry 0 is an SV whose PV is a
                                           "packed" list of IVs listing
                                           the now-free slots in the array */
PERLVAR(I, stashpad,    HV **)		/* for CopSTASH */
PERLVARI(I, stashpadmax, PADOFFSET, 64)
PERLVARI(I, stashpadix, PADOFFSET, 0)
PERLVARI(I, env_mutex_depth, int, 0)     /* Emulate general semaphore */
#endif

#ifdef USE_REENTRANT_API
PERLVAR(I, reentrant_buffer, REENTR *)	/* here we store the _r buffers */
#endif

PERLVAR(I, custom_op_names, HV *)	/* Names of user defined ops */
PERLVAR(I, custom_op_descs, HV *)	/* Descriptions of user defined ops */

#ifdef PERLIO_LAYERS
PERLVARI(I, perlio,	PerlIOl *, NULL)
PERLVARI(I, known_layers, PerlIO_list_t *, NULL)
PERLVARI(I, def_layerlist, PerlIO_list_t *, NULL)
#endif

PERLVARI(I, checkav_save, AV *, NULL)	/* save CHECK{}s when compiling */
PERLVARI(I, unitcheckav_save, AV *, NULL)
                                        /* save UNITCHECK{}s when compiling */

PERLVARI(I, clocktick,	long,	0)	/* this many times() ticks in a second */

/* Hooks to shared SVs and locks. */
PERLVARI(I, sharehook,	share_proc_t, Perl_sv_nosharing)
PERLVARI(I, lockhook,	share_proc_t, Perl_sv_nosharing)

#if defined(__HP_cc) || defined(__HP_aCC)
#pragma diag_suppress 3215
#endif
GCC_DIAG_IGNORE(-Wdeprecated-declarations)
MSVC_DIAG_IGNORE(4996)

#ifdef NO_MATHOMS
#  define PERL_UNLOCK_HOOK Perl_sv_nosharing
#else
/* This reference ensures that the mathoms are linked with perl */
#  define PERL_UNLOCK_HOOK Perl_sv_nounlocking
#endif
PERLVARI(I, unlockhook,	share_proc_t, PERL_UNLOCK_HOOK)

MSVC_DIAG_RESTORE
GCC_DIAG_RESTORE
#if defined(__HP_cc) || defined(__HP_aCC)
#pragma diag_default 3215
#endif

PERLVARI(I, threadhook,	thrhook_proc_t,	Perl_nothreadhook)

/* Can shared object be destroyed */
PERLVARI(I, destroyhook, destroyable_proc_t, Perl_sv_destroyable)

PERLVARI(I, signalhook,	despatch_signals_proc_t, Perl_despatch_signals)

PERLVARI(I, isarev, HV *, NULL)		/* Reverse map of @ISA dependencies */

/* Register of known Method Resolution Orders.
   What this actually points to is an implementation detail (it may change to
   a structure incorporating a reference count - use mro_get_from_name to
   retrieve a C<struct mro_alg *>  */
PERLVAR(I, registered_mros, HV *)

/* Compile-time block start/end hooks */
PERLVAR(I, blockhooks,	AV *)

PERLVAR(I, custom_ops,	HV *)		/* custom op registrations */

/* name of the scopes we've ENTERed. Only used with -DDEBUGGING, but needs to be
   present always, as -DDEBUGGING must be binary compatible with non.  */
PERLVARI(I, scopestack_name, const char **, NULL)

PERLVAR(I, debug_pad,	struct perl_debug_pad)	/* always needed because of the re extension */

/* Hook for File::Glob */
PERLVARI(I, globhook,	globhook_t, NULL)

#if defined(MULTIPLICITY)
/* The last unconditional member of the interpreter structure when 5.18.0 was
   released. The offset of the end of this is baked into a global variable in 
   any shared perl library which will allow a sanity test in future perl
   releases.  */
#  define PERL_LAST_5_18_0_INTERP_MEMBER	Iglobhook
#endif

#ifdef MULTIPLICITY
PERLVARI(I, my_cxt_list, void **, NULL) /* per-module array of MY_CXT pointers */
PERLVARI(I, my_cxt_size, int,	0)	/* size of PL_my_cxt_list */
#endif

#if defined(MULTIPLICITY) || defined(PERL_DEBUG_READONLY_COW)
/* For use with the memory debugging code in util.c. This is used only in
 * DEBUGGING builds (as long as the relevant structure is defined), but
 * defining it in non-debug builds too means that we retain binary
 * compatibility between otherwise-compatible plain and debug builds. */
PERLVAR(I, memory_debug_header, struct perl_memory_debug_header)
#endif

#ifdef DEBUG_LEAKING_SCALARS_FORK_DUMP
/* File descriptor to talk to the child which dumps scalars.  */
PERLVARI(I, dumper_fd,	int,	-1)
#endif


#ifdef DEBUG_LEAKING_SCALARS
PERLVARI(I, sv_serial,	U32,	0)	/* SV serial number, used in sv.c */
#endif

PERLVARA(I, sv_consts, SV_CONSTS_COUNT, SV*)	/* constant SVs with precomputed hash value */

#ifdef PERL_TRACE_OPS
PERLVARA(I, op_exec_cnt, OP_max+2, UV)  /* Counts of executed OPs of the given type.
                                           If PERL_TRACE_OPS is enabled, we'll dump
                                           a summary count of all ops executed in the
                                           program at perl_destruct time. Used only
                                           for profiling in DEBUGGING mode. */
#endif

PERLVAR(I, random_state, PL_RANDOM_STATE_TYPE)

PERLVARI(I, dump_re_max_len, STRLEN, 60)

/* For internal uses of randomness, this ensures the sequence of
 * random numbers returned by rand() isn't modified by perl's internal
 * use of randomness.
 * This is important if the user has called srand() with a seed.
 */

PERLVAR(I, internal_random_state, PL_RANDOM_STATE_TYPE)

PERLVARA(I, TR_SPECIAL_HANDLING_UTF8, UTF8_MAXBYTES, char)

PERLVAR(I, AboveLatin1,	SV *)
PERLVAR(I, Assigned_invlist, SV *)
PERLVAR(I, GCB_invlist, SV *)
PERLVAR(I, HasMultiCharFold,   SV *)
PERLVAR(I, InMultiCharFold,   SV *)
PERLVAR(I, Latin1,	SV *)
PERLVAR(I, LB_invlist, SV *)
PERLVAR(I, SB_invlist, SV *)
PERLVAR(I, SCX_invlist, SV *)
PERLVAR(I, UpperLatin1,	SV *)   /* Code points 128 - 255 */

PERLVARA(I, fold_locale, 256, U8)

/* List of characters that participate in any fold defined by Unicode */
PERLVAR(I, in_some_fold, SV *)

/* Everything that folds to a given character, for case insensitivity regex
 * matching */
PERLVAR(I, utf8_foldclosures, SV *)

PERLVAR(I, utf8_idcont,	SV *)
PERLVAR(I, utf8_idstart, SV *)
PERLVAR(I, utf8_perl_idcont, SV *)
PERLVAR(I, utf8_perl_idstart, SV *)
PERLVAR(I, utf8_xidcont, SV *)
PERLVAR(I, utf8_xidstart, SV *)
PERLVAR(I, WB_invlist, SV *)
PERLVARA(I, XPosix_ptrs, POSIX_CC_COUNT, SV *)
PERLVARA(I,  Posix_ptrs, POSIX_CC_COUNT, SV *)
PERLVAR(I, utf8_toupper, SV *)
PERLVAR(I, utf8_totitle, SV *)
PERLVAR(I, utf8_tolower, SV *)
PERLVAR(I, utf8_tofold,	SV *)
PERLVAR(I, utf8_tosimplefold,	SV *)
PERLVAR(I, utf8_charname_begin, SV *)
PERLVAR(I, utf8_charname_continue, SV *)
PERLVAR(I, utf8_mark,	SV *)
PERLVARI(I, InBitmap,	SV *, NULL)
PERLVAR(I, CCC_non0_non230,	SV *)
PERLVAR(I, Private_Use,	SV *)

#ifdef HAS_MBRLEN
PERLVAR(I, mbrlen_ps, mbstate_t)
#endif
#ifdef HAS_MBRTOWC
PERLVAR(I, mbrtowc_ps, mbstate_t)
#endif
#ifdef HAS_WCRTOMB
PERLVAR(I, wcrtomb_ps, mbstate_t)
#endif
#ifdef PERL_MEM_LOG
/* Enough space for the reserved byte, 1 for a potential leading 0, then enough
 * for the longest representable integer plus an extra, the 3 flag characters,
 * and NUL */
#define PERL_MEM_LOG_ARYLEN (1 + 1 + TYPE_DIGITS(UV) + 1 + 3 + 1)
PERLVARA(I, mem_log, PERL_MEM_LOG_ARYLEN,  char)
#endif

/* The most recently seen `use VERSION` declaration, encoded in a single
 * U16 as (major << 8) | minor. We do this rather than store an entire SV
 * version object so we can fit the U16 into the uv of a SAVEHINTS and not
 * have to worry about SV refcounts during scope enter/exit. */
PERLVAR(I, prevailing_version, U16)

PERLVARI(I, in_diehook, bool, FALSE)
PERLVARI(I, in_warnhook, bool, FALSE)

/* If you are adding a U8 or U16, check to see if there are 'Space' comments
 * above on where there are gaps which currently will be structure padding.  */

/* Within a stable branch, new variables must be added to the very end, before
 * this comment, for binary compatibility (the offsets of the old members must
 *  not change).
 * (Don't forget to add your variable also to perl_clone()!)
 */
