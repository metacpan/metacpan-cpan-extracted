#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION \
	PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) \
	(PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

#ifndef sv_catpvs_nomg
# define sv_catpvs_nomg(sv, string) \
	sv_catpvn_nomg(sv, ""string"", sizeof(string)-1)
#endif /* !sv_catpvs_nomg */

#ifndef gv_stashpvs
# define gv_stashpvs(name, flags) gv_stashpvn(""name"", sizeof(name)-1, flags)
#endif /* !gv_stashpvs */

/* stashed stashes */

static HV *stash_content, *stash_element;

/* stashed constant content */

static SV *empty_contentobject;

/* parameter classification */

#define sv_is_glob(sv) (SvTYPE(sv) == SVt_PVGV)

#if PERL_VERSION_GE(5,11,0)
# define sv_is_regexp(sv) (SvTYPE(sv) == SVt_REGEXP)
#else /* <5.11.0 */
# define sv_is_regexp(sv) 0
#endif /* <5.11.0 */

#define sv_is_string(sv) \
	(!sv_is_glob(sv) && !sv_is_regexp(sv) && \
	 (SvFLAGS(sv) & (SVf_IOK|SVf_NOK|SVf_POK|SVp_IOK|SVp_NOK|SVp_POK)))

/* exceptions */

#define throw_utf8_error() croak("broken internal UTF-8 encoding\n")
#define throw_syntax_error(p) croak("XML syntax error\n")
#define throw_wfc_error(MSG) croak("XML constraint error: "MSG"\n")
#define throw_data_error(MSG) croak("invalid XML data: "MSG"\n")

/*
 * string walking
 *
 * The parser deals with strings that are internally encoded using Perl's
 * extended form of UTF-8.  It is not assumed that the encoding is
 * well-formed; encoding errors will result in an exception.  The encoding
 * octets are treated as U8 type.
 *
 * Characters that are known to be in the ASCII range are in some places
 * processed as U8.  General Unicode characters are processed as U32, with
 * the intent that the entire ISO-10646 31-bit range be handleable.  Any
 * codepoint is accepted for processing, even the surrogates (which are
 * not legal in true UTF-8 encoding).  Perl's extended UTF-8 extends to
 * 72-bit codepoints; encodings beyond the 31-bit range are translated to
 * codepoint U+7fffffff, which is equally invalid in the XML syntax.
 *
 * char_unicode() returns the codepoint represented by the character being
 * pointed at, or throws an exception if the encoding is malformed.
 *
 * To move on to the character following the one pointed at, use the core
 * macro UTF8SKIP(), as in (p + UTF8SKIP(p)).  It assumes that the character
 * is properly encoded, so it is essential that char_unicode() has been
 * called on it first.
 *
 * Given an input SV (that is meant to be a string), pass it through
 * upgrade_sv() to return an SV that contains the string in UTF-8.  This
 * could be either the same SV (if it is already UTF-8-encoded or contains
 * no non-ASCII characters) or a mortal upgraded copy.
 *
 * Given an unboxed Latin-1 string, upgrade_latin1_pvn() returns details of
 * an equivalent UTF-8 string, either the same string (if it's ASCII) or a
 * mortal SV.
 */

#define char_unicode(p) THX_char_unicode(aTHX_ p)
static U32 THX_char_unicode(pTHX_ U8 *p)
{
	U32 val = *p;
	U8 req_c1;
	int ncont;
	int i;
	if(!(val & 0x80)) return val;
	if(!(val & 0x40)) throw_utf8_error();
	if(!(val & 0x20)) {
		if(!(val & 0x1e)) throw_utf8_error();
		val &= 0x1f;
		ncont = 1;
		req_c1 = 0x00;
	} else if(!(val & 0x10)) {
		val &= 0x0f;
		ncont = 2;
		req_c1 = 0x20;
	} else if(!(val & 0x08)) {
		val &= 0x07;
		ncont = 3;
		req_c1 = 0x30;
	} else if(!(val & 0x04)) {
		val &= 0x03;
		ncont = 4;
		req_c1 = 0x38;
	} else if(!(val & 0x02)) {
		val &= 0x01;
		ncont = 5;
		req_c1 = 0x3c;
	} else if(!(val & 0x01)) {
		if(!(p[1] & 0x3e)) throw_utf8_error();
		for(i = 6; i--; )
			if((*++p & 0xc0) != 0x80)
				throw_utf8_error();
		return 0x7fffffff;
	} else {
		U8 first_six = 0;
		for(i = 6; i--; ) {
			U8 ext = *++p;
			if((ext & 0xc0) != 0x80)
				throw_utf8_error();
			first_six |= ext;
		}
		if(!(first_six & 0x3f))
			throw_utf8_error();
		for(i = 6; i--; )
			if((*++p & 0xc0) != 0x80)
				throw_utf8_error();
		return 0x7fffffff;
	}
	if(val == 0 && !(p[1] & req_c1))
		throw_utf8_error();
	for(i = ncont; i--; ) {
		U8 ext = *++p;
		if((ext & 0xc0) != 0x80)
			throw_utf8_error();
		val = UTF8_ACCUMULATE(val, ext);
	}
	return val;
}

#define upgrade_sv(input) THX_upgrade_sv(aTHX_ input)
static SV *THX_upgrade_sv(pTHX_ SV *input)
{
	U8 *p, *end;
	STRLEN len;
	if(SvUTF8(input)) return input;
	p = (U8*)SvPV(input, len);
	for(end = p + len; p != end; p++) {
		if(*p & 0x80) {
			SV *output = sv_mortalcopy(input);
			sv_utf8_upgrade(output);
			return output;
		}
	}
	return input;
}

#define upgrade_latin1_pvn(ptrp, lenp) THX_upgrade_latin1_pvn(aTHX_ ptrp, lenp)
static void THX_upgrade_latin1_pvn(pTHX_ U8 **ptrp, STRLEN *lenp)
{
	U8 *ptr = *ptrp;
	STRLEN len = *lenp;
	U8 *p = ptr, *end = ptr + len;
	for(; p != end; p++) {
		if(*p & 0x80) {
			SV *output = sv_2mortal(newSVpvn((char*)ptr, len));
			sv_utf8_upgrade(output);
			ptr = (U8*)SvPV(output, len);
			*ptrp = ptr;
			*lenp = len;
			return;
		}
	}
}

/*
 * character classification
 *
 * The full Unicode range of characters is subjected to fairly arbitrary
 * classification.  To avoid having enormous bitmaps, the ranges to match
 * against are stored in lists, which are binary-searched.  For speed,
 * the ASCII range is classified by a bitmap.
 *
 * nona_codepoint_is_in_set() checks whether a non-ASCII codepoint is in
 * a specified character set identified by a Unicode range table.
 *
 * The char_is_*() functions each check whether the character being
 * pointed at is of a particular type.
 *
 * The codepoint_is_*() functions each check whether a codepoint is of
 * a particular type.
 *
 * The ascii_codepoint_is_*() functions each check whether an ASCII
 * codepoint is of a particular type.
 */

struct unicode_range {
	U32 first;
	U32 last;
};

static struct unicode_range const uniset_namestart[] = {
	{ 0x003a, 0x003a },
	{ 0x0041, 0x005a },
	{ 0x005f, 0x005f },
	{ 0x0061, 0x007a },
	{ 0x00c0, 0x00d6 },
	{ 0x00d8, 0x00f6 },
	{ 0x00f8, 0x0131 },
	{ 0x0134, 0x013e },
	{ 0x0141, 0x0148 },
	{ 0x014a, 0x017e },
	{ 0x0180, 0x01c3 },
	{ 0x01cd, 0x01f0 },
	{ 0x01f4, 0x01f5 },
	{ 0x01fa, 0x0217 },
	{ 0x0250, 0x02a8 },
	{ 0x02bb, 0x02c1 },
	{ 0x0386, 0x0386 },
	{ 0x0388, 0x038a },
	{ 0x038c, 0x038c },
	{ 0x038e, 0x03a1 },
	{ 0x03a3, 0x03ce },
	{ 0x03d0, 0x03d6 },
	{ 0x03da, 0x03da },
	{ 0x03dc, 0x03dc },
	{ 0x03de, 0x03de },
	{ 0x03e0, 0x03e0 },
	{ 0x03e2, 0x03f3 },
	{ 0x0401, 0x040c },
	{ 0x040e, 0x044f },
	{ 0x0451, 0x045c },
	{ 0x045e, 0x0481 },
	{ 0x0490, 0x04c4 },
	{ 0x04c7, 0x04c8 },
	{ 0x04cb, 0x04cc },
	{ 0x04d0, 0x04eb },
	{ 0x04ee, 0x04f5 },
	{ 0x04f8, 0x04f9 },
	{ 0x0531, 0x0556 },
	{ 0x0559, 0x0559 },
	{ 0x0561, 0x0586 },
	{ 0x05d0, 0x05ea },
	{ 0x05f0, 0x05f2 },
	{ 0x0621, 0x063a },
	{ 0x0641, 0x064a },
	{ 0x0671, 0x06b7 },
	{ 0x06ba, 0x06be },
	{ 0x06c0, 0x06ce },
	{ 0x06d0, 0x06d3 },
	{ 0x06d5, 0x06d5 },
	{ 0x06e5, 0x06e6 },
	{ 0x0905, 0x0939 },
	{ 0x093d, 0x093d },
	{ 0x0958, 0x0961 },
	{ 0x0985, 0x098c },
	{ 0x098f, 0x0990 },
	{ 0x0993, 0x09a8 },
	{ 0x09aa, 0x09b0 },
	{ 0x09b2, 0x09b2 },
	{ 0x09b6, 0x09b9 },
	{ 0x09dc, 0x09dd },
	{ 0x09df, 0x09e1 },
	{ 0x09f0, 0x09f1 },
	{ 0x0a05, 0x0a0a },
	{ 0x0a0f, 0x0a10 },
	{ 0x0a13, 0x0a28 },
	{ 0x0a2a, 0x0a30 },
	{ 0x0a32, 0x0a33 },
	{ 0x0a35, 0x0a36 },
	{ 0x0a38, 0x0a39 },
	{ 0x0a59, 0x0a5c },
	{ 0x0a5e, 0x0a5e },
	{ 0x0a72, 0x0a74 },
	{ 0x0a85, 0x0a8b },
	{ 0x0a8d, 0x0a8d },
	{ 0x0a8f, 0x0a91 },
	{ 0x0a93, 0x0aa8 },
	{ 0x0aaa, 0x0ab0 },
	{ 0x0ab2, 0x0ab3 },
	{ 0x0ab5, 0x0ab9 },
	{ 0x0abd, 0x0abd },
	{ 0x0ae0, 0x0ae0 },
	{ 0x0b05, 0x0b0c },
	{ 0x0b0f, 0x0b10 },
	{ 0x0b13, 0x0b28 },
	{ 0x0b2a, 0x0b30 },
	{ 0x0b32, 0x0b33 },
	{ 0x0b36, 0x0b39 },
	{ 0x0b3d, 0x0b3d },
	{ 0x0b5c, 0x0b5d },
	{ 0x0b5f, 0x0b61 },
	{ 0x0b85, 0x0b8a },
	{ 0x0b8e, 0x0b90 },
	{ 0x0b92, 0x0b95 },
	{ 0x0b99, 0x0b9a },
	{ 0x0b9c, 0x0b9c },
	{ 0x0b9e, 0x0b9f },
	{ 0x0ba3, 0x0ba4 },
	{ 0x0ba8, 0x0baa },
	{ 0x0bae, 0x0bb5 },
	{ 0x0bb7, 0x0bb9 },
	{ 0x0c05, 0x0c0c },
	{ 0x0c0e, 0x0c10 },
	{ 0x0c12, 0x0c28 },
	{ 0x0c2a, 0x0c33 },
	{ 0x0c35, 0x0c39 },
	{ 0x0c60, 0x0c61 },
	{ 0x0c85, 0x0c8c },
	{ 0x0c8e, 0x0c90 },
	{ 0x0c92, 0x0ca8 },
	{ 0x0caa, 0x0cb3 },
	{ 0x0cb5, 0x0cb9 },
	{ 0x0cde, 0x0cde },
	{ 0x0ce0, 0x0ce1 },
	{ 0x0d05, 0x0d0c },
	{ 0x0d0e, 0x0d10 },
	{ 0x0d12, 0x0d28 },
	{ 0x0d2a, 0x0d39 },
	{ 0x0d60, 0x0d61 },
	{ 0x0e01, 0x0e2e },
	{ 0x0e30, 0x0e30 },
	{ 0x0e32, 0x0e33 },
	{ 0x0e40, 0x0e45 },
	{ 0x0e81, 0x0e82 },
	{ 0x0e84, 0x0e84 },
	{ 0x0e87, 0x0e88 },
	{ 0x0e8a, 0x0e8a },
	{ 0x0e8d, 0x0e8d },
	{ 0x0e94, 0x0e97 },
	{ 0x0e99, 0x0e9f },
	{ 0x0ea1, 0x0ea3 },
	{ 0x0ea5, 0x0ea5 },
	{ 0x0ea7, 0x0ea7 },
	{ 0x0eaa, 0x0eab },
	{ 0x0ead, 0x0eae },
	{ 0x0eb0, 0x0eb0 },
	{ 0x0eb2, 0x0eb3 },
	{ 0x0ebd, 0x0ebd },
	{ 0x0ec0, 0x0ec4 },
	{ 0x0f40, 0x0f47 },
	{ 0x0f49, 0x0f69 },
	{ 0x10a0, 0x10c5 },
	{ 0x10d0, 0x10f6 },
	{ 0x1100, 0x1100 },
	{ 0x1102, 0x1103 },
	{ 0x1105, 0x1107 },
	{ 0x1109, 0x1109 },
	{ 0x110b, 0x110c },
	{ 0x110e, 0x1112 },
	{ 0x113c, 0x113c },
	{ 0x113e, 0x113e },
	{ 0x1140, 0x1140 },
	{ 0x114c, 0x114c },
	{ 0x114e, 0x114e },
	{ 0x1150, 0x1150 },
	{ 0x1154, 0x1155 },
	{ 0x1159, 0x1159 },
	{ 0x115f, 0x1161 },
	{ 0x1163, 0x1163 },
	{ 0x1165, 0x1165 },
	{ 0x1167, 0x1167 },
	{ 0x1169, 0x1169 },
	{ 0x116d, 0x116e },
	{ 0x1172, 0x1173 },
	{ 0x1175, 0x1175 },
	{ 0x119e, 0x119e },
	{ 0x11a8, 0x11a8 },
	{ 0x11ab, 0x11ab },
	{ 0x11ae, 0x11af },
	{ 0x11b7, 0x11b8 },
	{ 0x11ba, 0x11ba },
	{ 0x11bc, 0x11c2 },
	{ 0x11eb, 0x11eb },
	{ 0x11f0, 0x11f0 },
	{ 0x11f9, 0x11f9 },
	{ 0x1e00, 0x1e9b },
	{ 0x1ea0, 0x1ef9 },
	{ 0x1f00, 0x1f15 },
	{ 0x1f18, 0x1f1d },
	{ 0x1f20, 0x1f45 },
	{ 0x1f48, 0x1f4d },
	{ 0x1f50, 0x1f57 },
	{ 0x1f59, 0x1f59 },
	{ 0x1f5b, 0x1f5b },
	{ 0x1f5d, 0x1f5d },
	{ 0x1f5f, 0x1f7d },
	{ 0x1f80, 0x1fb4 },
	{ 0x1fb6, 0x1fbc },
	{ 0x1fbe, 0x1fbe },
	{ 0x1fc2, 0x1fc4 },
	{ 0x1fc6, 0x1fcc },
	{ 0x1fd0, 0x1fd3 },
	{ 0x1fd6, 0x1fdb },
	{ 0x1fe0, 0x1fec },
	{ 0x1ff2, 0x1ff4 },
	{ 0x1ff6, 0x1ffc },
	{ 0x2126, 0x2126 },
	{ 0x212a, 0x212b },
	{ 0x212e, 0x212e },
	{ 0x2180, 0x2182 },
	{ 0x3007, 0x3007 },
	{ 0x3021, 0x3029 },
	{ 0x3041, 0x3094 },
	{ 0x30a1, 0x30fa },
	{ 0x3105, 0x312c },
	{ 0x4e00, 0x9fa5 },
	{ 0xac00, 0xd7a3 },
};

static struct unicode_range const uniset_name[] = {
	{ 0x002d, 0x002e },
	{ 0x0030, 0x003a },
	{ 0x0041, 0x005a },
	{ 0x005f, 0x005f },
	{ 0x0061, 0x007a },
	{ 0x00b7, 0x00b7 },
	{ 0x00c0, 0x00d6 },
	{ 0x00d8, 0x00f6 },
	{ 0x00f8, 0x0131 },
	{ 0x0134, 0x013e },
	{ 0x0141, 0x0148 },
	{ 0x014a, 0x017e },
	{ 0x0180, 0x01c3 },
	{ 0x01cd, 0x01f0 },
	{ 0x01f4, 0x01f5 },
	{ 0x01fa, 0x0217 },
	{ 0x0250, 0x02a8 },
	{ 0x02bb, 0x02c1 },
	{ 0x02d0, 0x02d1 },
	{ 0x0300, 0x0345 },
	{ 0x0360, 0x0361 },
	{ 0x0387, 0x038a },
	{ 0x038c, 0x038c },
	{ 0x038e, 0x03a1 },
	{ 0x03a3, 0x03ce },
	{ 0x03d0, 0x03d6 },
	{ 0x03da, 0x03da },
	{ 0x03dc, 0x03dc },
	{ 0x03de, 0x03de },
	{ 0x03e0, 0x03e0 },
	{ 0x03e2, 0x03f3 },
	{ 0x0401, 0x040c },
	{ 0x040e, 0x044f },
	{ 0x0451, 0x045c },
	{ 0x045e, 0x0481 },
	{ 0x0483, 0x0486 },
	{ 0x0490, 0x04c4 },
	{ 0x04c7, 0x04c8 },
	{ 0x04cb, 0x04cc },
	{ 0x04d0, 0x04eb },
	{ 0x04ee, 0x04f5 },
	{ 0x04f8, 0x04f9 },
	{ 0x0531, 0x0556 },
	{ 0x0559, 0x0559 },
	{ 0x0561, 0x0586 },
	{ 0x0591, 0x05a1 },
	{ 0x05a3, 0x05b9 },
	{ 0x05bb, 0x05bd },
	{ 0x05bf, 0x05bf },
	{ 0x05c1, 0x05c2 },
	{ 0x05c4, 0x05c4 },
	{ 0x05d0, 0x05ea },
	{ 0x05f0, 0x05f2 },
	{ 0x0621, 0x063a },
	{ 0x0641, 0x0652 },
	{ 0x0660, 0x0669 },
	{ 0x0670, 0x06b7 },
	{ 0x06ba, 0x06be },
	{ 0x06c0, 0x06ce },
	{ 0x06d0, 0x06d3 },
	{ 0x06e5, 0x06e8 },
	{ 0x06ea, 0x06ed },
	{ 0x06f0, 0x06f9 },
	{ 0x0901, 0x0903 },
	{ 0x0905, 0x0939 },
	{ 0x093e, 0x094d },
	{ 0x0951, 0x0954 },
	{ 0x0958, 0x0963 },
	{ 0x0966, 0x096f },
	{ 0x0981, 0x0983 },
	{ 0x0985, 0x098c },
	{ 0x098f, 0x0990 },
	{ 0x0993, 0x09a8 },
	{ 0x09aa, 0x09b0 },
	{ 0x09b2, 0x09b2 },
	{ 0x09b6, 0x09b9 },
	{ 0x09bc, 0x09bc },
	{ 0x09bf, 0x09c4 },
	{ 0x09c7, 0x09c8 },
	{ 0x09cb, 0x09cd },
	{ 0x09d7, 0x09d7 },
	{ 0x09dc, 0x09dd },
	{ 0x09df, 0x09e3 },
	{ 0x09e6, 0x09f1 },
	{ 0x0a02, 0x0a02 },
	{ 0x0a05, 0x0a0a },
	{ 0x0a0f, 0x0a10 },
	{ 0x0a13, 0x0a28 },
	{ 0x0a2a, 0x0a30 },
	{ 0x0a32, 0x0a33 },
	{ 0x0a35, 0x0a36 },
	{ 0x0a38, 0x0a39 },
	{ 0x0a3c, 0x0a3c },
	{ 0x0a3f, 0x0a42 },
	{ 0x0a47, 0x0a48 },
	{ 0x0a4b, 0x0a4d },
	{ 0x0a59, 0x0a5c },
	{ 0x0a5e, 0x0a5e },
	{ 0x0a70, 0x0a74 },
	{ 0x0a81, 0x0a83 },
	{ 0x0a85, 0x0a8b },
	{ 0x0a8d, 0x0a8d },
	{ 0x0a8f, 0x0a91 },
	{ 0x0a93, 0x0aa8 },
	{ 0x0aaa, 0x0ab0 },
	{ 0x0ab2, 0x0ab3 },
	{ 0x0ab5, 0x0ab9 },
	{ 0x0abd, 0x0ac5 },
	{ 0x0ac7, 0x0ac9 },
	{ 0x0acb, 0x0acd },
	{ 0x0ae0, 0x0ae0 },
	{ 0x0ae6, 0x0aef },
	{ 0x0b01, 0x0b03 },
	{ 0x0b05, 0x0b0c },
	{ 0x0b0f, 0x0b10 },
	{ 0x0b13, 0x0b28 },
	{ 0x0b2a, 0x0b30 },
	{ 0x0b32, 0x0b33 },
	{ 0x0b36, 0x0b39 },
	{ 0x0b3d, 0x0b43 },
	{ 0x0b47, 0x0b48 },
	{ 0x0b4b, 0x0b4d },
	{ 0x0b56, 0x0b57 },
	{ 0x0b5c, 0x0b5d },
	{ 0x0b5f, 0x0b61 },
	{ 0x0b66, 0x0b6f },
	{ 0x0b82, 0x0b83 },
	{ 0x0b85, 0x0b8a },
	{ 0x0b8e, 0x0b90 },
	{ 0x0b92, 0x0b95 },
	{ 0x0b99, 0x0b9a },
	{ 0x0b9c, 0x0b9c },
	{ 0x0b9e, 0x0b9f },
	{ 0x0ba3, 0x0ba4 },
	{ 0x0ba8, 0x0baa },
	{ 0x0bae, 0x0bb5 },
	{ 0x0bb7, 0x0bb9 },
	{ 0x0bbe, 0x0bc2 },
	{ 0x0bc6, 0x0bc8 },
	{ 0x0bca, 0x0bcd },
	{ 0x0bd7, 0x0bd7 },
	{ 0x0be7, 0x0bef },
	{ 0x0c01, 0x0c03 },
	{ 0x0c05, 0x0c0c },
	{ 0x0c0e, 0x0c10 },
	{ 0x0c12, 0x0c28 },
	{ 0x0c2a, 0x0c33 },
	{ 0x0c35, 0x0c39 },
	{ 0x0c3e, 0x0c44 },
	{ 0x0c46, 0x0c48 },
	{ 0x0c4a, 0x0c4d },
	{ 0x0c55, 0x0c56 },
	{ 0x0c60, 0x0c61 },
	{ 0x0c66, 0x0c6f },
	{ 0x0c82, 0x0c83 },
	{ 0x0c85, 0x0c8c },
	{ 0x0c8e, 0x0c90 },
	{ 0x0c92, 0x0ca8 },
	{ 0x0caa, 0x0cb3 },
	{ 0x0cb5, 0x0cb9 },
	{ 0x0cbe, 0x0cc4 },
	{ 0x0cc6, 0x0cc8 },
	{ 0x0cca, 0x0ccd },
	{ 0x0cd5, 0x0cd6 },
	{ 0x0cde, 0x0cde },
	{ 0x0ce0, 0x0ce1 },
	{ 0x0ce6, 0x0cef },
	{ 0x0d02, 0x0d03 },
	{ 0x0d05, 0x0d0c },
	{ 0x0d0e, 0x0d10 },
	{ 0x0d12, 0x0d28 },
	{ 0x0d2a, 0x0d39 },
	{ 0x0d3e, 0x0d43 },
	{ 0x0d46, 0x0d48 },
	{ 0x0d4a, 0x0d4d },
	{ 0x0d57, 0x0d57 },
	{ 0x0d60, 0x0d61 },
	{ 0x0d66, 0x0d6f },
	{ 0x0e01, 0x0e2e },
	{ 0x0e32, 0x0e3a },
	{ 0x0e46, 0x0e4e },
	{ 0x0e50, 0x0e59 },
	{ 0x0e81, 0x0e82 },
	{ 0x0e84, 0x0e84 },
	{ 0x0e87, 0x0e88 },
	{ 0x0e8a, 0x0e8a },
	{ 0x0e8d, 0x0e8d },
	{ 0x0e94, 0x0e97 },
	{ 0x0e99, 0x0e9f },
	{ 0x0ea1, 0x0ea3 },
	{ 0x0ea5, 0x0ea5 },
	{ 0x0ea7, 0x0ea7 },
	{ 0x0eaa, 0x0eab },
	{ 0x0ead, 0x0eae },
	{ 0x0eb2, 0x0eb9 },
	{ 0x0ebb, 0x0ebd },
	{ 0x0ec0, 0x0ec4 },
	{ 0x0ec6, 0x0ec6 },
	{ 0x0ec8, 0x0ecd },
	{ 0x0ed0, 0x0ed9 },
	{ 0x0f18, 0x0f19 },
	{ 0x0f20, 0x0f29 },
	{ 0x0f35, 0x0f35 },
	{ 0x0f37, 0x0f37 },
	{ 0x0f39, 0x0f39 },
	{ 0x0f3f, 0x0f47 },
	{ 0x0f49, 0x0f69 },
	{ 0x0f71, 0x0f84 },
	{ 0x0f86, 0x0f8b },
	{ 0x0f90, 0x0f95 },
	{ 0x0f97, 0x0f97 },
	{ 0x0f99, 0x0fad },
	{ 0x0fb1, 0x0fb7 },
	{ 0x0fb9, 0x0fb9 },
	{ 0x10a0, 0x10c5 },
	{ 0x10d0, 0x10f6 },
	{ 0x1100, 0x1100 },
	{ 0x1102, 0x1103 },
	{ 0x1105, 0x1107 },
	{ 0x1109, 0x1109 },
	{ 0x110b, 0x110c },
	{ 0x110e, 0x1112 },
	{ 0x113c, 0x113c },
	{ 0x113e, 0x113e },
	{ 0x1140, 0x1140 },
	{ 0x114c, 0x114c },
	{ 0x114e, 0x114e },
	{ 0x1150, 0x1150 },
	{ 0x1154, 0x1155 },
	{ 0x1159, 0x1159 },
	{ 0x115f, 0x1161 },
	{ 0x1163, 0x1163 },
	{ 0x1165, 0x1165 },
	{ 0x1167, 0x1167 },
	{ 0x1169, 0x1169 },
	{ 0x116d, 0x116e },
	{ 0x1172, 0x1173 },
	{ 0x1175, 0x1175 },
	{ 0x119e, 0x119e },
	{ 0x11a8, 0x11a8 },
	{ 0x11ab, 0x11ab },
	{ 0x11ae, 0x11af },
	{ 0x11b7, 0x11b8 },
	{ 0x11ba, 0x11ba },
	{ 0x11bc, 0x11c2 },
	{ 0x11eb, 0x11eb },
	{ 0x11f0, 0x11f0 },
	{ 0x11f9, 0x11f9 },
	{ 0x1e00, 0x1e9b },
	{ 0x1ea0, 0x1ef9 },
	{ 0x1f00, 0x1f15 },
	{ 0x1f18, 0x1f1d },
	{ 0x1f20, 0x1f45 },
	{ 0x1f48, 0x1f4d },
	{ 0x1f50, 0x1f57 },
	{ 0x1f59, 0x1f59 },
	{ 0x1f5b, 0x1f5b },
	{ 0x1f5d, 0x1f5d },
	{ 0x1f5f, 0x1f7d },
	{ 0x1f80, 0x1fb4 },
	{ 0x1fb6, 0x1fbc },
	{ 0x1fbe, 0x1fbe },
	{ 0x1fc2, 0x1fc4 },
	{ 0x1fc6, 0x1fcc },
	{ 0x1fd0, 0x1fd3 },
	{ 0x1fd6, 0x1fdb },
	{ 0x1fe0, 0x1fec },
	{ 0x1ff2, 0x1ff4 },
	{ 0x1ff6, 0x1ffc },
	{ 0x20d0, 0x20dc },
	{ 0x20e1, 0x20e1 },
	{ 0x2126, 0x2126 },
	{ 0x212a, 0x212b },
	{ 0x212e, 0x212e },
	{ 0x2180, 0x2182 },
	{ 0x3005, 0x3005 },
	{ 0x3007, 0x3007 },
	{ 0x3021, 0x302f },
	{ 0x3031, 0x3035 },
	{ 0x3041, 0x3094 },
	{ 0x3099, 0x309a },
	{ 0x309d, 0x309e },
	{ 0x30a1, 0x30fa },
	{ 0x30fc, 0x30fe },
	{ 0x3105, 0x312c },
	{ 0x4e00, 0x9fa5 },
	{ 0xac00, 0xd7a3 },
};

#define ARRAY_END(a) ((a) + sizeof((a))/sizeof(*(a)))

static int nona_codepoint_is_in_set(U32 c, struct unicode_range const *rl,
	struct unicode_range const *rr)
{
	rr--;
	while(rl != rr) {
		/* invariant: c >= rl->first && c < rr[1].first */
		struct unicode_range const *rt = rl + ((rr-rl+1) >> 1);
		if(c >= rt->first) {
			rl = rt;
		} else {
			rr = rt-1;
		}
	}
	return c <= rl->last;
}

#define CHARATTR_NAMESTART 0x01
#define CHARATTR_NAME      0x02
#define CHARATTR_S         0x04
#define CHARATTR_ENCSTART  0x10
#define CHARATTR_ENC       0x20
#define CHARATTR_CHAR      0x80

static U8 const asciichar_attr[128] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* NUL to BEL */
	0x00, 0x84, 0x84, 0x00, 0x00, 0x84, 0x00, 0x00, /* BS to SI */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* DLE to ETB */
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, /* CAN to US */
	0x84, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, /* SP to ' */
	0x80, 0x80, 0x80, 0x80, 0x80, 0xa2, 0xa2, 0x80, /* ( to / */
	0xa2, 0xa2, 0xa2, 0xa2, 0xa2, 0xa2, 0xa2, 0xa2, /* 0 to 7 */
	0xa2, 0xa2, 0x83, 0x80, 0x80, 0x80, 0x80, 0x80, /* 8 to ? */
	0x80, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, /* @ to G */
	0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, /* H to O */
	0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, /* P to W */
	0xb3, 0xb3, 0xb3, 0x80, 0x80, 0x80, 0x80, 0xa3, /* X to _ */
	0x80, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, /* ` to g */
	0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, /* h to o */
	0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, /* p to w */
	0xb3, 0xb3, 0xb3, 0x80, 0x80, 0x80, 0x80, 0x80, /* x to DEL */
};

#define char_is_namestart(p) THX_char_is_namestart(aTHX_ p)
static int THX_char_is_namestart(pTHX_ U8 *p)
{
	U8 c0 = *p;
	if(!(c0 & 0x80)) return asciichar_attr[c0] & CHARATTR_NAMESTART;
	return nona_codepoint_is_in_set(char_unicode(p),
		uniset_namestart, ARRAY_END(uniset_namestart));
}

#define char_is_name(p) THX_char_is_name(aTHX_ p)
static int THX_char_is_name(pTHX_ U8 *p)
{
	U8 c0 = *p;
	if(!(c0 & 0x80)) return asciichar_attr[c0] & CHARATTR_NAME;
	return nona_codepoint_is_in_set(char_unicode(p),
		uniset_name, ARRAY_END(uniset_name));
}

static int char_is_s(U8 *p)
{
	U8 c0 = *p;
	if(!(c0 & 0x80)) return asciichar_attr[c0] & CHARATTR_S;
	return 0;
}

#if 0 /* unused */
static int ascii_codepoint_is_s(U8 c)
{
	return asciichar_attr[c] & CHARATTR_S;
}
#endif

static int char_is_encstart(U8 *p)
{
	U8 c0 = *p;
	if(!(c0 & 0x80)) return asciichar_attr[c0] & CHARATTR_ENCSTART;
	return 0;
}

