#include "EXTERN.h"

#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define XML_DEBUG 0
#define XML_DEVEL 0

#include "xmlfast.h"

#if XML_DEBUG
#define WHERESTR    " at %s line %d.\n"
#define WHEREARG    __FILE__, __LINE__
#define debug(...)   do{ fprintf(stderr, __VA_ARGS__); fprintf(stderr, WHERESTR, WHEREARG); } while(0)
#else
#define debug(...)
#endif


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>

#ifndef ptr_t
typedef void * ptr_t;
#endif

#ifndef PERL_ARGS_ASSERT_SV_RECODE_TO_UTF8
#define PERL_ARGS_ASSERT_SV_RECODE_TO_UTF8
#endif

typedef struct {
	char *name;
	unsigned int len;
	char *fullname;
	unsigned int fulllen;
} xml_node;

/*
commit 30866c9f74d890c45e8da27ea855468a314a59cf
xmlbare 1785/s      --    -19%
xmlfast 2209/s     24%      --

*/

#define UTF8_BYTES   1
#define UTF8_UPGRADE 2
#define UTF8_DECODE  3
#define UTF8_EDECODE 4

#define EMIT_WARNS   0x0001
#define TAG_MATCH    0x0002

#define MODE_ORDER   0x1000
#define MODE_TRIM    0x2000
#define MODE_ARRAYS  0x4000

typedef struct {
	// config
	unsigned int flags;
	unsigned int bytes;
	unsigned int utf8;
	SV  * attr;
	SV  * text;
	SV  * join;
	SV  * cdata;
	SV  * comm;
	HV  * array;

	// state
	char *encoding;
	SV   *encode;
	int depth;
	unsigned int chainsize;
	xml_node * chain;
	HV ** hchain;
	HV  * hcurrent; //just a pointer

	SV  * pi;
	SV  * attrname;
	SV  * textval;
	
	SV  * error;
	parser_state * state;
	
} parsestate;

typedef struct {
	// config
	unsigned int flags;
	unsigned int bytes;
	unsigned int utf8;
	
	char  * attr; STRLEN attl;
	char  * text;
	char  * join;
	char  * cdata;
	char  * comm;
	
	
	HV  * array;

	// state
	char *encoding;
	SV   *encode;
	unsigned int chainsize;
	xml_node * chain;
	HV ** hchain;
	HV  * hcurrent; //just a pointer

	SV  * pi;
	SV  * attrname;
	SV  * textval;
	
	SV  * error;
	
	/// new
	I32 depth;
	I32 ix;
	SV  * result;
	SV  * nested;
	
	
} compstate;

// hv_store to array if already have non-array value
#define hv_store_a( hv, key, sv ) \
	STMT_START { \
		SV **exists; \
		char *kv = SvPV_nolen(key); \
		int   kl = SvCUR(key); \
		if( exists = hv_fetch(hv, kv, kl, 0) ) { \
			if ( SvROK(*exists) && SvTYPE( SvRV(*exists) ) == SVt_PVAV) { \
				AV *av = (AV *) SvRV( *exists ); \
				av_push( av, sv ); \
			} \
			else { \
				AV *av   = newAV(); \
				if (SvROK(*exists)) { \
					SvREFCNT_inc(*exists); \
					av_push( av, *exists ); \
				} else { \
					SV *old  = newSV(0); \
					sv_copypv(old, *exists); \
					av_push( av, old ); \
				} \
				av_push( av, sv ); \
				(void) hv_store( hv, kv, kl, newRV_noinc( (SV *) av ), 0 ); \
			} \
		} else { \
			(void) hv_store(hv, kv, kl, sv, 0); \
		} \
	} STMT_END

// hv_store to array, create if not exists
#define hv_store_aa( hv, key, sv ) \
	STMT_START { \
		SV **exists; \
		char *kv = SvPV_nolen(key); \
		int   kl = SvCUR(key); \
		if( ( exists = hv_fetch(hv, kv, kl, 0) ) && SvROK(*exists) && (SvTYPE( SvRV(*exists) ) == SVt_PVAV) ) { \
			AV *av = (AV *) SvRV( *exists ); \
			av_push( av, sv ); \
		} \
		else { \
			AV *av   = newAV(); \
			av_push( av, sv ); \
			(void) hv_store( hv, kv, kl, newRV_noinc( (SV *) av ), 0 ); \
		} \
	} STMT_END

#define xml_sv_decode(ctx, sv) \
	STMT_START { \
		if (!ctx->bytes && !SvUTF8(sv)) {\
			if (ctx->utf8 == UTF8_UPGRADE) { \
				SvUTF8_on(sv); \
			} \
			else if (ctx->utf8 == UTF8_DECODE) { \
				sv_utf8_decode(sv); \
			} \
			else if (ctx->encode) { \
				(void) sv_recode_to_utf8(sv, ctx->encode); \
			} \
		}\
	} STMT_END

void on_bytes_charset_part(void * pctx, char * data, unsigned int length);
void on_bytes_charset(void * pctx, char * data, unsigned int length);
void on_tag_close(void * pctx, char * data, unsigned int length);

static inline void my_warn(parsestate *ctx, char * format, ...) {
	//TODO: free all
	if(!(ctx->flags & EMIT_WARNS)) return;
	va_list va;
	va_start(va,format);
	SV *text = sv_2mortal(newSVpvn("",0));
	sv_vcatpvf(text, format, &va);
	va_end(va);
	warn("%s",SvPV_nolen(text));
}

