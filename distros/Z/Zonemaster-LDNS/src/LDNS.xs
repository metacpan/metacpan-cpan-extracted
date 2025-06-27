#include <LDNS.h>

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS

PROTOTYPES: ENABLE

SV *
to_idn(...)
    PPCODE:
    {
#ifdef WE_CAN_HAZ_IDN
        int i;
        for( i = 0; i<items; i++ )
        {
            char *out;
            int status;
            SV *obj = ST(i);

            if (SvPOK(ST(i)))
            {
               status = idn2_to_ascii_8z(SvPVutf8_nolen(obj), &out, IDN2_ALLOW_UNASSIGNED);
               if (status == IDN2_OK)
               {
                  SV *new = newSVpv(out,0);
                  SvUTF8_on(new); /* We know the string is plain ASCII, so let Perl know too */
                  mXPUSHs(new);
                  free(out);
               }
               else
               {
                  croak("IDN encoding error: %s\n", idn2_strerror_name(status));
               }
            }
        }
#else
        croak("libidn2 not installed");
#endif
    }

bool
has_idn()
    CODE:
#ifdef WE_CAN_HAZ_IDN
        RETVAL = 1;
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

bool
has_gost()
	CODE:
#ifdef USE_GOST
		RETVAL = 1;
#else
		RETVAL = 0;
#endif
	OUTPUT:
		RETVAL

const char *
lib_version()
    CODE:
        RETVAL = ldns_version();
    OUTPUT:
        RETVAL

SV *
load_zonefile(filename)
    char *filename;
    PPCODE:
    {
		ldns_zone *zone;
		ldns_status s;
		ldns_rr *soa;
		ldns_rr_list *rrs;
		ldns_rdf *root = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME,".");
        I32 context = GIMME_V;
		size_t i,n;

        if (context == G_VOID)
        {
            return;
        }

        FILE *fp = fopen(filename, "r");
		if(!fp)
		{
	    	croak("%s",strerror(errno));
		}

		s = ldns_zone_new_frm_fp(&zone, fp, root, 3600, LDNS_RR_CLASS_IN);
		if(s != LDNS_STATUS_OK)
		{
			croak("%s",ldns_get_errorstr_by_id(s));
		}

		soa = ldns_zone_soa(zone);
		rrs = ldns_zone_rrs(zone);

        n = ldns_rr_list_rr_count(rrs);

        if (context == G_SCALAR)
        {
            ldns_zone_deep_free(zone);
            ldns_rdf_deep_free(root);
            XSRETURN_IV(n+1); /* Add one for SOA */
        }

        mXPUSHs(rr2sv(ldns_rr_clone(soa)));
        for(i = 0; i < n; ++i)
        {
            mXPUSHs(rr2sv(ldns_rr_clone(ldns_rr_list_rr(rrs,i))));
        }
		ldns_zone_deep_free(zone);
		ldns_rdf_deep_free(root);
    }

SV *
new(class, ...)
    char *class;
    CODE:
    {
        int i;
        ldns_resolver *res;
        RETVAL = newSV(0);

        if (items == 1 ) { /* Called without arguments, use resolv.conf */
            ldns_resolver_new_frm_file(&res,NULL);
        }
        else {
            res = ldns_resolver_new();
            ldns_resolver_set_recursive(res, 1);
            for (i=1;i<items;i++)
            {
                ldns_status s;
                ldns_rdf *addr;

                SvGETMAGIC(ST(i));
                addr = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_A, SvPV_nolen(ST(i)));
                if ( addr == NULL) {
                    addr = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_AAAA, SvPV_nolen(ST(i)));
                }
                if ( addr == NULL ) {
                    croak("Failed to parse IP address: %s", SvPV_nolen(ST(i)));
                }
                s = ldns_resolver_push_nameserver(res, addr);
                ldns_rdf_deep_free(addr);
                if(s != LDNS_STATUS_OK)
                {
                    croak("Adding nameserver failed: %s", ldns_get_errorstr_by_id(s));
                }
            }
        }
        sv_setref_pv(RETVAL, class, res);
    }
    OUTPUT:
        RETVAL

SV *
query(obj, dname, rrtype="A", rrclass="IN")
    Zonemaster::LDNS obj;
    char *dname;
    char *rrtype;
    char *rrclass;
    CODE:
    {
        ldns_rdf *domain;
        ldns_rr_type t;
        ldns_rr_class c;
        ldns_status status;
        ldns_pkt *pkt;
        uint16_t flags = 0;

        t = ldns_get_rr_type_by_name(rrtype);
        if(!t)
        {
            croak("Unknown RR type: %s", rrtype);
        }

        c = ldns_get_rr_class_by_name(rrclass);
        if(!c)
        {
            croak("Unknown RR class: %s", rrclass);
        }

        domain = ldns_dname_new_frm_str(dname);
        if(domain==NULL)
        {
            croak("Invalid domain name: %s", dname);
        }

        if(ldns_resolver_recursive(obj))
        {
            flags |= LDNS_RD;
        }

        if(ldns_resolver_dnssec_cd(obj))
        {
            flags |= LDNS_CD;
        }

        status = ldns_resolver_send(&pkt, obj, domain, t, c, flags);
        if ( status != LDNS_STATUS_OK) {
            /* Remove and reinsert nameserver to make ldns forget it failed */
            ldns_status s;
            ldns_rdf *ns = ldns_resolver_pop_nameserver(obj);
            if (ns != NULL) {
                s = ldns_resolver_push_nameserver(obj, ns);
                if ( s != LDNS_STATUS_OK) {
                    croak("Failed to reinsert nameserver after failure (ouch): %s", ldns_get_errorstr_by_id(s));
                }
                ldns_rdf_deep_free(ns);
            }
            ldns_rdf_deep_free(domain);
            croak("%s", ldns_get_errorstr_by_id(status));
            RETVAL = NULL;
        }
        ldns_pkt *clone = ldns_pkt_clone(pkt);
        ldns_pkt_set_timestamp(clone, ldns_pkt_timestamp(pkt));
        RETVAL = sv_setref_pv(newSV(0), "Zonemaster::LDNS::Packet", clone);
        ldns_rdf_deep_free(domain);
        ldns_pkt_free(pkt);
    }
    OUTPUT:
        RETVAL

#
# Function: query_with_pkt
# ------------------------
# Sister function of 'query' that takes a 'ready to send'
# packet instead of create a new one from provided parameters.
#
# obj: LDNS resolver object
# query_pkt: the packet to send
#
# returns: a "Zonemaster::LDNS::Packet" object with answer of the query
#
SV *
query_with_pkt(obj, query_pkt)
    Zonemaster::LDNS obj;
    Zonemaster::LDNS::Packet query_pkt;
    CODE:
    {
        ldns_status status;
        ldns_pkt *pkt;

        status = ldns_resolver_send_pkt(&pkt, obj, query_pkt);
        if ( status != LDNS_STATUS_OK) {
            /* Remove and reinsert nameserver to make ldns forget it failed */
            ldns_status s;
            ldns_rdf *ns = ldns_resolver_pop_nameserver(obj);
            if (ns != NULL) {
                s = ldns_resolver_push_nameserver(obj, ns);
                if ( s != LDNS_STATUS_OK) {
                    croak("Failed to reinsert nameserver after failure (ouch): %s", ldns_get_errorstr_by_id(s));
                }
                ldns_rdf_deep_free(ns);
            }
            croak("%s", ldns_get_errorstr_by_id(status));
            RETVAL = NULL;
        }
        ldns_pkt *clone = ldns_pkt_clone(pkt);
        ldns_pkt_set_timestamp(clone, ldns_pkt_timestamp(pkt));
        RETVAL = sv_setref_pv(newSV(0), "Zonemaster::LDNS::Packet", clone);
        ldns_pkt_free(pkt);
    }
    OUTPUT:
        RETVAL