static int char_is_enc(U8 *p)
{
	U8 c0 = *p;
	if(!(c0 & 0x80)) return asciichar_attr[c0] & CHARATTR_ENC;
	return 0;
}

static int nona_codepoint_is_char(U32 c)
{
	if(c <= 0xd7ff) return 1;
	return c >= 0xe000 && c <= 0x10ffff && (c & ~1) != 0xfffe;
}

static int codepoint_is_char(U32 c)
{
	return (c < 0x80) ? asciichar_attr[c] & CHARATTR_CHAR :
		nona_codepoint_is_char(c);
}

#define char_is_char(p) THX_char_is_char(aTHX_ p)
static int THX_char_is_char(pTHX_ U8 *p)
{
	U8 c0 = *p;
	if(!(c0 & 0x80)) return asciichar_attr[c0] & CHARATTR_CHAR;
	return nona_codepoint_is_char(char_unicode(p));
}

/*
 * XML node handling
 */

#define contentobject_twine(cobj) THX_contentobject_twine(aTHX_ cobj)
static SV *THX_contentobject_twine(pTHX_ SV *cobj)
{
	AV *twine;
	SV **item_ptr;
	if(!SvROK(cobj))
		throw_data_error("content data isn't a content chunk");
	twine = (AV*)SvRV(cobj);
	if(SvTYPE((SV*)twine) != SVt_PVAV || av_len(twine) != 0)
		throw_data_error("content data isn't a content chunk");
	if(!SvOBJECT((SV*)twine) || SvSTASH((SV*)twine) != stash_content)
		throw_data_error("content data isn't a content chunk");
	item_ptr = av_fetch(twine, 0, 0);
	if(!item_ptr) throw_data_error("content array isn't an array");
	return *item_ptr;
}

