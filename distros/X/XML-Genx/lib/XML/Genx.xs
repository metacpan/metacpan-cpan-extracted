/*
 * Copyright (C) 1992-2004 Dominic Mitchell. All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/* @(#) $Id: Genx.xs 1267 2006-10-08 17:07:38Z dom $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "genx.h"

/* 
 * We use a typemap to change the underscore into a double colon.
 * This makes it easier to get things of the right class used.
 */

typedef genxWriter    XML_Genx;
typedef genxNamespace XML_Genx_Namespace;
typedef genxElement   XML_Genx_Element;
typedef genxAttribute XML_Genx_Attribute;

/*
 * Initialize the hash inside the writer, reusing the existing one if
 * possible.  This should be called by each StartDocFoo().
 */

static HV *
initSelfUserData( genxWriter w )
{
    HV *self = (HV *)genxGetUserData( w );
    if ( self != NULL ) {
        hv_clear( self );
    } else {
        self = newHV();
        genxSetUserData( w, self );
    }
    return self;
}

/*
 * DEBUG -- uncomment to use.  This is just a convenience function for
 * seeing what's inside an object.
 */

#ifdef notdef
static void
dump_self( genxWriter w, const char *msg )
{
    dSP;
    HV *self = (HV *)genxGetUserData( w );
    CV *dump;
    ENTER;
    SAVETMPS;

    /* Set up the stack. */
    PUSHMARK(SP);
    /* Don't bother creating a reference here. */
    XPUSHs((SV *)self);
    PUTBACK;

    SPAGAIN;                    /* XXX Necessary? */

    if ( msg )
        warn( msg );

    if ( self != NULL ) {
        (void)eval_pv("use Devel::Peek;", TRUE);
        if ((dump = get_cv("Devel::Peek::Dump", FALSE)) != NULL ) {
            call_sv( (SV *)dump, G_VOID );
        } else {
            warn("Devel::Peek not loaded!");
        }
    } else {
        warn("No hash in self to dump!");
    }

    FREETMPS;
    LEAVE;
}
#endif

static genxStatus
sender_write( void *userData, constUtf8 s )
{
    dSP;
    HV *self = (HV *)userData;
    SV **svp;
    SV *str = newSVpv( (const char *)s, 0 );
    ENTER;
    SAVETMPS;

    /* genx guarantees that thus will be UTF-8, so tell Perl that. */
    SvUTF8_on(str);

    /* Set up the stack. */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(str));
    XPUSHs(sv_2mortal(newSVpv("write", 5)));
    PUTBACK;

    /* Do the business. */
    if ((svp = hv_fetch( self, "callback", 8, 0 )))
        (void)call_sv( *svp, G_VOID );

    SPAGAIN;                    /* XXX Necessary? */

    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxStatus
sender_write_bounded( void *userData, constUtf8 start, constUtf8 end )
{
    dSP;
    HV *self = (HV *)userData;
    SV **svp;
    SV *str = newSVpv((const char *)start, end - start);
    ENTER;
    SAVETMPS;

    /* genx guarantees that thus will be UTF-8, so tell Perl that. */
    SvUTF8_on(str);

    /* Set up the stack. */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(str));
    XPUSHs(sv_2mortal(newSVpv("write_bounded", 13)));
    PUTBACK;

    /* Do the business. */
    if ((svp = hv_fetch( self, "callback", 8, 0 )))
        (void)call_sv( *svp, G_VOID );

    SPAGAIN;                    /* XXX Necessary? */

    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxStatus
sender_flush( void *userData )
{
    dSP;
    HV *self = (HV *)userData;
    SV **svp;
    ENTER;
    SAVETMPS;

    /* Set up the stack. */
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("", 0)));
    XPUSHs(sv_2mortal(newSVpv("flush", 5)));
    PUTBACK;

    /* Do the business. */
    if ((svp = hv_fetch( self, "callback", 8, 0 )))
        (void)call_sv( *svp, G_VOID );

    SPAGAIN;                    /* XXX Necessary? */

    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxSender sender = {
    sender_write,
    sender_write_bounded,
    sender_flush
};

/*
 * Some helper functions for automatically appending genx output into a
 * string.  The string is stored inside a hash, which genx's userData
 * field holds for us.
 */

