#include "EXTERN.h"
#include "perl.h"
#include "zmqxs.h"

inline void Zmqxs_set_bang(pTHX_ int err){
    SV *errsv;
    errsv = get_sv("!", GV_ADD);
    sv_setsv(errsv, newSViv(err));
}

void zmqxs_free_data(void *data, void *hint) {
    Safefree(data);
}

int Zmqxs_has_object(pTHX_ SV *self){
    void *s = xs_object_magic_get_struct(aTHX_ SvRV(self));
    return (s != NULL);
}

inline void Zmqxs_ensure_unallocated(pTHX_ SV *self) {
    if(zmqxs_has_object(self))
        croak("A struct is already attached to this object (SV %p)!", self);
}

inline zmq_msg_t *Zmqxs_msg_start_allocate(pTHX_ SV *self) {
    zmq_msg_t *msg;
    zmqxs_ensure_unallocated(self);
    Newx(msg, 1, zmq_msg_t);
    if(msg == NULL)
       croak("Error allocating memory for zmq_msg_t structure!");
    return msg;
}

inline void Zmqxs_msg_finish_allocate(pTHX_ SV *self, int status, zmq_msg_t *msg){
    if(status < 0){
        SET_BANG;
        Safefree(msg);
        if(_ERRNO == ENOMEM)
            croak("Insufficient space memory available for message.");
        croak("Unknown error initializing message!");
    }
    xs_object_magic_attach_struct(aTHX_ SvRV(self), msg);
}
