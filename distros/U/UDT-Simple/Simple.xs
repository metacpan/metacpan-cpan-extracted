#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif
#include "UDT__Simple.hpp"

MODULE = UDT::Simple		PACKAGE = UDT::Simple		


UDT__Simple *
UDT__Simple::new(int family, int type)

void
UDT__Simple::DESTROY()

void
UDT__Simple::bind(char *host, short port)

void
UDT__Simple::udt_sndbuf(int value)

void
UDT__Simple::udp_sndbuf(int value)    

void
UDT__Simple::udt_rcvbuf(int value)

void
UDT__Simple::udp_rcvbuf(int value)

void
UDT__Simple::udt_rcvtimeo(int value)

void
UDT__Simple::udt_sndtimeo(int value)

void
UDT__Simple::listen(int backlog)

void
UDT__Simple::close()

UDT__Simple *
UDT__Simple::accept()

void
UDT__Simple::connect(char *host, short port)

int
UDT__Simple::send(SV *data,int offset = 0)

SV *
UDT__Simple::recv(int bytes)