static inline void DESTROY (parsestate *ctx) {
	if(ctx->encode)   { SvREFCNT_dec(ctx->encode);   ctx->encode = 0;   }
	if(ctx->textval)  { SvREFCNT_dec(ctx->textval);  ctx->textval = 0;  }
	if(ctx->pi)       { SvREFCNT_dec(ctx->pi);       ctx->pi = 0;       }
	if(ctx->attrname) { SvREFCNT_dec(ctx->attrname); ctx->attrname = 0; }
	if(ctx->array)    { SvREFCNT_dec(ctx->array);   ctx->array = 0;    }
	if(ctx->depth > -1) {
		//fprintf(stderr,"DESTROY Free depth %d\n",ctx->depth);
		int currdepth = ctx->depth;
		while(ctx->depth > -1) {
			//fprintf(stderr,"Free depth %d\n",ctx->depth);
			on_tag_close(ctx,ctx->chain->name,ctx->chain->len);
			if (currdepth == ctx->depth) {
				my_warn(ctx,"Recursion during autoclose tags. depth=%d\n",ctx->depth);
				break;
			}
		}
	}
	if (ctx->hchain) { Safefree(ctx->hchain); ctx->hchain = 0; }
	if (ctx->chain)  { Safefree(ctx->chain); ctx->chain = 0; }
}

static inline void my_croak(parsestate *ctx, char * format, ...) {
	//TODO: free all
	DESTROY(ctx);
	va_list va;
	va_start(va,format);
	SV *text = sv_2mortal(newSVpvn("",0));
	sv_vcatpvf(text, format, &va);
	va_end(va);
	croak("%s",SvPV_nolen(text));
}

SV * find_encoding(char * encoding) {
	dSP;
	int count;
	//require_pv("Encode.pm");
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(encoding, 0)));
	PUTBACK;
	
	count = call_pv("Encode::find_encoding",G_SCALAR);
	
	SPAGAIN;
	if (SvTRUE(ERRSV)) {
		warn("Shit happens: %s\n", SvPV_nolen(ERRSV));
		(void) POPs;
	}
	
	if (count != 1)
		croak("find_encoding fault: bad number of returned values: %d",count);
	
	SV *encode = POPs;
	SvREFCNT_inc(encode);
	
	PUTBACK;
	
	FREETMPS;
	LEAVE;
	
	return encode;
}

SV * get_constant(char * name) {
	dSP;
	int count;
	//require_pv("Encode.pm");
	
	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	PUTBACK;
	
	count = call_pv(name,G_SCALAR);
	
	SPAGAIN;
	
	if (count != 1)
		croak("Bad number of returned values: %d",count);
	
	SV *value = POPs;
	sv_dump(value);
	SvREFCNT_inc(value);
	
	PUTBACK;
	
	FREETMPS;
	LEAVE;
	
	return value;
}

SV * sv_recode_from_utf8(pTHX_ SV *sv, SV *encoding) {
	dVAR;

	PERL_ARGS_ASSERT_SV_RECODE_TO_UTF8;
	if (SvPOK(sv) && SvUTF8(sv) && SvROK(encoding)) {
		SV *bytes;
		dSP;
		ENTER;
		SAVETMPS;
		save_re_context();
		PUSHMARK(sp);
		EXTEND(SP, 3);
		XPUSHs(encoding);
		XPUSHs(sv);
		XPUSHs(sv_2mortal(newSViv(4)));
		
		PUTBACK;
		call_method("encode", G_SCALAR);
		SPAGAIN;
		bytes = POPs;
		SvREFCNT_inc(bytes);
		PUTBACK;
		
		FREETMPS;
		LEAVE;
		return bytes;
	}
	return SvPOKp(sv) ? sv : NULL;
}

void on_comment(void * pctx, char * data,unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_comment");
#endif
	parsestate *ctx = pctx;
	SV         *sv  = newSVpvn(data, length);
	hv_store_a(ctx->hcurrent, ctx->comm, sv );
}

//TODO: Separate on_bytes/on_uchar for non-utf mode

void on_pi_attr(parsestate *ctx) {
	//warn("pi attr '%-.*s'", SvCUR(ctx->attrname), SvPVX(ctx->attrname));
			if (
				(SvCUR(ctx->attrname) == 8) &&
				(memcmp(SvPV_nolen(ctx->attrname), "encoding", 8) == 0 )
			) {
				ctx->encoding = (char *) SvPV_nolen(ctx->textval);
				//printf("Noticed encoding %s\n",ctx->encoding);
				if ( ( SvCUR(ctx->textval) == 5 ) && ( strncasecmp( ctx->encoding, "utf-8",5 ) == 0 ) ) {
					if (ctx->bytes) ctx->utf8 = UTF8_BYTES;
					//printf("Native utf-8 mode (%d)\n",ctx->utf8);
				} else {
					ctx->encode      = find_encoding(ctx->encoding);
					ctx->utf8        = 0;
					if(ctx->text) {
						//printf("Switch text mode to charset\n");
						ctx->state->cb.bytes        = on_bytes_charset;
						ctx->state->cb.bytespart    = on_bytes_charset_part;
					}
				}
			} else {
				//printf("PI %s, attr %s='%s'\n",SvPV_nolen(ctx->pi), SvPV_nolen(ctx->attrname),SvPV_nolen(ctx->textval) );
			}
			sv_2mortal(ctx->attrname);
			sv_2mortal(ctx->textval);
			ctx->attrname = ctx->textval = 0;
}

static inline SV * mkchr(UV chr) {
	char *end, utf[UTF8_MAXBYTES + 1];
	/*
	if (UTF8_IS_INVARIANT(chr)) {
		utf[0] = (char)chr;
		utf[1] = 0;
		return newSVpvn(utf,2);
	}
	*/
	SV *tmp;
	end = uvchr_to_utf8(utf, chr);
	*end = '\0';
	tmp = newSVpvn(utf, end-utf);
	SvUTF8_on(tmp);
	return tmp;
}