#define twine_contentobject(tref) THX_twine_contentobject(aTHX_ tref)
static SV *THX_twine_contentobject(pTHX_ SV *tref)
{
	AV *content = newAV();
	SV *cref = sv_2mortal(newRV_noinc((SV*)content));
	av_push(content, SvREFCNT_inc(tref));
	sv_bless(cref, stash_content);
	SvREADONLY_on((SV*)content);
	SvREADONLY_on(cref);
	return cref;
}

#define element_nodearray(eref) THX_element_nodearray(aTHX_ eref)
static AV *THX_element_nodearray(pTHX_ SV *eref)
{
	AV *earr;
	if(!SvROK(eref)) throw_data_error("element data isn't an element");
	earr = (AV*)SvRV(eref);
	if(SvTYPE((SV*)earr) != SVt_PVAV || av_len(earr) != 2)
		throw_data_error("element data isn't an element");
	if(!SvOBJECT((SV*)earr) || SvSTASH((SV*)earr) != stash_element)
		throw_data_error("element data isn't an element");
	return earr;
}

#define userchardata_chardata(idata) THX_userchardata_chardata(aTHX_ idata)
static SV *THX_userchardata_chardata(pTHX_ SV *idata)
{
	SV *odata;
	U8 *p, *end;
	STRLEN len;
	if(!sv_is_string(idata))
		throw_data_error("character data isn't a string");
	odata = sv_mortalcopy(idata);
	sv_utf8_upgrade(odata);
	SvREADONLY_on(odata);
	p = (U8*)SvPV(odata, len);
	end = p + len;
	while(*p != 0) {
		if(!char_is_char(p))
			throw_data_error("character data "
				"contains illegal character");
		p += UTF8SKIP(p);
	}
	if(p != end)
		throw_data_error("character data contains illegal character");
	return odata;
}

#define usertwine_twine(itref) THX_usertwine_twine(aTHX_ itref)
static SV *THX_usertwine_twine(pTHX_ SV *itref)
{
	SV *otref;
	AV *itwine, *otwine;
	I32 clen, i;
	if(!SvROK(itref)) throw_data_error("content array isn't an array");
	itwine = (AV*)SvRV(itref);
	if(SvTYPE((SV*)itwine) != SVt_PVAV || SvOBJECT((SV*)itwine))
		throw_data_error("content array isn't an array");
	clen = av_len(itwine);
	if(clen & 1) throw_data_error("content array has even length");
	otwine = newAV();
	otref = sv_2mortal(newRV_noinc((SV*)otwine));
	SvREADONLY_on(otref);
	av_extend(otwine, clen);
	for(i = 0; ; i++) {
		SV **item_ptr, *iitem, *oitem, *elem;
		item_ptr = av_fetch(itwine, i, 0);
		if(!item_ptr)
			throw_data_error("character data isn't a string");
		iitem = *item_ptr;
		if(!sv_is_string(iitem))
			throw_data_error("character data isn't a string");
		oitem = userchardata_chardata(iitem);
		av_push(otwine, SvREFCNT_inc(oitem));
		if(i++ == clen) break;
		item_ptr = av_fetch(itwine, i, 0);
		if(!item_ptr)
			throw_data_error("element data isn't an element");
		iitem = *item_ptr;
		if(!SvROK(iitem))
			throw_data_error("element data isn't an element");
		elem = SvRV(iitem);
		if(!SvOBJECT(elem) || SvSTASH(elem) != stash_element)
			throw_data_error("element data isn't an element");
		oitem = newRV_inc(elem);
		SvREADONLY_on(oitem);
		av_push(otwine, oitem);
	}
	SvREADONLY_on((SV*)otwine);
	return otref;
}

/*
 * parsing
 *
 * The parse_*() functions each parse some syntactic construct within the
 * XML grammar.  Their main input is the pointer to the start of that
 * construct in the input.  Generally they can be pointed at anything,
 * however malformed, and they will detect a syntax error if it is not the
 * item they are meant to parse.  Upon a successful parse they return, in
 * one way or another, a pointer to the end of the parsed construct and
 * any details required of the item's content.  Upon syntax error or UTF-8
 * encoding error, they throw an exception.
 *
 * The end of the input string is not explicitly indicated to the parser
 * functions.  They detect the end of input by means of the NUL terminator.
 * A NUL can also be embedded in the string, in which case parsing will
 * initially return a successful result (if that's a valid place to end),
 * and the outermost code (which has access to the SV) will detect that it
 * was an embedded NUL rather than end of input and throw an exception.
 *
 * Unlike the regular expressions in XML::Easy::Syntax, these parser
 * functions won't match their grammar production in absolutely any context.
 * They are specialised to work in the context of the complete XML grammar,
 * and are permitted to detect XML syntax errors that strictly fall outside
 * the construct being parsed.  For example, parse_contentobject() will
 * complain if it faces "]]>", rather than matching "]]" and then returning.
 *
 * All objects created by parsing are initially mortal, and have their
 * reference counts later increased when a persistent reference is made.
 * Thus on exception all the partial results are cleaned up.
 */

