#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdio.h>
#include <string.h>

#include <pzk.h>
#include <pzk_channel.h>
#include <pzk_pipe_dispatcher.h>
#include <pzk_interrupt_dispatcher.h>
#include <pzk_transaction.h>
#include <pzk_xs_utils.h>
#include <zookeeper/zookeeper.h>
#include <zookeeper/zookeeper_version.h>


MODULE = ZooKeeper PACKAGE = ZooKeeper 

BOOT:
{
    zoo_set_debug_level(0);
    zoo_set_log_stream(NULL);
}

void
trace(SV* self, int level, const char* path=NULL)
    PPCODE:
        if (level > ZOO_LOG_LEVEL_DEBUG) {
            level = ZOO_LOG_LEVEL_DEBUG;
        }
        zoo_set_debug_level(level);

        FILE* stream = path ? fopen(path, "a") : NULL;
        zoo_set_log_stream(stream);

void
_xs_init(SV* self)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;
        pzk_t* pzk = new_pzk(NULL);
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) pzk, 0);

void
connect(pzk, hosts, recv_timeout, _watcher=NULL, clientid=NULL, flags=0)
        pzk_t*            pzk
        const char*       hosts
        SV*               _watcher
        int               recv_timeout
        const clientid_t* clientid
        int               flags
    PPCODE:
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ _watcher);
        watcher_fn cb = watcher ? pzk_watcher_cb : NULL;
        zhandle_t* handle = zookeeper_init(hosts, cb, recv_timeout, clientid, (void*) watcher, flags);
        if (!handle) throw_zerror(aTHX_ errno, "Error initializing ZooKeeper handle for '%s': %s", hosts, strerror(errno));

        pzk->handle = handle;

int
is_unrecoverable(pzk_t* pzk)
    CODE:
        RETVAL = is_unrecoverable(pzk->handle);
    OUTPUT:
        RETVAL

void
close(SV* self)
    PPCODE:
        pzk_t* pzk = (pzk_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (pzk) pzk->close(pzk);

void
_xs_destroy(SV* self)
    PPCODE:
        pzk_t* pzk = (pzk_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (pzk) pzk->destroy(pzk);

void
_set_watcher(pzk_t* pzk, SV* _watcher=NULL)
    PPCODE:
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ _watcher);
        zoo_set_watcher(pzk->handle, pzk_watcher_cb);
        zoo_set_context(pzk->handle, (void*) watcher);

int
state(pzk_t* pzk)
    CODE:
        RETVAL = zoo_state(pzk->handle);
    OUTPUT:
        RETVAL

void
add_auth(pzk_t* pzk, char* scheme, char* credential=NULL, SV* _watcher=NULL)
    PPCODE:
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ _watcher);
        void_completion_t cb = watcher ? pzk_auth_cb : NULL;
        int rc = zoo_add_auth(pzk->handle, scheme, credential, strlen(credential), cb, (void*) watcher);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error trying to authenticate: %s", zerror(rc));

SV*
create(pzk_t* pzk, char* path, SV* value_sv, int buffer_len, struct ACL_vector* acl=NULL, int flags=0)
    CODE:
        char* buffer; Newxz(buffer, buffer_len + 1, char);
        size_t value_len = -1;
        char* value      = SvOK(value_sv) ? SvPV(value_sv, value_len) : NULL;

        int rc = zoo_create(pzk->handle, path, value, value_len, acl, flags, buffer, buffer_len);
        RETVAL = newSVpv(buffer, 0);
        Safefree(buffer);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error creating node '%s': %s", path, zerror(rc));
    OUTPUT:
        RETVAL

void
delete(pzk_t* pzk, char* path, int version=-1)
    PPCODE:
        int rc = zoo_delete(pzk->handle, path, version);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error deleting node '%s': %s", path, zerror(rc));

SV*
exists(pzk_t* pzk, char* path, SV* _watcher=NULL)
    CODE:
        int rc;
        struct Stat stat; Zero(&stat, 1, struct Stat);
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ _watcher);
        if (watcher) {
            rc = zoo_wexists(pzk->handle, path, pzk_watcher_cb, (void*) watcher, &stat);
        } else {
            rc = zoo_exists(pzk->handle, path, 0, &stat);
        }

        if (rc == ZOK) {
            RETVAL = stat_to_sv(aTHX_ &stat);
        } else if (rc == ZNONODE) {
            RETVAL = &PL_sv_undef;
        } else {
            throw_zerror(aTHX_ rc, "Error checking existence of node '%s': %s", path, zerror(rc));
        }
    OUTPUT:
        RETVAL

void
get_children(pzk_t* pzk, char* path, SV* _watcher=NULL)
    PPCODE:
        int rc;
        struct String_vector strings; Zero(&strings, 1, struct String_vector);
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ _watcher);
        if (watcher) {
            rc = zoo_wget_children(pzk->handle, path, pzk_watcher_cb, (void*) watcher, &strings);
        } else {
            rc = zoo_get_children(pzk->handle, path, 0, &strings);
        }

        if (rc == ZOK) {
            int32_t size = strings.count;
            int i; for (i = 0; i < size; i++) {
                ST(i) = sv_2mortal(newSVpv(strings.data[i], 0));
            }
            deallocate_String_vector(&strings);
            XSRETURN(size);
        } else {
            deallocate_String_vector(&strings);
            throw_zerror(aTHX_ rc, "Error getting children for node '%s': %s", path, zerror(rc));
        }

void
get(pzk_t* pzk, char* path, int buffer_len, SV* _watcher=NULL)
    PPCODE:
        int rc;
        char* buffer; Newxz(buffer, buffer_len + 1, char);
        struct Stat stat; Zero(&stat, 1, struct Stat);
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ _watcher);
        if (watcher) {
            rc = zoo_wget(pzk->handle, path, pzk_watcher_cb, watcher, buffer, &buffer_len, &stat);
        } else {
            rc = zoo_get(pzk->handle, path, 0, buffer, &buffer_len, &stat);
        }

        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error getting data for node '%s': %s", path, zerror(rc));

        ST(0) = buffer_len == -1 ? &PL_sv_undef : newSVpv(buffer, buffer_len);
        Safefree(buffer);
        if (GIMME_V == G_ARRAY) {
            ST(1) = sv_2mortal(stat_to_sv(aTHX_ &stat));
            XSRETURN(2);
        } else {
            XSRETURN(1);
        }

SV*
set(pzk_t* pzk, char* path, SV* value_sv, int version=-1)
    CODE:
        struct Stat stat; Zero(&stat, 1, struct Stat);
        size_t value_len = -1;
        char* value      = SvOK(value_sv) ? SvPV(value_sv, value_len) : NULL;

        int rc = zoo_set2(pzk->handle, path, value, value_len, version, &stat);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error setting data for node '%s': %s", path, zerror(rc));
        RETVAL = stat_to_sv(aTHX_ &stat);

    OUTPUT:
        RETVAL

void
get_acl(pzk_t* pzk, char* path)
    PPCODE:
        struct Stat stat; Zero(&stat, 1, struct Stat);
        struct ACL_vector acl; Zero(&acl, 1, struct ACL_vector);
        int rc = zoo_get_acl(pzk->handle, path, &acl, &stat);

        ST(0) = sv_2mortal(acl_vector_to_sv(aTHX_ &acl));
        deallocate_ACL_vector(&acl);

        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error getting acl for node '%s': %s", path, zerror(rc));

        if (GIMME_V == G_ARRAY) {
            ST(1) = sv_2mortal(stat_to_sv(aTHX_ &stat));
            XSRETURN(2);
        } else {
            XSRETURN(1);
        }

void
set_acl(pzk_t* pzk, char* path, SV* acl_sv, int version=-1)
    PPCODE:
        struct ACL_vector* acl = sv_to_acl_vector(aTHX_ acl_sv);
        int rc = zoo_set_acl(pzk->handle, path, version, acl);
        Safefree(acl->data);
        Safefree(acl);
        if (rc != ZOK) throw_zerror(aTHX_ rc, "Error setting acl for node '%s': %s", path, zerror(rc));

const clientid_t*
client_id(pzk_t* pzk)
    CODE:
        RETVAL = zoo_client_id(pzk->handle);
    OUTPUT:
        RETVAL


MODULE = ZooKeeper PACKAGE = ZooKeeper::Channel

void
_xs_init(SV* self)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        pzk_channel_t* channel = new_pzk_channel();
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) channel, 0);

void
DESTROY(SV* self)
    PPCODE:
        pzk_channel_t* channel = (pzk_channel_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (channel) channel->destroy(channel);

int
size(pzk_channel_t* channel)
    CODE:
        RETVAL = channel->size;
    OUTPUT:
        RETVAL

void
send(pzk_channel_t* channel, ...)
    PPCODE:
        int i;
        for (i = 1; i < items; i++) {
            channel->push(channel, SvREFCNT_inc(ST(i)));
        }
        XSRETURN_YES;

SV*
recv(pzk_channel_t* channel)
    CODE:
        SV* element = (SV*) channel->shift(channel);
        if (!element) element = &PL_sv_undef;
        RETVAL = element;
    OUTPUT:
        RETVAL


MODULE = ZooKeeper PACKAGE = ZooKeeper::Dispatcher

SV*
recv_event(pzk_dispatcher_t* dispatcher)
    CODE:
        pzk_channel_t* channel = dispatcher->channel;
        if (!channel->size) XSRETURN_EMPTY;

        pzk_event_t* event = (pzk_event_t*) channel->shift(channel);
        RETVAL = event ? event_to_sv(aTHX_ event) : &PL_sv_undef;
        if (event) event->destroy(event);
    OUTPUT:
        RETVAL

int
send_event(dispatcher, type, state, path, watcher)
        pzk_dispatcher_t* dispatcher
        int               type
        int               state
        const char*       path
        pzk_watcher_t*    watcher
    CODE:
        if (!dispatcher) Perl_croak(aTHX_ "dispatcher has not yet been initialized by ZooKeeper::Dispatcher");
        pzk_watcher_cb(NULL, type, state, path, (void*) watcher);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self)
    PPCODE:
        pzk_dispatcher_t* dispatcher = (pzk_dispatcher_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (dispatcher) {
            pzk_event_t*   event;
            pzk_channel_t* channel = dispatcher->channel;
            while ((event = (pzk_event_t*) channel->shift(channel))) {
                event->destroy(event);
            }
        }


MODULE = ZooKeeper PACKAGE = ZooKeeper::Dispatcher::Pipe

void
_xs_init(SV* self, pzk_channel_t* channel)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        pzk_pipe_dispatcher_t* dispatcher = new_pzk_pipe_dispatcher(channel);
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) dispatcher, 0);

int
fd(pzk_pipe_dispatcher_t* dispatcher)
    CODE:
        RETVAL = dispatcher->fd[0];
    OUTPUT:
        RETVAL

int
read_pipe(pzk_pipe_dispatcher_t* dispatcher)
    CODE:
        RETVAL = dispatcher->read_pipe(dispatcher);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self)
    PPCODE:
        pzk_pipe_dispatcher_t* dispatcher = (pzk_pipe_dispatcher_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (dispatcher) dispatcher->destroy(dispatcher);


MODULE = ZooKeeper PACKAGE = ZooKeeper::Dispatcher::Interrupt

void
_xs_init(SV* self, pzk_channel_t* channel, interrupt_fn func, void* arg)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        pzk_interrupt_dispatcher_t* dispatcher = new_pzk_interrupt_dispatcher(channel, func, arg);
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) dispatcher, 0);

