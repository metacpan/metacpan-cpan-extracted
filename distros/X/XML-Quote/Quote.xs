/* $Version: release/perl/base/XML-Quote/Quote.xs,v 1.12 2003/01/31 09:16:58 godegisel Exp $ */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

#define XQ_DEBUG	0

#ifdef SVf_UTF8
#define XML_Util_UTF8
#endif

//////////////////////////////////////////////////////////////////////////////

// '"'==0x22	&quot;	5
// '&'==0x26	&amp;	4
// '\''==0x27	&apos;	5
// '<'==0x3C	&lt;	3
// '>'==0x3E	&gt;	3

static STRLEN XQ_quote_add[] = {
// 0x00 - 0x0F
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
// 0x10 - 0x1F
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
// 0x20 - 0x2F
0,0,5,0,0,0,4,5,0,0,0,0,0,0,0,0,
// 0x30 - 0x3F
0,0,0,0,0,0,0,0,0,0,0,0,3,0,3,0,
};

static STRLEN XQ_quote_add_min[] = {
// 0x00 - 0x0F
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
// 0x10 - 0x1F
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
// 0x20 - 0x2F
0,0,5,0,0,0,4,0,0,0,0,0,0,0,0,0,
// 0x30 - 0x3F
0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,
};

//////////////////////////////////////////////////////////////////////////////

static SV *
xml_quote(SV * srcSV)	{
	SV      * dstSV;
	unsigned char	* src, * src2;
	unsigned char	* dst;
	unsigned char c;
	STRLEN  src_len, src_len2, dst_len, offset;

	src=SvPV(srcSV, src_len);	//length without trailing \0

#if XQ_DEBUG
	warn("source=%s\n",src);
	warn("src=%p\n",src);
#endif

	dst_len=src_len;
	src2=src;
	src_len2=src_len;

#if XQ_DEBUG
	warn("source length=%i\n",src_len);
#endif

	// calculate target string length
	while(src_len2--)	{
		c=*src2++;
		if(c < 0x3F && (offset=XQ_quote_add[c]) )	{
#if XQ_DEBUG
			warn("add offset=%i [symbol=%i]\n",offset,c);
#endif
			dst_len+=offset;
		}
/* table lookup is faster (or not?...)
		if(c > 0x3E || c < 0x22)	{	// || < 0x22
			continue;
		}
		if('&'==c)		{	// 0x26
   			// &amp;
			dst_len+=4;
   		}else if('"'==c)	{	// 0x22
   			// &quot;
			dst_len+=5;
   		}else if('\''==c)	{	// 0x27
			// &apos;
   			dst_len+=5;
		}else if('<'==c)	{	// 0x3C
   			// &lt;
			dst_len+=3;
   		}else if('>'==c)	{	// 0x3E
			// &gt;
   			dst_len+=3;
		}//if
*/
	}//while

        if(dst_len == src_len)	{
#if XQ_DEBUG
		warn("nothing to quote\n");
#endif
        	// nothing to quote
		dstSV=newSVpv(src, dst_len);
#ifdef XML_Util_UTF8
   		if(SvUTF8(srcSV))
   			SvUTF8_on(dstSV);
#endif
		return dstSV;
        }

#if XQ_DEBUG
	warn("dest length=%i\n",dst_len);
#endif

   	dstSV=newSV(dst_len);
	SvCUR_set(dstSV, dst_len);
	SvPOK_on(dstSV);
#ifdef XML_Util_UTF8
   	if(SvUTF8(srcSV))
		SvUTF8_on(dstSV);
#endif

   	dst=SvPVX(dstSV);

   	while(src_len--)	{	// \0 also copied
		c=*src++;
#if XQ_DEBUG
		warn("src_len=%i symbol=%c src=%lx\n",src_len,c,src);
#endif
//		if(c > 0x3E || c < 0x22)	{
		if(c > 0x3E || ! XQ_quote_add[c])	{
			*dst++=c;
			continue;
		}
/*	it's overkill
#ifdef XML_Util_UTF8
		// really 'dst_len' has other semantic (i.e. 'sym_len')
		// I just reuse it ;)
		dst_len=PL_utf8skip[c];	//dst_len=UTF8SKIP(c);
		if(dst_len > 1)	{
   			*dst++=c;
			while(--dst_len)	{
				*dst++=*src++;
				src_len--;
			}
			continue;
		}
#endif
*/
		*dst++='&';
		if('&'==c)		{	// 0x26
   			// &amp;
			*dst++='a'; *dst++='m'; *dst++='p';
		}else if('>'==c)	{	// 0x3E
   			// &gt;
   			*dst++='g'; *dst++='t';
		}else if('<'==c)	{	// 0x3C
   			// &lt;
   			*dst++='l'; *dst++='t';
		}else if('"'==c)	{	// 0x22
   			// &quot;
			*dst++='q'; *dst++='u'; *dst++='o'; *dst++='t';
//		}else if('\''==c)	{	// 0x27
		}else	{
   			// &apos;
   			*dst++='a'; *dst++='p'; *dst++='o'; *dst++='s';
   		}//if
		*dst++=';';
	}//while

	return dstSV;
}
//////////////////////////////////////////////////////////////////////////////