/* parse_s(), parse_opt_s(), parse_eq(): return the updated pointer */

#define parse_s(p) THX_parse_s(aTHX_ p)
static U8 *THX_parse_s(pTHX_ U8 *p)
{
	if(!char_is_s(p)) throw_syntax_error(p);
	do {
		p++;
	} while(char_is_s(p));
	return p;
}

static U8 *parse_opt_s(U8 *p)
{
	while(char_is_s(p))
		p++;
	return p;
}

#define parse_eq(p) THX_parse_eq(aTHX_ p)
static U8 *THX_parse_eq(pTHX_ U8 *p)
{
	p = parse_opt_s(p);
	if(*p != '=') throw_syntax_error(p);
	return parse_opt_s(p+1);
}

/* parse_name(): returns the number of octets encoding the name */

#define parse_name(p) THX_parse_name(aTHX_ p)
static STRLEN THX_parse_name(pTHX_ U8 *p)
{
	U8 *start = p;
	if(!char_is_namestart(p)) throw_syntax_error(p);
	do {
		p += UTF8SKIP(p);
	} while(char_is_name(p));
	return p - start;
}

/* parse_reference(): updates pointer in place and returns codepoint of
   referenced character */

static U8 const digit_value[256] = {
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 99, 77, 99, 99, 99, 99,
	99, 10, 11, 12, 13, 14, 15, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 10, 11, 12, 13, 14, 15, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
	99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
};

#define parse_reference(pp) THX_parse_reference(aTHX_ pp)
static U32 THX_parse_reference(pTHX_ U8 **pp)
{
	U8 *p = *pp;
	U8 c;
	U32 val;
	if(*p != '&') throw_syntax_error(p);
	c = *++p;
	if(c == '#') {
		c = *++p;
		if(c == 'x') {
			val = digit_value[*++p];
			if(val > 15) throw_syntax_error(p);
			while(1) {
				c = digit_value[*++p];
				if(c > 15) break;
				if(val & 0xf0000000)
					throw_wfc_error("invalid character "
						"in character reference");
				val = (val<<4) + c;
			}
		} else {
			val = digit_value[c];
			if(val > 9) throw_syntax_error(p);
			while(1) {
				c = digit_value[*++p];
				if(c > 9) break;
				if(val >= 100000000)
					throw_wfc_error("invalid character "
						"in character reference");
				val = val*10 + c;
			}
		}
		if(c != 77) throw_syntax_error(p);
		p++;
		if(!codepoint_is_char(val))
			throw_wfc_error("invalid character "
				"in character reference");
	} else if(c == 'l' && p[1] == 't' && p[2] == ';') {
		p += 3;
		val = '<';
	} else if(c == 'g' && p[1] == 't' && p[2] == ';') {
		p += 3;
		val = '>';
	} else if(c == 'a' && p[1] == 'm' && p[2] == 'p' && p[3] == ';') {
		p += 4;
		val = '&';
	} else if(c == 'q' && p[1] == 'u' && p[2] == 'o' && p[3] == 't' &&
			p[4] == ';') {
		p += 5;
		val = '"';
	} else if(c == 'a' && p[1] == 'p' && p[2] == 'o' && p[3] == 's' &&
			p[4] == ';') {
		p += 5;
		val = '\'';
	} else {
		p += parse_name(p);
		if(*p != ';') throw_syntax_error(p);
		throw_wfc_error("reference to undeclared entity");
	}
	*pp = p;
	return val;
}

/* parse_chars(): parses literal characters and references, for use in
   ordinary content, CDATA, and attribute values; guarantees to return only
   when facing correct terminator; returns updated pointer, appends
   characters to supplied SV */

#define CHARDATA_AMP_REF     0x01
#define CHARDATA_LT_ERR      0x02
#define CHARDATA_S_LINEAR    0x04
#define CHARDATA_RBRBGT_ERR  0x08
#define CHARDATA_NUL_END     0x10

#define parse_chars(p, value, endc, flags) \
	THX_parse_chars(aTHX_ p, value, endc, flags)
static U8 *THX_parse_chars(pTHX_ U8 *p, SV *value, U8 endc, U32 flags)
{
	U8 *lstart = p;
	while(1) {
		U8 c = *p;
		if(c < 0x80) {
			U8 *lend = p;
			U32 val;
			if(c == endc && (c != ']' ||
					 (p[1] == ']' && p[2] == '>')))
				break;
			if(c < 0x20) {
				if(c == 0 && (flags & CHARDATA_NUL_END)) {
					break;
				} else if(c == 0x9 || c == 0xa) {
					val = (flags & CHARDATA_S_LINEAR) ?
						0x20 : 0;
				} else if(c == 0xd) {
					if(p[1] == 0xa) p++;
					val = (flags & CHARDATA_S_LINEAR) ?
						0x20 : 0xa;
				} else
					throw_syntax_error(p);
				p++;
			} else if(c == '&' && (flags & CHARDATA_AMP_REF)) {
				val = parse_reference(&p);
			} else if((c == '<' && (flags & CHARDATA_LT_ERR)) ||
					(c == ']' &&
					 (flags & CHARDATA_RBRBGT_ERR) &&
					 p[1] == ']' && p[2] == '>')) {
				throw_syntax_error(p);
			} else {
				val = 0;
				p++;
			}
			if(val) {
				STRLEN vlen;
				U8 *vstart, *voldend, *vnewend;
				if(lstart != lend)
					sv_catpvn_nomg(value, (char*)lstart,
						lend-lstart);
				vlen = SvCUR(value);
				vstart = (U8*)SvGROW(value, vlen+4+1);
				voldend = vstart + vlen;
				vnewend = uvuni_to_utf8_flags(voldend, val,
						UNICODE_ALLOW_ANY);
				*vnewend = 0;
				SvCUR_set(value, vnewend - vstart);
				lstart = p;
			}
		} else {
			if(!char_is_char(p)) throw_syntax_error(p);
			p += UTF8SKIP(p);
		}
	}
	if(lstart != p) sv_catpvn_nomg(value, (char*)lstart, p-lstart);
	return p;
}

/* parse_comment(), parse_pi(): return updated pointer */

#define parse_comment(p) THX_parse_comment(aTHX_ p)
static U8 *THX_parse_comment(pTHX_ U8 *p)
{
	if(!(p[0] == '<' && p[1] == '!' && p[2] == '-' && p[3] == '-'))
		throw_syntax_error(p);
	p += 4;
	while(1) {
		if(*p == '-') {
			if(*++p == '-') break;
		}
		if(!char_is_char(p)) throw_syntax_error(p);
		p += UTF8SKIP(p);
	}
	if(p[1] != '>') throw_syntax_error(p);
	return p + 2;
}

#define parse_pi(p) THX_parse_pi(aTHX_ p)
static U8 *THX_parse_pi(pTHX_ U8 *p)
{
	STRLEN tgtlen;
	if(!(p[0] == '<' && p[1] == '?')) throw_syntax_error(p);
	p += 2;
	tgtlen = parse_name(p);
	if(tgtlen == 3 && (p[0] & ~0x20) == 'X' &&
			(p[1] & ~0x20) == 'M' &&
			(p[2] & ~0x20) == 'L')
		throw_syntax_error(p);
	p += tgtlen;
	if(!(p[0] == '?' && p[1] == '>')) {
		if(!char_is_s(p)) throw_syntax_error(p);
		p++;
		while(!(p[0] == '?' && p[1] == '>')) {
			if(!char_is_char(p)) throw_syntax_error(p);
			p += UTF8SKIP(p);
		}
	}
	return p + 2;
}

/* parse_twine(): parses content, guarantees to return only when
   facing the correct terminator ("</" or NUL); updates pointer in place,
   returns reference to AV which alternates character data and element
   objects */

#define CONTENT_TOPLEVEL  (CHARDATA_AMP_REF|CHARDATA_RBRBGT_ERR| \
			   CHARDATA_NUL_END)
#define CONTENT_INSIDE    (CHARDATA_AMP_REF|CHARDATA_RBRBGT_ERR)

#define parse_element(pp) THX_parse_element(aTHX_ pp)
static SV *THX_parse_element(pTHX_ U8 **pp);

#define parse_twine(pp, chardata_flags) \
	THX_parse_twine(aTHX_ pp, chardata_flags)
static SV *THX_parse_twine(pTHX_ U8 **pp, U32 chardata_flags)
{
	U8 *p = *pp;
	SV *chardata = newSVpvs("");
	AV *twine = newAV();
	SV *tref = sv_2mortal(newRV_noinc((SV*)twine));
	SvUTF8_on(chardata);
	av_push(twine, chardata);
	SvREADONLY_on(tref);
	while(1) {
		U8 c = *p;
		if(c != '<') {
			p = parse_chars(p, chardata, '<', chardata_flags);
			if((chardata_flags & CHARDATA_NUL_END) && *p == 0)
				break;
		}
		c = p[1];
		if(c == '/' && !(chardata_flags & CHARDATA_NUL_END)) break;
		if(c == '!') {
			c = p[2];
			if(c == '-') {
				p = parse_comment(p);
			} else if(c == '[' && p[3] == 'C' &&
					p[4] == 'D' && p[5] == 'A' &&
					p[6] == 'T' && p[7] == 'A' &&
					p[8] == '[') {
				p = parse_chars(p+9, chardata, ']', 0) + 3;
			} else
				throw_syntax_error(p);
		} else if(c == '?') {
			p = parse_pi(p);
		} else {
			SvREADONLY_on(chardata);
			av_push(twine, SvREFCNT_inc(parse_element(&p)));
			chardata = newSVpvs("");
			SvUTF8_on(chardata);
			av_push(twine, chardata);
		}
	}
	*pp = p;
	SvREADONLY_on(chardata);
	SvREADONLY_on((SV*)twine);
	return tref;
}

