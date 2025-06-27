#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newSVpvn_share
#define NEED_sv_2pv_flags
#define NEED_newRV_noinc
#include "ppport.h"

#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <ldns/ldns.h>

#ifdef WE_CAN_HAZ_IDN
#include <idn2.h>
#endif

/* ldns 1.6.17 does not have this in its header files, but it is in the published documentation and we need it */
/* It looks like 1.6.18 will have it, but we'll fix that when it happens. */
#if (LDNS_REVISION) >= ((1<<16)|(6<<8)|(17))
void ldns_axfr_abort(ldns_resolver *obj);
#endif

typedef ldns_resolver *Zonemaster__LDNS;
typedef ldns_pkt *Zonemaster__LDNS__Packet;
typedef ldns_rr_list *Zonemaster__LDNS__RRList;
typedef ldns_rr *Zonemaster__LDNS__RR;
typedef ldns_rr *Zonemaster__LDNS__RR__A;
typedef ldns_rr *Zonemaster__LDNS__RR__A6;
typedef ldns_rr *Zonemaster__LDNS__RR__AAAA;
typedef ldns_rr *Zonemaster__LDNS__RR__AFSDB;
typedef ldns_rr *Zonemaster__LDNS__RR__APL;
typedef ldns_rr *Zonemaster__LDNS__RR__ATMA;
typedef ldns_rr *Zonemaster__LDNS__RR__CAA;
typedef ldns_rr *Zonemaster__LDNS__RR__CDS;
typedef ldns_rr *Zonemaster__LDNS__RR__CERT;
typedef ldns_rr *Zonemaster__LDNS__RR__CNAME;
typedef ldns_rr *Zonemaster__LDNS__RR__DHCID;
typedef ldns_rr *Zonemaster__LDNS__RR__DLV;
typedef ldns_rr *Zonemaster__LDNS__RR__DNAME;
typedef ldns_rr *Zonemaster__LDNS__RR__DNSKEY;
typedef ldns_rr *Zonemaster__LDNS__RR__DS;
typedef ldns_rr *Zonemaster__LDNS__RR__EID;
typedef ldns_rr *Zonemaster__LDNS__RR__EUI48;
typedef ldns_rr *Zonemaster__LDNS__RR__EUI64;
typedef ldns_rr *Zonemaster__LDNS__RR__GID;
typedef ldns_rr *Zonemaster__LDNS__RR__GPOS;
typedef ldns_rr *Zonemaster__LDNS__RR__HINFO;
typedef ldns_rr *Zonemaster__LDNS__RR__HIP;
typedef ldns_rr *Zonemaster__LDNS__RR__IPSECKEY;
typedef ldns_rr *Zonemaster__LDNS__RR__ISDN;
typedef ldns_rr *Zonemaster__LDNS__RR__KEY;
typedef ldns_rr *Zonemaster__LDNS__RR__KX;
typedef ldns_rr *Zonemaster__LDNS__RR__L32;
typedef ldns_rr *Zonemaster__LDNS__RR__L64;
typedef ldns_rr *Zonemaster__LDNS__RR__LOC;
typedef ldns_rr *Zonemaster__LDNS__RR__LP;
typedef ldns_rr *Zonemaster__LDNS__RR__MAILA;
typedef ldns_rr *Zonemaster__LDNS__RR__MAILB;
typedef ldns_rr *Zonemaster__LDNS__RR__MB;
typedef ldns_rr *Zonemaster__LDNS__RR__MD;
typedef ldns_rr *Zonemaster__LDNS__RR__MF;
typedef ldns_rr *Zonemaster__LDNS__RR__MG;
typedef ldns_rr *Zonemaster__LDNS__RR__MINFO;
typedef ldns_rr *Zonemaster__LDNS__RR__MR;
typedef ldns_rr *Zonemaster__LDNS__RR__MX;
typedef ldns_rr *Zonemaster__LDNS__RR__NAPTR;
typedef ldns_rr *Zonemaster__LDNS__RR__NID;
typedef ldns_rr *Zonemaster__LDNS__RR__NIMLOC;
typedef ldns_rr *Zonemaster__LDNS__RR__NINFO;
typedef ldns_rr *Zonemaster__LDNS__RR__NS;
typedef ldns_rr *Zonemaster__LDNS__RR__NSAP;
typedef ldns_rr *Zonemaster__LDNS__RR__NSEC;
typedef ldns_rr *Zonemaster__LDNS__RR__NSEC3;
typedef ldns_rr *Zonemaster__LDNS__RR__NSEC3PARAM;
typedef ldns_rr *Zonemaster__LDNS__RR__NULL;
typedef ldns_rr *Zonemaster__LDNS__RR__NXT;
typedef ldns_rr *Zonemaster__LDNS__RR__PTR;
typedef ldns_rr *Zonemaster__LDNS__RR__PX;
typedef ldns_rr *Zonemaster__LDNS__RR__RKEY;
typedef ldns_rr *Zonemaster__LDNS__RR__RP;
typedef ldns_rr *Zonemaster__LDNS__RR__RRSIG;
typedef ldns_rr *Zonemaster__LDNS__RR__RT;
typedef ldns_rr *Zonemaster__LDNS__RR__SIG;
typedef ldns_rr *Zonemaster__LDNS__RR__SINK;
typedef ldns_rr *Zonemaster__LDNS__RR__SOA;
typedef ldns_rr *Zonemaster__LDNS__RR__SPF;
typedef ldns_rr *Zonemaster__LDNS__RR__SRV;
typedef ldns_rr *Zonemaster__LDNS__RR__SSHFP;
typedef ldns_rr *Zonemaster__LDNS__RR__TA;
typedef ldns_rr *Zonemaster__LDNS__RR__TALINK;
typedef ldns_rr *Zonemaster__LDNS__RR__TKEY;
typedef ldns_rr *Zonemaster__LDNS__RR__TLSA;
typedef ldns_rr *Zonemaster__LDNS__RR__TXT;
typedef ldns_rr *Zonemaster__LDNS__RR__TYPE;
typedef ldns_rr *Zonemaster__LDNS__RR__UID;
typedef ldns_rr *Zonemaster__LDNS__RR__UINFO;
typedef ldns_rr *Zonemaster__LDNS__RR__UNSPEC;
typedef ldns_rr *Zonemaster__LDNS__RR__URI;
typedef ldns_rr *Zonemaster__LDNS__RR__WKS;
typedef ldns_rr *Zonemaster__LDNS__RR__X25;

#define D_STRING(what,where) ldns_rdf2str(ldns_rr_rdf(what,where))
#define D_U8(what,where) ldns_rdf2native_int8(ldns_rr_rdf(what,where))
#define D_U16(what,where) ldns_rdf2native_int16(ldns_rr_rdf(what,where))
#define D_U32(what,where) ldns_rdf2native_int32(ldns_rr_rdf(what,where))

SV *rr2sv(ldns_rr *rr);
void strip_newline(char* in);

#ifdef USE_ITHREADS
void net_ldns_remember_resolver(SV *rv);
void net_ldns_remember_rr(SV *rv);
void net_ldns_remember_rrlist(SV *rv);
void net_ldns_remember_packet(SV *rv);
void net_ldns_remember(SV *rv, const char *hashname);
void net_ldns_forget();
void net_ldns_clone_resolvers();
void net_ldns_clone_rrs();
void net_ldns_clone_rrlists();
void net_ldns_clone_packets();
#endif