static genxStatus
string_sender_write( void *userData, constUtf8 s )
{
    HV *self = (HV *)userData;
    SV **svp;
    ENTER;
    SAVETMPS;
    if ((svp = hv_fetch( self, "string", 6, 0 )))
        sv_catpv( *svp, (const char *)s );
    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxStatus
string_sender_write_bounded( void *userData, constUtf8 start, constUtf8 end )
{
    HV *self = (HV *)userData;
    SV **svp;
    ENTER;
    SAVETMPS;
    if ((svp = hv_fetch( self, "string", 6, 0 )))
        sv_catpvn( *svp, (const char *)start, end - start );
    FREETMPS;
    LEAVE;
    return GENX_SUCCESS;
}

static genxStatus
string_sender_flush( void *userData ) {
    return GENX_SUCCESS;
}

static genxSender string_sender = {
    string_sender_write,
    string_sender_write_bounded,
    string_sender_flush
};

/*
 * Small utility function to throw the correct exception.
 */
static void
croak_on_genx_error( genxWriter w, genxStatus st )
{
    char *msg;

    if ( st == GENX_SUCCESS ) {
        msg = NULL;
    } else if ( w ) {
        msg = genxLastErrorMessage( w );
    } else {
        /* 
         * If we don't have a writer object handy, make one for this
         * purpose.  This is slow, but unavoidable.
         */
        w = genxNew( NULL, NULL, NULL );
        msg = genxGetErrorMessage( w, st );
        genxDispose( w );
        w = NULL;
    }

    /*
     * We rely on the writer object to store the associated status code
     * for us.
     */
    if ( msg )
        croak( msg );
}

/*
 * Extract the namespace URI from an SV.  If it's a string, just use
 * that string.  If it's a namespace object, extract the uri from there.
 * If it's undef, return NULL to indicate no namespace.
 */
static constUtf8
sv_to_namespace_uri( SV* thing )
{
    /* not defined? */
    if (!SvTRUE(thing))
        return NULL;

    if (sv_isobject(thing) && sv_derived_from(thing, "XML::Genx::Namespace")) {
        /* This is similiar to the typemap T_PTROBJ_SPECIAL. */
        IV tmp = SvIV((SV*)SvRV(thing));
        genxNamespace ns = INT2PTR(genxNamespace, tmp);
        /* I added this "back door" call to genx. */
        constUtf8 uri = (constUtf8)genxGetNamespaceUri(ns);
        return uri;
    } else {
        return (constUtf8)SvPV_nolen(thing);
    }
}

MODULE = XML::Genx	PACKAGE = XML::Genx	PREFIX=genx

PROTOTYPES: DISABLE

# We work around the typemap and do things ourselves since it's
# otherwise hard to get the class name correct.  Doing things this way
# ensures that we are subclassable.  Example taken from Digest::MD5.
void
new( klass )
    char* klass
  INIT:
    XML_Genx w;
  PPCODE:
    w = genxNew( NULL, NULL, NULL );
    ST( 0 ) = sv_newmortal();
    sv_setref_pv( ST(0), klass, (void*)w );
    SvREADONLY_on(SvRV(ST(0)));
    XSRETURN( 1 );

void
DESTROY( w )
    XML_Genx w
  PREINIT:
    HV *self;
  CODE:
    self = (HV *)genxGetUserData( w );
    /* 
     * Ensure that Perl can clean up this hash now that nothing's
     * referencing it.
     */
    if ( self != NULL )
        SvREFCNT_dec( self );
    genxDispose( w );

genxStatus
genxStartDocFile( w, fh )
    XML_Genx w
    FILE *fh
  PREINIT:
    Stat_t st;
    HV *self;
    SV *fhsv;
  INIT:
    self = initSelfUserData( w );
    /* 
     * Sometimes we get back a filehandle with an invalid file
     * descriptor instead of NULL.  So use fstat() to check that it's
     * actually live and usable.
     *
     * Many thanks to http://www.testdrive.hp.com/ for providing a
     * service that let me find this out when I couldn't reproduce it
     * on my own box.
     */
    if ( fh == NULL || fstat(fileno(fh), &st) == -1 )
      croak( "Bad filehandle" );
    /* Store a the filehandle in ourselves. */
    fhsv = SvROK( ST(1) ) ? SvRV( ST(1) ) : ST(1);
    if (!hv_store( self, "fh", 2, SvREFCNT_inc(fhsv), 0))
        SvREFCNT_dec( fhsv );
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

genxStatus
genxStartDocSender( w, callback )
    XML_Genx w
    SV *callback
  PREINIT:
    HV *self;
  CODE:
    self = initSelfUserData( w );
    if (!hv_store( self, "callback", 8, SvREFCNT_inc(callback), 0 ))
        SvREFCNT_dec( callback );
    RETVAL = genxStartDocSender( w, &sender );
  POSTCALL:
    croak_on_genx_error( w, RETVAL );
  OUTPUT:
    RETVAL

genxStatus
genxEndDocument( w )
    XML_Genx w
  PREINIT:
    HV *self;
  POSTCALL:
    self = (HV *)genxGetUserData( w );
    /* Decrement the reference count on the filehandle. */
    hv_delete( self, "fh", 2, G_DISCARD );
    croak_on_genx_error( w, RETVAL );

# Take a variable length list so that we can make the namespace
# parameter optional.  Even when present, it will only be used if it's
# a true value.
genxStatus
genxStartElementLiteral( w, ... )
    XML_Genx w
  PREINIT:
    constUtf8  xmlns;
    constUtf8  name;
  INIT:
    if ( items == 2 ) {
        xmlns = NULL;
        name  = (constUtf8)SvPV_nolen(ST(1));
    } else if ( items == 3 ) {
        xmlns = sv_to_namespace_uri(ST(1));
        name  = (constUtf8)SvPV_nolen(ST(2));
    } else {
        croak( "Usage: w->StartElementLiteral([xmlns],name)" );
    }
  CODE:
    RETVAL = genxStartElementLiteral( w, xmlns, name );
  POSTCALL:
    croak_on_genx_error( w, RETVAL );
  OUTPUT:
    RETVAL

# Same design as StartElementLiteral().
genxStatus
genxAddAttributeLiteral( w, ... )
    XML_Genx w
  PREINIT:
    constUtf8  xmlns;
    constUtf8  name;
    constUtf8  value;
  INIT:
    if ( items == 3 ) {
        xmlns = NULL;
        name  = (constUtf8)SvPV_nolen(ST(1));
        value = (constUtf8)SvPV_nolen(ST(2));
    } else if ( items == 4 ) {
        xmlns = sv_to_namespace_uri(ST(1));
        name  = (constUtf8)SvPV_nolen(ST(2));
        value = (constUtf8)SvPV_nolen(ST(3));
    } else {
        croak( "Usage: w->AddAttributeLiteral([xmlns],name,value)" );
    }
  CODE:
    RETVAL = genxAddAttributeLiteral( w, xmlns, name, value );
  POSTCALL:
    croak_on_genx_error( w, RETVAL );
  OUTPUT:
    RETVAL

genxStatus
genxEndElement( w )
    XML_Genx w
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

char *
genxLastErrorMessage( w )
    XML_Genx w

# This is an extension of the genx API.
int
genxLastErrorCode( w )
    XML_Genx w
  CODE:
    RETVAL = genxGetStatusCode( w );
  OUTPUT:
    RETVAL

char *
genxGetErrorMessage( w, st )
    XML_Genx w
    genxStatus st

genxStatus
genxAddText( w, start )
    XML_Genx w
    constUtf8 start
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

genxStatus
genxAddCharacter( w, c )
    XML_Genx w
    int c
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

genxStatus
genxComment( w, text )
    XML_Genx w
    constUtf8 text
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

genxStatus
genxPI( w, target, text );
    XML_Genx w
    constUtf8 target
    constUtf8 text
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

genxStatus
genxUnsetDefaultNamespace( w )
    XML_Genx w
  POSTCALL:
    croak_on_genx_error( w, RETVAL );

char *
genxGetVersion( class )
    char * class
  CODE:
    /* avoid unused variable warning. */
    (void)class;
    RETVAL = genxGetVersion();
  OUTPUT:
    RETVAL

# We need to map an undef prefix to NULL.  But we want to pass an
# empty prefix straight through as that means "default".
void
genxDeclareNamespace( w, uri, ... )
    XML_Genx w
    constUtf8  uri
  PREINIT:
    constUtf8     prefix;
    XML_Genx_Namespace ns;
    genxStatus    st = GENX_SUCCESS;
  INIT:
    if ( items == 2 )
        prefix = NULL;
    else if ( items == 3 )
        prefix = SvOK(ST(2)) ? (constUtf8)SvPV_nolen(ST(2)) : NULL;
    else
        croak( "usage: w->DeclareNamespace(uri,[defaultPrefix])" );
  PPCODE:
    ns = genxDeclareNamespace( w, uri, prefix, &st );
    croak_on_genx_error( w, st );
    ST( 0 ) = sv_newmortal();
    sv_setref_pv( ST(0), "XML::Genx::Namespace", (void*)ns );
    SvREADONLY_on(SvRV(ST(0)));
    XSRETURN( 1 );

void
genxDeclareElement( w, ... )
    XML_Genx    w
  PREINIT:
    genxStatus         st = GENX_SUCCESS;
    XML_Genx_Element   el;
    XML_Genx_Namespace ns;
    constUtf8          type;
  PPCODE:
    if ( items == 2 ) {
        ns = (XML_Genx_Namespace) NULL;
        type = (constUtf8)SvPV_nolen(ST(1));
    } else if ( items == 3 ) {
        /*  Bleargh, would be nice to be able to reuse typemap here */
        if (!SvOK(ST(1))) {
            ns = (XML_Genx_Namespace) NULL;
        } else if (sv_derived_from(ST(1), "XML::Genx::Namespace")) {
            IV tmp = SvIV((SV*)SvRV(ST(1)));
            ns = INT2PTR(XML_Genx_Namespace, tmp);
        } else {
            croak("ns is not undef or of type XML::Genx::Namespace");
        }
        type = (constUtf8)SvPV_nolen(ST(2));
    } else {
        croak( "Usage: w->DeclareElement([ns],type)" );
    }
    el = genxDeclareElement( w, ns, type, &st );
    croak_on_genx_error( w, st );
    ST( 0 ) = sv_newmortal();
    sv_setref_pv( ST(0), "XML::Genx::Element", (void*)el );
    SvREADONLY_on(SvRV(ST(0)));
    XSRETURN( 1 );

void
genxDeclareAttribute( w, ... )
    XML_Genx    w
  PREINIT:
    genxStatus         st = GENX_SUCCESS;
    XML_Genx_Attribute at;
    XML_Genx_Namespace ns;
    constUtf8          name;
  PPCODE:
    if ( items == 2 ) {
        ns = (XML_Genx_Namespace) NULL;
        name = (constUtf8)SvPV_nolen(ST(1));
    } else if ( items == 3 ) {
        /*  Bleargh, would be nice to be able to reuse typemap here */
        if (!SvOK(ST(1))) {
            ns = (XML_Genx_Namespace) NULL;
        } else if (sv_derived_from(ST(1), "XML::Genx::Namespace")) {
            IV tmp = SvIV((SV*)SvRV(ST(1)));
            ns = INT2PTR(XML_Genx_Namespace, tmp);
        } else {
            croak("ns is not undef or of type XML::Genx::Namespace");
        }
        name = (constUtf8)SvPV_nolen(ST(2));
    } else {
        croak( "Usage: w->DeclareAttribute([ns],name)" );
    }
    at = genxDeclareAttribute( w, ns, name, &st );
    if ( at && st == GENX_SUCCESS ) {
        ST( 0 ) = sv_newmortal();
        sv_setref_pv( ST(0), "XML::Genx::Attribute", (void*)at );
        SvREADONLY_on(SvRV(ST(0)));
        XSRETURN( 1 );
    } else {
        XSRETURN_UNDEF;
    }

SV *
genxScrubText( w, in )
    XML_Genx w
    SV *in
  CODE:
    RETVAL = newSVsv( in );
    (void)genxScrubText( w, (constUtf8) SvPV_nolen( in ), (utf8) SvPV_nolen( RETVAL ) );
    /* Fix up the new length. */
    SvCUR_set( RETVAL, strlen( SvPV_nolen( RETVAL ) ) );
  OUTPUT:
    RETVAL

MODULE = XML::Genx	PACKAGE = XML::Genx::Namespace	PREFIX=genx

utf8
genxGetNamespacePrefix( ns )
    XML_Genx_Namespace ns

genxStatus
genxAddNamespace(ns, ...);
    XML_Genx_Namespace ns
  PREINIT:
    utf8 prefix;
  CODE:
    if ( items == 1 )
        prefix = NULL;
    else if ( items == 2 )
        prefix = SvOK(ST(1)) ? (utf8)SvPV_nolen(ST(1)) : NULL;
    else
        croak( "Usage: ns->AddNamespace([prefix])" );
    RETVAL = genxAddNamespace( ns, prefix );
  POSTCALL:
    croak_on_genx_error( genxGetNamespaceWriter( ns ), RETVAL );
  OUTPUT:
    RETVAL

MODULE = XML::Genx	PACKAGE = XML::Genx::Element	PREFIX=genx

genxStatus
genxStartElement( e )
    XML_Genx_Element e
  POSTCALL:
    croak_on_genx_error( genxGetElementWriter( e ), RETVAL );

MODULE = XML::Genx	PACKAGE = XML::Genx::Attribute	PREFIX=genx

genxStatus
genxAddAttribute( a, value )
    XML_Genx_Attribute a
    constUtf8 value
  POSTCALL:
      croak_on_genx_error( genxGetAttributeWriter( a ), RETVAL );

MODULE = XML::Genx	PACKAGE = XML::Genx::Constants

# It would really be very good indeed to get these automatically generated...
genxStatus
GENX_SUCCESS()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_SUCCESS;
  OUTPUT:
    RETVAL

genxStatus
GENX_BAD_UTF8()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_BAD_UTF8;
  OUTPUT:
    RETVAL

genxStatus
GENX_NON_XML_CHARACTER()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_NON_XML_CHARACTER;
  OUTPUT:
    RETVAL

genxStatus
GENX_BAD_NAME()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_BAD_NAME;
  OUTPUT:
    RETVAL

genxStatus
GENX_ALLOC_FAILED()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_ALLOC_FAILED;
  OUTPUT:
    RETVAL

genxStatus
GENX_BAD_NAMESPACE_NAME()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_BAD_NAMESPACE_NAME;
  OUTPUT:
    RETVAL

genxStatus
GENX_INTERNAL_ERROR()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_INTERNAL_ERROR;
  OUTPUT:
    RETVAL

genxStatus
GENX_DUPLICATE_PREFIX()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_DUPLICATE_PREFIX;
  OUTPUT:
    RETVAL

genxStatus
GENX_SEQUENCE_ERROR()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_SEQUENCE_ERROR;
  OUTPUT:
    RETVAL

genxStatus
GENX_NO_START_TAG()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_NO_START_TAG;
  OUTPUT:
    RETVAL

genxStatus
GENX_IO_ERROR()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_IO_ERROR;
  OUTPUT:
    RETVAL

genxStatus
GENX_MISSING_VALUE()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_MISSING_VALUE;
  OUTPUT:
    RETVAL

genxStatus
GENX_MALFORMED_COMMENT()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_MALFORMED_COMMENT;
  OUTPUT:
    RETVAL

genxStatus
GENX_XML_PI_TARGET()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_XML_PI_TARGET;
  OUTPUT:
    RETVAL

genxStatus
GENX_MALFORMED_PI()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_MALFORMED_PI;
  OUTPUT:
    RETVAL

genxStatus
GENX_DUPLICATE_ATTRIBUTE()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_DUPLICATE_ATTRIBUTE;
  OUTPUT:
    RETVAL

genxStatus
GENX_ATTRIBUTE_IN_DEFAULT_NAMESPACE()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_ATTRIBUTE_IN_DEFAULT_NAMESPACE;
  OUTPUT:
    RETVAL

genxStatus
GENX_DUPLICATE_NAMESPACE()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_DUPLICATE_NAMESPACE;
  OUTPUT:
    RETVAL

genxStatus
GENX_BAD_DEFAULT_DECLARATION()
  PROTOTYPE:
  CODE:
    RETVAL = GENX_BAD_DEFAULT_DECLARATION;
  OUTPUT:
    RETVAL

MODULE = XML::Genx	PACKAGE = XML::Genx::Simple	PREFIX=genx

# Our own add on.  This provides a way of getting the output of genx
# into a string without the overhead of popping back into Perl the whole
# time.
genxStatus
genxStartDocString( w )
    XML_Genx w
  PREINIT:
    HV *self;
  CODE:
    self = initSelfUserData( w );
    /* No need to inc ref count as we're creating the SV here. */
    (void)hv_store( self, "string", 6, newSVpv("", 0), 0 );
    RETVAL = genxStartDocSender( w, &string_sender );
  OUTPUT:
    RETVAL

SV *
genxGetDocString( w )
    XML_Genx w
  PREINIT:
    HV *self;
    SV **svp;
  CODE:
    self = (HV *)genxGetUserData( w );
    /* 
     * Fetch the string out of ourselves.  Ensure that it gets sent back
     * as UTF-8, which genx guarantees for us.
     */
    if ((svp = hv_fetch(self, "string", 6, 0))) {
        SvUTF8_on( *svp );
        SvREFCNT_inc( *svp );
        RETVAL = *svp;
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL
