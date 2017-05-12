#ifndef PZK_XS_UTILS_H_
#define PZK_XS_UTILS_H_
#include <stdarg.h>

void* _tied_object_to_ptr(pTHX_ SV* obj_sv, const char* var, const char* pkg, int unsafe) {
    if (!SvROK(obj_sv) || (SvTYPE(SvRV(obj_sv)) != SVt_PVHV)) {
        if (unsafe) return NULL;
        Perl_croak(aTHX_ "%s is not a blessed reference of type %s", var, pkg);
    }

    SV* tied_hash = SvRV(obj_sv);
    MAGIC* ext_magic = mg_find(tied_hash, PERL_MAGIC_ext);
    if (!ext_magic) {
        if (unsafe) return NULL;
        Perl_croak(aTHX_ "%s has not been initialized by %s", var, pkg);
    }

    return  (void*) ext_magic->mg_ptr;
}

void* unsafe_tied_object_to_ptr(pTHX_ SV* obj_sv) {
    return _tied_object_to_ptr(aTHX_ obj_sv, NULL, NULL, 1);
}

void* tied_object_to_ptr(pTHX_ SV* obj_sv, const char* var, const char* pkg) {
    return _tied_object_to_ptr(aTHX_ obj_sv, var, pkg, 0);
}

SV* ptr_to_tied_object(pTHX_ void* ptr, const char* pkg) {
    HV* stash = gv_stashpv(pkg, GV_ADDWARN);
    SV* attr_hash = (SV*) newHV();
    sv_magic(attr_hash, Nullsv, PERL_MAGIC_ext, (const char*) ptr, 0);
    return sv_bless(newRV_noinc(attr_hash), stash);
}

struct ACL* sv_to_acl_entry(pTHX_ SV* acl_sv) {
    if (!SvROK(acl_sv) || (SvTYPE(SvRV(acl_sv)) != SVt_PVHV))
        Perl_croak(aTHX_ "acl entry must be a hash ref");
    HV* acl_hv = (HV*) SvRV(acl_sv);
    struct ACL* acl_entry; Newxz(acl_entry, 1, struct ACL);

    SV** perm_val_ptr = hv_fetch(acl_hv, "perms", 5, 0);
    if (perm_val_ptr) acl_entry->perms = SvIV(*perm_val_ptr);

    SV** scheme_val_ptr = hv_fetch(acl_hv, "scheme", 6, 0);
    if (scheme_val_ptr) acl_entry->id.scheme = SvPV_nolen(*scheme_val_ptr);

    SV** id_val_ptr = hv_fetch(acl_hv, "id", 2, 0);
    if (id_val_ptr) acl_entry->id.id = SvPV_nolen(*id_val_ptr);

    return acl_entry;
}

struct ACL_vector* sv_to_acl_vector(pTHX_ SV* acl_v_sv) {
    if (!SvROK(acl_v_sv) || !(SvTYPE(SvRV(acl_v_sv)) == SVt_PVAV))
        Perl_croak(aTHX_ "acl must be an array ref of hash refs");
    AV* acl_v_av = (AV*) SvRV(acl_v_sv);
    SSize_t length = av_len(acl_v_av) + 1;

    struct ACL_vector *v;
    Newxz(v, 1, struct ACL_vector);
    Newxz(v->data, length, struct ACL);
    int i; for (i = 0; i < length; i++) {
        SV* acl_sv = *(av_fetch(acl_v_av, i, 0));
        v->data[i] = *(sv_to_acl_entry(aTHX_ acl_sv));
    }
    v->count = length;

    return v;
}

SV* acl_entry_to_sv(pTHX_ struct ACL* acl_entry) {
    HV* acl_hv = newHV();

    hv_store(acl_hv, "perms", 5, newSViv(acl_entry->perms), 0);
    hv_store(acl_hv, "scheme", 6, newSVpv(acl_entry->id.scheme, 0), 0);
    hv_store(acl_hv, "id", 2, newSVpv(acl_entry->id.id, 0), 0);

    return newRV_noinc((SV*) acl_hv);
}

SV* acl_vector_to_sv(pTHX_ struct ACL_vector* acl_v) {
    AV* acl_v_av = newAV();
    int32_t length = acl_v->count;

    int i; for (i = 0; i < length; i++) {
        struct ACL* acl_entry = &acl_v->data[i];
        av_push(acl_v_av, acl_entry_to_sv(aTHX_ acl_entry));
    }

    return newRV_noinc((SV*) acl_v_av);
}

SV* stat_to_sv(pTHX_ struct Stat* stat) {
    HV* stat_hv = newHV();

    hv_store(stat_hv, "czxid",          5,  newSViv(stat->czxid),          0);
    hv_store(stat_hv, "mzxid",          5,  newSViv(stat->mzxid),          0);
    hv_store(stat_hv, "ctime",          5,  newSViv(stat->ctime),          0);
    hv_store(stat_hv, "mtime",          5,  newSViv(stat->mtime),          0);
    hv_store(stat_hv, "version",        7,  newSViv(stat->version),        0);
    hv_store(stat_hv, "cversion",       8,  newSViv(stat->cversion),       0);
    hv_store(stat_hv, "aversion",       8,  newSViv(stat->aversion),       0);
    hv_store(stat_hv, "ephemeralOwner", 14, newSViv(stat->ephemeralOwner), 0);
    hv_store(stat_hv, "dataLength",     10, newSViv(stat->dataLength),     0);
    hv_store(stat_hv, "numChildren",    11, newSViv(stat->numChildren),    0);
    hv_store(stat_hv, "pzxid",          5,  newSViv(stat->pzxid),          0);

    return newRV_noinc((SV*) stat_hv);
}

SV* event_to_sv(pTHX_ pzk_event_t* event) {
    HV* event_hv = newHV();

    hv_store(event_hv, "type",    4, newSViv(event->type),           0);
    hv_store(event_hv, "state",   5, newSViv(event->state),          0);
    hv_store(event_hv, "path",    4, newSVpv(event->path, 0),        0);
    hv_store(event_hv, "watcher", 7, SvREFCNT_inc((SV*) event->arg), 0);

    return newRV_noinc((SV*) event_hv);
}

pzk_event_t* sv_to_event(pTHX_ void* watcher, SV* event_sv) {
    if (!SvROK(event_sv) || (SvTYPE(SvRV(event_sv)) != SVt_PVHV))
        Perl_croak(aTHX_ "event must be a hash ref");
    HV* event_hv = (HV*) SvRV(event_sv);

    SV** type_val_ptr = hv_fetch(event_hv, "type", 4, 0);
    int type = type_val_ptr ? SvIV(*type_val_ptr) : -1;

    SV** state_val_ptr = hv_fetch(event_hv, "state", 5, 0);
    int state = state_val_ptr ? SvIV(*state_val_ptr) : -1;

    SV** path_val_ptr= hv_fetch(event_hv, "path", 4, 0);
    char* path = path_val_ptr ? SvPV_nolen(*path_val_ptr) : NULL;

    return new_pzk_event(type, state, path, watcher);
}

void throw_zerror(pTHX_ int rc, const char* fmt, ...) {
    dSP;

    ENTER;
    SAVETMPS;

    HV* args_hv = newHV();
    hv_store(args_hv, "code", 4, newSViv(rc), 0);

    va_list args; va_start(args, fmt);
    hv_store(args_hv, "message", 7, newSVsv(vmess(fmt, &args)), 0);
    va_end(args);

    SV* args_sv = newRV_noinc((SV*) args_hv);

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("ZooKeeper::Error", 0)));
    XPUSHs(sv_2mortal(args_sv));
    PUTBACK;

    call_method("throw", G_DISCARD);

    FREETMPS;
    LEAVE;
}

SV* op_error_to_sv(pTHX_ zoo_op_result_t result) {
    HV* result_hv = newHV();

    hv_store(result_hv, "type",    4, newSVpv("error", 0),            0);
    hv_store(result_hv, "code",    4, newSViv(result.err),            0);
    hv_store(result_hv, "message", 7, newSVpv(zerror(result.err), 0), 0);

    return newRV_noinc((SV*) result_hv);
}

