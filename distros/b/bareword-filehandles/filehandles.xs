#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "hook_op_check.h"
#include "ppport.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#if PERL_VERSION_GE(5,9,2)
#define CONST const
#else
#define CONST /**/
#endif

#define bareword_croak_unless_builtin(op, gv) \
    THX_bareword_croak_unless_builtin(aTHX_ op, gv)
STATIC void THX_bareword_croak_unless_builtin (pTHX_ CONST OP *op, const GV *gv) {
    if (gv
        && gv != PL_stdingv
        && gv != PL_stderrgv
        && gv != PL_defgv
        && gv != PL_argvgv
        && gv != PL_argvoutgv
        && gv != gv_fetchpv("STDOUT", TRUE, SVt_PVIO)
        && gv != gv_fetchpv("DATA", TRUE, SVt_PVIO)
    )
        croak("Use of bareword filehandle in %s", OP_DESC(op));
}

#define bareword_croak_unless_builtin_op(op, argop) \
    THX_bareword_croak_unless_builtin_op(aTHX_ op, argop)
STATIC void THX_bareword_croak_unless_builtin_op (pTHX_ CONST OP *op, const OP *argop) {
    if (argop && argop->op_type == OP_GV)
        bareword_croak_unless_builtin(op, cGVOPx_gv(argop));
    else if (argop && argop->op_type == OP_CONST &&
             (argop->op_private & OPpCONST_BARE)) {
        const GV *gv = gv_fetchsv(cSVOPx(argop)->op_sv, 0, SVt_PVIO);
        bareword_croak_unless_builtin(op, gv);
    }
}

STATIC OP *bareword_filehandles_unary_check_op (pTHX_ OP *op, void *user_data) {
    SV **hint = hv_fetchs(GvHV(PL_hintgv), "bareword::filehandles/disabled", 0);

    PERL_UNUSED_ARG(user_data);

    if (!hint || !SvOK(*hint))
        return op;

    if (op->op_flags & OPf_KIDS)
        bareword_croak_unless_builtin_op(op, cUNOPx(op)->op_first);

    return op;
}

STATIC OP *bareword_filehandles_stat_check_op (pTHX_ OP *op, void *user_data) {
    SV **hint = hv_fetchs(GvHV(PL_hintgv), "bareword::filehandles/disabled", 0);

    PERL_UNUSED_ARG(user_data);

    if (!hint || !SvOK(*hint))
        return op;

    if (op->op_flags & OPf_REF)
	bareword_croak_unless_builtin(op, cGVOPx_gv(op));

    return op;
}

STATIC OP *bareword_filehandles_list_check_op (pTHX_ OP *op, void *user_data) {
    SV **hint = hv_fetchs(GvHV(PL_hintgv), "bareword::filehandles/disabled", 0);
    OP *child;
    int num_args = user_data ? *(int*)user_data : 1;

    if (!hint || !SvOK(*hint))
        return op;

    child = cLISTOPx(op)->op_first;
    if (child && (child->op_type == OP_PUSHMARK || child->op_type == OP_NULL)) {
        while(num_args-- && (child = OpSIBLING(child)))
	    bareword_croak_unless_builtin_op(op, child);
    }

    return op;
}

STATIC const int bareword_filehandles_two = 2;

MODULE = bareword::filehandles PACKAGE = bareword::filehandles

PROTOTYPES: ENABLE

#define bareword_check(type, op) \
    hook_op_check(op, bareword_filehandles_##type##_check_op, NULL);

#define bareword_check_list2(op) \
    hook_op_check(op, bareword_filehandles_list_check_op, \
		  (void*)&bareword_filehandles_two);

BOOT:
    bareword_check(unary, OP_CLOSE);
    bareword_check(unary, OP_CLOSEDIR);
    bareword_check(unary, OP_ENTERWRITE);
    bareword_check(unary, OP_EOF);
    bareword_check(unary, OP_FILENO);
    bareword_check(unary, OP_GETC);
    bareword_check(unary, OP_GETPEERNAME);
    bareword_check(unary, OP_GETSOCKNAME);
    bareword_check(unary, OP_READDIR);
    bareword_check(unary, OP_READLINE);
    bareword_check(unary, OP_REWINDDIR);
    bareword_check(unary, OP_TELL);
    bareword_check(unary, OP_TELLDIR);
    bareword_check(unary, OP_CHDIR);

    bareword_check(list, OP_BIND);
    bareword_check(list, OP_BINMODE);
    bareword_check(list, OP_CONNECT);
    bareword_check(list, OP_FCNTL);
    bareword_check(list, OP_FLOCK);
    bareword_check(list, OP_GSOCKOPT);
    bareword_check(list, OP_IOCTL);
    bareword_check(list, OP_LISTEN);
    bareword_check(list, OP_OPEN);
    bareword_check(list, OP_OPEN_DIR);
    bareword_check(list, OP_READ);
    bareword_check(list, OP_RECV);
    bareword_check(list, OP_SEEK);
    bareword_check(list, OP_SEEKDIR);
    bareword_check(list, OP_SELECT);
    bareword_check(list, OP_SEND);
    bareword_check(list, OP_SHUTDOWN);
    bareword_check(list, OP_SOCKET);
    bareword_check(list, OP_SSOCKOPT);
    bareword_check(list, OP_SYSREAD);
    bareword_check(list, OP_SYSSEEK);
    bareword_check(list, OP_SYSWRITE);
    bareword_check(list, OP_TRUNCATE);
    bareword_check_list2(OP_ACCEPT);
    bareword_check_list2(OP_PIPE_OP);
    bareword_check_list2(OP_SOCKPAIR);

    bareword_check(stat, OP_STAT);
    bareword_check(stat, OP_LSTAT);
#if PERL_VERSION_GE(5,31,1)
    bareword_check(stat, OP_FTRREAD);
    bareword_check(stat, OP_FTRWRITE);
    bareword_check(stat, OP_FTREXEC);
    bareword_check(stat, OP_FTEREAD);
    bareword_check(stat, OP_FTEWRITE);
    bareword_check(stat, OP_FTEEXEC);
    bareword_check(stat, OP_FTIS);
    bareword_check(stat, OP_FTSIZE);
    bareword_check(stat, OP_FTMTIME);
    bareword_check(stat, OP_FTATIME);
    bareword_check(stat, OP_FTCTIME);
    bareword_check(stat, OP_FTROWNED);
    bareword_check(stat, OP_FTEOWNED);
    bareword_check(stat, OP_FTZERO);
    bareword_check(stat, OP_FTSOCK);
    bareword_check(stat, OP_FTCHR);
    bareword_check(stat, OP_FTBLK);
    bareword_check(stat, OP_FTFILE);
    bareword_check(stat, OP_FTDIR);
    bareword_check(stat, OP_FTPIPE);
    bareword_check(stat, OP_FTSUID);
    bareword_check(stat, OP_FTSGID);
    bareword_check(stat, OP_FTSVTX);
    bareword_check(stat, OP_FTLINK);
    bareword_check(stat, OP_FTTTY);
    bareword_check(stat, OP_FTTEXT);
    bareword_check(stat, OP_FTBINARY);
#endif