void on_uchar(void * pctx, wchar_t chr) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_text_part");
#endif
	parsestate *ctx = pctx;
	dTHX;
	if ( !( ctx->attrname || ctx->text ) ) return;
	
	if (!ctx->utf8 && ctx->bytes && !UTF8_IS_INVARIANT(chr) ) {
		if (!ctx->encode)
			my_croak(ctx,"Can't decode entities in non-utf8, bytes mode");
		SV *tmp = mkchr(chr);
		SV *bytes = sv_recode_from_utf8(aTHX_ tmp, ctx->encode);
		if (SvCUR(bytes) == 0) {
			my_warn(ctx,"Can't recode U+%04d entity into %s in bytes mode", chr, ctx->encoding);
			if (ctx->textval) {
				sv_catpvn(ctx->textval,"?",1);
			} else {
				ctx->textval = newSVpvn("?",1);
			}
			sv_2mortal(tmp);
			sv_2mortal(bytes);
			return;
		}
		//printf("Created char %s / %s / bytes = %s\n",utf, SvPV_nolen(tmp),SvPV_nolen(bytes));
		if (ctx->textval) {
			sv_catsv(ctx->textval,bytes);
			sv_2mortal(bytes);
		} else {
			ctx->textval = bytes;
		}
		return;
	} else {
		char *start, *end;
		STRLEN len = 0;
		if (ctx->textval) {
			len = SvCUR(ctx->textval);
		} else {
			ctx->textval = newSVpvn("",0);
		}
		sv_grow(ctx->textval, len + UTF8_MAXBYTES + 1 );
		start = end = SvEND(ctx->textval);
		end = uvchr_to_utf8(start, chr);*end = '\0';
		SvCUR_set(ctx->textval,len + end - start);
	}
}


void on_bytes_charset_part(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_bytes_charset_part");
#endif
	parsestate *ctx = pctx;
	if ( !( ctx->attrname || ctx->text ) ) return;
	if (!length) return;
	SV *tmp = newSVpvn(data, length);
	xml_sv_decode(ctx,tmp);
	if (ctx->textval) {
		sv_catsv(ctx->textval, tmp);
		sv_2mortal(tmp);
	} else {
		ctx->textval = tmp;
	}
}

void on_bytes_charset(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_bytes");
#endif
	parsestate *ctx = pctx;
	//if (!ctx->textval && !length) {
	//	my_warn(ctx,"Called on_bytes with empty text and empty body");
	//}
	if ( !( ctx->attrname || ctx->text ) ) return;
	SV *tmp = newSVpvn(data, length);
	xml_sv_decode(ctx,tmp);
	if (ctx->textval) {
		sv_catsv(ctx->textval, tmp);
		sv_2mortal(tmp);
	} else {
		ctx->textval = tmp;
	}
	if (ctx->attrname) {
		if (ctx->pi) {
			on_pi_attr(ctx);
		} else {
			hv_store_a(ctx->hcurrent, ctx->attrname, ctx->textval);
		}
		sv_2mortal(ctx->attrname);
		ctx->attrname = 0;
		ctx->textval = 0;
	}
	else {
		hv_store_a(ctx->hcurrent, ctx->text, ctx->textval);
	}
	ctx->textval = 0;
}

void on_bytes_part(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_bytes_part");
#endif
	parsestate *ctx = pctx;
	
	if ( !( ctx->attrname || ctx->text ) ) return;
	
	if (ctx->textval) {
		if (length > 0) { sv_catpvn(ctx->textval, data, length); }
	} else {
		ctx->textval = newSVpvn(data, length);
	}
}

void on_bytes(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_bytes");
#endif
	parsestate *ctx = pctx;
	//if (!ctx->textval && !length) {
	//	my_warn(ctx,"Called on_bytes with empty text and empty body");
	//}
	if ( !( ctx->attrname || ctx->text ) ) return;
	
	if (ctx->textval) {
		if (length > 0) { sv_catpvn(ctx->textval, data, length); }
	} else {
		ctx->textval = newSVpvn(data, length);
	}
	xml_sv_decode(ctx,ctx->textval);
	if (ctx->attrname) {
		if (ctx->pi) {
			on_pi_attr(ctx);
		} else {
			hv_store_a(ctx->hcurrent, ctx->attrname, ctx->textval);
		}
		sv_2mortal(ctx->attrname);
		ctx->attrname = 0;
		ctx->textval = 0;
	}
	else {
		//printf("text close, store %s\n",SvPV_nolen(ctx->textval));
		hv_store_a(ctx->hcurrent, ctx->text, ctx->textval);
	}
	ctx->textval = 0;
}


void on_cdata(void * pctx, char * data,unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_cdata");
#endif
	parsestate *ctx = pctx;
	SV *sv   = newSVpvn(data, length);
	xml_sv_decode(ctx,sv);
	hv_store_a(ctx->hcurrent, ctx->cdata, sv );
}

void on_pi_open(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_pi_open");
#endif
	parsestate *ctx = pctx;
	ctx->pi = newSVpvn(data,length);
}

void on_pi_close(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_pi_close");
#endif
	parsestate *ctx = pctx;
	sv_2mortal(ctx->pi);
	ctx->pi = 0;
}

void on_tag_open(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_tag_open");
#endif
	parsestate *ctx = pctx;
	if (ctx->textval) {
		xml_sv_decode(ctx,ctx->textval);
		hv_store_a(ctx->hcurrent, ctx->text, ctx->textval);
		ctx->textval = 0;
	}
	HV * hv = newHV();
	ctx->depth++;
	if (ctx->depth >= ctx->chainsize) {
		warn("XML depth too high. Consider increasing `_max_depth' to at more than %d to avoid reallocations",ctx->chainsize);
		ctx->chainsize *= 2;
		Renew( ctx->hchain, ctx->chainsize, HV* );
		Renew( ctx->chain, ctx->chainsize, xml_node);
	}
	ctx->chain[ctx->depth].len = length;
	ctx->chain[ctx->depth].name = data;
	if (ctx->flags & TAG_MATCH) {
		if (ctx->depth == 0) {
			ctx->chain[ctx->depth].fulllen = length + 1;
			Newx(ctx->chain[ctx->depth].fullname, ctx->chain[ctx->depth].fulllen + 1, char);
			ctx->chain[ctx->depth].fullname[0] = '/';
			memcpy(ctx->chain[ctx->depth].fullname+1,data,length);
			ctx->chain[ctx->depth].fullname[length+1] = 0;
			//printf("Fullame = %s\n",ctx->chain[ctx->depth].fullname);
		} else {
			ctx->chain[ctx->depth].fulllen = ctx->chain[ctx->depth - 1].fulllen + length + 1;
			Newx(ctx->chain[ctx->depth].fullname, ctx->chain[ctx->depth].fulllen + 1, char);
			memcpy(
				ctx->chain[ctx->depth].fullname,
				ctx->chain[ctx->depth - 1].fullname,
				ctx->chain[ctx->depth - 1].fulllen
			);
			ctx->chain[ctx->depth].fullname[ ctx->chain[ctx->depth - 1].fulllen ] = '/';
			memcpy(
				ctx->chain[ctx->depth].fullname + ctx->chain[ctx->depth - 1].fulllen + 1,
				data,
				length
			);
			ctx->chain[ctx->depth].fullname[ ctx->chain[ctx->depth].fulllen ] = 0;
			//printf("Fullame = %s\n",ctx->chain[ctx->depth].fullname);
		}
	}
	//printf("node name=%s, fullname=%s\n", SvPV_nolen(ctx->name[ ctx->depth ]),SvPV_nolen(fname));
	ctx->hchain[ ctx->depth ] = ctx->hcurrent;
	ctx->hcurrent = hv;
}

void on_tag_close(void * pctx, char * data, unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_tag_close");
#endif
	parsestate *ctx = pctx;
	SV *tag = sv_2mortal(newSVpvn(data,length));
	
	SV **text;
	I32 keys = HvKEYS(ctx->hcurrent);
	SV  *svtext = 0;
	if (ctx->textval) {
		xml_sv_decode(ctx,ctx->textval);
		hv_store_a(ctx->hcurrent, ctx->text, ctx->textval);
		ctx->textval = 0;
	}
	if (ctx->depth < 0) {
		my_warn(ctx,"Ignore unbalanced tag: closed upper than root");
		return;
	}
	if ( (ctx->chain[ctx->depth].len != length) || (memcmp( ctx->chain[ctx->depth].name, data, length) != 0) ) {
		int close, depth = ctx->depth;
		my_warn(ctx,"Unbalanced close tag <%s> depth=%d\n", SvPV_nolen(tag),depth);
		// checkdepth is used to avoid infinite loops on errors with auto_closing
		int checkdepth = depth + 10;
		while (depth > -1 && checkdepth-- > 0) {
			if ( (ctx->chain[depth].len == length) && (memcmp( ctx->chain[depth].name, data, length) == 0)) {
				for (close = ctx->depth; close >= depth; close--) {
					my_warn(ctx,"Force tag close <%.*s> at depth %u", ctx->chain[close].len, ctx->chain[close].name, close);
					on_tag_close(pctx, ctx->chain[close].name, (STRLEN)ctx->chain[close].len);
				}
				depth = -1;
				break;
			}
			depth--;
		}
		if (depth != -1) {
			my_warn(ctx,"Found no open tag for %s. Ignored", SvPV_nolen(tag));
		}
		return;
	}
	// Text joining
	if (ctx->text) {
		// we may have stored text node
		text = hv_fetch(ctx->hcurrent, SvPV_nolen(ctx->text), SvCUR(ctx->text), 0);
		if (text && SvOK(*text)) {
			if (SvROK(*text) && SvTYPE( SvRV(*text) ) == SVt_PVAV) {
				AV *av = (AV *) SvRV( *text );
				SV **val;
				I32 len = 0, avlen = av_len(av) + 1;
				if (ctx->join) {
					svtext = newSVpvn("",0);
					if (SvCUR(ctx->join)) {
						//printf("Join length = %d, avlen=%d\n",SvCUR(*join),avlen);
						for ( len = 0; len < avlen; len++ ) {
							if( ( val = av_fetch(av,len,0) ) && SvOK(*val) ) {
								//printf("Join %s with '%s'\n",SvPV_nolen(*val), SvPV_nolen(ctx->join));
								if(len > 0) { sv_catsv(svtext,ctx->join); }
								//printf("Join %s with '%s'\n",SvPV_nolen(*val), SvPV_nolen(ctx->join));
								sv_catsv(svtext,*val);
							}
						}
					} else {
						//printf("Optimized join loop\n");
						for ( len = 0; len < avlen; len++ ) {
							if( ( val = av_fetch(av,len,0) ) && SvOK(*val) ) {
								//printf("Join %s with ''\n",SvPV_nolen(*val));
								sv_catsv(svtext,*val);
							}
						}
					}
					//printf("Joined: to %s => '%s'\n",SvPV_nolen(ctx->text),SvPV_nolen(svtext));
					SvREFCNT_inc(svtext);
					(void) hv_store(ctx->hcurrent, SvPV_nolen(ctx->text), SvCUR(ctx->text), svtext, 0);
				}
				else
				// currently unreachable, since if we have single element, it is stored as SV value, not AV
				//if ( avlen == 1 ) {
				//	Perl_warn("# AVlen=1\n");
				//	/* works
				//	svtext = newSVpvn("",0);
				//	val = av_fetch(av,0,0);
				//	if (val && SvOK(*val)) {
				//		//svtext = *val;
				//		//SvREFCNT_inc(svtext);
				//		sv_catsv(svtext,*val);
				//	}
				//	*/
				//	val = av_fetch(av,0,0);
				//	if (val) {
				//		svtext = *val;
				//		SvREFCNT_inc(svtext);
				//		hv_store(ctx->hcurrent, SvPV_nolen(ctx->text), SvCUR(ctx->text), svtext, 0);
				//	}
				//}
				//else
				{
					// Remebmer for use if it is single
					//warn("# No join\n");
					svtext = newRV( (SV *) av );
				}
			} else {
				svtext = *text;
				SvREFCNT_inc(svtext);
			}
		}
	}
	//printf("svtext=(0x%lx) '%s'\n", svtext, svtext ? SvPV_nolen(svtext) : "");
	// Text joining
	if (ctx->depth > -1) {
		HV *hv = ctx->hcurrent;
		ctx->hcurrent = ctx->hchain[ ctx->depth ];
		ctx->hchain[ ctx->depth ] = (HV *)NULL;
		ctx->depth--;
		if (keys == 0) {
			//printf("Tag %s have no keys\n", SvPV_nolen(tag));
			SvREFCNT_dec(hv);
			SV *sv = newSVpvn("",0);
			if (ctx->flags & MODE_ARRAYS) {
				hv_store_aa(ctx->hcurrent, tag, sv);
			}
			else if (ctx->array && (hv_exists(ctx->array, data,length ) )) {
				hv_store_aa(ctx->hcurrent, tag, sv);
			}
			else {
				hv_store_a(ctx->hcurrent, tag, sv);
			}
		}
		else
		if (keys == 1 && svtext) {
			//SV *sx   = newSVpvn(data, length);sv_2mortal(sx);
			//printf("Hash in tag '%s' for destruction have refcnt = %d (%lx | %lx)\n",SvPV_nolen(sx),SvREFCNT(hv), hv, ctx->hcurrent);
			SvREFCNT_inc(svtext);
			SvREFCNT_dec(hv);
			//hv_store(ctx->hcurrent, data, length, svtext, 0);
			if (ctx->flags & MODE_ARRAYS) {
				//printf("Cast %s as array (all should be)\n",SvPV_nolen(tag));
				hv_store_aa(ctx->hcurrent, tag, svtext);
			}
			else if (ctx->array && (hv_exists(ctx->array, data,length ) )) {
				//printf("Cast %s as array\n",SvPV_nolen(tag));
				hv_store_aa(ctx->hcurrent, tag, svtext);
			}
			else {
				hv_store_a(ctx->hcurrent, tag, svtext);
			}
		} else {
			SV *sv = newRV_noinc( (SV *) hv );
			//printf("Store hash into RV '%lx'\n",sv);
			//hv_store(ctx->hcurrent, data, length, sv, 0);
			//printf("Check %s to be array\n",SvPV_nolen(tag));
			if (ctx->flags & MODE_ARRAYS) {
				//printf("Cast %s as array (all should be)\n",SvPV_nolen(tag));
				hv_store_aa(ctx->hcurrent, tag, sv);
			}
			else if (ctx->array && ( hv_exists(ctx->array, data,length ) )) {
				//printf("Cast %s as array\n",SvPV_nolen(tag));
				hv_store_aa(ctx->hcurrent, tag, sv);
			}
			else {
				hv_store_a(ctx->hcurrent, tag, sv);
			}
		}
		if (svtext) SvREFCNT_dec(svtext);
	} else {
		my_croak(ctx,"Bad depth: %d for tag close %s\n",ctx->depth,SvPV_nolen(tag));
	}
}