/* parse_contentobject(): parses content, guarantees to return only when
   facing the correct terminator ("</" or NUL); updates pointer in place,
   returns reference to AV blessed into XML::Easy::Content (sole element
   is a reference to an AV which alternates character data and element
   objects) */

#define parse_contentobject(p, chardata_flags) \
	THX_parse_contentobject(aTHX_ p, chardata_flags)
static SV *THX_parse_contentobject(pTHX_ U8 **pp, U32 chardata_flags)
{
	return twine_contentobject(parse_twine(pp, chardata_flags));
}

/* parse_element(): updates pointer in place, returns reference to AV blessed
   into XML::Easy::Element (first element is an SV containing the element
   type name, the second element is a reference to an HV containing the
   attributes, and the third element is a reference to the content object) */

static SV *THX_parse_element(pTHX_ U8 **pp)
{
	U8 *p = *pp;
	U8 *typename_start, *namestart;
	STRLEN typename_len, namelen;
	SV *typename;
	HV *attrs;
	SV *aref;
	AV *element;
	SV *eref;
	U8 c;
	if(*p != '<') throw_syntax_error(p);
	typename_start = ++p;
	typename_len = parse_name(p);
	p += typename_len;
	typename = newSVpvn((char*)typename_start, typename_len);
	SvUTF8_on(typename);
	SvREADONLY_on(typename);
	element = newAV();
	av_extend(element, 2);
	eref = sv_2mortal(newRV_noinc((SV*)element));
	av_push(element, typename);
	attrs = newHV();
	aref = newRV_noinc((SV*)attrs);
	SvREADONLY_on(aref);
	av_push(element, aref);
	while(1) {
		SV *attval;
		c = *p;
		if(c == '>' || c == '/') break;
		p = parse_s(p);
		c = *p;
		if(c == '>' || c == '/') break;
		namelen = parse_name(p);
		namestart = p;
		p += namelen;
		if(hv_exists(attrs, (char*)namestart, -namelen))
			throw_wfc_error("duplicate attribute");
		p = parse_eq(p);
		c = *p;
		if(c != '"' && c != '\'') throw_syntax_error(p);
		attval = sv_2mortal(newSVpvs(""));
		SvUTF8_on(attval);
		p = parse_chars(p+1, attval, c,
			CHARDATA_AMP_REF|CHARDATA_LT_ERR|CHARDATA_S_LINEAR)
				+ 1;
		SvREADONLY_on(attval);
		if(!hv_store(attrs, (char*)namestart, -namelen,
				SvREFCNT_inc(attval), 0))
			SvREFCNT_dec(attval);
	}
	SvREADONLY_on((SV*)attrs);
	if(c == '/') {
		if(*++p != '>') throw_syntax_error(p);
		av_push(element, SvREFCNT_inc(empty_contentobject));
	} else {
		p++;
		av_push(element,
			SvREFCNT_inc(
				parse_contentobject(&p, CONTENT_INSIDE)));
		p += 2;
		namelen = parse_name(p);
		if(namelen != typename_len ||
				memcmp(p, typename_start, namelen))
			throw_wfc_error("mismatched tags");
		p += namelen;
		p = parse_opt_s(p);
		if(*p != '>') throw_syntax_error(p);
	}
	*pp = p + 1;
	sv_bless(eref, stash_element);
	SvREADONLY_on((SV*)element);
	SvREADONLY_on(eref);
	return eref;
}

/* parse_opt_xmldecl(): parses optional XML declaration or text declaration,
   returns updated pointer */

#define XMLDECL_VERSION     0x01
#define XMLDECL_ENCODING    0x02
#define XMLDECL_STANDALONE  0x03

#define parse_opt_xmldecl(p, allow, require) \
	THX_parse_opt_xmldecl(aTHX_ p, allow, require)
static U8 *THX_parse_opt_xmldecl(pTHX_ U8 *p, U32 allow, U32 require)
{
#if 0 /* unused, because throw_syntax_error() ignores its argument */
	U8 *start = p;
#endif
	U32 found = 0;
	if(!(p[0] == '<' && p[1] == '?' && p[2] == 'x' && p[3] == 'm' &&
			p[4] == 'l' && p[5] <= 0x20))
		return p;
	p += 5;
	if(*p == '?') goto enddecl;
	p = parse_s(p);
	if(*p == '?') goto enddecl;
	if(p[0] == 'v' && p[1] == 'e' && p[2] == 'r' && p[3] == 's' &&
			p[4] == 'i' && p[5] == 'o' && p[6] == 'n') {
		U8 q;
		p = parse_eq(p + 7);
		q = p[0];
		if(q != '"' && q != '\'') throw_syntax_error(start);
		if(!(p[1] == '1' && p[2] == '.' && p[3] == '0' && p[4] == q))
			throw_syntax_error(start);
		p += 5;
		found |= XMLDECL_VERSION;
		if(*p == '?') goto enddecl;
		p = parse_s(p);
		if(*p == '?') goto enddecl;
	}
	if(p[0] == 'e' && p[1] == 'n' && p[2] == 'c' && p[3] == 'o' &&
			p[4] == 'd' && p[5] == 'i' && p[6] == 'n' &&
			p[7] == 'g') {
		U8 q;
		p = parse_eq(p + 8);
		q = *p;
		if(q != '"' && q != '\'') throw_syntax_error(start);
		p++;
		if(!char_is_encstart(p)) throw_syntax_error(start);
		do {
			p++;
		} while(char_is_enc(p));
		if(*p != q) throw_syntax_error(start);
		p++;
		found |= XMLDECL_ENCODING;
		if(*p == '?') goto enddecl;
		p = parse_s(p);
		if(*p == '?') goto enddecl;
	}
	if(p[0] == 's' && p[1] == 't' && p[2] == 'a' && p[3] == 'n' &&
			p[4] == 'd' && p[5] == 'a' && p[6] == 'l' &&
			p[7] == 'o' && p[8] == 'n' && p[9] == 'e') {
		U8 q;
		p = parse_eq(p + 10);
		q = p[0];
		if(q != '"' && q != '\'') throw_syntax_error(start);
		if(!((p[1] == 'y' && p[2] == 'e' && p[3] == 's' && p[4] == q)
			|| (p[1] == 'n' && p[2] == 'o' && p[3] == q)))
			throw_syntax_error(start);
		p += p[1] == 'y' ? 5 : 4;
		found |= XMLDECL_STANDALONE;
		if(*p == '?') goto enddecl;
		p = parse_s(p);
		if(*p == '?') goto enddecl;
	}
	throw_syntax_error(start);
	enddecl:
	if(!(p[1] == '>' && !(found & ~allow) && !(require & ~found)))
		throw_syntax_error(start);
	return p + 2;
}

/* parse_misc_seq(): returns updated pointer */

#define parse_misc_seq(p) THX_parse_misc_seq(aTHX_ p)
static U8 *THX_parse_misc_seq(pTHX_ U8 *p)
{
	while(1) {
		U8 c = p[0];
		if(c == 0) break;
		if(c == '<') {
			c = p[1];
			if(c == '!') {
				p = parse_comment(p);
			} else if(c == '?') {
				p = parse_pi(p);
			} else {
				break;
			}
		} else {
			p = parse_s(p);
		}
	}
	return p;
}

/*
 * serialisation
 *
 * The serialise_*() functions each serialise some syntactic construct
 * within the XML grammar.  Their main input is an SV to which they append
 * the textual form of the item in question.
 */

#define check_encname(enc) THX_check_encname(aTHX_ enc)
static void THX_check_encname(pTHX_ SV *enc)
{
	U8 *p, *end;
	STRLEN len;
	if(!sv_is_string(enc))
		throw_data_error("encoding name isn't a string");
	p = (U8*)SvPV(enc, len);
	if(len == 0) throw_data_error("illegal encoding name");
	end = p + len;
	if(!char_is_encstart(p)) throw_data_error("illegal encoding name");
	while(1) {
		p++;
		if(p == end) return;
		if(!char_is_enc(p)) throw_data_error("illegal encoding name");
	}
}

#define is_name(p, len) THX_is_name(aTHX_ p, len)
static int THX_is_name(pTHX_ U8 *p, STRLEN len)
{
	U8 *end = p + len;
	if(!char_is_namestart(p)) return 0;
	do {
		p += UTF8SKIP(p);
		if(p == end) return 1;
	} while(char_is_name(p));
	return 0;
}

static U8 const hexdig[16] = "0123456789abcdef";

#define serialise_chardata(out, data) THX_serialise_chardata(aTHX_ out, data)
static void THX_serialise_chardata(pTHX_ SV *out, SV *data)
{
	STRLEN datalen;
	U8 *datastart, *dataend, *p, *lstart;
	if(!sv_is_string(data))
		throw_data_error("character data isn't a string");
	data = upgrade_sv(data);
	datastart = (U8*)SvPV(data, datalen);
	dataend = datastart + datalen;
	lstart = p = datastart;
	while(1) {
		U8 c = *p;
		if(c == 0) break;
		if(c == 0xd || c == '<' || c == '&' ||
				(c == '>' && p-lstart >= 2 &&
				 p[-1] == ']' && p[-2] == ']')) {
			U8 refbuf[6] = "&#xXX;";
			if(lstart != p)
				sv_catpvn_nomg(out, (char*)lstart, p-lstart);
			refbuf[3] = hexdig[c >> 4];
			refbuf[4] = hexdig[c & 0xf];
			sv_catpvn(out, (char*)refbuf, 6);
			lstart = ++p;
		} else {
			if(!char_is_char(p))
				throw_data_error("character data contains "
						 "illegal character");
			p += UTF8SKIP(p);
		}
	}
	if(p != dataend)
		throw_data_error("character data contains illegal character");
	if(lstart != p) sv_catpvn_nomg(out, (char*)lstart, p-lstart);
}