void
DESTROY(SV* self)
    PPCODE:
        pzk_interrupt_dispatcher_t* dispatcher = (pzk_interrupt_dispatcher_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (dispatcher) dispatcher->destroy(dispatcher);


MODULE = ZooKeeper PACKAGE = ZooKeeper::Watcher

void
_xs_init(SV* self, pzk_dispatcher_t* dispatcher)
    PPCODE:
        if (!SvROK(self) || (SvTYPE(SvRV(self)) != SVt_PVHV)) XSRETURN_EMPTY;

        pzk_watcher_t* watcher; Newxz(watcher, 1, pzk_watcher_t);
        watcher->dispatcher = dispatcher;
        watcher->ctx        = (void*) sv_rvweaken(SvREFCNT_inc(self));
        sv_magic(SvRV(self), Nullsv, PERL_MAGIC_ext, (const char*) watcher, 0);

void
trigger(pzk_watcher_t* watcher, const char* path, int state, int type)
    PPCODE:
        pzk_watcher_cb(NULL, type, state, path, (void*) watcher);

void
DESTROY(SV* self)
    PPCODE:
        pzk_watcher_t* watcher = (pzk_watcher_t*) unsafe_tied_object_to_ptr(aTHX_ self);
        if (watcher) {
            SvREFCNT_dec(watcher->ctx);
            Safefree(watcher);
        }


MODULE = ZooKeeper PACKAGE = ZooKeeper::Constants

BOOT:
{
    HV* stash = gv_stashpv("ZooKeeper::Constants", GV_ADDWARN);

    newCONSTSUB(stash, "ZOK",                      newSViv(ZOK));
    newCONSTSUB(stash, "ZSYSTEMERROR",             newSViv(ZSYSTEMERROR));
    newCONSTSUB(stash, "ZRUNTIMEINCONSISTENCY",    newSViv(ZRUNTIMEINCONSISTENCY));
    newCONSTSUB(stash, "ZDATAINCONSISTENCY",       newSViv(ZDATAINCONSISTENCY));
    newCONSTSUB(stash, "ZCONNECTIONLOSS",          newSViv(ZCONNECTIONLOSS));
    newCONSTSUB(stash, "ZMARSHALLINGERROR",        newSViv(ZMARSHALLINGERROR));
    newCONSTSUB(stash, "ZUNIMPLEMENTED",           newSViv(ZUNIMPLEMENTED));
    newCONSTSUB(stash, "ZOPERATIONTIMEOUT",        newSViv(ZOPERATIONTIMEOUT));
    newCONSTSUB(stash, "ZBADARGUMENTS",            newSViv(ZBADARGUMENTS));
    newCONSTSUB(stash, "ZINVALIDSTATE",            newSViv(ZINVALIDSTATE));
    newCONSTSUB(stash, "ZAPIERROR",                newSViv(ZAPIERROR));
    newCONSTSUB(stash, "ZNONODE",                  newSViv(ZNONODE));
    newCONSTSUB(stash, "ZNOAUTH",                  newSViv(ZNOAUTH));
    newCONSTSUB(stash, "ZBADVERSION",              newSViv(ZBADVERSION));
    newCONSTSUB(stash, "ZNOCHILDRENFOREPHEMERALS", newSViv(ZNOCHILDRENFOREPHEMERALS));
    newCONSTSUB(stash, "ZNODEEXISTS",              newSViv(ZNODEEXISTS));
    newCONSTSUB(stash, "ZNOTEMPTY",                newSViv(ZNOTEMPTY));
    newCONSTSUB(stash, "ZSESSIONEXPIRED",          newSViv(ZSESSIONEXPIRED));
    newCONSTSUB(stash, "ZINVALIDCALLBACK",         newSViv(ZINVALIDCALLBACK));
    newCONSTSUB(stash, "ZINVALIDACL",              newSViv(ZINVALIDACL));
    newCONSTSUB(stash, "ZAUTHFAILED",              newSViv(ZAUTHFAILED));
    newCONSTSUB(stash, "ZCLOSING",                 newSViv(ZCLOSING));
    newCONSTSUB(stash, "ZNOTHING",                 newSViv(ZNOTHING));

    newCONSTSUB(stash, "ZOO_EPHEMERAL", newSViv(ZOO_EPHEMERAL));
    newCONSTSUB(stash, "ZOO_SEQUENCE",  newSViv(ZOO_SEQUENCE));

    newCONSTSUB(stash, "ZOO_OPEN_ACL_UNSAFE", acl_vector_to_sv(aTHX_ &ZOO_OPEN_ACL_UNSAFE));
    newCONSTSUB(stash, "ZOO_READ_ACL_UNSAFE", acl_vector_to_sv(aTHX_ &ZOO_READ_ACL_UNSAFE));
    newCONSTSUB(stash, "ZOO_CREATOR_ALL_ACL", acl_vector_to_sv(aTHX_ &ZOO_CREATOR_ALL_ACL));

    newCONSTSUB(stash, "ZOO_PERM_READ",   newSViv(ZOO_PERM_READ));
    newCONSTSUB(stash, "ZOO_PERM_WRITE",  newSViv(ZOO_PERM_WRITE));
    newCONSTSUB(stash, "ZOO_PERM_CREATE", newSViv(ZOO_PERM_CREATE));
    newCONSTSUB(stash, "ZOO_PERM_DELETE", newSViv(ZOO_PERM_DELETE));
    newCONSTSUB(stash, "ZOO_PERM_ADMIN",  newSViv(ZOO_PERM_ADMIN));
    newCONSTSUB(stash, "ZOO_PERM_ALL",    newSViv(ZOO_PERM_ALL));

    newCONSTSUB(stash, "ZOO_CREATED_EVENT",     newSViv(ZOO_CREATED_EVENT));
    newCONSTSUB(stash, "ZOO_DELETED_EVENT",     newSViv(ZOO_DELETED_EVENT));
    newCONSTSUB(stash, "ZOO_CHANGED_EVENT",     newSViv(ZOO_CHANGED_EVENT));
    newCONSTSUB(stash, "ZOO_CHILD_EVENT",       newSViv(ZOO_CHILD_EVENT));
    newCONSTSUB(stash, "ZOO_SESSION_EVENT",     newSViv(ZOO_SESSION_EVENT));
    newCONSTSUB(stash, "ZOO_NOTWATCHING_EVENT", newSViv(ZOO_NOTWATCHING_EVENT));

    newCONSTSUB(stash, "ZOO_EXPIRED_SESSION_STATE", newSViv(ZOO_EXPIRED_SESSION_STATE));
    newCONSTSUB(stash, "ZOO_AUTH_FAILED_STATE",     newSViv(ZOO_AUTH_FAILED_STATE));
    newCONSTSUB(stash, "ZOO_CONNECTING_STATE",      newSViv(ZOO_CONNECTING_STATE));
    newCONSTSUB(stash, "ZOO_ASSOCIATING_STATE",     newSViv(ZOO_ASSOCIATING_STATE));
    newCONSTSUB(stash, "ZOO_CONNECTED_STATE",       newSViv(ZOO_CONNECTED_STATE));

    newCONSTSUB(stash, "ZOO_CREATE_OP",  newSViv(ZOO_CREATE_OP));
    newCONSTSUB(stash, "ZOO_DELETE_OP",  newSViv(ZOO_DELETE_OP));
    newCONSTSUB(stash, "ZOO_SETDATA_OP", newSViv(ZOO_SETDATA_OP));
    newCONSTSUB(stash, "ZOO_CHECK_OP",   newSViv(ZOO_CHECK_OP));
}

const char*
zerror(int c)

MODULE = ZooKeeper PACKAGE = ZooKeeper::Transaction

void
commit(SV* self, pzk_t* pzk, int count, SV* ops_sv)
    PPCODE:
        int i;
        zoo_op_result_t* results; Newxz(results, count, zoo_op_result_t);
        zoo_op_t* ops = sv_to_ops(aTHX_ ops_sv);

        int rc = zoo_multi(pzk->handle, count, ops, results);
        if (rc == ZMARSHALLINGERROR && is_unrecoverable(pzk->handle)) {
            // assume the error is ZINVALIDSTATE if handle is unrecoverable
            // internally Request_path_init checks the zhandle status
            //  and returns an error if it is unrecoverable
            // zoo_multi considers this a marshalling error, because it's generated
            //  while forming the request, which is misleading to the user
            rc = ZINVALIDSTATE;
        }

        // handle any system errors
        if (rc != ZOK) {
            int op_errors = 0;
            for (i = 0; i < count; i++) {
                if (results[i].err != ZOK) op_errors++;
            }
            if (!op_errors) {
                // if the multi call failed, but no ops had errors
                // assume this is a system error and throw an exception
                Safefree(results);
                free_ops(aTHX_ ops, count);
                throw_zerror(aTHX_ rc, "Error committing transaction: %s", zerror(rc));
            }
        }

        for (i = 0; i < count; i++) {
            if (rc == ZOK) {
                ST(i) = sv_2mortal(op_to_sv(aTHX_ ops[i]));
            } else {
                ST(i) = sv_2mortal(op_error_to_sv(aTHX_ results[i]));
            }
        }
        Safefree(results);
        free_ops(aTHX_ ops, count);
        XSRETURN(count);