SV* op_to_sv(pTHX_ const zoo_op_t op) {
    HV* op_hv = newHV();

    if (op.type == ZOO_CREATE_OP) {
        hv_store(op_hv, "type", 4, newSVpv("create", 0), 0);
        hv_store(op_hv, "path", 4, newSVpv(op.create_op.buf, 0), 0);
    } else if (op.type == ZOO_DELETE_OP) {
        hv_store(op_hv, "type", 4, newSVpv("delete", 0), 0);
    } else if (op.type == ZOO_SETDATA_OP) {
        hv_store(op_hv, "type", 4, newSVpv("set", 0), 0);
        SV* stat_sv = stat_to_sv(aTHX_ op.set_op.stat);
        hv_store(op_hv, "stat", 4, stat_sv, 0);
    } else if (op.type == ZOO_CHECK_OP) {
        hv_store(op_hv, "type", 4, newSVpv("check", 0), 0);
    }

    return newRV_noinc((SV*) op_hv);
}

zoo_op_t sv_to_op(pTHX_ SV* const op_sv) {
    if (!SvROK(op_sv) || (SvTYPE(SvRV(op_sv)) != SVt_PVAV))
        Perl_croak(aTHX_ "op must be an array ref");
    AV* op_av = (AV*) SvRV(op_sv);
    SSize_t length = av_len(op_av) + 1;
    int type       = SvIV(*(av_fetch(op_av, 0, 0)));

    zoo_op_t op;
    if (type == ZOO_CREATE_OP) {
        size_t value_len = -1;
        SV* value_sv     = *(av_fetch(op_av, 2, 0));
        char* value      = SvOK(value_sv) ? SvPV(value_sv, value_len) : NULL;

        const char* path  = SvPV_nolen(*(av_fetch(op_av, 1, 0)));
        int buffer_len    = SvIV(*(av_fetch(op_av, 3, 0)));
        const struct ACL_vector* acl =
            sv_to_acl_vector(aTHX_ *(av_fetch(op_av, 4, 0)));
        int flags = SvIV(*(av_fetch(op_av, 5, 0)));

        char* buffer; Newxz(buffer, buffer_len + 1, char);

        zoo_create_op_init(&op, path, value, value_len, acl, flags, buffer, buffer_len);
    } else if (type == ZOO_DELETE_OP) {
        const char* path = SvPV_nolen(*(av_fetch(op_av, 1, 0)));
        int version      = SvIV(*(av_fetch(op_av, 2, 0)));
        zoo_delete_op_init(&op, path, version);
    } else if (type == ZOO_SETDATA_OP) {
        size_t value_len = -1;
        SV* value_sv     = *(av_fetch(op_av, 2, 0));
        char* value      = SvOK(value_sv) ? SvPV(value_sv, value_len) : NULL;

        const char* path  = SvPV_nolen(*(av_fetch(op_av, 1, 0)));
        int version       = SvIV(*(av_fetch(op_av, 3, 0)));

        struct Stat* stat; Newxz(stat, 1, struct Stat);

        zoo_set_op_init(&op, path, value, value_len, version, stat);
    } else if (type == ZOO_CHECK_OP) {
        const char* path = SvPV_nolen(*(av_fetch(op_av, 1, 0)));
        int version      = SvIV(*(av_fetch(op_av, 2, 0)));
        zoo_check_op_init(&op, path, version);
    }

    return op;
}

zoo_op_t* sv_to_ops(pTHX_ const SV* ops_sv) {
    if (!SvROK(ops_sv) || !(SvTYPE(SvRV(ops_sv)) == SVt_PVAV))
        Perl_croak(aTHX_ "ops must be an array ref");
    AV* ops_av     = (AV*) SvRV(ops_sv);
    SSize_t length = av_len(ops_av) + 1;

    zoo_op_t* ops; Newxz(ops, length, zoo_op_t);
    int i; for (i = 0; i < length; i++) {
        SV* op_sv = *(av_fetch(ops_av, i, 0));
        ops[i]    = sv_to_op(aTHX_ op_sv);
    }

    return ops;
}

void free_op(pTHX_ zoo_op_t op) {
    if (op.type == ZOO_CREATE_OP) {
        Safefree(op.create_op.buf);
        Safefree(op.create_op.acl->data);
        Safefree(op.create_op.acl);
    } else if (op.type == ZOO_SETDATA_OP) {
        Safefree(op.set_op.stat);
    }
}

void free_ops(pTHX_ zoo_op_t* ops, int length) {
    int i; for (i = 0; i < length; i++) {
        free_op(aTHX_ ops[i]);
    }
    Safefree(ops);
}

#endif // ifndef PZK_XS_UTILS_H_