#define serialise_element(out, elem) THX_serialise_element(aTHX_ out, elem)
static void THX_serialise_element(pTHX_ SV *out, SV *elem);

#define serialise_twine(out, tref) THX_serialise_twine(aTHX_ out, tref)
static void THX_serialise_twine(pTHX_ SV *out, SV *tref)
{
	AV *twine;
	I32 clen, i;
	SV **item_ptr;
	if(!SvROK(tref)) throw_data_error("content array isn't an array");
	twine = (AV*)SvRV(tref);
	if(SvTYPE((SV*)twine) != SVt_PVAV || SvOBJECT((SV*)twine))
		throw_data_error("content array isn't an array");
	clen = av_len(twine);
	if(clen & 1) throw_data_error("content array has even length");
	item_ptr = av_fetch(twine, 0, 0);
	if(!item_ptr) throw_data_error("character data isn't a string");
	serialise_chardata(out, *item_ptr);
	for(i = 0; i != clen; ) {
		item_ptr = av_fetch(twine, ++i, 0);
		if(!item_ptr)
			throw_data_error("element data isn't an element");
		serialise_element(out, *item_ptr);
		item_ptr = av_fetch(twine, ++i, 0);
		if(!item_ptr)
			throw_data_error("character data isn't a string");
		serialise_chardata(out, *item_ptr);
	}
}

#define serialise_contentobject(out, cref) \
	THX_serialise_contentobject(aTHX_ out, cref)
static void THX_serialise_contentobject(pTHX_ SV *out, SV *cref)
{
	serialise_twine(out, contentobject_twine(cref));
}

#define serialise_eithercontent(out, cref) \
	THX_serialise_eithercontent(aTHX_ out, cref)
static void THX_serialise_eithercontent(pTHX_ SV *out, SV *cref)
{
	SV *tgt;
	if(SvROK(cref) && (tgt = SvRV(cref), SvTYPE(tgt) == SVt_PVAV) &&
			!SvOBJECT(tgt)) {
		serialise_twine(out, cref);
	} else {
		serialise_contentobject(out, cref);
	}
}

#define twine_is_empty(tref) THX_twine_is_empty(aTHX_ tref)
static int THX_twine_is_empty(pTHX_ SV *tref)
{
	AV *twine;
	SV **item_ptr;
	SV *item;
	if(!SvROK(tref)) return 0;
	twine = (AV*)SvRV(tref);
	if(SvTYPE((SV*)twine) != SVt_PVAV || SvOBJECT((SV*)twine)) return 0;
	if(av_len(twine) != 0) return 0;
	item_ptr = av_fetch(twine, 0, 0);
	if(!item_ptr) return 0;
	item = *item_ptr;
	if(!SvOK(item) || SvROK(item)) return 0;
	return SvPOK(item) && SvCUR(item) == 0;
}

#define content_is_empty(cref) THX_content_is_empty(aTHX_ cref)
static int THX_content_is_empty(pTHX_ SV *cref)
{
	AV *twine;
	SV **item_ptr;
	if(!SvROK(cref)) return 0;
	twine = (AV*)SvRV(cref);
	if(SvTYPE((SV*)twine) != SVt_PVAV || av_len(twine) != 0) return 0;
	if(!SvOBJECT((SV*)twine) || SvSTASH((SV*)twine) != stash_content)
		return 0;
	item_ptr = av_fetch(twine, 0, 0);
	if(!item_ptr) return 0;
	return twine_is_empty(*item_ptr);
}

#define serialise_attvalue(out, data) THX_serialise_attvalue(aTHX_ out, data)
static void THX_serialise_attvalue(pTHX_ SV *out, SV *data)
{
	STRLEN datalen;
	U8 *datastart, *dataend, *p, *lstart;
	if(!sv_is_string(data))
		throw_data_error("character data isn't a string");
	data = upgrade_sv(data);
	datastart = (U8*)SvPV(data, datalen);
	dataend = datastart + datalen;
	lstart = p = datastart;
	while(1) {
		U8 c = *p;
		if(c == 0) break;
		if(c == 0x9 || c == 0xa || c == 0xd || c == '<' || c == '&' ||
				c == '"') {
			U8 refbuf[6] = "&#xXX;";
			if(lstart != p)
				sv_catpvn_nomg(out, (char*)lstart, p-lstart);
			refbuf[3] = hexdig[c >> 4];
			refbuf[4] = hexdig[c & 0xf];
			sv_catpvn(out, (char*)refbuf, 6);
			lstart = ++p;
		} else {
			if(!char_is_char(p))
				throw_data_error("character data contains "
						 "illegal character");
			p += UTF8SKIP(p);
		}
	}
	if(p != dataend)
		throw_data_error("character data contains illegal character");
	if(lstart != p) sv_catpvn_nomg(out, (char*)lstart, p-lstart);
}

static void THX_serialise_element(pTHX_ SV *out, SV *eref)
{
	AV *earr;
	SV **item_ptr;
	SV *typename, *attrs, *content;
	HV *ahash;
	U8 *typename_start;
	STRLEN typename_len;
	U32 nattrs;
	earr = element_nodearray(eref);
	sv_catpvs_nomg(out, "<");
	item_ptr = av_fetch(earr, 0, 0);
	if(!item_ptr) throw_data_error("element type name isn't a string");
	typename = *item_ptr;
	if(!sv_is_string(typename))
		throw_data_error("element type name isn't a string");
	typename = upgrade_sv(typename);
	typename_start = (U8*)SvPV(typename, typename_len);
	if(!is_name(typename_start, typename_len))
		throw_data_error("illegal element type name");
	sv_catpvn_nomg(out, (char*)typename_start, typename_len);
	item_ptr = av_fetch(earr, 1, 0);
	if(!item_ptr) throw_data_error("attribute hash isn't a hash");
	attrs = *item_ptr;
	if(!SvROK(attrs)) throw_data_error("attribute hash isn't a hash");
	ahash = (HV*)SvRV(attrs);
	if(SvTYPE((SV*)ahash) != SVt_PVHV || SvOBJECT((SV*)ahash))
		throw_data_error("attribute hash isn't a hash");
	nattrs = hv_iterinit(ahash);
	if(nattrs != 0) {
		if(nattrs == 1) {
			STRLEN klen;
			U8 *key;
			HE *ent = hv_iternext(ahash);
			sv_catpvs_nomg(out, " ");
			key = (U8*)HePV(ent, klen);
			if(!HeKUTF8(ent)) upgrade_latin1_pvn(&key, &klen);
			if(!is_name(key, klen))
				throw_data_error("illegal attribute name");
			sv_catpvn_nomg(out, (char*)key, klen);
			sv_catpvs_nomg(out, "=\"");
			serialise_attvalue(out, HeVAL(ent));
			sv_catpvs_nomg(out, "\"");
		} else {
			U32 i;
			AV *keys = newAV();
			sv_2mortal((SV*)keys);
			av_extend(keys, nattrs-1);
			for(i = nattrs; i--; ) {
				SV *keysv = upgrade_sv(
					hv_iterkeysv(hv_iternext(ahash)));
				SvREFCNT_inc(keysv);
				av_push(keys, keysv);
			}
			sortsv(AvARRAY(keys), nattrs, Perl_sv_cmp);
			for(i = 0; i != nattrs; i++) {
				SV *keysv;
				STRLEN klen;
				U8 *key;
				sv_catpvs_nomg(out, " ");
				keysv = *av_fetch(keys, i, 0);
				key = (U8*)SvPV(keysv, klen);
				if(!is_name(key, klen))
					throw_data_error("illegal attribute "
							 "name");
				sv_catpvn_nomg(out, (char*)key, klen);
				sv_catpvs_nomg(out, "=\"");
				serialise_attvalue(out,
					*hv_fetch(ahash, (char*)key, -klen,
						0));
				sv_catpvs_nomg(out, "\"");
			}
		}
	}
	item_ptr = av_fetch(earr, 2, 0);
	if(!item_ptr) throw_data_error("content data isn't a content chunk");
	content = *item_ptr;
	if(content_is_empty(content)) {
		sv_catpvs_nomg(out, "/>");
	} else {
		sv_catpvs_nomg(out, ">");
		serialise_contentobject(out, content);
		sv_catpvs_nomg(out, "</");
		sv_catpvn_nomg(out, (char*)typename_start, typename_len);
		sv_catpvs_nomg(out, ">");
	}
}

MODULE = XML::Easy PACKAGE = XML::Easy::Content

PROTOTYPES: DISABLE

BOOT:
	/* stash stashes */
	stash_content = gv_stashpvs("XML::Easy::Content", 1);
	stash_element = gv_stashpvs("XML::Easy::Element", 1);
	/* stash shared empty-content object */
	{
		SV *chardata;
		AV *twine;
		SV *tref;
		AV *content;
		SV *cref;
		chardata = newSVpvs("");
		SvREADONLY_on(chardata);
		twine = newAV();
		av_push(twine, chardata);
		SvREADONLY_on((SV*)twine);
		tref = newRV_noinc((SV*)twine);
		SvREADONLY_on(tref);
		content = newAV();
		av_push(content, tref);
		cref = newRV_noinc((SV*)content);
		sv_bless(cref, stash_content);
		SvREADONLY_on((SV*)content);
		SvREADONLY_on(cref);
		empty_contentobject = cref;
	}

SV *
new(SV *classname, SV *tref)
CODE:
	PERL_UNUSED_VAR(classname);
	RETVAL = twine_contentobject(usertwine_twine(tref));
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
twine(SV *cref)
CODE:
	RETVAL = contentobject_twine(cref);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

MODULE = XML::Easy PACKAGE = XML::Easy::Element

SV *
new(SV *classname, SV *type_name, SV *attrs, SV *content)
PREINIT:
	U8 *p;
	STRLEN len;
	HV *iahash, *oahash;
	U32 nattrs;
	SV *tgt;
	AV *earr;