bool
recurse(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if(items>1) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_recursive(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_recursive(obj);
    OUTPUT:
        RETVAL

bool
debug(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_debug(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_debug(obj);
    OUTPUT:
        RETVAL

bool
dnssec(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_dnssec(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_dnssec(obj);
    OUTPUT:
        RETVAL

bool
cd(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_dnssec_cd(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_dnssec_cd(obj);
    OUTPUT:
        RETVAL

bool
usevc(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_usevc(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_usevc(obj);
    OUTPUT:
        RETVAL

bool
igntc(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_igntc(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_igntc(obj);
    OUTPUT:
        RETVAL

#
# Function: fallback
# ------------------
# Get/set 'fallback' flag
#
# returns: a boolean
#
bool
fallback(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_fallback(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_fallback(obj);
    OUTPUT:
        RETVAL

U8
retry(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_retry(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_retry(obj);
    OUTPUT:
        RETVAL

U8
retrans(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_retrans(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_retrans(obj);
    OUTPUT:
        RETVAL

U16
edns_size(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if( items > 1 )
        {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_edns_udp_size(obj, (U16)SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_edns_udp_size(obj);
    OUTPUT:
        RETVAL

U16
port(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if( items > 1 )
        {
            SvGETMAGIC(ST(1));
            ldns_resolver_set_port(obj, (U16)SvIV(ST(1)));
        }
        RETVAL = ldns_resolver_port(obj);
    OUTPUT:
        RETVAL

SV *
name2addr(obj,name)
    Zonemaster::LDNS obj;
    const char *name;
    PPCODE:
    {
        ldns_rr_list *addrs;
        ldns_rdf *dname;
        size_t n, i;
        I32 context;

        context = GIMME_V;

        if(context == G_VOID)
        {
            XSRETURN_NO;
        }

        dname = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, name);
        if(dname==NULL)
        {
            croak("Name error for '%s'", name);
        }

        addrs = ldns_get_rr_list_addr_by_name(obj,dname,LDNS_RR_CLASS_IN,0);
        n = ldns_rr_list_rr_count(addrs);
        ldns_rdf_deep_free(dname);

        if (context == G_SCALAR)
        {
          ldns_rr_list_deep_free(addrs);
          XSRETURN_IV(n);
        }
        else
        {
            for(i = 0; i < n; ++i)
            {
                ldns_rr *rr = ldns_rr_list_rr(addrs,i);
                ldns_rdf *addr_rdf = ldns_rr_a_address(rr);
                char *addr_str = ldns_rdf2str(addr_rdf);

                SV* sv = newSVpv(addr_str,0);
                mXPUSHs(sv);
                free(addr_str);
            }
            ldns_rr_list_deep_free(addrs);
        }
    }

SV *
addr2name(obj,addr_in)
    Zonemaster::LDNS obj;
    const char *addr_in;
    PPCODE:
    {
        ldns_rr_list *names;
        ldns_rdf *addr_rdf;
        size_t n, i;
        I32 context;

        context = GIMME_V;

        if(context == G_VOID)
        {
            XSRETURN_NO;
        }

        addr_rdf = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_A, addr_in);
        if(addr_rdf==NULL)
        {
            addr_rdf = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_AAAA, addr_in);
        }
        if(addr_rdf==NULL)
        {
            croak("Failed to parse address: %s", addr_in);
        }

        names = ldns_get_rr_list_name_by_addr(obj,addr_rdf,LDNS_RR_CLASS_IN,0);
        ldns_rdf_deep_free(addr_rdf);
        n = ldns_rr_list_rr_count(names);

        if (context == G_SCALAR)
        {
          ldns_rr_list_deep_free(names);
          XSRETURN_IV(n);
        }
        else
        {
            for(i = 0; i < n; ++i)
            {
                ldns_rr *rr = ldns_rr_list_rr(names,i);
                ldns_rdf *name_rdf = ldns_rr_rdf(rr,0);
                char *name_str = ldns_rdf2str(name_rdf);

                SV* sv = newSVpv(name_str,0);
                mXPUSHs(sv);
                free(name_str);
            }
            ldns_rr_list_deep_free(names);
        }
    }

bool
axfr(obj,dname,callback,class="IN")
    Zonemaster::LDNS obj;
    const char *dname;
    SV *callback;
    const char *class;
    CODE:
    {
        ldns_rdf *domain = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, dname);
        ldns_rr_class cl = ldns_get_rr_class_by_name(class);
        ldns_status status;

        SvGETMAGIC(callback);
        if(SvTYPE(SvRV(callback)) != SVt_PVCV)
        {
          ldns_rdf_deep_free(domain);
          croak("Callback not a code reference");
        }

        if(domain==NULL)
        {
          ldns_rdf_deep_free(domain);
          croak("Name error for '%s", dname);
        }

        if(!cl)
        {
          ldns_rdf_deep_free(domain);
          croak("Unknown RR class: %s", class);
        }

        status = ldns_axfr_start(obj, domain, cl);
        ldns_rdf_deep_free(domain);

        if(status != LDNS_STATUS_OK)
        {
            croak("AXFR setup error: %s", ldns_get_errorstr_by_id(status));
        }

        RETVAL = 1;
        while (!ldns_axfr_complete(obj))
        {
            int count;
            SV *ret;
            ldns_rr *rr = ldns_axfr_next(obj);
            if(rr==NULL)
            {
                ldns_pkt *pkt = ldns_axfr_last_pkt(obj);
                if(pkt != NULL)
                {
                   char tmp[20];
                   char *msg = ldns_pkt_rcode2str(ldns_pkt_get_rcode(pkt));
                   strncpy(tmp,msg,19);
                   free(msg);
                   croak("AXFR transfer error: %s", tmp);
                }
                else {
                    croak("AXFR transfer error: unknown problem");
                }
                ldns_pkt_free(pkt);
            }

            /* Enter the Cargo Cult */
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            mXPUSHs(rr2sv(rr));
            PUTBACK;
            count = call_sv(callback, G_SCALAR);
            SPAGAIN;

            if(count != 1)
            {
                croak("Callback did not return exactly one value in scalar context");
            }

            ret = POPs;

            if(!SvTRUE(ret))
            {
                RETVAL = 0;
                break;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
            /* Callback magic ends */
        }
        ldns_axfr_abort(obj);
    }
    OUTPUT:
        RETVAL

bool
axfr_start(obj,dname,class="IN")
    Zonemaster::LDNS obj;
    const char *dname;
    const char *class;
    CODE:
    {
        ldns_rdf *domain = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, dname);
        ldns_rr_class cl = ldns_get_rr_class_by_name(class);
        ldns_status s;

        if(domain==NULL)
        {
            croak("Name error for '%s", dname);
        }

        if(!cl)
        {
            croak("Unknown RR class: %s", class);
        }

        s = ldns_axfr_start(obj, domain, cl);

        RETVAL = (s==LDNS_STATUS_OK);
    }
    OUTPUT:
        RETVAL

SV *
axfr_next(obj)
    Zonemaster::LDNS obj;
    CODE:
    {
        ldns_rr *rr;

        /* ldns unfortunately prints to standard error, so close it while we call them */
        /* EDIT: That behavior should be changed starting with ldns 1.6.17, but we'll keep the closing for a while */
        int err_fd = fileno(stderr);            /* Remember fd for stderr */
        int save_fd = dup(err_fd);              /* Copy open fd for stderr */
        int tmp_fd;

        fflush(stderr);                         /* Print anything waiting */
        tmp_fd = open("/dev/null",O_RDWR);      /* Open something to allocate the now-free fd stderr used */
        dup2(tmp_fd,err_fd);
        rr = ldns_axfr_next(obj);               /* Shut up */
        close(tmp_fd);                          /* Close the placeholder */
        fflush(stderr);                         /* Flush anything ldns buffered */
        dup2(save_fd,err_fd);                   /* And copy the open stderr back to where it should be */

        if(rr==NULL)
        {
            croak("AXFR error");
        }

        RETVAL = rr2sv(rr);
    }
    OUTPUT:
        RETVAL

bool
axfr_complete(obj)
    Zonemaster::LDNS obj;
    CODE:
        RETVAL = ldns_axfr_complete(obj);
    OUTPUT:
        RETVAL

Zonemaster::LDNS::Packet
axfr_last_packet(obj)
    Zonemaster::LDNS obj;
    CODE:
        RETVAL = ldns_axfr_last_pkt(obj);
    OUTPUT:
        RETVAL

double
timeout(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        struct timeval tv;

        if( items > 1)
        {
            double dec_part, int_part;
            struct timeval tn;

            SvGETMAGIC(ST(1));
            dec_part = modf(SvNV(ST(1)), &int_part);
            tn.tv_sec  = int_part;
            tn.tv_usec = 1000000*dec_part;
            ldns_resolver_set_timeout(obj, tn);
        }

        tv = ldns_resolver_timeout(obj);
        RETVAL = (double)tv.tv_sec;
        RETVAL += ((double)tv.tv_usec)/1000000;
    OUTPUT:
        RETVAL


char *
source(obj,...)
    Zonemaster::LDNS obj;
    CODE:
        if(items >= 2)
        {
           ldns_rdf *address;

           SvGETMAGIC(ST(1));
           address = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_A, SvPV_nolen(ST(1)));
           if(address == NULL)
           {
              address = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_AAAA, SvPV_nolen(ST(1)));
           }
           if(address == NULL)
           {
              croak("Failed to parse IP address: %s", SvPV_nolen(ST(1)));
           }

           ldns_resolver_set_source(obj, address);
        }
        RETVAL = ldns_rdf2str(ldns_resolver_source(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);



void
DESTROY(obj)
    Zonemaster::LDNS obj;
    CODE:
        ldns_axfr_abort(obj);
        ldns_resolver_deep_free(obj);

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::Packet           PREFIX=packet_

SV *
packet_new(objclass,name,type="A",class="IN")
    char *objclass;
    char *name;
    char *type;
    char *class;
    CODE:
    {
        ldns_rdf *rr_name;
        ldns_rr_type rr_type;
        ldns_rr_class rr_class;
        ldns_pkt *pkt;

        rr_type = ldns_get_rr_type_by_name(type);
        if(!rr_type)
        {
            croak("Unknown RR type: %s", type);
        }

        rr_class = ldns_get_rr_class_by_name(class);
        if(!rr_class)
        {
            croak("Unknown RR class: %s", class);
        }

        rr_name = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, name);
        if(rr_name == NULL)
        {
            croak("Name error for '%s'", name);
        }

        pkt = ldns_pkt_query_new(rr_name, rr_type, rr_class,0);
        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, objclass, pkt);
    }
    OUTPUT:
        RETVAL

char *
packet_rcode(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
		if ( items > 1 ) {
            SvGETMAGIC(ST(1));
			if ( strnEQ("NOERROR", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_NOERROR);
			}
			else if ( strnEQ("FORMERR", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_FORMERR);
			}
			else if ( strnEQ("SERVFAIL", SvPV_nolen(ST(1)), 8) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_SERVFAIL);
			}
			else if ( strnEQ("NXDOMAIN", SvPV_nolen(ST(1)), 8) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_NXDOMAIN);
			}
			else if ( strnEQ("NOTIMPL", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_NOTIMPL);
			}
			else if ( strnEQ("REFUSED", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_REFUSED);
			}
			else if ( strnEQ("YXDOMAIN", SvPV_nolen(ST(1)), 8) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_YXDOMAIN);
			}
			else if ( strnEQ("YXRRSET", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_YXRRSET);
			}
			else if ( strnEQ("NXRRSET", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_NXRRSET);
			}
			else if ( strnEQ("NOTAUTH", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_NOTAUTH);
			}
			else if ( strnEQ("NOTZONE", SvPV_nolen(ST(1)), 7) ) {
				ldns_pkt_set_rcode(obj, LDNS_RCODE_NOTZONE);
			}
			else {
				croak("Unknown RCODE: %s", SvPV_nolen(ST(1)));
			}
		}
        RETVAL = ldns_pkt_rcode2str(ldns_pkt_get_rcode(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

char *
packet_opcode(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
		if ( items > 1 ) {
            SvGETMAGIC(ST(1));
			if ( strnEQ("QUERY", SvPV_nolen(ST(1)), 5) ) {
				ldns_pkt_set_opcode(obj, LDNS_PACKET_QUERY);
			}
			else if ( strnEQ("IQUERY", SvPV_nolen(ST(1)), 6) ) {
				ldns_pkt_set_opcode(obj, LDNS_PACKET_IQUERY);
			}
			else if ( strnEQ("STATUS", SvPV_nolen(ST(1)), 6) ) {
				ldns_pkt_set_opcode(obj, LDNS_PACKET_STATUS);
			}
			else if ( strnEQ("NOTIFY", SvPV_nolen(ST(1)), 6) ) {
				ldns_pkt_set_opcode(obj, LDNS_PACKET_NOTIFY);
			}
			else if ( strnEQ("UPDATE", SvPV_nolen(ST(1)), 6) ) {
				ldns_pkt_set_opcode(obj, LDNS_PACKET_UPDATE);
			}
			else {
				croak("Unknown OPCODE: %s", SvPV_nolen(ST(1)));
			}
		}
        RETVAL = ldns_pkt_opcode2str(ldns_pkt_get_opcode(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

U16
packet_id(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_id(obj, (U16)SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_id(obj);
    OUTPUT:
        RETVAL

bool
packet_qr(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_qr(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_qr(obj);
    OUTPUT:
        RETVAL

bool
packet_aa(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_aa(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_aa(obj);
    OUTPUT:
        RETVAL

bool
packet_tc(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_tc(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_tc(obj);
    OUTPUT:
        RETVAL

bool
packet_rd(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_rd(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_rd(obj);
    OUTPUT:
        RETVAL

bool
packet_cd(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_cd(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_cd(obj);
    OUTPUT:
        RETVAL

bool
packet_ra(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_ra(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_ra(obj);
    OUTPUT:
        RETVAL

bool
packet_ad(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_ad(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_ad(obj);
    OUTPUT:
        RETVAL

bool
packet_do(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_edns_do(obj, SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_edns_do(obj);
    OUTPUT:
        RETVAL

size_t
packet_size(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt_size(obj);
    OUTPUT:
        RETVAL

U32
packet_querytime(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if ( items > 1 ) {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_querytime(obj, (U32)SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_querytime(obj);
    OUTPUT:
        RETVAL

char *
packet_answerfrom(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if(items >= 2)
        {
           ldns_rdf *address;

           SvGETMAGIC(ST(1));
           address = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_A, SvPV_nolen(ST(1)));
           if(address == NULL)
           {
              address = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_AAAA, SvPV_nolen(ST(1)));
           }
           if(address == NULL)
           {
              croak("Failed to parse IP address: %s", SvPV_nolen(ST(1)));
           }

           ldns_pkt_set_answerfrom(obj, address);
        }
        RETVAL = ldns_rdf2str(ldns_pkt_answerfrom(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

double
packet_timestamp(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if(items >= 2)
        {
            struct timeval tn;
            double dec_part, int_part;

            SvGETMAGIC(ST(1));
            dec_part = modf(SvNV(ST(1)), &int_part);
            tn.tv_sec  = int_part;
            tn.tv_usec = 1000000*dec_part;
            ldns_pkt_set_timestamp(obj,tn);
        }
        struct timeval t = ldns_pkt_timestamp(obj);
        RETVAL = (double)t.tv_sec;
        RETVAL += ((double)t.tv_usec)/1000000;
    OUTPUT:
        RETVAL

SV *
packet_answer_unfiltered(obj)
    Zonemaster::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;
        I32 context = GIMME_V;

        if (context == G_VOID)
        {
            return;
        }

        rrs = ldns_pkt_answer(obj);
        n = ldns_rr_list_rr_count(rrs);

        if (context == G_SCALAR)
        {
            XSRETURN_IV(n);
        }

        for(i = 0; i < n; ++i)
        {
            mXPUSHs(rr2sv(ldns_rr_clone(ldns_rr_list_rr(rrs,i))));
        }
    }

SV *
packet_authority_unfiltered(obj)
    Zonemaster::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;
        I32 context = GIMME_V;

        if (context == G_VOID)
        {
            return;
        }

        rrs = ldns_pkt_authority(obj);
        n = ldns_rr_list_rr_count(rrs);

        if (context == G_SCALAR)
        {
            XSRETURN_IV(n);
        }

        for(i = 0; i < n; ++i)
        {
            mXPUSHs(rr2sv(ldns_rr_clone(ldns_rr_list_rr(rrs,i))));
        }
    }

SV *
packet_additional_unfiltered(obj)
    Zonemaster::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;
        I32 context = GIMME_V;

        if (context == G_VOID)
        {
            return;
        }

        rrs = ldns_pkt_additional(obj);
        n = ldns_rr_list_rr_count(rrs);

        if (context == G_SCALAR)
        {
            XSRETURN_IV(n);
        }

        for(i = 0; i < n; ++i)
        {
            mXPUSHs(rr2sv(ldns_rr_clone(ldns_rr_list_rr(rrs,i))));
        }
    }

SV *
packet_question(obj)
    Zonemaster::LDNS::Packet obj;
    PPCODE:
    {
        size_t i,n;
        ldns_rr_list *rrs;
        I32 context = GIMME_V;

        if (context == G_VOID)
        {
            return;
        }

        rrs = ldns_pkt_question(obj);
        n = ldns_rr_list_rr_count(rrs);

        if (context == G_SCALAR)
        {
            XSRETURN_IV(n);
        }

        for(i = 0; i < n; ++i)
        {
            mXPUSHs(rr2sv(ldns_rr_clone(ldns_rr_list_rr(rrs,i))));
        }
    }

bool
packet_unique_push(obj,section,rr)
    Zonemaster::LDNS::Packet obj;
    char *section;
    Zonemaster::LDNS::RR rr;
    CODE:
    {
        ldns_pkt_section sec;
        char lbuf[21];
        char *p;

        p = lbuf;
        strncpy(lbuf, section, 20);
        for(; *p; p++) *p = tolower(*p);

        if(strncmp(lbuf, "answer", 6)==0)
        {
            sec = LDNS_SECTION_ANSWER;
        }
        else if(strncmp(lbuf, "additional", 10)==0)
        {
            sec = LDNS_SECTION_ADDITIONAL;
        }
        else if(strncmp(lbuf, "authority", 9)==0)
        {
            sec = LDNS_SECTION_AUTHORITY;
        }
        else if(strncmp(lbuf, "question", 8)==0)
        {
            sec = LDNS_SECTION_QUESTION;
        }
        else
        {
            croak("Unknown section: %s", section);
        }

        RETVAL = ldns_pkt_safe_push_rr(obj, sec, ldns_rr_clone(rr));
    }
    OUTPUT:
        RETVAL

SV *
packet_all(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
        ldns_rr_list *list = ldns_pkt_all_noquestion(obj);
        RETVAL = sv_setref_pv(newSV(0), "Zonemaster::LDNS::RRList", list);
    OUTPUT:
        RETVAL

char *
packet_string(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
        RETVAL = ldns_pkt2str(obj);
        if(RETVAL == NULL || RETVAL[0] == '\0')
        {
            croak("Failed to convert packet to string");
        }
        else
        {
            strip_newline(RETVAL);
        }
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

SV *
packet_wireformat(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
    {
        size_t sz;
        uint8_t *buf;
        ldns_status status;

        status = ldns_pkt2wire(&buf, obj, &sz);
        if(status != LDNS_STATUS_OK)
        {
            croak("Failed to produce wire format: %s",  ldns_get_errorstr_by_id(status));
        }
        else
        {
            RETVAL = newSVpvn((const char *)buf,sz);
            free(buf);
        }
    }
    OUTPUT:
        RETVAL

SV *
packet_new_from_wireformat(class,buf)
    char *class;
    SV *buf;
    CODE:
    {
        Zonemaster__LDNS__Packet pkt;
        ldns_status status;

        SvGETMAGIC(buf);
        status = ldns_wire2pkt(&pkt, (const uint8_t *)SvPV_nolen(buf), SvCUR(buf));
        if(status != LDNS_STATUS_OK)
        {
            croak("Failed to parse wire format: %s",  ldns_get_errorstr_by_id(status));
        }
        else
        {
            RETVAL = newSV(0);
            sv_setref_pv(RETVAL, class, pkt);
        }
    }
    OUTPUT:
        RETVAL

#
# Function: set_edns_present
# --------------------------
# Set edns_present property of Packet object
#
SV *
packet_set_edns_present(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
        obj->_edns_present = true;

#
# Function: unset_edns_present
# ----------------------------
# Unset edns_present property of Packet object
#
SV *
packet_unset_edns_present(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
        obj->_edns_present = false;

U16
packet_edns_size(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if(items>=2)
        {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_edns_udp_size(obj, (U16)SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_edns_udp_size(obj);
    OUTPUT:
        RETVAL

U8
packet_edns_rcode(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if(items>=2)
        {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_edns_extended_rcode(obj, (U8)SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_edns_extended_rcode(obj);
    OUTPUT:
        RETVAL

U16
packet_edns_z(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if(items>=2)
        {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_edns_z(obj, (U16)SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_edns_z(obj);
    OUTPUT:
        RETVAL 

U8
packet_edns_version(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        if(items>=2)
        {
            SvGETMAGIC(ST(1));
            ldns_pkt_set_edns_version(obj, (U8)SvIV(ST(1)));
        }
        RETVAL = ldns_pkt_edns_version(obj);
    OUTPUT:
        RETVAL

#
# Function: edns_data
# -------------------
# Get/set EDNS data
# 
# This function acts on the OPT RDATA field of a packet. An OPT RDATA consists of at least one triplet
# {OPTION-CODE, OPTION-LENGTH, OPTION-DATA}.
# When given a parameter, this function will set and return the field, although with the limitation described below.
# Otherwise, it will get and return the field (if any).
#
# Beware, when setting OPT RDATA, this code can only take a unique U32 parameter
# which means it is not a full implementation of EDNS data but it is enough for our
# current purpose. It can only deal with option codes with OPTION-LENGTH=0
# (see 6.1.2 section of RFC 6891) which means OPTION-DATA is always empty.
#
# returns: a bytes string (or undef if no OPT RDATA is found)
#
SV *
packet_edns_data(obj,...)
    Zonemaster::LDNS::Packet obj;
    CODE:
        ldns_rdf* opt;
        if(items>=2)
        {
            SvGETMAGIC(ST(1));
            opt = ldns_native2rdf_int32(LDNS_RDF_TYPE_INT32, (U32)SvIV(ST(1)));
            if(opt == NULL)
            {
                croak("Failed to set OPT RDATA");
            }
            ldns_pkt_set_edns_data(obj, opt);
        }
        else {
            opt = ldns_pkt_edns_data(obj);
            if(opt == NULL)
            {
                XSRETURN_UNDEF;
            }
        }
        RETVAL = newSVpvn((char*)(opt->_data), opt->_size);
    OUTPUT:
        RETVAL

bool
packet_needs_edns(obj)
    Zonemaster::LDNS::Packet obj;
    ALIAS:
        Zonemaster::LDNS::Packet::has_edns = 1
    CODE:
        RETVAL = ldns_pkt_edns(obj);
    OUTPUT:
        RETVAL

#
# Function: nsid
# --------------
# Set the EDNS option NSID in the packet
#
void
packet_nsid(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
    {
#ifdef NSID_SUPPORT
        ldns_edns_option_list* edns_list;
        ldns_edns_option*      edns_opt;

        edns_list = ldns_pkt_edns_get_option_list(obj);

        if ( !edns_list )
            edns_list = ldns_edns_option_list_new();

        edns_opt  = ldns_edns_new_from_data(LDNS_EDNS_NSID, 0, NULL);
        if ( edns_list == NULL || edns_opt == NULL )
            croak("Could not allocate EDNS option");
        if ( ! ldns_edns_option_list_push(edns_list, edns_opt) )
            croak("Could not attach EDNS option NSID");
        ldns_pkt_set_edns_option_list(obj, edns_list);
#else
        croak("NSID not supported");
#endif
    }

#
# Function: get_nsid
# ------------------
# Get the EDNS option NSID if any from the packet
#
# returns: a bytes string (or undef if no NSID is found)
#
SV *
packet_get_nsid(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
    {
#ifdef NSID_SUPPORT
        ldns_edns_option_list* edns_list;
        ldns_edns_option* edns_opt;
        size_t i,count;

        edns_list = ldns_pkt_edns_get_option_list(obj);
        if ( edns_list == NULL )
            XSRETURN_UNDEF;

        RETVAL = NULL;
        count = ldns_edns_option_list_get_count(edns_list);
        for ( i=0; i<count; i++ )
        {
            edns_opt = ldns_edns_option_list_get_option(edns_list, i);
            if ( edns_opt == NULL )
                continue;
            if ( ldns_edns_get_code(edns_opt) == LDNS_EDNS_NSID )
                RETVAL = newSVpv(ldns_edns_get_data(edns_opt), ldns_edns_get_size(edns_opt));
        }
        if ( RETVAL == NULL )
            XSRETURN_UNDEF;
#else
        croak("NSID not supported");
#endif
    }
    OUTPUT:
        RETVAL

SV *
packet_type(obj)
    Zonemaster::LDNS::Packet obj;
    CODE:
        ldns_pkt_type type = ldns_pkt_reply_type(obj);
        switch (type){
            case LDNS_PACKET_QUESTION:
                RETVAL = newSVpvs_share("question");
                break;

            case LDNS_PACKET_REFERRAL:
                RETVAL = newSVpvs_share("referral");
                break;

            case LDNS_PACKET_ANSWER:
                RETVAL = newSVpvs_share("answer");
                break;

            case LDNS_PACKET_NXDOMAIN:
                RETVAL = newSVpvs_share("nxdomain");
                break;

            case LDNS_PACKET_NODATA:
                RETVAL = newSVpvs_share("nodata");
                break;

            case LDNS_PACKET_UNKNOWN:
                RETVAL = newSVpvs_share("unknown");
                break;

            default:
                croak("Packet type is not even unknown");
        }
    OUTPUT:
        RETVAL

void
packet_DESTROY(sv)
    SV *sv;
    CODE:
        SvGETMAGIC(sv);
        ldns_pkt *obj = INT2PTR(ldns_pkt *, SvIV((SV *)SvRV(sv)));
        ldns_pkt_free(obj);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RRList           PREFIX=rrlist_

SV *
rrlist_new(objclass, ...)
    char* objclass;
    CODE:
    {
        AV *rrs_in = NULL;
        ldns_rr_list *rrs = ldns_rr_list_new();

        /* Take RRs out of the array and stick them in a list */
        if (items > 1) {
            SSize_t i;
            rrs_in = (AV *) SvRV(ST(1));

            for(i = 0; i <= av_len(rrs_in); ++i)
            {
                ldns_rr *rr;
                SV **rrsv = av_fetch(rrs_in,i,1);
                if (rrsv != NULL && sv_isobject(*rrsv) && sv_derived_from(*rrsv, "Zonemaster::LDNS::RR")) {
                    SvGETMAGIC(*rrsv);
                    IV tmp = SvIV((SV*)SvRV(*rrsv));
                    rr = INT2PTR(ldns_rr *,tmp);
                    if(rr != NULL)
                    {
                        ldns_rr_list_push_rr(rrs, ldns_rr_clone(rr));
                    }
                }
                else {
                    croak("Incorrect type in list");
                }
            }
        }

        RETVAL = newSV(0);
        sv_setref_pv(RETVAL, objclass, rrs);
    }
    OUTPUT:
        RETVAL

size_t
rrlist_count(obj)
    Zonemaster::LDNS::RRList obj;
    CODE:
        RETVAL = ldns_rr_list_rr_count(obj);
    OUTPUT:
        RETVAL

SV *
rrlist_get(obj,pos)
    Zonemaster::LDNS::RRList obj;
    size_t pos;
    CODE:
        size_t n;
        n = ldns_rr_list_rr_count(obj);

        if(n==0 || pos > n-1)
        {
            XSRETURN_UNDEF;
        }

        RETVAL = rr2sv(ldns_rr_clone(ldns_rr_list_rr(obj, pos)));
    OUTPUT:
        RETVAL

SV *
rrlist_pop(obj)
    Zonemaster::LDNS::RRList obj;
    CODE:
        ldns_rr *rr = ldns_rr_list_pop_rr(obj);
        if(rr==NULL)
        {
            RETVAL = &PL_sv_no;
        }
        else
        {
            RETVAL = rr2sv(rr);
        }
    OUTPUT:
        RETVAL

bool
rrlist_push(obj,rr)
    Zonemaster::LDNS::RRList obj;
    Zonemaster::LDNS::RR rr;
    CODE:
        RETVAL = ldns_rr_list_push_rr(obj,ldns_rr_clone(rr));
    OUTPUT:
        RETVAL

bool
rrlist_is_rrset(obj)
    Zonemaster::LDNS::RRList obj;
    CODE:
        RETVAL = ldns_is_rrset(obj);
    OUTPUT:
        RETVAL

I32
rrlist_compare(obj1,obj2)
    Zonemaster::LDNS::RRList obj1;
    Zonemaster::LDNS::RRList obj2;
    CODE:
        ldns_rr_list *rrl1 = ldns_rr_list_clone(obj1);
        ldns_rr_list *rrl2 = ldns_rr_list_clone(obj2);

        ldns_rr_list_sort(rrl1);
        ldns_rr_list_sort(rrl2);

        RETVAL = ldns_rr_list_compare(rrl1, rrl2);

        ldns_rr_list_deep_free(rrl1);
        ldns_rr_list_deep_free(rrl2);
    OUTPUT:
        RETVAL

char *
rrlist_string(obj)
    Zonemaster::LDNS::RRList obj;
    CODE:
        RETVAL = ldns_rr_list2str(obj);
        if(RETVAL == NULL)
        {
            croak("Failed to convert RRList to string");
        }
        else
        {
            strip_newline(RETVAL);
        }
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

void
rrlist_DESTROY(obj)
    Zonemaster::LDNS::RRList obj;
    CODE:
        ldns_rr_list_deep_free(obj);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR           PREFIX=rr_

SV *
rr_new_from_string(class,str)
    char *class;
    char *str;
    PPCODE:
        ldns_status s;
        ldns_rr *rr;
        char rrclass[40];
        char *rrtype;
        SV* rr_sv;

        s = ldns_rr_new_frm_str(&rr, str, 0, NULL, NULL);
        if(s != LDNS_STATUS_OK)
        {
            croak("Failed to build RR: %s", ldns_get_errorstr_by_id(s));
        }
        rrtype = ldns_rr_type2str(ldns_rr_get_type(rr));
        snprintf(rrclass, 39, "Zonemaster::LDNS::RR::%s", rrtype);
        free(rrtype);
        rr_sv = sv_newmortal();
        sv_setref_pv(rr_sv, rrclass, rr);
        PUSHs(rr_sv);

char *
rr_owner(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rdf2str(ldns_rr_owner(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

U32
rr_ttl(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_ttl(obj);
    OUTPUT:
        RETVAL

char *
rr_type(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_type2str(ldns_rr_get_type(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

char *
rr_class(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_class2str(ldns_rr_get_class(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

char *
rr_string(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr2str(obj);
        if(RETVAL == NULL || RETVAL[0] == '\0')
        {
            croak("Failed to convert RR to string");
        }
        else
        {
            strip_newline(RETVAL);
        }
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

I32
rr_compare(obj1,obj2)
    Zonemaster::LDNS::RR obj1;
    Zonemaster::LDNS::RR obj2;
    CODE:
        RETVAL = ldns_rr_compare(obj1,obj2);
    OUTPUT:
        RETVAL

size_t
rr_rd_count(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        RETVAL = ldns_rr_rd_count(obj);
    OUTPUT:
        RETVAL

SV *
rr_rdf(obj,n)
    Zonemaster::LDNS::RR obj;
    size_t n;
    CODE:
        ldns_rdf *rdf = ldns_rr_rdf(obj,n);
        if(rdf==NULL)
        {
            croak("Trying to fetch nonexistent RDATA at position %lu", n);
        }
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    OUTPUT:
        RETVAL

bool
rr_check_rd_count(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        ldns_rr_type rr_type = ldns_rr_get_type(obj);
        const ldns_rr_descriptor *desc = ldns_rr_descript(rr_type);
        size_t rd_min = ldns_rr_descriptor_minimum(desc);
        size_t rd_max = ldns_rr_descriptor_maximum(desc);
        size_t rd_count = ldns_rr_rd_count(obj);

        // Workaround for when the last field is variable length with length
        // zero, and ldns represents this by omitting the last field from
        // the field list.
        if (rd_min > 0 && rd_min == rd_max)
        {
            switch (ldns_rr_descriptor_field_type(desc,rd_min-1))
            {
            // This list is taken from ldns_wire2rdf()
            case LDNS_RDF_TYPE_APL:
            case LDNS_RDF_TYPE_B64:
            case LDNS_RDF_TYPE_HEX:
            case LDNS_RDF_TYPE_NSEC:
            case LDNS_RDF_TYPE_UNKNOWN:
            case LDNS_RDF_TYPE_SERVICE:
            case LDNS_RDF_TYPE_LOC:
            case LDNS_RDF_TYPE_WKS:
            case LDNS_RDF_TYPE_NSAP:
            case LDNS_RDF_TYPE_ATMA:
            case LDNS_RDF_TYPE_IPSECKEY:
            case LDNS_RDF_TYPE_LONG_STR:
            case LDNS_RDF_TYPE_AMTRELAY:
            case LDNS_RDF_TYPE_NONE:
                rd_min -= 1;
            }
        }

        RETVAL = rd_min <= rd_count && rd_count <= rd_max;
    OUTPUT:
        RETVAL

void
rr_DESTROY(obj)
    Zonemaster::LDNS::RR obj;
    CODE:
        ldns_rr_free(obj);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::NS           PREFIX=rr_ns_

char *
rr_ns_nsdname(obj)
    Zonemaster::LDNS::RR::NS obj;
    CODE:
        RETVAL = ldns_rdf2str(ldns_rr_rdf(obj, 0));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::MX           PREFIX=rr_mx_

U16
rr_mx_preference(obj)
    Zonemaster::LDNS::RR::MX obj;
    CODE:
        RETVAL = D_U16(obj, 0);
    OUTPUT:
        RETVAL

char *
rr_mx_exchange(obj)
    Zonemaster::LDNS::RR::MX obj;
    CODE:
        RETVAL = D_STRING(obj, 1);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::A                PREFIX=rr_a_

char *
rr_a_address(obj)
    Zonemaster::LDNS::RR::A obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::AAAA             PREFIX=rr_aaaa_

char *
rr_aaaa_address(obj)
    Zonemaster::LDNS::RR::AAAA obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::SOA              PREFIX=rr_soa_

char *
rr_soa_mname(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

char *
rr_soa_rname(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_STRING(obj,1);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

U32
rr_soa_serial(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,2);
    OUTPUT:
        RETVAL

U32
rr_soa_refresh(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,3);
    OUTPUT:
        RETVAL

U32
rr_soa_retry(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,4);
    OUTPUT:
        RETVAL

U32
rr_soa_expire(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,5);
    OUTPUT:
        RETVAL

U32
rr_soa_minimum(obj)
    Zonemaster::LDNS::RR::SOA obj;
    CODE:
        RETVAL = D_U32(obj,6);
    OUTPUT:
        RETVAL


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::DS               PREFIX=rr_ds_

U16
rr_ds_keytag(obj)
    Zonemaster::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_U16(obj,0);
    OUTPUT:
        RETVAL

U8
rr_ds_algorithm(obj)
    Zonemaster::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_ds_digtype(obj)
    Zonemaster::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_ds_digest(obj)
    Zonemaster::LDNS::RR::DS obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,3);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL

char *
rr_ds_hexdigest(obj)
    Zonemaster::LDNS::RR::DS obj;
    CODE:
        RETVAL = D_STRING(obj,3);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);


bool
rr_ds_verify(obj,other)
    Zonemaster::LDNS::RR::DS obj;
    Zonemaster::LDNS::RR other;
    CODE:
        RETVAL = ldns_rr_compare_ds(obj, other);
    OUTPUT:
        RETVAL

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::DNSKEY           PREFIX=rr_dnskey_

U16
rr_dnskey_flags(obj)
    Zonemaster::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_U16(obj,0);
    OUTPUT:
        RETVAL

U8
rr_dnskey_protocol(obj)
    Zonemaster::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_dnskey_algorithm(obj)
    Zonemaster::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_dnskey_keydata(obj)
    Zonemaster::LDNS::RR::DNSKEY obj;
    CODE:
    {
        if (ldns_rr_rd_count(obj)>3)
        {
            ldns_rdf *rdf = ldns_rr_rdf(obj,3);
            RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
        }
        else
        {
            RETVAL = newSVpvn("",0);
        }
    }
    OUTPUT:
        RETVAL

char *
rr_dnskey_hexkeydata(obj)
    Zonemaster::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = D_STRING(obj,3);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

U16
rr_dnskey_keytag(obj)
    Zonemaster::LDNS::RR::DNSKEY obj;
    CODE:
        RETVAL = ldns_calc_keytag(obj);
    OUTPUT:
        RETVAL

Zonemaster::LDNS::RR::DS
rr_dnskey_ds(obj, hash)
    Zonemaster::LDNS::RR::DNSKEY obj;
    const char *hash;
    CODE:
    {
        char lbuf[21];
        char *p;
        ldns_hash htype;

        p = lbuf;
        strncpy(lbuf, hash, 20);
        for(; *p; p++) *p = tolower(*p);

        if(strEQ(lbuf,"sha1"))
        {
            htype = LDNS_SHA1;
        }
        else if(strEQ(lbuf, "sha256"))
        {
            htype = LDNS_SHA256;
        }
        else if(strEQ(lbuf, "sha384"))
        {
            htype = LDNS_SHA384;
        }
        else if(strEQ(lbuf,"gost"))
        {
            htype = LDNS_HASH_GOST;
        }
        else
        {
            croak("Unknown hash type: %s", hash);
        }

        RETVAL = ldns_key_rr2ds(obj,htype);
    }
    OUTPUT:
        RETVAL

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::RRSIG            PREFIX=rr_rrsig_

char *
rr_rrsig_typecovered(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

U8
rr_rrsig_algorithm(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_rrsig_labels(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

U32
rr_rrsig_origttl(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U32(obj,3);
    OUTPUT:
        RETVAL

U32
rr_rrsig_expiration(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U32(obj,4);
    OUTPUT:
        RETVAL

U32
rr_rrsig_inception(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U32(obj,5);
    OUTPUT:
        RETVAL

U16
rr_rrsig_keytag(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_U16(obj,6);
    OUTPUT:
        RETVAL

char *
rr_rrsig_signer(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
        RETVAL = D_STRING(obj,7);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

SV *
rr_rrsig_signature(obj)
    Zonemaster::LDNS::RR::RRSIG obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,8);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL

bool
rr_rrsig_verify_time(obj,rrset_in,keys_in, when, msg)
    Zonemaster::LDNS::RR::RRSIG obj;
    AV *rrset_in;
    AV *keys_in;
    time_t when;
    const char *msg;
    CODE:
    {
        size_t i;
        ldns_status s;
        ldns_rr_list *rrset = ldns_rr_list_new();
        ldns_rr_list *keys  = ldns_rr_list_new();
        ldns_rr_list *sig   = ldns_rr_list_new();
        ldns_rr_list *good  = ldns_rr_list_new();

        if(av_len(rrset_in)==-1)
        {
           croak("RRset is empty");
        }

        if(av_len(keys_in)==-1)
        {
           croak("Key list is empty");
        }

        /* Make a list with only the RRSIG */
        ldns_rr_list_push_rr(sig, obj);

        /* Take RRs out of the array and stick in a list */
        for(i = 0; i <= av_len(rrset_in); ++i)
        {
            ldns_rr *rr;
            SV **rrsv = av_fetch(rrset_in,i,1);
            if (rrsv != NULL) {
                SvGETMAGIC(*rrsv);
                IV tmp = SvIV((SV*)SvRV(*rrsv));
                rr = INT2PTR(ldns_rr *,tmp);
                if(rr != NULL)
                {
                    ldns_rr_list_push_rr(rrset, rr);
                }
            }
        }

        /* Again, for the keys */
        for(i = 0; i <= av_len(keys_in); ++i)
        {
            ldns_rr *rr;
            SV **rrsv = av_fetch(keys_in,i,1);
            IV tmp = SvIV((SV*)SvRV(*rrsv));
            rr = INT2PTR(ldns_rr *,tmp);
            if(rr != NULL)
            {
                ldns_rr_list_push_rr(keys, rr);
            }
        }

        /* And verify using the lists */
        s = ldns_verify_time(rrset, sig, keys, when, good);

        RETVAL = (s == LDNS_STATUS_OK);
        msg = ldns_get_errorstr_by_id(s);

        ldns_rr_list_free(rrset);
        ldns_rr_list_free(keys);
        ldns_rr_list_free(sig);
        ldns_rr_list_free(good);
    }
    OUTPUT:
        RETVAL
        msg

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::NSEC             PREFIX=rr_nsec_

char *
rr_nsec_next(obj)
    Zonemaster::LDNS::RR::NSEC obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL

char *
rr_nsec_typelist(obj)
    Zonemaster::LDNS::RR::NSEC obj;
    CODE:
        RETVAL = D_STRING(obj,1);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

SV *
rr_nsec_typehref(obj)
    Zonemaster::LDNS::RR::NSEC obj;
    CODE:
    {
        char *typestring = D_STRING(obj,1);
        char *copy = typestring;
        size_t pos;
        HV *res = newHV();

        pos = 0;
        while(typestring[pos] != '\0')
        {
            pos++;
            if(typestring[pos] == ' ')
            {
                typestring[pos] = '\0';
                if(hv_store(res,typestring,pos,newSViv(1),0)==NULL)
                {
                    croak("Failed to store to hash");
                }
                typestring += pos+1;
                pos = 0;
            }
        }
        RETVAL = newRV_noinc((SV *)res);
        free(copy);
    }
    OUTPUT:
        RETVAL

bool
rr_nsec_covers(obj,name)
    Zonemaster::LDNS::RR::NSEC obj;
    const char *name;
    CODE:
        ldns_rdf *dname = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, name);
        ldns_dname2canonical(dname);
        ldns_rr2canonical(obj);
        RETVAL = ldns_nsec_covers_name(obj,dname);
        ldns_rdf_deep_free(dname);
    OUTPUT:
        RETVAL

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::NSEC3            PREFIX=rr_nsec3_

U8
rr_nsec3_algorithm(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_algorithm(obj);
    OUTPUT:
        RETVAL

U8
rr_nsec3_flags(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_flags(obj);
    OUTPUT:
        RETVAL

bool
rr_nsec3_optout(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_optout(obj);
    OUTPUT:
        RETVAL

U16
rr_nsec3_iterations(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_nsec3_iterations(obj);
    OUTPUT:
        RETVAL

SV *
rr_nsec3_salt(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
    {
        uint8_t *salt = ldns_nsec3_salt_data(obj);
        if (salt) {
            RETVAL = newSVpvn((char *)salt, ldns_nsec3_salt_length(obj));
            LDNS_FREE(salt);
        }
    }
    OUTPUT:
        RETVAL

SV *
rr_nsec3_next_owner(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    INIT:
        ldns_rdf *buf = NULL;
        size_t size;
    CODE:
        buf = ldns_nsec3_next_owner(obj);
        if (!buf) {
            XSRETURN_UNDEF;
        }
        size = ldns_rdf_size(buf);
        if (size < 1) {
            XSRETURN_UNDEF;
        }

        /* ldns_rdf_data(buf) points to the hashed next owner name preceded by a
         * length byte, which we don't want. */
        RETVAL = newSVpvn((char *)(ldns_rdf_data(buf) + 1), size - 1);
    OUTPUT:
        RETVAL

char *
rr_nsec3_typelist(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
        RETVAL = ldns_rdf2str(ldns_nsec3_bitmap(obj));
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

SV *
rr_nsec3_typehref(obj)
    Zonemaster::LDNS::RR::NSEC3 obj;
    CODE:
    {
        char *typestring = ldns_rdf2str(ldns_nsec3_bitmap(obj));
        char *copy = typestring;
        size_t pos;
        HV *res = newHV();

        pos = 0;
        while(typestring[pos] != '\0')
        {
            pos++;
            if(typestring[pos] == ' ')
            {
                typestring[pos] = '\0';
                if(hv_store(res,typestring,pos,newSViv(1),0)==NULL)
                {
                    croak("Failed to store to hash");
                }
                typestring += pos+1;
                pos = 0;
            }
        }
        RETVAL = newRV_noinc((SV *)res);
        free(copy);
    }
    OUTPUT:
        RETVAL

bool
rr_nsec3_covers(obj,name)
    Zonemaster::LDNS::RR::NSEC3 obj;
    const char *name;
    INIT:
        /* Sanity test on owner name */
        if (ldns_dname_label_count(ldns_rr_owner(obj)) == 0)
            XSRETURN_UNDEF;

        /* Sanity test on hashed next owner field */
        ldns_rdf *next_owner = ldns_nsec3_next_owner(obj);
        if (!next_owner || ldns_rdf_size(next_owner) <= 1)
            XSRETURN_UNDEF;
    CODE:
    {
        ldns_rr *clone;
        ldns_rdf *dname;
        ldns_rdf *hashed;
        ldns_rdf *chopped;

        dname = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, name);
        if (!dname)
            XSRETURN_UNDEF;

        ldns_dname2canonical(dname);

        chopped = ldns_dname_left_chop(dname);
        if (!chopped) {
            ldns_rdf_deep_free(dname);
            XSRETURN_UNDEF;
        }

        clone = ldns_rr_clone(obj);
        ldns_rr2canonical(clone);
        hashed = ldns_nsec3_hash_name_frm_nsec3(clone, dname);

        ldns_rdf_deep_free(dname);

        ldns_dname_cat(hashed,chopped);

        RETVAL = ldns_nsec_covers_name(clone,hashed);

        ldns_rdf_deep_free(hashed);
        ldns_rdf_deep_free(chopped);
        ldns_rr_free(clone);
    }
    OUTPUT:
        RETVAL

SV *
rr_nsec3_hash_name(obj,name)
    Zonemaster::LDNS::RR::NSEC3 obj;
    const char *name;
    INIT:
        /* Sanity test on owner name */
        if (ldns_dname_label_count(ldns_rr_owner(obj)) == 0)
            XSRETURN_UNDEF;
    CODE:
    {
        ldns_rdf *hashed;
        ldns_rdf *dname;

        dname = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, name);
        if (!dname)
            XSRETURN_UNDEF;

        hashed = ldns_nsec3_hash_name_frm_nsec3(obj, dname);

        ldns_rdf_deep_free(dname);

        if (!hashed || ldns_rdf_size(hashed) < 1 ) {
            XSRETURN_UNDEF;
        }

        char *hash_str = ldns_rdf2str(hashed);
        RETVAL = newSVpv(hash_str, ldns_rdf_size(hashed) - 2);
        free(hash_str);
    }
    OUTPUT:
        RETVAL

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::NSEC3PARAM       PREFIX=rr_nsec3param_

U8
rr_nsec3param_algorithm(obj)
    Zonemaster::LDNS::RR::NSEC3PARAM obj;
    CODE:
        RETVAL = D_U8(obj,0);
    OUTPUT:
        RETVAL

U8
rr_nsec3param_flags(obj)
    Zonemaster::LDNS::RR::NSEC3PARAM obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL


U16
rr_nsec3param_iterations(obj)
    Zonemaster::LDNS::RR::NSEC3PARAM obj;
    CODE:
        RETVAL = D_U16(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_nsec3param_salt(obj)
    Zonemaster::LDNS::RR::NSEC3PARAM obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj, 3);
        size_t size = ldns_rdf_size(rdf);
        if (size > 0)
        {
            RETVAL = newSVpvn((char *)(ldns_rdf_data(rdf) + 1), size - 1);
        }
    }
    OUTPUT:
        RETVAL

SV *
rr_nsec3param_hash_name(obj,name)
    Zonemaster::LDNS::RR::NSEC3PARAM obj;
    const char *name;
    INIT:
        /* Sanity test on owner name */
        if (ldns_dname_label_count(ldns_rr_owner(obj)) == 0)
            XSRETURN_UNDEF;
    CODE:
    {
        ldns_rdf *hashed;
        ldns_rdf *dname;

        dname = ldns_rdf_new_frm_str(LDNS_RDF_TYPE_DNAME, name);
        if (!dname)
            XSRETURN_UNDEF;

        hashed = ldns_nsec3_hash_name_frm_nsec3(obj, dname);

        ldns_rdf_deep_free(dname);

        if (!hashed || ldns_rdf_size(hashed) < 1 ) {
            XSRETURN_UNDEF;
        }

        char *hash_str = ldns_rdf2str(hashed);
        RETVAL = newSVpv(hash_str, ldns_rdf_size(hashed) - 2);
        free(hash_str);
    }
    OUTPUT:
        RETVAL

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::PTR              PREFIX=rr_ptr_

char *
rr_ptr_ptrdname(obj)
    Zonemaster::LDNS::RR::PTR obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);


MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::CNAME            PREFIX=rr_cname_

char *
rr_cname_cname(obj)
    Zonemaster::LDNS::RR::CNAME obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::DNAME            PREFIX=rr_dname_

char *
rr_dname_dname(obj)
    Zonemaster::LDNS::RR::DNAME obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::KEY           PREFIX=rr_key_

U16
rr_key_flags(obj)
    Zonemaster::LDNS::RR::KEY obj;
    CODE:
        RETVAL = D_U16(obj,0);
    OUTPUT:
        RETVAL

U8
rr_key_protocol(obj)
    Zonemaster::LDNS::RR::KEY obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_key_algorithm(obj)
    Zonemaster::LDNS::RR::KEY obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

SV *
rr_key_keydata(obj)
    Zonemaster::LDNS::RR::KEY obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,3);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL

MODULE = Zonemaster::LDNS        PACKAGE = Zonemaster::LDNS::RR::SIG            PREFIX=rr_sig_

char *
rr_sig_typecovered(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_STRING(obj,0);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

U8
rr_sig_algorithm(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_U8(obj,1);
    OUTPUT:
        RETVAL

U8
rr_sig_labels(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_U8(obj,2);
    OUTPUT:
        RETVAL

U32
rr_sig_origttl(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_U32(obj,3);
    OUTPUT:
        RETVAL

U32
rr_sig_expiration(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_U32(obj,4);
    OUTPUT:
        RETVAL

U32
rr_sig_inception(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_U32(obj,5);
    OUTPUT:
        RETVAL

U16
rr_sig_keytag(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_U16(obj,6);
    OUTPUT:
        RETVAL

char *
rr_sig_signer(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
        RETVAL = D_STRING(obj,7);
    OUTPUT:
        RETVAL
    CLEANUP:
        free(RETVAL);

SV *
rr_sig_signature(obj)
    Zonemaster::LDNS::RR::SIG obj;
    CODE:
    {
        ldns_rdf *rdf = ldns_rr_rdf(obj,8);
        RETVAL = newSVpvn((char*)ldns_rdf_data(rdf), ldns_rdf_size(rdf));
    }
    OUTPUT:
        RETVAL
