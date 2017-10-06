#include <LDNS.h>

#define RR_CLASSNAME_MAX_LEN 34

#ifdef USE_ITHREADS
#define RESOLVER_HASH_NAME "Zonemaster::LDNS::__resolvers__"
#define RR_HASH_NAME "Zonemaster::LDNS::__rrs__"
#define RRLIST_HASH_NAME "Zonemaster::LDNS::__rrlists__"
#define PACKET_HASH_NAME "Zonemaster::LDNS::__packets__"

void
net_ldns_forget()
{
    int i;

    const char *names[] = {
       RESOLVER_HASH_NAME,
       RR_HASH_NAME,
       RRLIST_HASH_NAME,
       PACKET_HASH_NAME,
       NULL
    };

    for(i=0; names[i]; i++)
    {
        HV *hash;
        HE *entry;

        hash = get_hv(names[i], GV_ADD);
        while ( (entry = hv_iternext(hash)) != NULL )
        {
            SV *val = hv_iterval(hash, entry);
            if(!SvOK(val))
            {
                SV *key = hv_iterkeysv(entry);
                hv_delete_ent(hash, key, G_DISCARD, 0);
            }
        }
    }
}

void
net_ldns_remember_resolver(SV *rv)
{
    net_ldns_remember(rv, RESOLVER_HASH_NAME);
}

void
net_ldns_remember_rr(SV *rv)
{
    net_ldns_remember(rv, RR_HASH_NAME);
}

void
net_ldns_remember_rrlist(SV *rv)
{
    net_ldns_remember(rv, RRLIST_HASH_NAME);
}

void
net_ldns_remember_packet(SV *rv)
{
    net_ldns_remember(rv, PACKET_HASH_NAME);
}

void
net_ldns_remember(SV *rv, const char *hashname)
{
    HV *hash;
    SV *val;
    STRLEN keylen;
    char *keystr;

    hash = get_hv(hashname, GV_ADD);
    val = newRV_inc(SvRV(rv));
    keystr = SvPV(val,keylen);
    sv_rvweaken(val);
    hv_store(hash, keystr, keylen, val, 0);
}

void
net_ldns_clone_resolvers()
{
    HV *hash;
    HE *entry;

    hash = get_hv(RESOLVER_HASH_NAME, GV_ADD);
    hv_iterinit(hash);
    while ( (entry = hv_iternext(hash)) != NULL )
    {
        SV *val = hv_iterval(hash, entry);
        if(SvOK(val))
        {
            ldns_resolver *old = INT2PTR(ldns_resolver *, SvIV((SV *)SvRV(val)));
            ldns_resolver *new = ldns_resolver_clone(old);
            sv_setiv_mg(SvRV(val), PTR2IV(new));
        }
        else
        {
            SV *key = hv_iterkeysv(entry);
            hv_delete_ent(hash, key, G_DISCARD, 0);
        }
    }
}

void
net_ldns_clone_rrs()
{
    HV *hash;
    HE *entry;

    hash = get_hv(RR_HASH_NAME, GV_ADD);
    hv_iterinit(hash);
    while ( (entry = hv_iternext(hash)) != NULL )
    {
        SV *val = hv_iterval(hash, entry);
        SV *key = hv_iterkeysv(entry);
        if(SvOK(val))
        {
            ldns_rr *old = INT2PTR(ldns_rr *, SvIV((SV *)SvRV(val)));
            ldns_rr *new = ldns_rr_clone(old);
            sv_setiv_mg(SvRV(val), PTR2IV(new));
        }
        else
        {
            hv_delete_ent(hash, key, G_DISCARD, 0);
        }
    }
}

void
net_ldns_clone_rrlists()
{
    HV *hash;
    HE *entry;

    hash = get_hv(RRLIST_HASH_NAME, GV_ADD);
    hv_iterinit(hash);
    while ( (entry = hv_iternext(hash)) != NULL )
    {
        SV *val = hv_iterval(hash, entry);
        if(SvOK(val))
        {
            ldns_rr_list *old = INT2PTR(ldns_rr_list *, SvIV((SV *)SvRV(val)));
            ldns_rr_list *new = ldns_rr_list_clone(old);
            sv_setiv_mg(SvRV(val), PTR2IV(new));
        }
        else
        {
            SV *key = hv_iterkeysv(entry);
            hv_delete_ent(hash, key, G_DISCARD, 0);
        }
    }
}

void
net_ldns_clone_packets()
{
    HV *hash;
    HE *entry;

    hash = get_hv(PACKET_HASH_NAME, GV_ADD);
    hv_iterinit(hash);
    while ( (entry = hv_iternext(hash)) != NULL )
    {
        SV *val = hv_iterval(hash, entry);
        if(SvOK(val))
        {
            ldns_pkt *old = INT2PTR(ldns_pkt *, SvIV((SV *)SvRV(val)));
            ldns_pkt *new = ldns_pkt_clone(old);
            sv_setiv_mg(SvRV(val), PTR2IV(new));
        }
        else
        {
            SV *key = hv_iterkeysv(entry);
            hv_delete_ent(hash, key, G_DISCARD, 0);
        }
    }
}

#endif

char *
randomize_capitalization(char *in)
{
#ifdef RANDOMIZE
    char *str;
    str = in;
    while(*str) {
        if(Drand01() < 0.5)
        {
            *str = tolower(*str);
        }
        else
        {
            *str = toupper(*str);
        }
        str++;
    }
#endif
    return in;
}

SV *
rr2sv(ldns_rr *rr)
{
    char rrclass[RR_CLASSNAME_MAX_LEN];
    char *type;

    type = ldns_rr_type2str(ldns_rr_get_type(rr));
    snprintf(rrclass, RR_CLASSNAME_MAX_LEN, "Zonemaster::LDNS::RR::%s", type);

    SV* rr_sv = newSV(0);
    if (strncmp(type, "TYPE", 4)==0)
    {
        sv_setref_pv(rr_sv, "Zonemaster::LDNS::RR", rr);
    }
    else
    {
        sv_setref_pv(rr_sv, rrclass, rr);
    }

    free(type);

#ifdef USE_ITHREADS
    net_ldns_remember_rr(rr_sv);
#endif

    return rr_sv;
}