void on_attr_name(void * pctx, char * data,unsigned int length) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_attr_name");
#endif
	parsestate *ctx = pctx;
	if (ctx->textval) {
		my_croak(ctx,"Have textval=%s, while called attrname\n",SvPV_nolen(ctx->textval));
	}
	//warn("Called attrname on %s '%-.*s'=",ctx->pi ? "pi" : "common", length,data);
	if (ctx->attrname) {
		my_croak(ctx,"Called attrname '%-.*s'=, while have attrname='%-.*s'\n",length,data,SvCUR(ctx->attrname),SvPVX(ctx->attrname));
	}
	if (ctx->pi) {
		ctx->attrname = newSVpvn(data,length);
	} else {
		if( ctx->attr ) {
			//warn("What TF is attr??"); attr prefix
			ctx->attrname = newSV(length + SvCUR(ctx->attr));
			sv_copypv(ctx->attrname, ctx->attr);
			sv_catpvn(ctx->attrname, data, length);
		} else {
			ctx->attrname = newSVpvn(data, length);
		}
	}
}

void on_warn(void * pctx, char * format, ...) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_warn");
#endif
	//parsestate *ctx = pctx;
	//if(!(ctx->flags & EMIT_WARNS)) return;
	va_list va;
	va_start(va,format);
	SV *text = sv_2mortal(newSVpvn("",0));
	sv_vcatpvf(text, format, &va);
	warn("%s",SvPV_nolen(text));
	va_end(va);
}

void on_die(void * pctx, char * format, ...) {
#if XML_DEVEL
	if (!pctx) croak("Context not passed to on_die");
#endif
	parsestate *ctx = pctx;
	va_list va;
	va_start(va,format);
	ctx->error = sv_2mortal(newSVpvn("",0));
	sv_vcatpvf(ctx->error, format, &va);
	//warn("got a die with %s",SvPV_nolen(ctx->error));
	va_end(va);
}



/*
#define newRVHV() newRV_noinc((SV *)newHV())
#define rv_hv_store(rv,key,len,sv,f) hv_store((HV*)SvRV(rv), key,len,sv,f)
#define rv_hv_fetch(rv,key,len,f) hv_fetch((HV*)SvRV(rv), key,len,f)
*/
/*
void
_test()
	CODE:
		SV *sv1 = newRVHV();
		SV *sv2 = newRVHV();
		sv_2mortal(sv1);
		sv_2mortal(sv2);
		SV *test = newSVpvn("test",4);
		rv_hv_store(sv1, "test",4,test,0);
		SvREFCNT_inc(test);
		rv_hv_store(sv2, "test",4,test,0);
*/

#ifndef HePV_nolen
#define HePV_nolen(he)	((HeKLEN(he) == HEf_SVKEY) ? \
				 SvPV_nolen(HeKEY_sv(he)) : \
				 (HeKEY(he)))
#endif
//#define strcmp(a,b) ( a && b ? strcmp(a,b) : fprintf(stderr, "Failed to compare %s with %s at %s line %d.\n", a,b,__FILE__,__LINE__)+2 )
#define mystrcmp(a,b) ( a && b ? strcmp(a,b) : 2 )

void h2xout( char *data, compstate *p ) {
	printf( "%*s", p->depth * 4,"" );
	printf( "%s\n", data );
}
void h2xoute( char *data, compstate *p ) {
	printf( "%*s", p->depth * 4,"" );
	printf("e(%s)\n", data);
}