static SV *
xml_quote_min(SV * srcSV)	{
	SV      * dstSV;
	unsigned char	* src, * src2;
	unsigned char	* dst;
	unsigned char c;
	STRLEN  src_len, src_len2, dst_len, offset;

	src=SvPV(srcSV, src_len);	//length without trailing \0

#if XQ_DEBUG
	warn("source=%s\n",src);
	warn("src=%p\n",src);
#endif

	dst_len=src_len;
	src2=src;
	src_len2=src_len;

#if XQ_DEBUG
	warn("source length=%i\n",src_len);
#endif

	// calculate target string length
	while(src_len2--)	{
		c=*src2++;
		if(c < 0x3D && (offset=XQ_quote_add_min[c]) )	{
#if XQ_DEBUG
			warn("add offset=%i [symbol=%i]\n",offset,c);
#endif
			dst_len+=offset;
		}
	}//while

        if(dst_len == src_len)	{
#if XQ_DEBUG
		warn("nothing to quote\n");
#endif
        	// nothing to quote
		dstSV=newSVpv(src, dst_len);
#ifdef XML_Util_UTF8
   		if(SvUTF8(srcSV))
   			SvUTF8_on(dstSV);
#endif
		return dstSV;
        }

#if XQ_DEBUG
	warn("dest length=%i\n",dst_len);
#endif

   	dstSV=newSV(dst_len);
	SvCUR_set(dstSV, dst_len);
	SvPOK_on(dstSV);
#ifdef XML_Util_UTF8
   	if(SvUTF8(srcSV))
		SvUTF8_on(dstSV);
#endif

   	dst=SvPVX(dstSV);

   	while(src_len--)	{	// \0 also copied
		c=*src++;
#if XQ_DEBUG
		warn("src_len=%i symbol=%c src=%lx\n",src_len,c,src);
#endif
		if(c > 0x3C || ! XQ_quote_add_min[c])	{
			*dst++=c;
			continue;
		}

		*dst++='&';
		if('&'==c)		{	// 0x26
   			// &amp;
			*dst++='a'; *dst++='m'; *dst++='p';
		}else if('<'==c)	{	// 0x3C
   			// &lt;
   			*dst++='l'; *dst++='t';
//		}else if('"'==c)	{	// 0x22
		}else	{
   			// &quot;
			*dst++='q'; *dst++='u'; *dst++='o'; *dst++='t';
   		}//if
		*dst++=';';
	}//while

	return dstSV;
}
//////////////////////////////////////////////////////////////////////////////
static SV *
xml_dequote(SV * srcSV)	{
	SV      * dstSV;
	unsigned char	* src, *src2;
	unsigned char	* dst;
	unsigned char c,c1,c2,c3,c4;
	STRLEN  src_len, src_len2, dst_len;

	src=SvPV(srcSV, src_len);	//length without trailing \0
//	warn("src_len=%i",src_len);
	src2=src;
	src_len2=src_len;
	dst_len=src_len;

	// calculate dequoted string length
	while(src_len >=3)	{
		c=*src++;
		src_len--;

		if('&'!=c)	{
			continue;
		}
		/*
		&amp;
		&quot;
		&apos;
		&lt;
		&gt;
		*/
		c=*src;
		c1=*(src+1);
		c2=*(src+2);
		if(c2==';' && c1=='t' && (c=='l' || c=='g'))	{
			dst_len-=3;
			src+=3;
   			src_len-=3;
			continue;
		}

		if(src_len >= 4)	{
			c3=*(src+3);
		}else	{
			continue;
		}

		if(c=='a' && c1=='m' && c2=='p' && c3==';')	{
			dst_len-=4;
			src+=4;
   			src_len-=4;
			continue;
		}

		if(src_len >= 5)	{
			c4=*(src+4);
		}else	{
			continue;
		}

		if(c4==';'
		&& (
			(c=='q' && c1=='u' && c2=='o' && c3=='t')
			||
			(c=='a' && c1=='p' && c2=='o' && c3=='s')
		   )
		)  {
			dst_len-=5;
			src+=5;
			src_len-=5;
			continue;
		}//if
	}//while

        if(dst_len == src_len2)	{
        	// nothing to dequote
		dstSV=newSVpv(src2, dst_len);
#ifdef XML_Util_UTF8
   		if(SvUTF8(srcSV))
   			SvUTF8_on(dstSV);
#endif
//		warn("nothing to dequote");
		return dstSV;
        }

//   	dstSV=newSVpv("", dst_len);
   	dstSV=newSV(dst_len);
	SvCUR_set(dstSV, dst_len);
	SvPOK_on(dstSV);
#ifdef XML_Util_UTF8
   	if(SvUTF8(srcSV))
		SvUTF8_on(dstSV);
#endif
	dst=SvPVX(dstSV);

   	while(src_len2>=3)	{	// 3 is min length of quoted symbol
		c=*src2++;
		src_len2--;
		if('&'!=c)	{
			*dst++=c;
			continue;
		}
		c=*src2;
		c1=*(src2+1);
		c2=*(src2+2);

		// 1. test len=3: &lt; &gt;
		if(c1=='t' && c2==';')	{
			if(c=='l')	{
				*dst++='<';
				src2+=3;
				src_len2-=3;
				continue;
			}else if(c=='g')	{
				*dst++='>';
			}else	{
				*dst++='&';
				continue;
			}
   			src2+=3;
   			src_len2-=3;
   			continue;
		}//if lt | gt

		
		// 2. test len=4: &amp;
		if(src_len2 >= 4)	{
			c3=*(src2+3);
		}else	{
			*dst++='&';
			continue;
		}

		if(c=='a' && c1=='m' && c2=='p' && c3==';')	{
			*dst++='&';
			src2+=4;
   			src_len2-=4;
			continue;
		}

		// 3. test len=5: &quot; &apos;
		if(src_len2 >= 5)	{
			c4=*(src2+4);
		}else	{
			*dst++='&';
			continue;
		}

		if(c4==';')	{
			if(c=='q' && c1=='u' && c2=='o' && c3=='t')	{
				*dst++='"';
			}else if(c=='a' && c1=='p' && c2=='o' && c3=='s') {
				*dst++='\'';
			}else	{
				*dst++='&';
				continue;
			}
			src2+=5;
   			src_len2-=5;
			continue;
		}//if ;

		*dst++='&';
	}//while


   	while(src_len2-- > 0)	{	// also copy trailing \0
		*dst++=*src2++;
	}

	return dstSV;
}
//////////////////////////////////////////////////////////////////////////////

MODULE = XML::Quote		PACKAGE = XML::Quote


SV *
xml_quote(string)
   SV *string
   INIT:
	if(!SvOK(string))	{
		XSRETURN_UNDEF;
	}
   CODE:
	RETVAL = xml_quote(string);
   OUTPUT:
	RETVAL


SV *
xml_quote_min(string)
   SV *string
   INIT:
	if(!SvOK(string))	{
		XSRETURN_UNDEF;
	}
   CODE:
	RETVAL = xml_quote_min(string);
   OUTPUT:
	RETVAL


SV *
xml_dequote(string)
   SV *string
   INIT:
	if(!SvOK(string))	{
		XSRETURN_UNDEF;
	}
   CODE:
	RETVAL = xml_dequote(string);
   OUTPUT:
	RETVAL

