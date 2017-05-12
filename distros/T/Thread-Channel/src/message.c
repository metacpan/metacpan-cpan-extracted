#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "message.h"

/*
 * struct message
 */

void S_destroy_message(pTHX_ const message* message_) {
	PerlMemShared_free((message*)message_);
}

static SV* S_message_get_sv(pTHX_ const message* message) {
	SV* stored = newSVpvn(message->value, message->length);
	return stored;
}

#define message_get_sv(message) S_message_get_sv(aTHX_ message)

static const message* S_message_new_sv(pTHX_ SV* value, enum message_type type) {
	message* message;
	const char* string;
	STRLEN len;
	string = SvPV(value, len);
   	message = PerlMemShared_calloc(1, sizeof(*message) + len + 1);
	message->type = type;
	message->length = len;
	Copy(string, message->value, len, char);
	return message;
}

#define message_new_sv(value, type) S_message_new_sv(aTHX_ value, type)

const message* S_message_store_value(pTHX_ SV* value) {
	dSP;
	const message* ret;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newRV_inc(value)));
	PUTBACK;
	call_pv("Sereal::Encoder::encode_sereal", G_SCALAR);
	SPAGAIN;
	ret = message_new_sv(POPs, SEREAL);
	FREETMPS;
	LEAVE;
	PUTBACK;
	return ret;
}

static int S_is_simple(pTHX_ SV* value) {
	return SvOK(value) && !SvROK(value) && !(SvPOK(value) && SvUTF8(value));
}
#define is_simple(value) S_is_simple(aTHX_ value)

static int S_are_simple(pTHX_ SV** begin, SV** end) {
	SV** current;
	for(current = begin; current <= end; current++)
		if (! is_simple(*current))
			return FALSE;
	return TRUE;
}

#define are_simple(begin, end) S_are_simple(aTHX_ begin, end)

static const char pack_template[] = "(I/a)*";

const message* S_message_from_stack(pTHX) {
	dSP; dMARK;
	if (SP == MARK && is_simple(*SP)) {
		return message_new_sv(MARK[0], STRING);
	}
	else if (are_simple(MARK + 1, SP)) {
		SV* tmp = sv_2mortal(newSVpvn("", 0));
		packlist(tmp, pack_template, pack_template + sizeof pack_template - 1, MARK + 1, SP + 1);
		return message_new_sv(tmp, PACKED);
	}
	else {
		SV* list = sv_2mortal((SV*)av_make(SP - MARK, MARK + 1));
		return message_store_value(list);
	}
}

SV* S_message_load_value(pTHX_ const message* message) {
	dSP;
	SV* ret;

	PUSHMARK(SP);
	XPUSHs(sv_2mortal(message_get_sv(message)));
	PUTBACK;
	call_pv("Sereal::Decoder::decode_sereal", G_SCALAR);
	SPAGAIN;
	ret = POPs;
	PUTBACK;
	return ret;
}

void S_message_to_stack(pTHX_ const message* message, U32 context) {
	dSP;
	switch(message->type) {
		case STRING:
			PUSHs(sv_2mortal(newRV_noinc(message_get_sv(message))));
			break;
		case PACKED: {
			SV* mess = sv_2mortal(message_get_sv(message));
			STRLEN len;
			const char* packed = SvPV(mess, len);
			PUTBACK;
			unpackstring(pack_template, pack_template + sizeof pack_template - 1, packed, packed + len, 0);
			SPAGAIN;
			break;
		}
		case SEREAL: {
			AV* values = (AV*) SvRV(message_load_value(message));
			SPAGAIN;

			if (context == G_SCALAR) {
				SV** ret = av_fetch(values, 0, FALSE);
				PUSHs(ret ? *ret : &PL_sv_undef);
			}
			else if (context == G_ARRAY) {
				UV count = av_len(values) + 1;
				EXTEND(SP, count);
				Copy(AvARRAY(values), SP + 1, count, SV*);
				SP += count;
			}
			break;
		}
		default:
			Perl_croak(aTHX_ "Type %d is not yet implemented", message->type);
	}

	PUTBACK;
}

AV* S_message_to_array(pTHX_ const message* message) {
	dSP;
	AV* ret;
	switch(message->type) {
		case STRING:
			ret = newAV();
			av_push(ret, message_get_sv(message));
			break;
		case PACKED: {
			SV* mess = message_get_sv(message);
			STRLEN len;
			int count;
			const char* packed = SvPV(mess, len);
			SV** mark = SP;
			PUTBACK;
			count = unpackstring(pack_template, pack_template + sizeof pack_template - 1, packed, packed + len, 0);
			SPAGAIN;
			ret = av_make(count, mark + 1);
			break;
		}
		case SEREAL: {
			ret = (AV*)SvREFCNT_inc(SvRV(message_load_value(message)));
			SPAGAIN;
			break;
		}
		default:
			Perl_croak(aTHX_ "Type %d is not yet implemented", message->type);
	}
	PUTBACK;

	return ret;
}

const message* S_message_clone(pTHX_ const message* origin) {
	//return savesharedpvn(origin, sizeof(message) + origin->length + 1)
	size_t size = sizeof(message) + origin->length + 1;
	message* clone = PerlMemShared_calloc(1, size);
	Copy(origin, clone, size, char);
	return clone;
}