void h2xp( compstate *p, char *f, ... ) {
	va_list va_args;
	
	/*
	printf( "%*s", p->depth * 4,"" );
	va_start(va_args,f);
	vfprintf(stdout, f, va_args);
	va_end(va_args);
	*/
	
	va_start(va_args,f);
	sv_vcatpvf( p->result, f, &va_args );
	va_end(va_args);
	
	//printf ("\n");
}
void h2xpe( compstate *p, char *s ) {
	char *b = s;
	while (1) {
		switch (*s) {
			warn("%c", *s);
			case 0:
				if (b < s) sv_catpvf( p->result, "%-.*s", (int)(s - b), b );
				return;
			case '<':
				if (b < s) sv_catpvf( p->result, "%-.*s", (int)(s - b), b );
				sv_catpvf( p->result, "%s", "&lt;" );
				b = s+1;
				break;
			case '>':
				if (b < s) sv_catpvf( p->result, "%-.*s", (int)(s - b), b );
				sv_catpvf( p->result, "%s", "&gt;" );
				b = s+1;
				break;
			case '"':
				if (b < s) sv_catpvf( p->result, "%-.*s", (int)(s - b), b );
				sv_catpvf( p->result, "%s", "&quot;" );
				b = s+1;
				break;
			case '\'':
				if (b < s) sv_catpvf( p->result, "%-.*s", (int)(s - b), b );
				sv_catpvf( p->result, "%s", "&apos;" );
				b = s+1;
				break;
			case '&':
				if (b < s) sv_catpvf( p->result, "%-.*s", (int)(s - b), b );
				sv_catpvf( p->result, "%s", "&amp;" );
				b = s+1;
				break;
			default:
				break;
		}
		s++;
	}
}


void kv2x ( char *key, SV *val, compstate *p );
void kv2x ( char *key, SV *val, compstate *p ) {
	char closed;
	
	HE* ent;
	
	char   *nkey;
	STRLEN  i, nlen;
	
	AV  *av;
	SV **avv;
	
	debug("key=%s, val=%s",key, SvPV_nolen(val));
	if ( mystrcmp( key, p->text ) == 0 ) {
		h2xpe(p, SvPV_nolen( val ));
	}
	else
	if ( mystrcmp( key, p->cdata ) == 0 ) {
		h2xp(p, "<![CDATA[");
		h2xp(p, SvPV_nolen( val ));
		h2xp(p, "]]>");
	}
	else
	if ( p->comm && mystrcmp( key, p->comm) == 0 ) {
		debug("comm: %s", SvPV_nolen( val ));
		h2xp(p, "<!-- ");
		h2xpe(p, SvPV_nolen( val ));
		h2xp(p, " -->");
	}
	else {
		if (SvROK( val )) {
			switch ( SvTYPE( SvRV( val ) ) ) {
				case SVt_PVHV:
					debug("%s -> hash inside", key);
					(void) hv_iterinit( (HV *) SvRV( val ) );
					h2xp(p, "<%s", key);
					closed = 0;
					while ((ent = hv_iternext( (HV *) SvRV( val ) ))) {
						nkey = HePV(ent, nlen);
						if ( strncmp( nkey, p->attr, p->attl ) == 0 ) {
							nkey += p->attl;
							h2xp(p, " %s=\"",nkey);
							h2xpe(p, SvPV_nolen(HeVAL(ent)));
							h2xp(p, "\"");
							continue;
						}
					}
					
					(void) hv_iterinit( (HV *) SvRV( val ) );
					while ((ent = hv_iternext( (HV *) SvRV( val ) ))) {
						nkey = HePV(ent, nlen);
						if ( strncmp( nkey, p->attr, p->attl ) == 0 ) {
							continue;
						}
						debug("Nested %s->%s", nkey, SvPV_nolen(HeVAL(ent)));
						if (!closed) {
							closed = 1;
							h2xp(p,">");
						}
						p->depth++;
						kv2x( nkey, HeVAL(ent), p );
						p->depth--;
					}
					
					if (!closed) {
						h2xp(p, "/>");
					} else {
						h2xp(p, "</%s>",key);
					}
					
					
					break;
				case SVt_PVAV:
					debug("array inside (Multinode)");
					
					av = (AV *) SvRV( val );
					nlen = av_len(av) + 1;
					
					for ( i = 0; i < nlen; i++ ) {
						if( ( avv = av_fetch(av,i,0) ) && SvOK(*avv) ) {
							kv2x( key, *avv, p );
/*							
							//printf("AV.V: %s\n",SvPV_nolen(*avv));
							if (closed) {
								h2xp(p, "<%s", key);
								closed = 0;
							}
							if (SvROK( *avv )) {
								switch( SvTYPE( SvRV(*avv) ) ) {
									case SVt_PVHV:
										//debug ("hv inside av");
										(void) hv_iterinit( (HV *) SvRV( *avv ) );
										while ((ent = hv_iternext( (HV *) SvRV( *avv ) ))) {
											nkey = HePV_nolen(ent);
											if ( strncmp( nkey, p->attr, p->attl ) == 0 ) {
												nkey += p->attl;
												h2xp(p, " %s='%s'",nkey, SvPV_nolen(HeVAL(ent)));
												continue;
											}
										}
										break;
									case SVt_PVAV:
										//Ignore attrs from AV in AV
										//debug ("av inside av");
										// Prohibited
										break;
									default:
										debug("Unhandled svtype: %s", SvPV_nolen( *avv ));
								}
							} else {
								
							}
							
							h2xp(p, "</%s>", key);
							closed = 1;
*/
						}
					}
					/*
					debug("array inside. loop 2");
					
					for ( i = 0; i < nlen; i++ ) {
						if( ( avv = av_fetch(av,i,0) ) && SvOK(*avv) ) {
							if (SvROK( *avv )) {
								switch( SvTYPE( SvRV(*avv) ) ) {
									case SVt_PVHV:
										(void) hv_iterinit( (HV *) SvRV( *avv ) );
										while ((ent = hv_iternext( (HV *) SvRV( *avv ) ))) {
											nkey = HePV_nolen(ent);
											if ( strncmp( nkey, p->attr, p->attl ) == 0 ) {
												continue;
											}
											
											//
											debug("Nested %s->%s", nkey, SvPV_nolen(HeVAL(ent)));
											if (!closed) {
												closed = 1;
												h2xp(p,">");
											}
											p->depth++;
											kv2x( nkey, HeVAL(ent), p );
											p->depth--;
										}
										break;
									case SVt_PVAV:
										//AV in AV
										debug("Array within Array is useless and not supported. Ignoring");
										break;
									default:
										debug("Unhandled svtype: %s", SvPV_nolen( *avv ));
								}
							} else {
								
							}
						}
					}
					*/
					
					break;
				default:
					warn("Bad reference found: %s", SvPV_nolen( SvRV(val) ));
					break;
			}
		} else {
			if (SvOK(val) && SvCUR(val)) {
				h2xp(p, "<%s>", key);
				h2xpe(p, SvPV_nolen(val));
				h2xp(p, "</%s>", key);
			} else {
				h2xp(p, "<%s/>",key);
			}
		}
	}
}