CODE:
	PERL_UNUSED_VAR(classname);
	if(!sv_is_string(type_name))
		throw_data_error("element type name isn't a string");
	type_name = sv_mortalcopy(type_name);
	sv_utf8_upgrade(type_name);
	SvREADONLY_on(type_name);
	p = (U8*)SvPV(type_name, len);
	if(!is_name(p, len)) throw_data_error("illegal element type name");
	if(!SvROK(attrs)) throw_data_error("attribute hash isn't a hash");
	iahash = (HV*)SvRV(attrs);
	if(SvTYPE((SV*)iahash) != SVt_PVHV || SvOBJECT((SV*)iahash))
		throw_data_error("attribute hash isn't a hash");
	oahash = newHV();
	attrs = sv_2mortal(newRV_noinc((SV*)oahash));
	SvREADONLY_on(attrs);
	nattrs = hv_iterinit(iahash);
	if(nattrs != 0) {
		if(nattrs == 1) {
			STRLEN klen;
			U8 *key;
			HE *ent = hv_iternext(iahash);
			key = (U8*)HePV(ent, klen);
			if(!HeKUTF8(ent)) upgrade_latin1_pvn(&key, &klen);
			if(!is_name(key, klen))
				throw_data_error("illegal attribute name");
			tgt = userchardata_chardata(HeVAL(ent));
			if(!hv_store(oahash, (char *)key, -klen,
					SvREFCNT_inc(tgt), 0))
				SvREFCNT_dec(tgt);
		} else {
			U32 i;
			AV *keys = newAV();
			sv_2mortal((SV*)keys);
			av_extend(keys, nattrs-1);
			for(i = nattrs; i--; ) {
				SV *keysv = upgrade_sv(
					hv_iterkeysv(hv_iternext(iahash)));
				SvREFCNT_inc(keysv);
				av_push(keys, keysv);
			}
			sortsv(AvARRAY(keys), nattrs, Perl_sv_cmp);
			for(i = 0; i != nattrs; i++) {
				SV *keysv;
				STRLEN klen;
				U8 *key;
				keysv = *av_fetch(keys, i, 0);
				key = (U8*)SvPV(keysv, klen);
				if(!is_name(key, klen))
					throw_data_error("illegal attribute "
							 "name");
				tgt = *hv_fetch(iahash, (char*)key, -klen, 0);
				tgt = userchardata_chardata(tgt);
				if(!hv_store(oahash, (char *)key, -klen,
						SvREFCNT_inc(tgt), 0))
					SvREFCNT_dec(tgt);
			}
		}
	}
	SvREADONLY_on((SV*)oahash);
	if(!SvROK(content))
		throw_data_error("content data isn't a content chunk");
	tgt = SvRV(content);
	if(!SvOBJECT(tgt) && SvTYPE(tgt) == SVt_PVAV) {
		content = twine_contentobject(usertwine_twine(content));
	} else if(SvOBJECT(tgt) && SvSTASH(tgt) == stash_content) {
		content = sv_2mortal(newRV_inc(tgt));
		SvREADONLY_on(content);
	} else {
		throw_data_error("content data isn't a content chunk");
	}
	earr = newAV();
	av_extend(earr, 2);
	av_push(earr, SvREFCNT_inc(type_name));
	av_push(earr, SvREFCNT_inc(attrs));
	av_push(earr, SvREFCNT_inc(content));
	RETVAL = newRV_noinc((SV*)earr);
	sv_bless(RETVAL, stash_element);
	SvREADONLY_on(earr);
	SvREADONLY_on(RETVAL);
OUTPUT:
	RETVAL

SV *
type_name(SV *eref)
PREINIT:
	AV *earr;
	SV **item_ptr;
CODE:
	earr = element_nodearray(eref);
	item_ptr = av_fetch(earr, 0, 0);
	if(!item_ptr) throw_data_error("element type name isn't a string");
	RETVAL = SvREFCNT_inc(*item_ptr);
OUTPUT:
	RETVAL

SV *
attributes(SV *eref)
PREINIT:
	AV *earr;
	SV **item_ptr;
CODE:
	earr = element_nodearray(eref);
	item_ptr = av_fetch(earr, 1, 0);
	if(!item_ptr) throw_data_error("attribute hash isn't a hash");
	RETVAL = SvREFCNT_inc(*item_ptr);
OUTPUT:
	RETVAL

SV *
attribute(SV *eref, SV *attrname_sv)
PREINIT:
	U8 *attrname;
	STRLEN attrname_len;
	AV *earr;
	HV *ahash;
	SV **item_ptr, *attrs;
CODE:
	if(!sv_is_string(attrname_sv))
		throw_data_error("attribute name isn't a string");
	attrname_sv = upgrade_sv(attrname_sv);
	attrname = (U8*)SvPV(attrname_sv, attrname_len);
	if(!is_name(attrname, attrname_len))
		throw_data_error("illegal attribute name");
	earr = element_nodearray(eref);
	item_ptr = av_fetch(earr, 1, 0);
	if(!item_ptr) throw_data_error("attribute hash isn't a hash");
	attrs = *item_ptr;
	if(!SvROK(attrs)) throw_data_error("attribute hash isn't a hash");
	ahash = (HV*)SvRV(attrs);
	if(SvTYPE((SV*)ahash) != SVt_PVHV || SvOBJECT((SV*)ahash))
		throw_data_error("attribute hash isn't a hash");
	if(hv_exists(ahash, (char *)attrname, -attrname_len)) {
		item_ptr = hv_fetch(ahash, (char *)attrname, -attrname_len, 0);
		RETVAL = item_ptr ? SvREFCNT_inc(*item_ptr) : &PL_sv_undef;
	} else {
		RETVAL = &PL_sv_undef;
	}
OUTPUT:
	RETVAL

SV *
content_object(SV *eref)
PREINIT:
	AV *earr;
	SV **item_ptr;
CODE:
	earr = element_nodearray(eref);
	item_ptr = av_fetch(earr, 2, 0);
	if(!item_ptr) throw_data_error("content data isn't a content chunk");
	RETVAL = SvREFCNT_inc(*item_ptr);
OUTPUT:
	RETVAL

SV *
content_twine(SV *eref)
PREINIT:
	AV *earr;
	SV **item_ptr;
CODE:
	earr = element_nodearray(eref);
	item_ptr = av_fetch(earr, 2, 0);
	if(!item_ptr) throw_data_error("content data isn't a content chunk");
	RETVAL = contentobject_twine(*item_ptr);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

MODULE = XML::Easy PACKAGE = XML::Easy::Text

SV *
xml10_read_content_object(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	RETVAL = parse_contentobject(&p, CONTENT_TOPLEVEL);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_read_content_twine(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	RETVAL = parse_twine(&p, CONTENT_TOPLEVEL);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_read_element(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	RETVAL = parse_element(&p);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_read_document(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	p = parse_opt_xmldecl(p,
		XMLDECL_VERSION|XMLDECL_ENCODING|XMLDECL_STANDALONE,
		XMLDECL_VERSION);
	p = parse_misc_seq(p);
	RETVAL = parse_element(&p);
	p = parse_misc_seq(p);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_read_extparsedent_object(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	p = parse_opt_xmldecl(p, XMLDECL_VERSION|XMLDECL_ENCODING,
		XMLDECL_ENCODING);
	RETVAL = parse_contentobject(&p, CONTENT_TOPLEVEL);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_read_extparsedent_twine(SV *text_sv)
PROTOTYPE: $
PREINIT:
	STRLEN text_len;
	U8 *p, *end;
CODE:
	if(!sv_is_string(text_sv)) throw_data_error("text isn't a string");
	text_sv = upgrade_sv(text_sv);
	p = (U8*)SvPV(text_sv, text_len);
	end = p + text_len;
	p = parse_opt_xmldecl(p, XMLDECL_VERSION|XMLDECL_ENCODING,
		XMLDECL_ENCODING);
	RETVAL = parse_twine(&p, CONTENT_TOPLEVEL);
	if(p != end) throw_syntax_error(p);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_write_content(SV *cont)
PROTOTYPE: $
CODE:
	RETVAL = sv_2mortal(newSVpvs(""));
	SvUTF8_on(RETVAL);
	serialise_eithercontent(RETVAL, cont);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_write_element(SV *elem)
PROTOTYPE: $
CODE:
	RETVAL = sv_2mortal(newSVpvs(""));
	SvUTF8_on(RETVAL);
	serialise_element(RETVAL, elem);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_write_document(SV *elem, SV *enc = &PL_sv_undef)
PROTOTYPE: $;$
CODE:
	RETVAL = sv_2mortal(newSVpvs("<?xml version=\"1.0\""));
	SvUTF8_on(RETVAL);
	if(SvOK(enc) || SvTYPE(enc) == SVt_PVGV) {
		check_encname(enc);
		sv_catpvs_nomg(RETVAL, " encoding=\"");
		sv_catsv_nomg(RETVAL, enc);
		sv_catpvs_nomg(RETVAL, "\" standalone=\"yes\"?>\n");
	} else {
		sv_catpvs_nomg(RETVAL, " standalone=\"yes\"?>\n");
	}
	serialise_element(RETVAL, elem);
	sv_catpvs_nomg(RETVAL, "\n");
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL

SV *
xml10_write_extparsedent(SV *cont, SV *enc = &PL_sv_undef)
PROTOTYPE: $;$
CODE:
	RETVAL = sv_2mortal(newSVpvs(""));
	SvUTF8_on(RETVAL);
	if(SvOK(enc) || SvTYPE(enc) == SVt_PVGV) {
		check_encname(enc);
		sv_catpvs_nomg(RETVAL, "<?xml encoding=\"");
		sv_catsv_nomg(RETVAL, enc);
		sv_catpvs_nomg(RETVAL, "\"?>");
	}
	serialise_eithercontent(RETVAL, cont);
	SvREFCNT_inc(RETVAL);
OUTPUT:
	RETVAL