void h2x ( SV *x, compstate *p );
void h2x ( SV *x, compstate *p ) {
	
	HE* ent;
	SV *val;
	char *key;
	STRLEN klen;
	
	if (SvROK (x)) {
		switch( SvTYPE( SvRV(x) ) ) {
			case SVt_PVHV:
				(void) hv_iterinit( (HV *) SvRV( x ) );
				while ((ent = hv_iternext( (HV *) SvRV( x ) ))) {
					key = HePV(ent, klen);
					val = HeVAL(ent);
					if ( strncmp( key, p->attr, strlen(p->attr) ) == 0 ) {
						debug("Attribute %s at this level is prohibited", key);
						continue;
					}
					kv2x( key, val, p );
				}
				break;
			default:
				warn("skip %s", SvPV_nolen( SvRV(x) ));
		}
	} else {
		warn("skip nonref");
	}
}



MODULE = XML::Fast		PACKAGE = XML::Fast

void
_test()
	CODE:
		dTHX;
		SV * cons = get_constant("Encode::FB_QUIET");
		SV * test = newSViv(4);
		sv_dump(test);
		printf("Got constant %s\n", SvPV_nolen(cons));
		//UV chr = 0x2622;
		UV chr = 0xAB;
		char *end, utf[UTF8_MAXBYTES + 1];
		SV *encode = find_encoding("windows-1251");
		end = uvchr_to_utf8(utf, chr);
		*end = '\0';
		SV *tmp = sv_2mortal(newSVpvn(utf, end-utf));
		SvUTF8_on(tmp);
		SV *bytes = sv_recode_from_utf8(aTHX_ tmp, encode);
		sv_dump(bytes);
		printf("Created char %s / %s / bytes = %s\n", utf, SvPV_nolen(tmp), SvPV_nolen(bytes));
		//sv_recode_to_utf8(tmp, encode);
		//printf("Recoded %s\n",SvPV_nolen(tmp));
		croak("Force exit");
		

void
_xml2hash(xml_sv,conf)
		SV *xml_sv;
		HV *conf;
	PROTOTYPE: $$
	PPCODE:
		SvGETMAGIC(xml_sv);
		char *xml = SvPVbyte_nolen(xml_sv);
		SV * RV;
		
		parser_state state;
		memset(&state,0,sizeof(state));
		
		parsestate ctx;
		memset(&ctx,0,sizeof(parsestate));
		
		state.ctx = &ctx;
		ctx.state = &state;
		
		SV **key;
		if ((key = hv_fetch(conf, "order", 5, 0)) && SvTRUE(*key)) {
			ctx.flags |= MODE_ORDER;
		}
		if ((key = hv_fetch(conf, "trim", 4, 0)) && SvTRUE(*key)) {
			ctx.flags |= MODE_TRIM;
		}
		if ((key = hv_fetch(conf, "bytes", 5, 0)) && SvTRUE(*key)) {
			ctx.bytes = 1;
		} else {
			if ((key = hv_fetch(conf, "utf8decode", 10, 0)) && SvTRUE(*key)) {
				ctx.utf8 = UTF8_DECODE;
			} else {
				ctx.utf8 = UTF8_UPGRADE;
			}
		}
		
		if ((key = hv_fetch(conf, "attr", 4, 0))) {
			if (SvOK(*key) && SvCUR(*key) > 0 ) { // defined and length
				ctx.attr = *key;
			}
		}
		if ((key = hv_fetch(conf, "text", 4, 0)) && SvOK(*key)) {
			ctx.text = *key;
		}
		if ((key = hv_fetch(conf, "join", 4, 0)) && SvPOK(*key)) {
			ctx.join = *key;
		}
		if ((key = hv_fetch(conf, "cdata", 5, 0)) && SvPOK(*key)) {
			ctx.cdata = *key;
		}
		if ((key = hv_fetch(conf, "comm", 4, 0)) && SvPOK(*key)) {
			ctx.comm = *key;
		}
		if ((key = hv_fetch(conf, "array", 5, 0)) && SvOK(*key)) {
			if (SvROK(*key) && SvTYPE( SvRV(*key) ) == SVt_PVAV) {
				AV *av = (AV *) SvRV( *key );
				ctx.array = newHV();
				I32 len = 0, avlen = av_len(av) + 1;
				SV **val;
				for ( len = 0; len < avlen; len++ ) {
					if( ( val = av_fetch(av,len,0) ) && SvOK(*val) ) {
						if(SvPOK(*val)) {
							(void) hv_store( ctx.array, SvPV_nolen(*val), SvCUR(*val), newSV(0), 0 );
						} else {
							my_croak(&ctx,"Bad enrty in array entry: %s",SvPV_nolen(*val));
						}
					}
				}
				
				
			}
			else if (!SvROK(*key)) {
				//printf("Remember all should be arrays\n");
				if (SvTRUE(*key)) {
					ctx.flags |= MODE_ARRAYS;
				}
			}
			else {
				my_croak(&ctx,"Bad entry in array: %s",SvPV_nolen(*key));
			}
		}
		
		//ctx.flags |= TAG_MATCH;
		
		
		if ((key = hv_fetch(conf, "_max_depth", 10, 0)) && SvOK(*key)) {
			ctx.chainsize = SvIV(*key);
			if (ctx.chainsize < 1) {
				my_croak(&ctx,"_max_depth contains bad value (%d)",ctx.chainsize);
			}
		} else {
			ctx.chainsize = 256;
		}
		
		if (!ctx.bytes) {
			ctx.encoding = "utf8";
		}
		
		if (ctx.flags & MODE_ORDER) {
			my_croak(&ctx,"Ordered mode not implemented yet\n");
		} else{
			ctx.hcurrent = newHV();
			
			Newx(ctx.chain, ctx.chainsize, xml_node);
			Newx(ctx.hchain, ctx.chainsize, HV*);
			ctx.depth    = -1;
			
			RV  = sv_2mortal(newRV_noinc( (SV *) ctx.hcurrent ));
			
			state.cb.piopen      = on_pi_open;
			state.cb.piclose     = on_pi_close;
			state.cb.tagopen      = on_tag_open;
			state.cb.tagclose     = on_tag_close;
			
			state.cb.attrname     = on_attr_name;
			if ((key = hv_fetch(conf, "nowarn", 6, 0)) && SvTRUE(*key)) {
				//
			} else {
				state.cb.warn         = on_warn;
				ctx.flags |= EMIT_WARNS;
			}
			state.cb.die         = on_die;
			
			if(ctx.comm)
				state.cb.comment      = on_comment;
			
			if(ctx.cdata)
				state.cb.cdata        = on_cdata;
			else if(ctx.text)
				state.cb.cdata        = on_bytes;
			
			state.cb.bytes        = on_bytes;
			state.cb.bytespart    = on_bytes_part;
			state.cb.uchar        = on_uchar;
			
			if (!(ctx.flags & MODE_TRIM))
				state.save_wsp     = 1;
		}
		parse(xml,&state);
		
		if (ctx.depth > -1 && !ctx.error) {
			ctx.error = sv_2mortal(newSVpv("Unbalanced tags",0));
		}
		
		DESTROY(&ctx);
		
		if (ctx.error) {
			croak("%s", SvPV_nolen(ctx.error));
		}
		ST(0) = RV;
		XSRETURN(1);

void
_hash2xml(hash,conf)
		SV *hash;
		HV *conf;
	PROTOTYPE: $$
	PPCODE:
		compstate ctx;
		memset(&ctx,0,sizeof(parsestate));
		
		SV **key;
		if ((key = hv_fetch(conf, "order", 5, 0)) && SvTRUE(*key)) {
			ctx.flags |= MODE_ORDER;
		}
		if ((key = hv_fetch(conf, "trim", 4, 0)) && SvTRUE(*key)) {
			ctx.flags |= MODE_TRIM;
		}
		/*
		if ((key = hv_fetch(conf, "bytes", 5, 0)) && SvTRUE(*key)) {
			ctx.bytes = 1;
		} else {
			if ((key = hv_fetch(conf, "utf8decode", 10, 0)) && SvTRUE(*key)) {
				ctx.utf8 = UTF8_DECODE;
			} else {
				ctx.utf8 = UTF8_UPGRADE;
			}
		}
		*/
		
		if ((key = hv_fetch(conf, "attr", 4, 0)) && SvPOK(*key)) {
			ctx.attr = SvPV_nolen(*key);
			// warn ("Set attr to '%s'", ctx.attr);
		} else {
			ctx.attr = "-";
		}
		if ((key = hv_fetch(conf, "text", 4, 0)) && SvPOK(*key)) {
			ctx.text = SvPV_nolen(*key);
		} else {
			ctx.text = "#text";
		}
		if ((key = hv_fetch(conf, "cdata", 5, 0)) && SvPOK(*key)) {
			ctx.cdata = SvPV_nolen(*key);
		} else {
			ctx.cdata = 0;
		}
		if ((key = hv_fetch(conf, "comm", 4, 0)) && SvPOK(*key)) {
			ctx.comm = SvPV_nolen(*key);
		} else {
			ctx.comm = 0;
		}
		/*
		if ((key = hv_fetch(conf, "array", 5, 0)) && SvOK(*key)) {
			if (SvROK(*key) && SvTYPE( SvRV(*key) ) == SVt_PVAV) {
				AV *av = (AV *) SvRV( *key );
				ctx.array = newHV();
				I32 len = 0, avlen = av_len(av) + 1;
				SV **val;
				for ( len = 0; len < avlen; len++ ) {
					if( ( val = av_fetch(av,len,0) ) && SvOK(*val) ) {
						if(SvPOK(*val)) {
							(void) hv_store( ctx.array, SvPV_nolen(*val), SvCUR(*val), newSV(0), 0 );
						} else {
							//my_croak(&ctx,"Bad enrty in array entry: %s",SvPV_nolen(*val));
						}
					}
				}
				
				
			}
			else if (!SvROK(*key)) {
				//printf("Remember all should be arrays\n");
				if (SvTRUE(*key)) {
					ctx.flags |= MODE_ARRAYS;
				}
			}
			else {
				//my_croak(&ctx,"Bad entry in array: %s",SvPV_nolen(*key));
			}
		}
		
		//ctx.flags |= TAG_MATCH;
		
		if (!ctx.bytes) {
			ctx.encoding = "utf8";
		}
		*/
		
		ctx.depth  = 0;
		ctx.ix     = 0;
		ctx.result = sv_2mortal(newSVpv("",0));
		//ctx.nested = newSVpv("",0);
		ctx.attl   = strlen(ctx.attr);
		
		SvGROW(ctx.result,1024);
		//SvGROW(ctx.nested,1024);
		h2x( hash, &ctx);
		
		//croak("XXX: %s", SvPV_nolen(ctx.result));
		
		if (ctx.error) {
			croak("%s", SvPV_nolen(ctx.error));
		}
		
		ST(0) = ctx.result;
		XSRETURN(1);
